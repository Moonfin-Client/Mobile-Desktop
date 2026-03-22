package org.moonfin.androidtv

import android.app.PendingIntent
import android.app.PictureInPictureParams
import android.app.RemoteAction
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.res.Configuration
import android.graphics.drawable.Icon
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import android.util.Rational
import androidx.mediarouter.media.MediaRouteSelector
import androidx.mediarouter.media.MediaRouter
import com.google.android.gms.cast.CastMediaControlIntent
import com.google.android.gms.cast.MediaInfo
import com.google.android.gms.cast.MediaLoadRequestData
import com.google.android.gms.cast.MediaMetadata
import com.google.android.gms.cast.MediaSeekOptions
import com.google.android.gms.cast.framework.CastContext
import com.google.android.gms.cast.framework.CastSession
import com.google.android.gms.cast.framework.SessionManagerListener
import com.google.android.gms.common.images.WebImage
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : AudioServiceActivity() {

    private var methodChannel: MethodChannel? = null
    private var castChannel: MethodChannel? = null
    private var castEventsChannel: EventChannel? = null
    private var castEventsSink: EventChannel.EventSink? = null
    private var castStatusListener: SessionManagerListener<CastSession>? = null
    private var pipEnabled = false
    private val handler = Handler(Looper.getMainLooper())
    private var dismissRunnable: Runnable? = null
    private var pendingCastTimeout: Runnable? = null
    private var pendingCastListener: SessionManagerListener<CastSession>? = null

    companion object {
        private const val CHANNEL = "org.moonfin.androidtv/pip"
        private const val CAST_CHANNEL = "com.moonfin/native_cast"
        private const val CAST_EVENTS_CHANNEL = "com.moonfin/native_cast_events"
        private const val ACTION_PLAY_PAUSE = "org.moonfin.androidtv.ACTION_PIP_PLAY_PAUSE"
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

        castChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CAST_CHANNEL,
        )
        castChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "discoverGoogleCastTargets" -> {
                    result.success(discoverGoogleCastTargets())
                }
                "startGoogleCastSession" -> {
                    val args = call.arguments as? Map<*, *> ?: emptyMap<String, Any>()
                    startGoogleCastSession(args, result)
                }
                "showAirPlayRoutePicker" -> {
                    result.error(
                        "UNSUPPORTED",
                        "AirPlay is only available on iOS.",
                        null,
                    )
                }
                "pauseGoogleCast" -> {
                    withRemoteMediaClient(result) { remoteClient ->
                        remoteClient.pause()
                        result.success(null)
                    }
                }
                "playGoogleCast" -> {
                    withRemoteMediaClient(result) { remoteClient ->
                        remoteClient.play()
                        result.success(null)
                    }
                }
                "seekGoogleCast" -> {
                    val args = call.arguments as? Map<*, *> ?: emptyMap<String, Any>()
                    val positionTicks = (args["positionTicks"] as? Number)?.toLong()
                    if (positionTicks == null || positionTicks < 0L) {
                        result.error("BAD_ARGS", "Missing or invalid positionTicks", null)
                        return@setMethodCallHandler
                    }

                    withRemoteMediaClient(result) { remoteClient ->
                        val positionMs = positionTicks / 10000L
                        val seekOptions = MediaSeekOptions.Builder()
                            .setPosition(positionMs)
                            .build()
                        remoteClient.seek(seekOptions)
                        result.success(null)
                    }
                }
                "stopGoogleCastSession" -> {
                    withRemoteMediaClient(result) { remoteClient ->
                        remoteClient.stop()
                        result.success(null)
                    }
                }
                else -> result.notImplemented()
            }
        }

        castEventsChannel = EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CAST_EVENTS_CHANNEL,
        )
        castEventsChannel?.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                castEventsSink = events
                emitGoogleCastEvent(
                    state = if (getCurrentCastSession() != null) "connected" else "disconnected",
                )
            }

            override fun onCancel(arguments: Any?) {
                castEventsSink = null
            }
        })

        registerCastStatusListener()

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
        pendingCastTimeout?.let { handler.removeCallbacks(it) }
        val castContext = runCatching { CastContext.getSharedInstance(this) }.getOrNull()
        val sessionManager = castContext?.sessionManager
        pendingCastListener?.let { listener ->
            sessionManager?.removeSessionManagerListener(listener, CastSession::class.java)
        }
        castStatusListener?.let { listener ->
            sessionManager?.removeSessionManagerListener(listener, CastSession::class.java)
        }
        try { unregisterReceiver(pipReceiver) } catch (_: Exception) {}
        try { unregisterReceiver(screenReceiver) } catch (_: Exception) {}
        castChannel?.setMethodCallHandler(null)
        castEventsChannel?.setStreamHandler(null)
        super.onDestroy()
    }

    private fun discoverGoogleCastTargets(): List<Map<String, Any>> {
        val selector = MediaRouteSelector.Builder()
            .addControlCategory(
                CastMediaControlIntent.categoryForCast(
                    CastMediaControlIntent.DEFAULT_MEDIA_RECEIVER_APPLICATION_ID,
                ),
            )
            .build()

        val mediaRouter = MediaRouter.getInstance(this)
        val routes = mediaRouter.routes.filter { route ->
            route.isEnabled && route.matchesSelector(selector)
        }

        return routes.map { route ->
            mapOf(
                "id" to route.id,
                "title" to route.name,
                "subtitle" to (route.description?.toString() ?: "Google Cast"),
            )
        }
    }

    private fun startGoogleCastSession(args: Map<*, *>, result: MethodChannel.Result) {
        val targetId = args["targetId"] as? String
        val streamUrl = args["streamUrl"] as? String
        val title = args["title"] as? String ?: "Moonfin"
        val subtitle = args["subtitle"] as? String
        val posterUrl = args["posterUrl"] as? String
        val startTicks = (args["startPositionTicks"] as? Number)?.toLong()

        if (targetId.isNullOrEmpty() || streamUrl.isNullOrEmpty()) {
            result.error("BAD_ARGS", "Missing targetId or streamUrl", null)
            return
        }

        emitGoogleCastEvent("connecting")

        val mediaRouter = MediaRouter.getInstance(this)
        val route = mediaRouter.routes.firstOrNull { it.id == targetId }
        if (route == null) {
            result.error("NOT_FOUND", "Google Cast route not found", null)
            return
        }

        val castContext = try {
            CastContext.getSharedInstance(this)
        } catch (t: Throwable) {
            result.error("CAST_INIT_FAILED", t.message, null)
            return
        }

        val sessionManager = castContext.sessionManager
        val currentSession = sessionManager.currentCastSession
        if (currentSession != null) {
            loadOnCastSession(
                session = currentSession,
                streamUrl = streamUrl,
                title = title,
                subtitle = subtitle,
                posterUrl = posterUrl,
                startTicks = startTicks,
                result = result,
            )
            return
        }

        pendingCastTimeout?.let { handler.removeCallbacks(it) }
        pendingCastListener?.let { listener ->
            sessionManager.removeSessionManagerListener(listener, CastSession::class.java)
        }

        val listener = object : SessionManagerListener<CastSession> {
            override fun onSessionStarted(session: CastSession, sessionId: String) {
                cleanupPendingCast(sessionManager, this)
                loadOnCastSession(session, streamUrl, title, subtitle, posterUrl, startTicks, result)
            }

            override fun onSessionResumed(session: CastSession, wasSuspended: Boolean) {
                cleanupPendingCast(sessionManager, this)
                loadOnCastSession(session, streamUrl, title, subtitle, posterUrl, startTicks, result)
            }

            override fun onSessionStartFailed(session: CastSession, error: Int) {
                cleanupPendingCast(sessionManager, this)
                result.error("CAST_START_FAILED", "Failed to start cast session: $error", null)
            }

            override fun onSessionEnded(session: CastSession, error: Int) {}
            override fun onSessionEnding(session: CastSession) {}
            override fun onSessionResumeFailed(session: CastSession, error: Int) {}
            override fun onSessionResuming(session: CastSession, sessionId: String) {}
            override fun onSessionStarting(session: CastSession) {}
            override fun onSessionSuspended(session: CastSession, reason: Int) {}
        }

        pendingCastListener = listener
        sessionManager.addSessionManagerListener(listener, CastSession::class.java)

        pendingCastTimeout = Runnable {
            cleanupPendingCast(sessionManager, listener)
            emitGoogleCastEvent("error", "Timed out waiting for cast session")
            result.error("CAST_TIMEOUT", "Timed out waiting for cast session", null)
        }.also { handler.postDelayed(it, 15000L) }

        mediaRouter.selectRoute(route)
    }

    private fun cleanupPendingCast(
        sessionManager: com.google.android.gms.cast.framework.SessionManager,
        listener: SessionManagerListener<CastSession>,
    ) {
        pendingCastTimeout?.let { handler.removeCallbacks(it) }
        pendingCastTimeout = null
        sessionManager.removeSessionManagerListener(listener, CastSession::class.java)
        pendingCastListener = null
    }

    private fun loadOnCastSession(
        session: CastSession,
        streamUrl: String,
        title: String,
        subtitle: String?,
        posterUrl: String?,
        startTicks: Long?,
        result: MethodChannel.Result,
    ) {
        val remoteClient = session.remoteMediaClient
        if (remoteClient == null) {
            result.error("NO_REMOTE_CLIENT", "No cast remote media client", null)
            return
        }

        val metadata = MediaMetadata(MediaMetadata.MEDIA_TYPE_MOVIE).apply {
            putString(MediaMetadata.KEY_TITLE, title)
            if (!subtitle.isNullOrBlank()) {
                putString(MediaMetadata.KEY_SUBTITLE, subtitle)
            }
            if (!posterUrl.isNullOrBlank()) {
                runCatching {
                    addImage(WebImage(Uri.parse(posterUrl)))
                }
            }
        }

        val mediaInfo = MediaInfo.Builder(streamUrl)
            .setStreamType(MediaInfo.STREAM_TYPE_BUFFERED)
            .setContentType("video/*")
            .setMetadata(metadata)
            .build()

        val startMs = startTicks?.div(10000L) ?: 0L
        val loadRequest = MediaLoadRequestData.Builder()
            .setMediaInfo(mediaInfo)
            .setAutoplay(true)
            .setCurrentTime(startMs)
            .build()

        remoteClient.load(loadRequest)
        result.success(null)
    }

    private fun withRemoteMediaClient(
        result: MethodChannel.Result,
        action: (com.google.android.gms.cast.framework.media.RemoteMediaClient) -> Unit,
    ) {
        val castContext = try {
            CastContext.getSharedInstance(this)
        } catch (t: Throwable) {
            result.error("CAST_INIT_FAILED", t.message, null)
            return
        }

        val session = castContext.sessionManager.currentCastSession
        if (session == null) {
            result.error("NO_CAST_SESSION", "No active Google Cast session", null)
            return
        }

        val remoteClient = session.remoteMediaClient
        if (remoteClient == null) {
            result.error("NO_REMOTE_CLIENT", "No cast remote media client", null)
            return
        }

        action(remoteClient)
    }

    private fun registerCastStatusListener() {
        val sessionManager = runCatching { CastContext.getSharedInstance(this).sessionManager }.getOrNull()
            ?: return

        castStatusListener?.let { listener ->
            sessionManager.removeSessionManagerListener(listener, CastSession::class.java)
        }

        val listener = object : SessionManagerListener<CastSession> {
            override fun onSessionStarted(session: CastSession, sessionId: String) {
                emitGoogleCastEvent("connected")
            }

            override fun onSessionResumed(session: CastSession, wasSuspended: Boolean) {
                emitGoogleCastEvent("connected")
            }

            override fun onSessionEnded(session: CastSession, error: Int) {
                emitGoogleCastEvent("disconnected")
            }

            override fun onSessionSuspended(session: CastSession, reason: Int) {
                emitGoogleCastEvent("disconnected")
            }

            override fun onSessionStartFailed(session: CastSession, error: Int) {
                emitGoogleCastEvent("error", "Failed to start cast session: $error")
            }

            override fun onSessionResumeFailed(session: CastSession, error: Int) {
                emitGoogleCastEvent("error", "Failed to resume cast session: $error")
            }

            override fun onSessionEnding(session: CastSession) {}
            override fun onSessionResuming(session: CastSession, sessionId: String) {}
            override fun onSessionStarting(session: CastSession) {}
        }

        castStatusListener = listener
        sessionManager.addSessionManagerListener(listener, CastSession::class.java)
    }

    private fun emitGoogleCastEvent(state: String, message: String? = null) {
        val payload = mutableMapOf<String, Any>(
            "kind" to "googleCast",
            "state" to state,
        )
        if (!message.isNullOrBlank()) {
            payload["message"] = message
        }
        runOnUiThread {
            castEventsSink?.success(payload)
        }
    }

    private fun getCurrentCastSession(): CastSession? {
        return runCatching { CastContext.getSharedInstance(this).sessionManager.currentCastSession }
            .getOrNull()
    }
}
