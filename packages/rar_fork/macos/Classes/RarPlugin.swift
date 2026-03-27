// macos/Classes/RarPlugin.swift
//
// Flutter plugin for macOS RAR file handling.
// Uses UnrarKit for RAR archive operations via method channels.

import Cocoa
import FlutterMacOS
import UnrarKit

public class RarPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "com.lkrjangid.rar", binaryMessenger: registrar.messenger)
    let instance = RarPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      result("macOS " + ProcessInfo.processInfo.operatingSystemVersionString)
    case "extractRarFile":
      extractRarFile(call, result: result)
    case "createRarArchive":
      result(["success": false, "message": "RAR creation is not supported on macOS. Consider using ZIP format instead."])
    case "listRarContents":
      listRarContents(call, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func extractRarFile(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let rarFilePath = args["rarFilePath"] as? String,
          let destinationPath = args["destinationPath"] as? String else {
      result(["success": false, "message": "Missing required arguments"])
      return
    }

    let password = args["password"] as? String

    // Ensure the destination directory exists
    let fileManager = FileManager.default
    do {
      try fileManager.createDirectory(atPath: destinationPath, withIntermediateDirectories: true, attributes: nil)
    } catch {
      result(["success": false, "message": "Failed to create destination directory: \(error.localizedDescription)"])
      return
    }

    // Extract the RAR file
    do {
      let archive = try URKArchive(path: rarFilePath)

      if let password = password {
        archive.password = password
      }

      try archive.extractFiles(to: destinationPath, overwrite: true)
      result(["success": true, "message": "Extraction completed successfully"])
    } catch {
      result(["success": false, "message": "Extraction failed: \(error.localizedDescription)"])
    }
  }

  private func listRarContents(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let rarFilePath = args["rarFilePath"] as? String else {
      result(["success": false, "message": "Missing required arguments", "files": []])
      return
    }

    let password = args["password"] as? String

    do {
      let archive = try URKArchive(path: rarFilePath)

      if let password = password {
        archive.password = password
      }

      let fileNames = try archive.listFilenames()
      result(["success": true, "message": "Successfully listed RAR contents", "files": fileNames])
    } catch {
      result(["success": false, "message": "Failed to list RAR contents: \(error.localizedDescription)", "files": []])
    }
  }
}
