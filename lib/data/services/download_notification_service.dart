import 'dart:async';
import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class DownloadNotificationService {
  static const _channelId = 'moonfin_downloads';
  static const _channelName = 'Downloads';
  static const _channelDesc = 'Shows download progress for offline media';
  static const _progressNotificationId = 1000;
  static const _completionNotificationId = 1001;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  DateTime _lastUpdate = DateTime.fromMillisecondsSinceEpoch(0);
  bool _foregroundServiceRunning = false;
  String? _lastProgressSignature;

  Future<void>? _pendingNotification;

  Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const linuxSettings =
        LinuxInitializationSettings(defaultActionName: 'Open');

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
      linux: linuxSettings,
    );

    await _plugin.initialize(initSettings);
    _initialized = true;

    if (Platform.isAndroid) {
      try {
        await _plugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission();
      } catch (_) {}
    }
  }

  Future<void> showProgress({
    required String itemName,
    required double progress,
    int batchTotal = 0,
    int batchCompleted = 0,
  }) async {
    if (!_initialized) return;

    final percent = progress >= 0 ? (progress * 100).round() : -1;
    final batchInfo =
        batchTotal > 1 ? ' (${batchCompleted + 1}/$batchTotal)' : '';
    final title = 'Downloading$batchInfo';
    final body = percent >= 0 ? '$itemName — $percent%' : '$itemName…';
    final signature = '$title\n$body\n$percent';

    if (signature == _lastProgressSignature) {
      return;
    }

    final now = DateTime.now();
    if (now.difference(_lastUpdate).inMilliseconds < 1500) return;
    _lastUpdate = now;
    _lastProgressSignature = signature;

    final previous = _pendingNotification;
    final completer = Completer<void>();
    _pendingNotification = completer.future;

    try {
      if (previous != null) await previous;

      if (Platform.isAndroid) {
        await _showAndroidForegroundProgress(title, body, percent);
      } else {
        await _showStandardProgress(title, body, percent);
      }
    } catch (_) {
    } finally {
      completer.complete();
    }
  }

  Future<void> showComplete({
    required String itemName,
    int batchTotal = 0,
  }) async {
    if (!_initialized) return;
    _lastProgressSignature = null;
    await _stopForegroundService();

    final title = batchTotal > 1 ? 'Downloads complete' : 'Download complete';
    final body = batchTotal > 1
        ? '$batchTotal items saved for offline'
        : '$itemName saved for offline';
    await _showSimple(_completionNotificationId, title, body);
  }

  Future<void> showError({
    required String itemName,
    required String error,
  }) async {
    if (!_initialized) return;
    _lastProgressSignature = null;
    await _stopForegroundService();
    await _showSimple(_completionNotificationId, 'Download failed', '$itemName: $error');
  }

  Future<void> dismiss() async {
    if (!_initialized) return;
    _lastProgressSignature = null;
    await _stopForegroundService();
    await _plugin.cancel(_progressNotificationId);
  }

  Future<void> _showAndroidForegroundProgress(
      String title, String body, int percent) async {
    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      showProgress: true,
      maxProgress: 100,
      progress: percent >= 0 ? percent : 0,
      indeterminate: percent < 0,
      category: AndroidNotificationCategory.progress,
    );

    final details = NotificationDetails(android: androidDetails);

    if (!_foregroundServiceRunning) {
      try {
        final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        await androidPlugin?.startForegroundService(
          _progressNotificationId,
          title,
          body,
          notificationDetails: androidDetails,
          foregroundServiceTypes: {
            AndroidServiceForegroundType.foregroundServiceTypeDataSync,
          },
        );
        _foregroundServiceRunning = true;
      } catch (_) {
        await _plugin.show(_progressNotificationId, title, body, details);
      }
    } else {
      await _plugin.show(_progressNotificationId, title, body, details);
    }
  }

  Future<void> _showStandardProgress(
      String title, String body, int percent) async {
    await _plugin.show(
      _progressNotificationId,
      title,
      body,
      const NotificationDetails(
        iOS: DarwinNotificationDetails(),
        macOS: DarwinNotificationDetails(),
        linux: LinuxNotificationDetails(),
      ),
    );
  }

  Future<void> _showSimple(int id, String title, String body) async {
    await _plugin.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          autoCancel: true,
        ),
        iOS: const DarwinNotificationDetails(),
        macOS: const DarwinNotificationDetails(),
        linux: const LinuxNotificationDetails(),
      ),
    );
  }

  Future<void> _stopForegroundService() async {
    if (!_foregroundServiceRunning) return;
    try {
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin
          ?.stopForegroundService()
          .timeout(const Duration(seconds: 5));
    } catch (_) {
    }
    _foregroundServiceRunning = false;
    try {
      await _plugin.cancel(_progressNotificationId)
          .timeout(const Duration(seconds: 5));
    } catch (_) {
    }
  }
}
