package org.moonfin.androidtv

import android.content.ContentValues
import android.content.Context
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MediaStoreHelper(private val context: Context) : MethodChannel.MethodCallHandler {

    companion object {
        const val CHANNEL = "com.moonfin/media_store"
        private const val SUBFOLDER = "Moonfin"
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getDownloadPath" -> {
                val relativePath = call.argument<String>("relativePath") ?: ""
                val fileName = call.argument<String>("fileName") ?: ""
                if (fileName.isEmpty()) {
                    result.error("INVALID_ARG", "fileName is required", null)
                    return
                }
                try {
                    val path = createMediaStoreEntry(relativePath, fileName)
                    result.success(path)
                } catch (e: Exception) {
                    result.error("MEDIA_STORE_ERROR", e.message, null)
                }
            }
            "getMediaStorePath" -> {
                val base = Environment.getExternalStoragePublicDirectory(
                    Environment.DIRECTORY_DOWNLOADS
                ).absolutePath + "/$SUBFOLDER"
                result.success(base)
            }
            else -> result.notImplemented()
        }
    }

    private fun createMediaStoreEntry(relativePath: String, fileName: String): String {
        val fullRelativePath = if (relativePath.isEmpty()) {
            "${Environment.DIRECTORY_DOWNLOADS}/$SUBFOLDER"
        } else {
            "${Environment.DIRECTORY_DOWNLOADS}/$SUBFOLDER/$relativePath"
        }

        val collection = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            MediaStore.Downloads.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
        } else {
            MediaStore.Files.getContentUri("external")
        }

        // Check if entry already exists and delete it
        val selection = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            "${MediaStore.Downloads.DISPLAY_NAME} = ? AND ${MediaStore.Downloads.RELATIVE_PATH} = ?"
        } else {
            "${MediaStore.Files.FileColumns.DISPLAY_NAME} = ?"
        }
        val selectionArgs = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            arrayOf(fileName, "$fullRelativePath/")
        } else {
            arrayOf(fileName)
        }
        context.contentResolver.delete(collection, selection, selectionArgs)

        val values = ContentValues().apply {
            put(MediaStore.Downloads.DISPLAY_NAME, fileName)
            put(MediaStore.Downloads.MIME_TYPE, guessMimeType(fileName))
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                put(MediaStore.Downloads.RELATIVE_PATH, fullRelativePath)
                put(MediaStore.Downloads.IS_PENDING, 0)
            }
        }

        val uri = context.contentResolver.insert(collection, values)
            ?: throw IllegalStateException("Failed to create MediaStore entry for $fileName")

        // Resolve the real file path from the URI
        context.contentResolver.query(uri, arrayOf(MediaStore.Downloads.DATA), null, null, null)?.use { cursor ->
            if (cursor.moveToFirst()) {
                val pathIndex = cursor.getColumnIndexOrThrow(MediaStore.Downloads.DATA)
                return cursor.getString(pathIndex)
            }
        }

        // Fallback: construct expected path
        val externalDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
        return if (relativePath.isEmpty()) {
            "${externalDir.absolutePath}/$SUBFOLDER/$fileName"
        } else {
            "${externalDir.absolutePath}/$SUBFOLDER/$relativePath/$fileName"
        }
    }

    private fun guessMimeType(fileName: String): String {
        val lower = fileName.lowercase()
        return when {
            lower.endsWith(".mkv") -> "video/x-matroska"
            lower.endsWith(".mp4") || lower.endsWith(".m4v") -> "video/mp4"
            lower.endsWith(".avi") -> "video/x-msvideo"
            lower.endsWith(".webm") -> "video/webm"
            lower.endsWith(".ts") -> "video/mp2t"
            lower.endsWith(".flac") -> "audio/flac"
            lower.endsWith(".mp3") -> "audio/mpeg"
            lower.endsWith(".m4a") -> "audio/mp4"
            lower.endsWith(".ogg") -> "audio/ogg"
            lower.endsWith(".opus") -> "audio/opus"
            lower.endsWith(".wav") -> "audio/wav"
            lower.endsWith(".epub") -> "application/epub+zip"
            lower.endsWith(".pdf") -> "application/pdf"
            else -> "application/octet-stream"
        }
    }
}
