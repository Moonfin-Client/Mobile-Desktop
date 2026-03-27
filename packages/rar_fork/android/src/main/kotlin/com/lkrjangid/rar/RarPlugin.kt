package com.lkrjangid.rar

import androidx.annotation.NonNull
import com.github.junrar.Junrar
import com.github.junrar.Archive
import com.github.junrar.exception.RarException

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

import android.util.Log
import java.io.File
import java.io.IOException
import java.util.ArrayList

/** RarPlugin */
class RarPlugin: FlutterPlugin, MethodCallHandler {
  companion object {
    private const val LOG_TAG = "RarPlugin"
  }

  private lateinit var channel : MethodChannel

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "com.lkrjangid.rar")
    channel.setMethodCallHandler(this)
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    when (call.method) {
      "extractRarFile" -> {
        val rarFilePath = call.argument<String>("rarFilePath")
        val destinationPath = call.argument<String>("destinationPath")
        val password = call.argument<String>("password")

        if (rarFilePath == null || destinationPath == null) {
          result.error("INVALID_ARGUMENTS", "Missing required arguments", null)
          return
        }

        extractRar(rarFilePath, destinationPath, password, result)
      }
      "createRarArchive" -> {
        // Note: Pure Java RAR creation is not well supported
        // We'll use command-line tools or suggest using ZIP instead
        result.error("UNSUPPORTED", "RAR creation is not supported on Android. Consider using ZIP format instead.", null)
      }
      "listRarContents" -> {
        val rarFilePath = call.argument<String>("rarFilePath")
        val password = call.argument<String>("password")

        if (rarFilePath == null) {
          result.error("INVALID_ARGUMENTS", "Missing required arguments", null)
          return
        }

        listRarContents(rarFilePath, password, result)
      }
      else -> {
        result.notImplemented()
      }
    }
  }

  private fun extractRar(rarFilePath: String, destinationPath: String, password: String?, result: Result) {
    // This method is no longer used as Android now uses FFI via Dart.
    // Keeping this stub to satisfy potential legacy calls if any, but logic is moved to Dart.
    result.notImplemented()
  }

  private fun listRarContents(rarFilePath: String, password: String?, result: Result) {
    // This method is no longer used as Android now uses FFI via Dart.
    // Keeping this stub to satisfy potential legacy calls if any, but logic is moved to Dart.
    result.notImplemented()
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }
}