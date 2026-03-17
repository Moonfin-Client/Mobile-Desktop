package org.moonfin.tv

import android.app.PendingIntent
import android.app.PictureInPictureParams
import android.app.RemoteAction
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.res.Configuration
import android.graphics.drawable.Icon
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import android.util.Rational
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private var methodChannel: MethodChannel? = null
    private var pipEnabled = false
    private val handler = Handler(Looper.getMainLooper())
    private var dismissRunnable: Runnable? = null

    companion object {
        private const val CHANNEL = "org.moonfin.tv/pip"
        private const val ACTION_PLAY_PAUSE = "org.moonfin.tv.ACTION_PIP_PLAY_PAUSE"
        private const val DISMISS_DELAY_MS = 300L
    }

    private val pipReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action == ACTION_PLAY_PAUSE) {
                methodChannel?.invokeMethod("onPiPAction", "playPause")
            }
        }
    }

    private val screenReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            when (intent?.action) {
                Intent.ACTION_SCREEN_OFF ->
                    methodChannel?.invokeMethod("onScreenLock", true)
                Intent.ACTION_SCREEN_ON ->
                    methodChannel?.invokeMethod("onScreenLock", false)
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        methodChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL,
        )
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "enableAutoPiP" -> {
                    pipEnabled = call.argument<Boolean>("enabled") ?: false
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                        setPictureInPictureParams(buildPiPParams(true))
                    }
                    result.success(true)
                }
                "updatePiPActions" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
                        isInPictureInPictureMode
                    ) {
                        setPictureInPictureParams(
                            buildPiPParams(
                                call.argument<Boolean>("isPlaying") ?: true,
                            ),
                        )
                    }
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        // Register with RECEIVER_EXPORTED so the PiP framework (running in
        // SystemUI process) can deliver the broadcast to our receiver.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(
                pipReceiver,
                IntentFilter(ACTION_PLAY_PAUSE),
                Context.RECEIVER_EXPORTED,
            )
        } else {
            @Suppress("UnspecifiedRegisterReceiverFlag")
            registerReceiver(pipReceiver, IntentFilter(ACTION_PLAY_PAUSE))
        }

        val screenFilter = IntentFilter().apply {
            addAction(Intent.ACTION_SCREEN_OFF)
            addAction(Intent.ACTION_SCREEN_ON)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(screenReceiver, screenFilter, Context.RECEIVER_EXPORTED)
        } else {
            @Suppress("UnspecifiedRegisterReceiverFlag")
            registerReceiver(screenReceiver, screenFilter)
        }
    }

    override fun onUserLeaveHint() {
        super.onUserLeaveHint()
        if (pipEnabled &&
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
            Build.VERSION.SDK_INT < Build.VERSION_CODES.S
        ) {
            enterPictureInPictureMode(buildPiPParams(true))
        }
    }

    override fun onPictureInPictureModeChanged(
        isInPiP: Boolean,
        newConfig: Configuration,
    ) {
        super.onPictureInPictureModeChanged(isInPiP, newConfig)
        methodChannel?.invokeMethod("onPiPChanged", isInPiP)

        if (!isInPiP) {
            val power = getSystemService(Context.POWER_SERVICE) as PowerManager
            if (!power.isInteractive) return

            // Schedule a dismiss — if onResume fires within the delay,
            // the user tapped to expand and we cancel.
            dismissRunnable = Runnable {
                methodChannel?.invokeMethod("onPiPAction", "dismissed")
                dismissRunnable = null
            }
            handler.postDelayed(dismissRunnable!!, DISMISS_DELAY_MS)
        }
    }

    override fun onResume() {
        super.onResume()
        dismissRunnable?.let {
            handler.removeCallbacks(it)
            dismissRunnable = null
        }
    }

    private fun buildPiPParams(isPlaying: Boolean): PictureInPictureParams {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            throw IllegalStateException("PiP requires API 26+")
        }

        val builder = PictureInPictureParams.Builder()
            .setAspectRatio(Rational(16, 9))

        val icon = if (isPlaying) {
            Icon.createWithResource(this, android.R.drawable.ic_media_pause)
        } else {
            Icon.createWithResource(this, android.R.drawable.ic_media_play)
        }
        val label = if (isPlaying) "Pause" else "Play"
        val intent = PendingIntent.getBroadcast(
            this,
            0,
            Intent(ACTION_PLAY_PAUSE).apply { setPackage(packageName) },
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
        val action = RemoteAction(icon, label, label, intent)
        builder.setActions(listOf(action))

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            builder.setAutoEnterEnabled(pipEnabled)
            builder.setSeamlessResizeEnabled(true)
        }

        return builder.build()
    }

    override fun onDestroy() {
        dismissRunnable?.let { handler.removeCallbacks(it) }
        try { unregisterReceiver(pipReceiver) } catch (_: Exception) {}
        try { unregisterReceiver(screenReceiver) } catch (_: Exception) {}
        super.onDestroy()
    }
}
