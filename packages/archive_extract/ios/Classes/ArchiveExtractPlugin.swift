import Flutter
import UIKit

public class ArchiveExtractPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "com.moonfin.archive_extract",
            binaryMessenger: registrar.messenger()
        )
        let instance = ArchiveExtractPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "extract7z":
            guard let args = call.arguments as? [String: Any],
                  let archivePath = args["archivePath"] as? String,
                  let destinationPath = args["destinationPath"] as? String else {
                result(FlutterError(code: "INVALID_ARGS",
                                    message: "archivePath and destinationPath are required",
                                    details: nil))
                return
            }
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let files = try LibarchiveExtractor.extract7z(
                        archivePath: archivePath,
                        destinationPath: destinationPath
                    )
                    DispatchQueue.main.async { result(files) }
                } catch {
                    DispatchQueue.main.async {
                        result(FlutterError(code: "EXTRACTION_FAILED",
                                            message: error.localizedDescription,
                                            details: nil))
                    }
                }
            }
        case "isSupported":
            result(true)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
