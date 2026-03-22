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
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    appDelegate?.castEventSink = nil
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
  fileprivate var castEventSink: FlutterEventSink?

  private struct PendingCastRequest {
    let targetId: String
    let streamUrl: URL
    let title: String
    let subtitle: String?
    let posterUrl: URL?
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

    castChannel.setMethodCallHandler { [weak self, weak controller] (call, result) in
      switch call.method {
      case "discoverGoogleCastTargets":
        guard let self else {
          result(
            FlutterError(
              code: "CAST_UNAVAILABLE",
              message: "AppDelegate not available.",
              details: nil
            )
          )
          return
        }

        self.discoverGoogleCastTargets(result: result)
      case "startGoogleCastSession":
        guard let self else {
          result(
            FlutterError(
              code: "CAST_UNAVAILABLE",
              message: "AppDelegate not available.",
              details: nil
            )
          )
          return
        }

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
        let startPositionTicks = (args["startPositionTicks"] as? NSNumber)?.int64Value

        self.startGoogleCastSession(
          targetId: targetId,
          streamUrl: streamUrl,
          title: title,
          subtitle: subtitle,
          posterUrl: posterUrl,
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

          let title = device.friendlyName.isEmpty ? "Google Cast" : device.friendlyName
          let subtitle = device.modelName
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

    let requestBuilder = GCKMediaLoadRequestDataBuilder()
    requestBuilder.mediaInformation = mediaInfoBuilder.build()

    if let startPositionTicks,
       startPositionTicks > 0 {
      requestBuilder.startTime = Double(startPositionTicks) / 10_000_000.0
    }

    remoteClient.loadMedia(with: requestBuilder.build())
    result(nil)
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
    emitGoogleCastEvent(state: "connected")
    completePendingCastIfPossible(for: session)
  }

  func sessionManager(_ sessionManager: GCKSessionManager, didResumeSession session: GCKSession) {
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
    emitGoogleCastEvent(state: "disconnected")
  }

  func sessionManager(_ sessionManager: GCKSessionManager, didSuspend session: GCKSession, with reason: GCKConnectionSuspendReason) {
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

  fileprivate func emitGoogleCastEvent(state: String, message: String? = nil) {
    var event: [String: Any] = [
      "kind": "googleCast",
      "state": state,
    ]
    if let message,
       !message.isEmpty {
      event["message"] = message
    }

    castEventSink?(event)
  }

  fileprivate func currentCastSession() -> GCKCastSession? {
    return GCKCastContext.sharedInstance().sessionManager.currentCastSession
  }
}
