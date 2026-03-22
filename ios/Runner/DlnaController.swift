import Foundation

final class DlnaController: NSObject {

    private let avTransportURN = "urn:schemas-upnp-org:service:AVTransport:1"
    private let renderingControlURN = "urn:schemas-upnp-org:service:RenderingControl:1"
    private let ssdpAddress = "239.255.255.250"
    private let ssdpPort: UInt16 = 1900
    private let discoveryTimeoutSeconds: TimeInterval = 3.0

    private var eventSink: (([String: Any]) -> Void)?
    private var activeDeviceControlUrl: String?
    private var activeDeviceRenderingControlUrl: String?
    private var pollTimer: DispatchSourceTimer?

    private var activeDeviceEventSubUrl: String?
    private var genaSubscriptionId: String?
    private var genaServerFd: Int32 = -1
    private var genaServerPort: UInt16 = 0
    private var genaRenewalTimer: DispatchSourceTimer?
    private var consecutivePollFailures: Int = 0
    private var discoveredEventSubUrls: [String: String] = [:]
    private var discoveredRenderingControlUrls: [String: String] = [:]

    private let session: URLSession = {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 5
        config.timeoutIntervalForResource = 10
        return URLSession(configuration: config)
    }()

    func setEventSink(_ sink: (([String: Any]) -> Void)?) {
        eventSink = sink
        if sink != nil && activeDeviceControlUrl != nil {
            emitEvent(state: "connected")
        } else if sink != nil {
            emitEvent(state: "disconnected")
        }
    }

    // MARK: - Discovery

    func discoverTargets(completion: @escaping ([[String: String]]) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else {
                DispatchQueue.main.async { completion([]) }
                return
            }

            var targets: [[String: String]] = []
            var fd: Int32 = -1

            do {
                fd = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)
                guard fd >= 0 else {
                    DispatchQueue.main.async { completion([]) }
                    return
                }

                var yes: Int32 = 1
                setsockopt(fd, SOL_SOCKET, SO_REUSEADDR, &yes, socklen_t(MemoryLayout<Int32>.size))

                var timeout = timeval(tv_sec: Int(self.discoveryTimeoutSeconds), tv_usec: 0)
                setsockopt(fd, SOL_SOCKET, SO_RCVTIMEO, &timeout, socklen_t(MemoryLayout<timeval>.size))

                let searchMessage = [
                    "M-SEARCH * HTTP/1.1",
                    "HOST: \(self.ssdpAddress):\(self.ssdpPort)",
                    "MAN: \"ssdp:discover\"",
                    "MX: 2",
                    "ST: \(self.avTransportURN)",
                    "", "",
                ].joined(separator: "\r\n")

                guard let data = searchMessage.data(using: .utf8) else {
                    if fd >= 0 { close(fd) }
                    DispatchQueue.main.async { completion([]) }
                    return
                }

                var addr = sockaddr_in()
                addr.sin_family = sa_family_t(AF_INET)
                addr.sin_port = self.ssdpPort.bigEndian
                inet_pton(AF_INET, self.ssdpAddress, &addr.sin_addr)

                let sent = data.withUnsafeBytes { ptr in
                    withUnsafePointer(to: &addr) { addrPtr in
                        addrPtr.withMemoryRebound(to: sockaddr.self, capacity: 1) { sa in
                            sendto(fd, ptr.baseAddress, data.count, 0, sa, socklen_t(MemoryLayout<sockaddr_in>.size))
                        }
                    }
                }
                guard sent > 0 else {
                    if fd >= 0 { close(fd) }
                    DispatchQueue.main.async { completion([]) }
                    return
                }

                var seenLocations = Set<String>()
                let deadline = Date().addingTimeInterval(self.discoveryTimeoutSeconds)
                var buf = [UInt8](repeating: 0, count: 4096)

                while Date() < deadline {
                    let n = recv(fd, &buf, buf.count, 0)
                    if n <= 0 { break }
                    let response = String(bytes: buf[..<n], encoding: .utf8) ?? ""
                    guard let location = self.parseHeader(response, name: "LOCATION"),
                          !seenLocations.contains(location) else { continue }
                    seenLocations.insert(location)

                    if let deviceInfo = self.fetchDeviceDescription(locationUrl: location) {
                        targets.append(deviceInfo)
                    }
                }
            }

            if fd >= 0 { close(fd) }

            DispatchQueue.main.async { completion(targets) }
        }
    }

    // MARK: - Transport

    func playToDevice(
        targetId: String,
        streamUrl: String,
        title: String,
        startPositionTicks: Int64?,
        completion: @escaping (Error?) -> Void
    ) {
        emitEvent(state: "connecting")

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else {
                DispatchQueue.main.async {
                    completion(DlnaError.controllerDeallocated)
                }
                return
            }

            do {
                let controlUrl = targetId
                let startTime = self.formatDlnaTime(ticks: startPositionTicks)

                let metadataXml = "&lt;DIDL-Lite xmlns=&quot;urn:schemas-upnp-org:metadata-1-0/DIDL-Lite/&quot; xmlns:dc=&quot;http://purl.org/dc/elements/1.1/&quot;&gt;&lt;item&gt;&lt;dc:title&gt;\(self.escapeXml(title))&lt;/dc:title&gt;&lt;/item&gt;&lt;/DIDL-Lite&gt;"

                try self.sendSoap(
                    controlUrl: controlUrl,
                    action: "SetAVTransportURI",
                    innerBody: """
                    <InstanceID>0</InstanceID>
                    <CurrentURI>\(self.escapeXml(streamUrl))</CurrentURI>
                    <CurrentURIMetaData>\(metadataXml)</CurrentURIMetaData>
                    """
                )

                if let ticks = startPositionTicks, ticks > 0 {
                    try self.sendSoap(
                        controlUrl: controlUrl,
                        action: "Seek",
                        innerBody: """
                        <InstanceID>0</InstanceID>
                        <Unit>REL_TIME</Unit>
                        <Target>\(startTime)</Target>
                        """
                    )
                }

                try self.sendSoap(
                    controlUrl: controlUrl,
                    action: "Play",
                    innerBody: """
                    <InstanceID>0</InstanceID>
                    <Speed>1</Speed>
                    """
                )

                self.activeDeviceControlUrl = controlUrl
                self.activeDeviceRenderingControlUrl = self.discoveredRenderingControlUrls[controlUrl]
                self.consecutivePollFailures = 0
                let eventSubUrl = self.discoveredEventSubUrls[controlUrl]
                self.activeDeviceEventSubUrl = eventSubUrl
                self.startGenaServer()
                if let url = eventSubUrl { self.subscribeGena(eventSubUrl: url) }
                self.startPlaybackPolling()

                DispatchQueue.main.async { [weak self] in
                    self?.emitEvent(state: "connected")
                    completion(nil)
                }
            } catch {
                DispatchQueue.main.async { [weak self] in
                    self?.emitEvent(state: "error", message: error.localizedDescription)
                    completion(error)
                }
            }
        }
    }

    func pause(completion: @escaping (Error?) -> Void) {
        withActiveDevice(completion: completion) { controlUrl in
            try self.sendSoap(
                controlUrl: controlUrl,
                action: "Pause",
                innerBody: "<InstanceID>0</InstanceID>"
            )
        }
    }

    func play(completion: @escaping (Error?) -> Void) {
        withActiveDevice(completion: completion) { controlUrl in
            try self.sendSoap(
                controlUrl: controlUrl,
                action: "Play",
                innerBody: """
                <InstanceID>0</InstanceID>
                <Speed>1</Speed>
                """
            )
        }
    }

    func seek(positionTicks: Int64, completion: @escaping (Error?) -> Void) {
        withActiveDevice(completion: completion) { controlUrl in
            let target = self.formatDlnaTime(ticks: positionTicks)
            try self.sendSoap(
                controlUrl: controlUrl,
                action: "Seek",
                innerBody: """
                <InstanceID>0</InstanceID>
                <Unit>REL_TIME</Unit>
                <Target>\(target)</Target>
                """
            )
        }
    }

    func stop(completion: @escaping (Error?) -> Void) {
        withActiveDevice(completion: completion) { [weak self] controlUrl in
            try self?.sendSoap(
                controlUrl: controlUrl,
                action: "Stop",
                innerBody: "<InstanceID>0</InstanceID>"
            )
            self?.stopGena()
            self?.consecutivePollFailures = 0
            self?.stopPlaybackPolling()
            self?.activeDeviceControlUrl = nil
            self?.activeDeviceRenderingControlUrl = nil
            DispatchQueue.main.async {
                self?.emitEvent(state: "disconnected")
            }
        }
    }

    func cleanup() {
        stopPlaybackPolling()
        stopGena()
        consecutivePollFailures = 0
        activeDeviceControlUrl = nil
        activeDeviceRenderingControlUrl = nil
        eventSink = nil
    }

    func getVolume(completion: @escaping (Double?, Error?) -> Void) {
        guard let renderingUrl = activeDeviceRenderingControlUrl else {
            completion(nil, DlnaError.noActiveSession)
            return
        }

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else {
                DispatchQueue.main.async {
                    completion(nil, DlnaError.controllerDeallocated)
                }
                return
            }

            do {
                let response = try self.sendSoap(
                    controlUrl: renderingUrl,
                    action: "GetVolume",
                    innerBody: "<InstanceID>0</InstanceID><Channel>Master</Channel>",
                    serviceURN: self.renderingControlURN
                )
                let currentVolume = Double(self.parseXmlElement(xml: response, elementName: "CurrentVolume") ?? "0") ?? 0
                let normalized = max(0, min(1, currentVolume / 100.0))
                DispatchQueue.main.async {
                    completion(normalized, nil)
                }
            } catch {
                DispatchQueue.main.async { [weak self] in
                    self?.emitEvent(state: "error", message: error.localizedDescription)
                    completion(nil, error)
                }
            }
        }
    }

    func setVolume(_ volume: Double, completion: @escaping (Error?) -> Void) {
        guard let renderingUrl = activeDeviceRenderingControlUrl else {
            completion(DlnaError.noActiveSession)
            return
        }

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else {
                DispatchQueue.main.async {
                    completion(DlnaError.controllerDeallocated)
                }
                return
            }

            do {
                let clamped = max(0, min(1, volume))
                let targetVolume = Int(clamped * 100)
                _ = try self.sendSoap(
                    controlUrl: renderingUrl,
                    action: "SetVolume",
                    innerBody: "<InstanceID>0</InstanceID><Channel>Master</Channel><DesiredVolume>\(targetVolume)</DesiredVolume>",
                    serviceURN: self.renderingControlURN
                )
                DispatchQueue.main.async {
                    completion(nil)
                }
            } catch {
                DispatchQueue.main.async { [weak self] in
                    self?.emitEvent(state: "error", message: error.localizedDescription)
                    completion(error)
                }
            }
        }
    }

    // MARK: - Helpers

    private func withActiveDevice(
        completion: @escaping (Error?) -> Void,
        action: @escaping (String) throws -> Void
    ) {
        guard let controlUrl = activeDeviceControlUrl else {
            completion(DlnaError.noActiveSession)
            return
        }

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            do {
                try action(controlUrl)
                DispatchQueue.main.async { completion(nil) }
            } catch {
                DispatchQueue.main.async {
                    self?.emitEvent(state: "error", message: error.localizedDescription)
                    completion(error)
                }
            }
        }
    }

    private func parseHeader(_ response: String, name: String) -> String? {
        for line in response.components(separatedBy: "\r\n") {
            if line.lowercased().hasPrefix(name.lowercased() + ":") {
                return String(line.dropFirst(name.count + 1)).trimmingCharacters(in: .whitespaces)
            }
        }
        return nil
    }

    private func fetchDeviceDescription(locationUrl: String) -> [String: String]? {
        guard let url = URL(string: locationUrl),
              let data = try? Data(contentsOf: url) else { return nil }

        let parser = DlnaDeviceXMLParser(data: data, avTransportURN: avTransportURN)
        guard parser.parse(),
              let controlPath = parser.avTransportControlURL else { return nil }

        let controlUrl = resolveUrl(base: locationUrl, relative: controlPath)
        if let renderingControlPath = parser.renderingControlURL {
            discoveredRenderingControlUrls[controlUrl] = resolveUrl(base: locationUrl, relative: renderingControlPath)
        }
        if let eventSubPath = parser.avTransportEventSubURL {
            discoveredEventSubUrls[controlUrl] = resolveUrl(base: locationUrl, relative: eventSubPath)
        }
        let friendlyName = parser.friendlyName ?? "DLNA Device"
        let modelName = parser.modelName ?? ""

        return [
            "id": controlUrl,
            "title": friendlyName,
            "subtitle": modelName,
        ]
    }

    private func resolveUrl(base: String, relative: String) -> String {
        guard let baseURL = URL(string: base),
              let resolved = URL(string: relative, relativeTo: baseURL) else {
            return relative
        }
        return resolved.absoluteString
    }

        @discardableResult
        private func sendSoap(
            controlUrl: String,
            action: String,
            innerBody: String,
            serviceURN: String? = nil
        ) throws -> String {
                guard let url = URL(string: controlUrl) else {
                        throw DlnaError.invalidUrl
                }

            let effectiveServiceURN = serviceURN ?? avTransportURN

                let envelope = """
                <?xml version="1.0" encoding="utf-8"?>
                <s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
                    <s:Body>
                        <u:\(action) xmlns:u="\(effectiveServiceURN)">
                            \(innerBody)
                        </u:\(action)>
                    </s:Body>
                </s:Envelope>
                """

                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("text/xml; charset=\"utf-8\"", forHTTPHeaderField: "Content-Type")
                request.setValue("\"\(effectiveServiceURN)#\(action)\"", forHTTPHeaderField: "SOAPAction")
                request.httpBody = envelope.data(using: .utf8)

                let semaphore = DispatchSemaphore(value: 0)
                var responseData: Data?
                var responseError: Error?
                var statusCode = 0

                let task = session.dataTask(with: request) { data, response, error in
                        responseData = data
                        responseError = error
                        statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
                        semaphore.signal()
                }
                task.resume()
                semaphore.wait()

                if let error = responseError { throw error }
                if statusCode < 200 || statusCode >= 300 {
                        throw DlnaError.httpError(action: action, statusCode: statusCode)
                }
                return String(data: responseData ?? Data(), encoding: .utf8) ?? ""
        }

    private func formatDlnaTime(ticks: Int64?) -> String {
        guard let ticks, ticks > 0 else { return "00:00:00" }
        let totalSeconds = ticks / 10_000_000
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    private func escapeXml(_ text: String) -> String {
        return text
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&apos;")
    }

    private func emitEvent(state: String, message: String? = nil, positionTicks: Int64? = nil) {
        var event: [String: Any] = [
            "kind": "dlna",
            "state": state,
        ]
        if let message, !message.isEmpty { event["message"] = message }
        if let positionTicks, positionTicks > 0 { event["positionTicks"] = positionTicks }
        eventSink?(event)
    }

    private func startPlaybackPolling() {
        stopPlaybackPolling()
        let timer = DispatchSource.makeTimerSource(queue: DispatchQueue.global(qos: .utility))
        timer.schedule(deadline: .now() + 1.0, repeating: 1.0)
        timer.setEventHandler { [weak self] in
            self?.pollPlaybackState()
        }
        pollTimer = timer
        timer.resume()
    }

    private func stopPlaybackPolling() {
        pollTimer?.cancel()
        pollTimer = nil
    }

    private func pollPlaybackState() {
        guard let controlUrl = activeDeviceControlUrl else { return }
        do {
            let state = try queryTransportState(controlUrl: controlUrl)
            let positionTicks = try queryPositionTicks(controlUrl: controlUrl)
            let mappedState: String
            switch state {
            case "PLAYING": mappedState = "playing"
            case "PAUSED_PLAYBACK": mappedState = "paused"
            case "TRANSITIONING": mappedState = "buffering"
            default: mappedState = "idle"
            }
            DispatchQueue.main.async { [weak self] in
                self?.consecutivePollFailures = 0
                self?.emitEvent(state: mappedState, positionTicks: positionTicks)
            }
        } catch {
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.consecutivePollFailures += 1
                if self.consecutivePollFailures >= 3 {
                    self.handleDeviceOffline()
                }
            }
        }
    }

    private func queryTransportState(controlUrl: String) throws -> String {
        let response = try sendSoap(controlUrl: controlUrl, action: "GetTransportInfo", innerBody: "<InstanceID>0</InstanceID>")
        return parseXmlElement(xml: response, elementName: "CurrentTransportState") ?? "STOPPED"
    }

    private func queryPositionTicks(controlUrl: String) throws -> Int64 {
        let response = try sendSoap(controlUrl: controlUrl, action: "GetPositionInfo", innerBody: "<InstanceID>0</InstanceID>")
        let relTime = parseXmlElement(xml: response, elementName: "RelTime") ?? "00:00:00"
        return parseDlnaTime(relTime)
    }

    private func parseXmlElement(xml: String, elementName: String) -> String? {
        guard let data = xml.data(using: .utf8) else { return nil }
        let parser = SimpleXMLElementParser(data: data, targetElement: elementName)
        return parser.parse()
    }

    private func parseDlnaTime(_ time: String) -> Int64 {
        let parts = time.split(separator: ":")
        guard parts.count == 3 else { return 0 }
        let hours = Int64(parts[0]) ?? 0
        let minutes = Int64(parts[1]) ?? 0
        let secondsPart = parts[2].split(separator: ".")
        let seconds = Int64(secondsPart[0]) ?? 0
        return (hours * 3600 + minutes * 60 + seconds) * 10_000_000
    }

    // MARK: - GENA Event Subscription

    private func handleDeviceOffline() {
        guard activeDeviceControlUrl != nil else { return }
        stopPlaybackPolling()
        stopGena()
        activeDeviceControlUrl = nil
        activeDeviceRenderingControlUrl = nil
        consecutivePollFailures = 0
        emitEvent(state: "disconnected", message: "Device unreachable")
    }

    private func startGenaServer() {
        stopGenaServer()
        let fd = Darwin.socket(AF_INET, SOCK_STREAM, IPPROTO_TCP)
        guard fd >= 0 else { return }

        var reuseAddr: Int32 = 1
        setsockopt(fd, SOL_SOCKET, SO_REUSEADDR, &reuseAddr, socklen_t(MemoryLayout<Int32>.size))

        var addr = sockaddr_in()
        addr.sin_family = sa_family_t(AF_INET)
        addr.sin_port = 0
        addr.sin_addr.s_addr = INADDR_ANY

        let bindResult = withUnsafePointer(to: &addr) { ptr in
            ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) { sa in
                Darwin.bind(fd, sa, socklen_t(MemoryLayout<sockaddr_in>.size))
            }
        }
        guard bindResult == 0 else { Darwin.close(fd); return }

        var assignedAddr = sockaddr_in()
        var addrLen = socklen_t(MemoryLayout<sockaddr_in>.size)
        withUnsafeMutablePointer(to: &assignedAddr) { ptr in
            ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) { sa in
                getsockname(fd, sa, &addrLen)
            }
        }
        let port = UInt16(bigEndian: assignedAddr.sin_port)

        Darwin.listen(fd, 5)
        genaServerFd = fd
        genaServerPort = port

        let serverFd = fd
        Thread.detachNewThread { [weak self] in
            guard let self else { Darwin.close(serverFd); return }
            self.genaServerLoop(fd: serverFd)
        }
    }

    private func stopGenaServer() {
        if genaServerFd >= 0 {
            Darwin.close(genaServerFd)
            genaServerFd = -1
        }
        genaServerPort = 0
    }

    private func genaServerLoop(fd: Int32) {
        var buf = [UInt8](repeating: 0, count: 4096)
        while true {
            let clientFd = Darwin.accept(fd, nil, nil)
            if clientFd < 0 { break }

            var timeout = timeval(tv_sec: 5, tv_usec: 0)
            setsockopt(clientFd, SOL_SOCKET, SO_RCVTIMEO, &timeout, socklen_t(MemoryLayout<timeval>.size))

            var rawData = Data()
            var headerEnd: Data.Index? = nil
            let separator = Data([13, 10, 13, 10])

            readLoop: while rawData.count < 65536 {
                let n = Darwin.recv(clientFd, &buf, buf.count, 0)
                if n <= 0 { break }
                rawData.append(contentsOf: buf[..<n])
                if let range = rawData.range(of: separator) {
                    headerEnd = range.upperBound
                    break readLoop
                }
            }

            var body = ""
            if let headerEnd,
               let headerStr = String(data: rawData[rawData.startIndex..<headerEnd], encoding: .utf8) {
                let contentLength = headerStr.components(separatedBy: "\r\n")
                    .first { $0.lowercased().hasPrefix("content-length:") }
                    .flatMap { Int($0.dropFirst("content-length:".count).trimmingCharacters(in: .whitespaces)) }
                    ?? 0

                var bodyData = Data(rawData[headerEnd...])
                var remaining = contentLength - bodyData.count
                while remaining > 0 {
                    let n = Darwin.recv(clientFd, &buf, min(remaining, buf.count), 0)
                    if n <= 0 { break }
                    bodyData.append(contentsOf: buf[..<n])
                    remaining -= n
                }
                body = String(data: bodyData, encoding: .utf8) ?? ""
            }

            let response = "HTTP/1.1 200 OK\r\nContent-Length: 0\r\n\r\n"
            response.withCString { ptr in _ = Darwin.send(clientFd, ptr, strlen(ptr), 0) }
            Darwin.close(clientFd)

            if !body.isEmpty { handleGenaNotify(body: body) }
        }
    }

    private func getLocalIPAddress() -> String? {
        var ifaddrPtr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddrPtr) == 0 else { return nil }
        defer { freeifaddrs(ifaddrPtr) }
        var ptr = ifaddrPtr
        while let current = ptr {
            let interface = current.pointee
            if interface.ifa_addr.pointee.sa_family == UInt8(AF_INET) {
                let name = String(cString: interface.ifa_name)
                if name.hasPrefix("en") {
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                                &hostname, socklen_t(hostname.count), nil, 0, NI_NUMERICHOST)
                    return String(cString: hostname)
                }
            }
            ptr = current.pointee.ifa_next
        }
        return nil
    }

    private func subscribeGena(eventSubUrl: String) {
        let port = genaServerPort
        guard port > 0, let localIp = getLocalIPAddress() else { return }
        let callbackUrl = "http://\(localIp):\(port)/notify"
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self, let url = URL(string: eventSubUrl) else { return }
            var request = URLRequest(url: url)
            request.httpMethod = "SUBSCRIBE"
            request.setValue("<\(callbackUrl)>", forHTTPHeaderField: "CALLBACK")
            request.setValue("upnp:event", forHTTPHeaderField: "NT")
            request.setValue("Second-1800", forHTTPHeaderField: "TIMEOUT")

            let semaphore = DispatchSemaphore(value: 0)
            var allHeaders: [AnyHashable: Any]?
            let task = self.session.dataTask(with: request) { _, response, _ in
                allHeaders = (response as? HTTPURLResponse)?.allHeaderFields
                semaphore.signal()
            }
            task.resume()
            semaphore.wait()

            guard let sid = allHeaders?.first(where: { ($0.key as? String)?.lowercased() == "sid" })?.value as? String
            else { return }

            self.genaSubscriptionId = sid
            let renewTimer = DispatchSource.makeTimerSource(queue: DispatchQueue.global(qos: .utility))
            renewTimer.schedule(deadline: .now() + 25 * 60)
            renewTimer.setEventHandler { [weak self] in
                self?.renewGena(eventSubUrl: eventSubUrl, sid: sid)
            }
            self.genaRenewalTimer = renewTimer
            renewTimer.resume()
        }
    }

    private func renewGena(eventSubUrl: String, sid: String) {
        guard genaSubscriptionId == sid, let url = URL(string: eventSubUrl) else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "SUBSCRIBE"
        request.setValue(sid, forHTTPHeaderField: "SID")
        request.setValue("Second-1800", forHTTPHeaderField: "TIMEOUT")

        let semaphore = DispatchSemaphore(value: 0)
        let task = session.dataTask(with: request) { _, _, _ in semaphore.signal() }
        task.resume()
        semaphore.wait()

        guard genaSubscriptionId == sid else { return }
        let renewTimer = DispatchSource.makeTimerSource(queue: DispatchQueue.global(qos: .utility))
        renewTimer.schedule(deadline: .now() + 25 * 60)
        renewTimer.setEventHandler { [weak self] in
            self?.renewGena(eventSubUrl: eventSubUrl, sid: sid)
        }
        genaRenewalTimer = renewTimer
        renewTimer.resume()
    }

    private func unsubscribeGena() {
        genaRenewalTimer?.cancel()
        genaRenewalTimer = nil
        guard let eventSubUrl = activeDeviceEventSubUrl,
              let sid = genaSubscriptionId,
              let url = URL(string: eventSubUrl) else { return }
        genaSubscriptionId = nil

        var request = URLRequest(url: url)
        request.httpMethod = "UNSUBSCRIBE"
        request.setValue(sid, forHTTPHeaderField: "SID")
        session.dataTask(with: request) { _, _, _ in }.resume()
    }

    private func stopGena() {
        unsubscribeGena()
        stopGenaServer()
        activeDeviceEventSubUrl = nil
    }

    private func handleGenaNotify(body: String) {
        guard let outerData = body.data(using: .utf8) else { return }
        let outerParser = SimpleXMLElementParser(data: outerData, targetElement: "LastChange")
        guard let lastChangeXml = outerParser.parse(), !lastChangeXml.isEmpty else { return }
        guard let innerData = lastChangeXml.data(using: .utf8) else { return }
        let eventParser = GenaEventXMLParser(data: innerData)
        let (transportState, relTimeStr) = eventParser.parse()
        guard let state = transportState else { return }
        let mappedState: String
        switch state {
        case "PLAYING": mappedState = "playing"
        case "PAUSED_PLAYBACK": mappedState = "paused"
        case "TRANSITIONING": mappedState = "buffering"
        default: mappedState = "idle"
        }
        let positionTicks = relTimeStr.map { parseDlnaTime($0) }
        DispatchQueue.main.async { [weak self] in
            self?.consecutivePollFailures = 0
            self?.emitEvent(state: mappedState, positionTicks: positionTicks)
        }
    }
}

// MARK: - Simple XML Element Parser

private final class SimpleXMLElementParser: NSObject, XMLParserDelegate {
    private let parser: XMLParser
    private let targetElement: String
    private var currentText = ""
    private var result: String?

    init(data: Data, targetElement: String) {
        self.parser = XMLParser(data: data)
        self.targetElement = targetElement
        super.init()
        parser.delegate = self
    }

    func parse() -> String? {
        parser.parse()
        return result
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName: String?, attributes: [String: String] = [:]) {
        currentText = ""
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        currentText += string
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName: String?) {
        if elementName == targetElement && result == nil {
            result = currentText.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }
}

// MARK: - XML Parser for Device Description

private final class DlnaDeviceXMLParser: NSObject, XMLParserDelegate {
    private let parser: XMLParser
    private let avTransportURN: String

    var friendlyName: String?
    var modelName: String?
    var avTransportControlURL: String?
    var avTransportEventSubURL: String?
    var renderingControlURL: String?

    private var currentText = ""
    private var inService = false
    private var currentServiceType: String?
    private var currentControlURL: String?
    private var currentEventSubURL: String?

    init(data: Data, avTransportURN: String) {
        self.parser = XMLParser(data: data)
        self.avTransportURN = avTransportURN
        super.init()
        parser.delegate = self
    }

    func parse() -> Bool {
        return parser.parse()
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName: String?, attributes: [String: String] = [:]) {
        currentText = ""
        if elementName == "service" {
            inService = true
            currentServiceType = nil
            currentControlURL = nil
            currentEventSubURL = nil
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        currentText += string
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName: String?) {
        let trimmed = currentText.trimmingCharacters(in: .whitespacesAndNewlines)

        switch elementName {
        case "friendlyName":
            if friendlyName == nil { friendlyName = trimmed }
        case "modelName":
            if modelName == nil { modelName = trimmed }
        case "serviceType":
            if inService { currentServiceType = trimmed }
        case "controlURL":
            if inService { currentControlURL = trimmed }
        case "eventSubURL":
            if inService { currentEventSubURL = trimmed }
        case "service":
            if inService {
                if currentServiceType == avTransportURN, let url = currentControlURL {
                    avTransportControlURL = url
                    if let sub = currentEventSubURL { avTransportEventSubURL = sub }
                }
                if currentServiceType == "urn:schemas-upnp-org:service:RenderingControl:1", let url = currentControlURL {
                    renderingControlURL = url
                }
                inService = false
            }
        default:
            break
        }
    }
}

// MARK: - GENA LastChange Event XML Parser

private final class GenaEventXMLParser: NSObject, XMLParserDelegate {
    private let parser: XMLParser
    private var transportState: String?
    private var relativeTimePosition: String?

    init(data: Data) {
        self.parser = XMLParser(data: data)
        super.init()
        parser.delegate = self
    }

    func parse() -> (String?, String?) {
        parser.parse()
        return (transportState, relativeTimePosition)
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName: String?, attributes: [String: String] = [:]) {
        switch elementName {
        case "TransportState": transportState = attributes["val"]
        case "RelativeTimePosition": relativeTimePosition = attributes["val"]
        default: break
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {}
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName: String?) {}
}

// MARK: - Errors

enum DlnaError: LocalizedError {
    case noActiveSession
    case invalidUrl
    case controllerDeallocated
    case httpError(action: String, statusCode: Int)

    var errorDescription: String? {
        switch self {
        case .noActiveSession: return "No active DLNA session."
        case .invalidUrl: return "Invalid DLNA control URL."
        case .controllerDeallocated: return "DLNA controller was deallocated."
        case .httpError(let action, let code): return "DLNA \(action) failed with HTTP \(code)."
        }
    }
}
