import Flutter
import UIKit
import AVKit
import GoogleCast

private final class NativeCastEventStreamHandler: NSObject, FlutterStreamHandler {
  weak var appDelegate: AppDelegate?

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    appDelegate?.castEventSink = events
    appDelegate?.emitGoogleCastEvent(
      state: appDelegate?.currentCastSession() != nil ? "connected" : "disconnected"
    )
    appDelegate?.emitCurrentGoogleCastStatus()
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    appDelegate?.castEventSink = nil
    return nil
  }
}

private final class NativeDlnaEventStreamHandler: NSObject, FlutterStreamHandler {
  weak var appDelegate: AppDelegate?

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    appDelegate?.dlnaController.setEventSink { event in events(event) }
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    appDelegate?.dlnaController.setEventSink(nil)
    return nil
  }
}

private final class NativeAirPlayEventStreamHandler: NSObject, FlutterStreamHandler {
  weak var appDelegate: AppDelegate?

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    appDelegate?.airPlayController.setEventSink { event in events(event) }
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    appDelegate?.airPlayController.setEventSink(nil)
    return nil
  }
}

@main
@objc class AppDelegate: FlutterAppDelegate, GCKSessionManagerListener {
  private let castDiscoveryDelaySeconds: TimeInterval = 1.5
  private let castSessionStartTimeoutSeconds: TimeInterval = 15
  private var hasConfiguredGoogleCast = false
  private var pendingCastRequest: PendingCastRequest?
  private var pendingCastTimeoutWorkItem: DispatchWorkItem?
  private let castEventStreamHandler = NativeCastEventStreamHandler()
  private let dlnaEventStreamHandler = NativeDlnaEventStreamHandler()
  private let airPlayEventStreamHandler = NativeAirPlayEventStreamHandler()
  fileprivate let dlnaController = DlnaController()
  fileprivate let airPlayController = AirPlayController()
  fileprivate var castEventSink: FlutterEventSink?

  private struct PendingCastRequest {
    let targetId: String
    let streamUrl: URL
    let title: String
    let subtitle: String?
    let posterUrl: URL?
    let queueItems: [[String: Any]]
    let startPositionTicks: Int64?
    let result: FlutterResult
  }

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    configureGoogleCast()

    GeneratedPluginRegistrant.register(with: self)

    let controller = window?.rootViewController as! FlutterViewController
    let storageChannel = FlutterMethodChannel(
      name: "com.moonfin/ios_storage",
      binaryMessenger: controller.binaryMessenger
    )
    let castChannel = FlutterMethodChannel(
      name: "com.moonfin/native_cast",
      binaryMessenger: controller.binaryMessenger
    )
    let castEventsChannel = FlutterEventChannel(
      name: "com.moonfin/native_cast_events",
      binaryMessenger: controller.binaryMessenger
    )
    castEventStreamHandler.appDelegate = self
    castEventsChannel.setStreamHandler(castEventStreamHandler)

    let dlnaChannel = FlutterMethodChannel(
      name: "com.moonfin/native_dlna",
      binaryMessenger: controller.binaryMessenger
    )
    let dlnaEventsChannel = FlutterEventChannel(
      name: "com.moonfin/native_dlna_events",
      binaryMessenger: controller.binaryMessenger
    )
    dlnaEventStreamHandler.appDelegate = self
    dlnaEventsChannel.setStreamHandler(dlnaEventStreamHandler)

    let airPlayEventsChannel = FlutterEventChannel(
      name: "com.moonfin/native_airplay_events",
      binaryMessenger: controller.binaryMessenger
    )
    airPlayEventStreamHandler.appDelegate = self
    airPlayEventsChannel.setStreamHandler(airPlayEventStreamHandler)

    dlnaChannel.setMethodCallHandler { [weak self] (call, result) in
      guard let self else {
        result(
          FlutterError(
            code: "DLNA_UNAVAILABLE",
            message: "AppDelegate not available.",
            details: nil
          )
        )
        return
      }

      switch call.method {
      case "discoverDlnaTargets":
        self.dlnaController.discoverTargets { targets in
          result(targets)
        }
      case "playToDlnaDevice":
        guard let args = call.arguments as? [String: Any],
              let targetId = args["targetId"] as? String,
              let streamUrl = args["streamUrl"] as? String,
              let title = args["title"] as? String else {
          result(
            FlutterError(
              code: "BAD_ARGS",
              message: "Missing or invalid DLNA playback arguments.",
              details: nil
            )
          )
          return
        }
        let startPositionTicks = (args["startPositionTicks"] as? NSNumber)?.int64Value
        self.dlnaController.playToDevice(
          targetId: targetId,
          streamUrl: streamUrl,
          title: title,
          startPositionTicks: startPositionTicks
        ) { error in
          if let error {
            result(
              FlutterError(
                code: "DLNA_PLAY_FAILED",
                message: error.localizedDescription,
                details: nil
              )
            )
          } else {
            result(nil)
          }
        }
      case "pauseDlna":
        self.dlnaController.pause { error in
          if let error {
            result(
              FlutterError(
                code: "DLNA_ACTION_FAILED",
                message: error.localizedDescription,
                details: nil
              )
            )
          } else {
            result(nil)
          }
        }
      case "playDlna":
        self.dlnaController.play { error in
          if let error {
            result(
              FlutterError(
                code: "DLNA_ACTION_FAILED",
                message: error.localizedDescription,
                details: nil
              )
            )
          } else {
            result(nil)
          }
        }
      case "seekDlna":
        guard let args = call.arguments as? [String: Any],
              let positionTicks = (args["positionTicks"] as? NSNumber)?.int64Value,
              positionTicks >= 0 else {
          result(
            FlutterError(
              code: "BAD_ARGS",
              message: "Missing or invalid positionTicks.",
              details: nil
            )
          )
          return
        }
        self.dlnaController.seek(positionTicks: positionTicks) { error in
          if let error {
            result(
              FlutterError(
                code: "DLNA_ACTION_FAILED",
                message: error.localizedDescription,
                details: nil
              )
            )
          } else {
            result(nil)
          }
        }
      case "stopDlna":
        self.dlnaController.stop { error in
          if let error {
            result(
              FlutterError(
                code: "DLNA_ACTION_FAILED",
                message: error.localizedDescription,
                details: nil
              )
            )
          } else {
            result(nil)
          }
        }
      case "getDlnaVolume":
        self.dlnaController.getVolume { volume, error in
          if let error {
            result(
              FlutterError(
                code: "DLNA_ACTION_FAILED",
                message: error.localizedDescription,
                details: nil
              )
            )
          } else {
            result(volume)
          }
        }
      case "setDlnaVolume":
        guard let args = call.arguments as? [String: Any],
              let volume = (args["volume"] as? NSNumber)?.doubleValue else {
          result(
            FlutterError(
              code: "BAD_ARGS",
              message: "Missing or invalid volume.",
              details: nil
            )
          )
          return
        }
        self.dlnaController.setVolume(volume) { error in
          if let error {
            result(
              FlutterError(
                code: "DLNA_ACTION_FAILED",
                message: error.localizedDescription,
                details: nil
              )
            )
          } else {
            result(nil)
          }
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    storageChannel.setMethodCallHandler { (call, result) in
      if call.method == "excludeFromBackup" {
        guard let args = call.arguments as? [String: Any],
              let path = args["path"] as? String else {
          result(FlutterError(code: "BAD_ARGS", message: "Missing path", details: nil))
          return
        }
        var fileUrl = URL(fileURLWithPath: path)
        var resourceValues = URLResourceValues()
        resourceValues.isExcludedFromBackup = true
        do {
          try fileUrl.setResourceValues(resourceValues)
          result(nil)
        } catch {
          result(FlutterError(code: "FAILED", message: error.localizedDescription, details: nil))
        }
      } else {
        result(FlutterMethodNotImplemented)
      }
    }

    castChannel.setMethodCallHandler { [weak controller] (call, result) in
      switch call.method {
      case "discoverGoogleCastTargets":
        self.discoverGoogleCastTargets(result: result)
      case "startGoogleCastSession":
        guard let args = call.arguments as? [String: Any],
              let targetId = args["targetId"] as? String,
              let streamUrlRaw = args["streamUrl"] as? String,
              let streamUrl = URL(string: streamUrlRaw),
              let title = args["title"] as? String else {
          result(
            FlutterError(
              code: "BAD_ARGS",
              message: "Missing or invalid cast session arguments.",
              details: nil
            )
          )
          return
        }

        let subtitle = args["subtitle"] as? String
        let posterUrlRaw = args["posterUrl"] as? String
        let posterUrl = posterUrlRaw.flatMap(URL.init(string:))
        let queueItems = (args["queueItems"] as? [[String: Any]]) ?? []
        let startPositionTicks = (args["startPositionTicks"] as? NSNumber)?.int64Value

        self.startGoogleCastSession(
          targetId: targetId,
          streamUrl: streamUrl,
          title: title,
          subtitle: subtitle,
          posterUrl: posterUrl,
          queueItems: queueItems,
          startPositionTicks: startPositionTicks,
          result: result
        )
      case "showAirPlayRoutePicker":
        guard let vc = controller else {
          result(
            FlutterError(
              code: "NO_VIEW_CONTROLLER",
              message: "Missing root FlutterViewController.",
              details: nil
            )
          )
          return
        }

        DispatchQueue.main.async {
          let routePicker = AVRoutePickerView(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
          routePicker.isHidden = true
          vc.view.addSubview(routePicker)

          let button = routePicker.subviews.compactMap { $0 as? UIButton }.first
          button?.sendActions(for: .touchUpInside)

          DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            routePicker.removeFromSuperview()
          }
        }
        result(nil)
      case "pauseGoogleCast":
        self.withGoogleCastRemoteClient(result: result) { remoteClient in
          remoteClient.pause()
          result(nil)
        }
      case "playGoogleCast":
        self.withGoogleCastRemoteClient(result: result) { remoteClient in
          remoteClient.play()
          result(nil)
        }
      case "seekGoogleCast":
        guard let args = call.arguments as? [String: Any],
              let positionTicks = (args["positionTicks"] as? NSNumber)?.int64Value,
              positionTicks >= 0 else {
          result(
            FlutterError(
              code: "BAD_ARGS",
              message: "Missing or invalid positionTicks.",
              details: nil
            )
          )
          return
        }

        self.withGoogleCastRemoteClient(result: result) { remoteClient in
          let seekOptions = GCKMediaSeekOptions()
          seekOptions.interval = Double(positionTicks) / 10_000_000.0
          remoteClient.seek(with: seekOptions)
          result(nil)
        }
      case "stopGoogleCastSession":
        self.withGoogleCastRemoteClient(result: result) { remoteClient in
          remoteClient.stop()
          result(nil)
        }
      case "getGoogleCastVolume":
        guard let castSession = self.currentCastSession() else {
          result(
            FlutterError(
              code: "NO_CAST_SESSION",
              message: "No active Google Cast session.",
              details: nil
            )
          )
          return
        }
        result(Double(castSession.currentDeviceVolume))
      case "setGoogleCastVolume":
        guard let args = call.arguments as? [String: Any],
              let volume = (args["volume"] as? NSNumber)?.doubleValue else {
          result(
            FlutterError(
              code: "BAD_ARGS",
              message: "Missing or invalid volume.",
              details: nil
            )
          )
          return
        }
        guard let castSession = self.currentCastSession() else {
          result(
            FlutterError(
              code: "NO_CAST_SESSION",
              message: "No active Google Cast session.",
              details: nil
            )
          )
          return
        }
        let clamped = max(0.0, min(1.0, volume))
        castSession.setDeviceVolume(Float(clamped))
        result(nil)
      case "pauseAirPlay":
        self.airPlayController.pause()
        result(nil)
      case "playAirPlay":
        self.airPlayController.play()
        result(nil)
      case "seekAirPlay":
        guard let args = call.arguments as? [String: Any],
              let positionTicks = (args["positionTicks"] as? NSNumber)?.int64Value,
              positionTicks >= 0 else {
          result(
            FlutterError(
              code: "BAD_ARGS",
              message: "Missing or invalid positionTicks.",
              details: nil
            )
          )
          return
        }
        self.airPlayController.seek(positionTicks: positionTicks)
        result(nil)
      case "stopAirPlay":
        self.airPlayController.stop()
        result(nil)
      case "loadAirPlay":
        guard let args = call.arguments as? [String: Any],
              let url = args["url"] as? String else {
          result(
            FlutterError(
              code: "BAD_ARGS",
              message: "Missing url for loadAirPlay.",
              details: nil
            )
          )
          return
        }
        let title = args["title"] as? String ?? ""
        let positionTicks = (args["positionTicks"] as? NSNumber)?.int64Value ?? 0
        let positionSeconds = Double(positionTicks) / 10_000_000.0
        self.airPlayController.preparePendingContent(
          urlString: url,
          title: title,
          positionSeconds: positionSeconds
        )
        result(nil)
      case "updateAirPlayPlaybackState":
        guard let args = call.arguments as? [String: Any],
              let isPlaying = args["isPlaying"] as? Bool,
              let isBuffering = args["isBuffering"] as? Bool,
              let positionTicks = (args["positionTicks"] as? NSNumber)?.int64Value else {
          result(
            FlutterError(
              code: "BAD_ARGS",
              message: "Missing or invalid AirPlay playback state arguments.",
              details: nil
            )
          )
          return
        }
        self.airPlayController.updatePlaybackState(
          isPlaying: isPlaying,
          isBuffering: isBuffering,
          positionTicks: positionTicks
        )
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func configureGoogleCast() {
    if hasConfiguredGoogleCast {
      return
    }

    let discoveryCriteria = GCKDiscoveryCriteria(applicationID: kGCKDefaultMediaReceiverApplicationID)
    let castOptions = GCKCastOptions(discoveryCriteria: discoveryCriteria)
    GCKCastContext.setSharedInstanceWith(castOptions)
    GCKCastContext.sharedInstance().sessionManager.add(self)
    hasConfiguredGoogleCast = true
  }

  private func discoverGoogleCastTargets(result: @escaping FlutterResult) {
    DispatchQueue.main.async {
      let discoveryManager = GCKCastContext.sharedInstance().discoveryManager
      discoveryManager.startDiscovery()

      DispatchQueue.main.asyncAfter(deadline: .now() + self.castDiscoveryDelaySeconds) {
        let deviceCount = Int(discoveryManager.deviceCount)
        var targets: [[String: String]] = []

        for index in 0..<deviceCount {
          let device = discoveryManager.device(at: UInt(index))

          let friendlyName = device.friendlyName ?? ""
          let title = friendlyName.isEmpty ? "Google Cast" : friendlyName
          let subtitle = device.modelName ?? ""
          targets.append(
            [
              "id": device.deviceID,
              "title": title,
              "subtitle": subtitle,
            ]
          )
        }

        result(targets)
      }
    }
  }

  private func startGoogleCastSession(
    targetId: String,
    streamUrl: URL,
    title: String,
    subtitle: String?,
    posterUrl: URL?,
    queueItems: [[String: Any]],
    startPositionTicks: Int64?,
    result: @escaping FlutterResult
  ) {
    DispatchQueue.main.async {
      let context = GCKCastContext.sharedInstance()
      let sessionManager = context.sessionManager

      if let activeSession = sessionManager.currentCastSession,
         activeSession.device.deviceID == targetId {
        self.loadOnCastSession(
          activeSession,
          streamUrl: streamUrl,
          title: title,
          subtitle: subtitle,
          posterUrl: posterUrl,
          queueItems: queueItems,
          startPositionTicks: startPositionTicks,
          result: result
        )
        return
      }

      let discoveryManager = context.discoveryManager
      discoveryManager.startDiscovery()

      let deviceCount = Int(discoveryManager.deviceCount)
      var targetDevice: GCKDevice?

      for index in 0..<deviceCount {
        let device = discoveryManager.device(at: UInt(index))

        if device.deviceID == targetId {
          targetDevice = device
          break
        }
      }

      guard let device = targetDevice else {
        result(
          FlutterError(
            code: "TARGET_NOT_FOUND",
            message: "Google Cast target is no longer available.",
            details: nil
          )
        )
        return
      }

      self.pendingCastTimeoutWorkItem?.cancel()
      self.pendingCastRequest = PendingCastRequest(
        targetId: targetId,
        streamUrl: streamUrl,
        title: title,
        subtitle: subtitle,
        posterUrl: posterUrl,
        queueItems: queueItems,
        startPositionTicks: startPositionTicks,
        result: result
      )

      let timeoutWorkItem = DispatchWorkItem { [weak self] in
        guard let self,
              let request = self.pendingCastRequest,
              request.targetId == targetId else {
          return
        }

        self.pendingCastRequest = nil
        self.pendingCastTimeoutWorkItem = nil
        request.result(
          FlutterError(
            code: "SESSION_TIMEOUT",
            message: "Timed out waiting for Google Cast session to start.",
            details: nil
          )
        )
      }

      self.pendingCastTimeoutWorkItem = timeoutWorkItem
      DispatchQueue.main.asyncAfter(
        deadline: .now() + self.castSessionStartTimeoutSeconds,
        execute: timeoutWorkItem
      )

      self.emitGoogleCastEvent(state: "connecting")
      sessionManager.startSession(with: device)
    }
  }

  private func loadOnCastSession(
    _ session: GCKCastSession,
    streamUrl: URL,
    title: String,
    subtitle: String?,
    posterUrl: URL?,
    queueItems: [[String: Any]],
    startPositionTicks: Int64?,
    result: @escaping FlutterResult
  ) {
    guard let remoteClient = session.remoteMediaClient else {
      result(
        FlutterError(
          code: "NO_REMOTE_CLIENT",
          message: "Google Cast remote media client is unavailable.",
          details: nil
        )
      )
      return
    }

    let startSeconds =
      (startPositionTicks != nil && startPositionTicks! > 0)
      ? Double(startPositionTicks!) / 10_000_000.0
      : 0
    let effectiveQueueItems = queueItems.isEmpty
      ? [[
        "streamUrl": streamUrl.absoluteString,
        "title": title,
        "subtitle": subtitle ?? "",
        "posterUrl": posterUrl?.absoluteString ?? "",
      ]]
      : queueItems

    if effectiveQueueItems.count > 1 {
      let queue = effectiveQueueItems.compactMap { buildMediaQueueItem(from: $0) }
      guard !queue.isEmpty else {
        result(
          FlutterError(
            code: "BAD_ARGS",
            message: "Queue items are invalid.",
            details: nil
          )
        )
        return
      }

      remoteClient.queueLoad(
        queue,
        start: 0,
        playPosition: startSeconds,
        repeatMode: .off,
        customData: nil
      )
    } else {
      let entry = effectiveQueueItems[0]
      guard let mediaInfo = buildMediaInformation(from: entry) else {
        result(
          FlutterError(
            code: "BAD_ARGS",
            message: "Missing queue stream URL.",
            details: nil
          )
        )
        return
      }

      let requestBuilder = GCKMediaLoadRequestDataBuilder()
      requestBuilder.mediaInformation = mediaInfo
      requestBuilder.startTime = startSeconds
      remoteClient.loadMedia(with: requestBuilder.build())
    }

    remoteClient.add(self)
    emitCurrentGoogleCastStatus(from: remoteClient)
    result(nil)
  }

  private func buildMediaInformation(from item: [String: Any]) -> GCKMediaInformation? {
    guard let streamUrlRaw = item["streamUrl"] as? String,
          let streamUrl = URL(string: streamUrlRaw) else {
      return nil
    }

    let title = (item["title"] as? String) ?? "Moonfin"
    let subtitle = item["subtitle"] as? String
    let posterUrlRaw = item["posterUrl"] as? String
    let posterUrl = posterUrlRaw.flatMap(URL.init(string:))

    let metadata = GCKMediaMetadata(metadataType: .movie)
    metadata.setString(title, forKey: kGCKMetadataKeyTitle)
    if let subtitle,
       !subtitle.isEmpty {
      metadata.setString(subtitle, forKey: kGCKMetadataKeySubtitle)
    }
    if let posterUrl {
      metadata.addImage(GCKImage(url: posterUrl, width: 0, height: 0))
    }

    let mediaInfoBuilder = GCKMediaInformationBuilder(contentURL: streamUrl)
    mediaInfoBuilder.streamType = .buffered
    mediaInfoBuilder.contentType = "application/octet-stream"
    mediaInfoBuilder.metadata = metadata
    return mediaInfoBuilder.build()
  }

  private func buildMediaQueueItem(from item: [String: Any]) -> GCKMediaQueueItem? {
    guard let mediaInfo = buildMediaInformation(from: item) else {
      return nil
    }

    let queueItemBuilder = GCKMediaQueueItemBuilder()
    queueItemBuilder.mediaInformation = mediaInfo
    queueItemBuilder.autoplay = true
    return queueItemBuilder.build()
  }

  private func withGoogleCastRemoteClient(
    result: @escaping FlutterResult,
    action: @escaping (GCKRemoteMediaClient) -> Void
  ) {
    DispatchQueue.main.async {
      let sessionManager = GCKCastContext.sharedInstance().sessionManager
      guard let session = sessionManager.currentCastSession else {
        result(
          FlutterError(
            code: "NO_CAST_SESSION",
            message: "No active Google Cast session.",
            details: nil
          )
        )
        return
      }

      guard let remoteClient = session.remoteMediaClient else {
        result(
          FlutterError(
            code: "NO_REMOTE_CLIENT",
            message: "Google Cast remote media client is unavailable.",
            details: nil
          )
        )
        return
      }

      action(remoteClient)
    }
  }

  func sessionManager(_ sessionManager: GCKSessionManager, didStart session: GCKSession) {
    if let castSession = session as? GCKCastSession {
      castSession.remoteMediaClient?.add(self)
      emitCurrentGoogleCastStatus(from: castSession.remoteMediaClient)
    }
    emitGoogleCastEvent(state: "connected")
    completePendingCastIfPossible(for: session)
  }

  func sessionManager(_ sessionManager: GCKSessionManager, didResumeSession session: GCKSession) {
    if let castSession = session as? GCKCastSession {
      castSession.remoteMediaClient?.add(self)
      emitCurrentGoogleCastStatus(from: castSession.remoteMediaClient)
    }
    emitGoogleCastEvent(state: "connected")
    completePendingCastIfPossible(for: session)
  }

  func sessionManager(_ sessionManager: GCKSessionManager, didFailToStartSessionWithError error: Error) {
    emitGoogleCastEvent(state: "error", message: error.localizedDescription)
    completePendingCastWithError(
      code: "CAST_START_FAILED",
      message: "Failed to start Google Cast session: \(error.localizedDescription)"
    )
  }

  func sessionManager(_ sessionManager: GCKSessionManager, didFailToResumeSessionWithError error: Error) {
    emitGoogleCastEvent(state: "error", message: error.localizedDescription)
    completePendingCastWithError(
      code: "CAST_RESUME_FAILED",
      message: "Failed to resume Google Cast session: \(error.localizedDescription)"
    )
  }

  func sessionManager(_ sessionManager: GCKSessionManager, didEnd session: GCKSession, withError error: Error?) {
    if let castSession = session as? GCKCastSession {
      castSession.remoteMediaClient?.remove(self)
    }
    emitGoogleCastEvent(state: "disconnected")
  }

  func sessionManager(_ sessionManager: GCKSessionManager, didSuspend session: GCKSession, with reason: GCKConnectionSuspendReason) {
    if let castSession = session as? GCKCastSession {
      castSession.remoteMediaClient?.remove(self)
    }
    emitGoogleCastEvent(state: "disconnected")
  }

  private func completePendingCastIfPossible(for session: GCKSession) {
    guard let castSession = session as? GCKCastSession,
          let request = pendingCastRequest,
          castSession.device.deviceID == request.targetId else {
      return
    }

    pendingCastTimeoutWorkItem?.cancel()
    pendingCastTimeoutWorkItem = nil
    pendingCastRequest = nil

    loadOnCastSession(
      castSession,
      streamUrl: request.streamUrl,
      title: request.title,
      subtitle: request.subtitle,
      posterUrl: request.posterUrl,
      queueItems: request.queueItems,
      startPositionTicks: request.startPositionTicks,
      result: request.result
    )
  }

  private func completePendingCastWithError(code: String, message: String) {
    guard let request = pendingCastRequest else {
      return
    }

    pendingCastTimeoutWorkItem?.cancel()
    pendingCastTimeoutWorkItem = nil
    pendingCastRequest = nil

    request.result(
      FlutterError(
        code: code,
        message: message,
        details: nil
      )
    )
  }

  fileprivate func emitGoogleCastEvent(state: String, message: String? = nil, positionTicks: Int64? = nil) {
    var event: [String: Any] = [
      "kind": "googleCast",
      "state": state,
    ]
    if let message,
       !message.isEmpty {
      event["message"] = message
    }
    if let positionTicks, positionTicks > 0 {
      event["positionTicks"] = positionTicks
    }

    castEventSink?(event)
  }

  fileprivate func emitCurrentGoogleCastStatus(from client: GCKRemoteMediaClient? = nil) {
    let remoteClient: GCKRemoteMediaClient?
    if let client {
      remoteClient = client
    } else {
      remoteClient = currentCastSession()?.remoteMediaClient
    }
    guard let remoteClient,
          let status = remoteClient.mediaStatus else {
      return
    }

    let state: String
    switch status.playerState {
    case .playing: state = "playing"
    case .paused: state = "paused"
    case .buffering: state = "buffering"
    case .idle: state = "idle"
    default: return
    }

    let positionTicks = Int64(remoteClient.approximateStreamPosition() * 10_000_000)
    emitGoogleCastEvent(state: state, positionTicks: positionTicks)
  }

  fileprivate func currentCastSession() -> GCKCastSession? {
    return GCKCastContext.sharedInstance().sessionManager.currentCastSession
  }
}

extension AppDelegate: GCKRemoteMediaClientListener {
  func remoteMediaClient(_ client: GCKRemoteMediaClient, didUpdate mediaStatus: GCKMediaStatus?) {
    emitCurrentGoogleCastStatus(from: client)
  }
}
