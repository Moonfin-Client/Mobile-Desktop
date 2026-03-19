package com.moonfin.archiveextract

import android.os.Handler
import android.os.Looper
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import org.apache.commons.compress.archivers.sevenz.SevenZFile
import java.io.File
import java.io.FileOutputStream

class ArchiveExtractPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun onAttachedToEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "com.moonfin.archive_extract")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            "extract7z" -> {
                val archivePath = call.argument<String>("archivePath")
                val destPath = call.argument<String>("destinationPath")
                if (archivePath == null || destPath == null) {
                    result.error("INVALID_ARGS", "archivePath and destinationPath are required", null)
                    return
                }
                Thread {
                    try {
                        val files = extract7z(archivePath, destPath)
                        mainHandler.post { result.success(files) }
                    } catch (e: Exception) {
                        mainHandler.post { result.error("EXTRACTION_FAILED", e.message, null) }
                    }
                }.start()
            }
            "isSupported" -> result.success(true)
            else -> result.notImplemented()
        }
    }

    private fun extract7z(archivePath: String, destPath: String): List<String> {
        val destDir = File(destPath)
        if (!destDir.exists()) destDir.mkdirs()

        val canonicalDest = destDir.canonicalPath
        val extractedFiles = mutableListOf<String>()

        SevenZFile(File(archivePath)).use { sevenZFile ->
            var entry = sevenZFile.nextEntry
            while (entry != null) {
                if (!entry.isDirectory && entry.hasStream()) {
                    val outFile = File(destDir, entry.name)
                    val canonicalOutPath = outFile.canonicalPath

                    if (!canonicalOutPath.startsWith(canonicalDest + File.separator)
                        && canonicalOutPath != canonicalDest
                    ) {
                        entry = sevenZFile.nextEntry
                        continue
                    }

                    outFile.parentFile?.mkdirs()

                    FileOutputStream(outFile).use { fos ->
                        val buffer = ByteArray(8192)
                        var bytesRead: Int
                        while (sevenZFile.read(buffer).also { bytesRead = it } != -1) {
                            fos.write(buffer, 0, bytesRead)
                        }
                    }
                    extractedFiles.add(outFile.absolutePath)
                }
                entry = sevenZFile.nextEntry
            }
        }

        return extractedFiles
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}
