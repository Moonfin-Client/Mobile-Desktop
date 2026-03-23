import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:server_core/server_core.dart';

import '../../platform/ios_storage.dart';
import '../../preference/user_preferences.dart';
import '../database/offline_database.dart';
import '../models/aggregated_item.dart';
import '../models/download_quality.dart';
import '../repositories/offline_repository.dart';
import 'book_reader_service.dart';
import 'download_logger.dart';
import 'download_notification_service.dart';
import 'storage_path_service.dart';

class DownloadProgress {
  final String itemId;
  final String fileName;
  final double progress;
  final int bytesReceived;
  final bool isComplete;
  final String? error;

  const DownloadProgress({
    required this.itemId,
    required this.fileName,
    this.progress = 0,
    this.bytesReceived = 0,
    this.isComplete = false,
    this.error,
  });
}

class DownloadService extends ChangeNotifier {
  static const String _guardCancelReason = 'download_guard_timeout';

  final MediaServerClient _client;
  final DownloadNotificationService _notificationService;
  final Dio _downloadDio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(hours: 6),
  ));

  final Map<String, DownloadProgress> _activeDownloads = {};
  Map<String, DownloadProgress> get activeDownloads =>
      Map.unmodifiable(_activeDownloads);

  final Map<String, CancelToken> _cancelTokens = {};
  final Map<String, DateTime> _downloadStartTimes = {};
  bool _cancelAllRequested = false;

  int _totalQueued = 0;
  int _completedCount = 0;
  int get totalQueued => _totalQueued;
  int get completedCount => _completedCount;
  bool get isBatchDownloading => _totalQueued > 0 && _completedCount < _totalQueued;

  DownloadService(this._client, this._notificationService);

  bool isDownloading(String itemId) => _activeDownloads.containsKey(itemId);

  UserPreferences get _prefs => GetIt.instance<UserPreferences>();

  int _concurrencyLimit() {
    return _prefs.get(UserPreferences.downloadConcurrentCount).clamp(1, 5);
  }

  int _inFlightDownloads() {
    return _activeDownloads.values
        .where((d) => !d.isComplete && d.error == null)
        .length;
  }

  bool _canClearCancelAllGate() {
    return _cancelTokens.isEmpty && _inFlightDownloads() == 0;
  }

  Future<void> _waitForDownloadSlot() async {
    while (!_cancelAllRequested && _inFlightDownloads() >= _concurrencyLimit()) {
      await Future.delayed(const Duration(milliseconds: 120));
    }
  }

  Future<bool> _checkWifiPolicy() async {
    if (!_prefs.get(UserPreferences.downloadWifiOnly)) return true;
    final results = await Connectivity().checkConnectivity();
    return results.any((r) => r == ConnectivityResult.wifi);
  }

  Future<bool> _checkStorageLimit(int estimatedBytes) async {
    final limitMb = _prefs.get(UserPreferences.downloadStorageLimitMb);
    if (limitMb <= 0) return true;
    final used = await _offlineRepo.getTotalStorageUsed();
    return (used + estimatedBytes) <= limitMb * 1024 * 1024;
  }

  StoragePathService get _storagePath => GetIt.instance<StoragePathService>();
  OfflineRepository get _offlineRepo => GetIt.instance<OfflineRepository>();
  DownloadLogger get _logger => GetIt.instance<DownloadLogger>();

  String _fileNameBaseFromPath(String savePath) {
    final fileName = savePath.split(Platform.pathSeparator).last;
    return fileName.replaceAll(RegExp(r'\.[^.]+$'), '');
  }

  Future<void> _deleteSubtitleFiles(Directory dir, String fileNameBase) async {
    if (!await dir.exists()) {
      return;
    }

    final prefix = '${fileNameBase}_sub_';
    await for (final entity in dir.list()) {
      if (entity is! File) {
        continue;
      }

      final name = entity.path.split(Platform.pathSeparator).last;
      if (name.startsWith(prefix)) {
        await entity.delete();
      }
    }
  }

  Future<void> _deleteEmptyDirectoriesUpTo(Directory start, Directory root) async {
    var current = start;

    while (current.path.startsWith(root.path) && current.path != root.path) {
      if (!await current.exists()) {
        current = current.parent;
        continue;
      }

      if (!await current.list().isEmpty) {
        break;
      }

      final parent = current.parent;
      await current.delete();
      current = parent;
    }
  }

  Future<void> _deleteFileArtifacts(String savePath) async {
    final offlineRoot = await _storagePath.getOfflineRoot();
    await _deleteFileArtifactsWithinRoot(savePath, offlineRoot);
  }

  Future<void> _deleteFileArtifactsWithinRoot(String savePath, Directory offlineRoot) async {
    final file = File(savePath);
    if (await file.exists()) {
      await file.delete();
    }

    final parent = file.parent;
    await _deleteSubtitleFiles(parent, _fileNameBaseFromPath(savePath));
    await _deleteEmptyDirectoriesUpTo(parent, offlineRoot);
  }

  Future<void> _deleteCandidateFileArtifacts(
    Directory dir,
    AggregatedItem item,
    Directory offlineRoot,
  ) async {
    final candidatePaths = _candidateSavePaths(dir, item).toList(growable: false);
    final fileNameBases = candidatePaths.map(_fileNameBaseFromPath).toSet();

    for (final savePath in candidatePaths) {
      final file = File(savePath);
      if (await file.exists()) {
        await file.delete();
      }
    }

    for (final fileNameBase in fileNameBases) {
      await _deleteSubtitleFiles(dir, fileNameBase);
    }

    await _deleteEmptyDirectoriesUpTo(dir, offlineRoot);
  }

  Future<void> _deleteImagesForIds(Iterable<String> itemIds, Directory imageDir) async {
    for (final itemId in itemIds.toSet()) {
      await _deleteItemImages(itemId, imageDir);
    }
  }

  Future<void> _cleanupEpisodeContainers(AggregatedItem episode, Directory imageDir) async {
    if (episode.seasonId != null) {
      final seasonEpisodes = await _offlineRepo.getSeasonEpisodes(episode.seasonId!);
      if (seasonEpisodes.isEmpty) {
        await _offlineRepo.deleteItem(episode.seasonId!);
        await _deleteItemImages(episode.seasonId!, imageDir);
      }
    }

    if (episode.seriesId != null) {
      final seriesEpisodes = await _offlineRepo.getSeriesEpisodes(episode.seriesId!);
      if (seriesEpisodes.isEmpty) {
        await _offlineRepo.deleteItem(episode.seriesId!);
        await _deleteItemImages(episode.seriesId!, imageDir);
      }
    }
  }

  Iterable<String> _candidateSavePaths(Directory dir, AggregatedItem item) sync* {
    final seenPaths = <String>{};

    for (final quality in DownloadQuality.values) {
      final savePath = '${dir.path}/${_buildFileName(item, quality)}';
      if (seenPaths.add(savePath)) {
        yield savePath;
      }
    }
  }

  double _initialProgressForQuality(DownloadQuality quality) {
    return quality.isTranscoded ? -1.0 : 0.0;
  }

  double _clampProgress(double progress) {
    if (progress <= 0) {
      return 0.0;
    }

    if (progress >= 1) {
      return 1.0;
    }

    return progress;
  }

  double _storedProgress(double progress) {
    return progress < 0 ? 0.0 : _clampProgress(progress);
  }

  Future<Set<String>> _relatedImageIds(AggregatedItem item) async {
    final allItems = await _offlineRepo.getItems();

    switch (item.type) {
      case 'Season':
        return allItems
            .where((row) => row.itemId == item.id || row.seasonId == item.id)
            .map((row) => row.itemId)
            .toSet();

      case 'Series':
        return allItems
            .where((row) => row.itemId == item.id || row.seriesId == item.id)
            .map((row) => row.itemId)
            .toSet();

      default:
        return {item.id};
    }
  }

  double _calculateProgress({
    required int received,
    required int total,
    required int estimatedSize,
    required DownloadQuality quality,
  }) {
    if (total > 0) {
      return _clampProgress(received / total);
    }

    if (quality.isTranscoded) {
      return -1.0;
    }

    if (estimatedSize > 0) {
      return _clampProgress(received / estimatedSize);
    }

    return -1.0;
  }

  String _sanitizePath(String name) {
    return name.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_').trim();
  }

  String _buildSubFolder(AggregatedItem item) {
    switch (item.type) {
      case 'Movie':
        final year = item.productionYear;
        final title = _sanitizePath(item.name);
        return year != null ? 'Movies/$title ($year)' : 'Movies/$title';

      case 'Audio':
        final artist = _sanitizePath(
          item.albumArtist ??
              (item.artists.isNotEmpty ? item.artists.first : 'Unknown Artist'),
        );
        final album = _sanitizePath(item.album ?? 'Singles');
        return 'Music/$artist/$album';

      case 'AudioBook':
        final author = _sanitizePath(
          item.albumArtist ??
              (item.artists.isNotEmpty ? item.artists.first : 'Unknown Author'),
        );
        final collection = _sanitizePath(item.album ?? item.name);
        return 'Audiobooks/$author/$collection';

      case 'Book':
        return 'Books/${_sanitizePath(item.name)}';

      case 'Episode':
        final series = _sanitizePath(item.seriesName ?? 'Unknown Series');
        final season = item.parentIndexNumber;
        final seasonFolder =
            season != null ? 'Season ${season.toString().padLeft(2, '0')}' : 'Specials';
        return 'TV/$series/$seasonFolder';

      default:
        return 'Other/${_sanitizePath(item.name)}';
    }
  }

  String _buildFileName(AggregatedItem item, DownloadQuality quality) {
    final container = _getContainer(item, quality);
    switch (item.type) {
      case 'Audio':
      case 'AudioBook':
        final index = item.indexNumber;
        final prefix = index != null ? '${index.toString().padLeft(2, '0')} - ' : '';
        return '$prefix${_sanitizePath(item.name)}.$container';

      case 'Episode':
        final s = item.parentIndexNumber;
        final e = item.indexNumber;
        final prefix =
            (s != null && e != null) ? 'S${s.toString().padLeft(2, '0')}E${e.toString().padLeft(2, '0')} - ' : '';
        return '$prefix${_sanitizePath(item.name)}.$container';

      default:
        return '${_sanitizePath(item.name)}.$container';
    }
  }

  String _getContainer(AggregatedItem item, DownloadQuality quality) {
    if (item.type == 'Book') {
      final ext = BookReaderService.detectExtension(item);
      if (ext != null && ext.isNotEmpty) return ext.toLowerCase();
    }

    if (quality.isTranscoded) return quality.container;
    if (item.mediaSources.isNotEmpty) {
      final c = item.mediaSources.first['Container'] as String?;
      if (c != null && c.isNotEmpty) return c.toLowerCase();
    }
    return 'mkv';
  }

  Future<String?> _correctBookExtension(
    File savedFile,
    Response? response,
  ) async {
    final currentPath = savedFile.path;
    final currentExt = currentPath.contains('.')
        ? currentPath.substring(currentPath.lastIndexOf('.') + 1).toLowerCase()
        : '';

    String? detectedExt;

    if (response != null) {
      final disposition = response.headers.value('content-disposition');
      detectedExt = BookReaderService.extractExtensionFromContentDisposition(disposition);

      if (detectedExt == null) {
        final contentType = response.headers.value('content-type');
        detectedExt = BookReaderService.extensionFromMime(contentType);
      }
    }

    if (detectedExt == null || detectedExt == currentExt) return null;
    if (!BookReaderService.supportedExtensions.contains(detectedExt)) return null;

    final newPath = currentPath.contains('.')
        ? currentPath.replaceAll(RegExp(r'\.[^.]+$'), '.$detectedExt')
        : '$currentPath.$detectedExt';
    if (newPath == currentPath) return null;
    await savedFile.rename(newPath);
    return newPath;
  }

  Future<void> _populateOfflineAssets(AggregatedItem item) async {
    await _downloadImages(item);
    if (_usesAudioDownloadEndpoint(item)) {
      await _downloadLyrics(item);
    }
    await _ensureParentContainers(item);
  }

  Future<void> _runPostCompletionTasks({
    required AggregatedItem item,
    required String savePath,
    required Directory dir,
    required String fileName,
  }) async {
    Future<void> runBestEffort(Future<void> task, Duration timeout) async {
      try {
        await task.timeout(timeout);
      } catch (_) {}
    }

    final extensionIndex = fileName.lastIndexOf('.');
    final fileNameBase = extensionIndex > 0
        ? fileName.substring(0, extensionIndex)
        : fileName;

    await runBestEffort(
      _populateOfflineAssets(item),
      const Duration(seconds: 30),
    );

    if (Platform.isIOS) {
      await runBestEffort(
        IosStorage.excludeFromBackup(savePath),
        const Duration(seconds: 10),
      );
    }

    if (_totalQueued <= 1 || _completedCount >= _totalQueued) {
      await runBestEffort(
        _notificationService.showComplete(
          itemName: item.name,
          batchTotal: _totalQueued > 1 ? _completedCount : 0,
        ),
        const Duration(seconds: 10),
      );
    }

    await runBestEffort(
      _downloadExternalSubtitles(
        item,
        dir,
        fileNameBase,
      ),
      const Duration(seconds: 30),
    );
  }

  /// Wraps [Dio.download] so that once all expected bytes have been received
  /// the future resolves after a short grace period, even if the HTTP
  /// connection hangs open (common behind reverse proxies / keep-alive).
  Future<Response> _downloadWithHangGuard(
    String url,
    String savePath, {
    required Options options,
    required CancelToken cancelToken,
    required int estimatedSize,
    required void Function(int, int) onReceiveProgress,
  }) async {
    final bytesComplete = Completer<void>();
    Timer? estimatedCompletionTimer;
    Timer? stallTimer;
    var lastReceived = 0;
    var lastTotal = -1;

    void markBytesCompleteIfPending() {
      if (!bytesComplete.isCompleted) {
        bytesComplete.complete();
      }
    }

    void armEstimatedCompletionTimer() {
      estimatedCompletionTimer?.cancel();
      estimatedCompletionTimer = Timer(
        const Duration(seconds: 5),
        markBytesCompleteIfPending,
      );
    }

    void armStallTimer() {
      stallTimer?.cancel();
      stallTimer = Timer(const Duration(seconds: 15), () {
        if (lastReceived > 0 && !bytesComplete.isCompleted) {
          markBytesCompleteIfPending();
        }
      });
    }

    final downloadFuture = _downloadDio.download(
      url,
      savePath,
      options: options,
      cancelToken: cancelToken,
      deleteOnError: false,
      onReceiveProgress: (received, total) {
        lastReceived = received;
        lastTotal = total;
        onReceiveProgress(received, total);
        if (total > 0 && received >= total && !bytesComplete.isCompleted) {
          markBytesCompleteIfPending();
          return;
        }

        if (total <= 0 && estimatedSize > 0 && received >= estimatedSize) {
          armEstimatedCompletionTimer();
        } else {
          estimatedCompletionTimer?.cancel();
        }

        // When no Content-Length is available (reverse proxy / chunked),
        // arm a stall timer that fires if no new bytes arrive for 15 s.
        if (total <= 0 && received > 0) {
          armStallTimer();
        }
      },
    );

    final completion = Completer<Response>();

    void completeIfPending(Response value) {
      if (!completion.isCompleted) {
        completion.complete(value);
      }
    }

    void completeErrorIfPending(Object error, [StackTrace? stackTrace]) {
      if (!completion.isCompleted) {
        completion.completeError(error, stackTrace);
      }
    }

    downloadFuture.then(completeIfPending).catchError(completeErrorIfPending);

    bytesComplete.future.then((_) async {
      if (completion.isCompleted) {
        return;
      }

      try {
        final settled = await downloadFuture.timeout(const Duration(seconds: 20));
        completeIfPending(settled);
      } on TimeoutException {
        // Reverse proxies may keep the connection open even after all bytes
        // are transferred. Finalize as a successful candidate and let
        // downstream file validation decide integrity.
        cancelToken.cancel(_guardCancelReason);
        final headers = Headers.fromMap({
          if (lastTotal > 0) 'content-length': [lastTotal.toString()],
        });
        completeIfPending(
          Response(
            requestOptions: RequestOptions(
              path: url,
              method: options.method ?? 'GET',
              headers: options.headers,
            ),
            statusCode: 200,
            headers: headers,
            data: null,
            extra: {
              'guardFinalized': true,
              'bytesReceived': lastReceived,
            },
          ),
        );
      } catch (e, st) {
        completeErrorIfPending(e, st);
      }
    }).ignore();

    try {
      return await completion.future;
    } finally {
      estimatedCompletionTimer?.cancel();
      stallTimer?.cancel();
    }
  }

  bool _hasAuthToken() {
    final token = _client.accessToken;
    return token != null && token.isNotEmpty;
  }

  bool _isGuardTimeoutCancel(DioException e) {
    final raw = e.error;
    return raw is String && raw == _guardCancelReason;
  }

  bool _supportsTranscodedDownload(String? type) {
    return type == 'Movie' || type == 'Episode';
  }

  Map<String, String> _buildAuthHeaders() {
    final token = _client.accessToken;
    if (token == null || token.isEmpty) {
      return const {};
    }

    return {
      'X-Emby-Token': token,
      'Authorization': 'MediaBrowser Token="$token"',
    };
  }

  Map<String, String> _buildDownloadRequestHeaders() {
    final token = _client.accessToken;
    if (token == null || token.isEmpty) {
      return {
        'Accept': 'application/octet-stream',
        'User-Agent': 'Moonfin/Flutter',
      };
    }
    return {
      'Accept': 'application/octet-stream',
      'User-Agent': 'Moonfin/Flutter',
      'X-Emby-Token': token,
      'Authorization': 'MediaBrowser Token="$token"',
    };
  }

  bool _usesAudioDownloadEndpoint(AggregatedItem item) {
    final mediaType = item.rawData['MediaType'] as String?;
    return item.type == 'Audio' || item.type == 'AudioBook' || mediaType == 'Audio';
  }

  bool _shouldRetryWithFallback(
    AggregatedItem item,
    DownloadQuality quality,
    DioException error,
  ) {
    final status = error.response?.statusCode;
    if (status != 401 && status != 403 && status != 404) {
      return false;
    }

    if (item.type == 'Book') {
      return true;
    }

    return !quality.isTranscoded;
  }

  String? _primaryMediaSourceId(AggregatedItem item) {
    return item.mediaSources.isNotEmpty ? item.mediaSources.first['Id'] as String? : null;
  }

  String _encodeQuery(Map<String, String> params) {
    return params.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }

  Map<String, String> _baseDownloadParams(
    AggregatedItem item, {
    bool isStatic = false,
    bool includeMediaSourceId = true,
  }) {
    final mediaSourceId = _primaryMediaSourceId(item);
    return <String, String>{
      if (isStatic) 'Static': 'true',
      if (includeMediaSourceId && mediaSourceId != null) 'MediaSourceId': mediaSourceId,
      if (_client.accessToken != null) 'ApiKey': _client.accessToken!,
    };
  }

  String _buildDirectItemFileUrl(String itemId, AggregatedItem item) {
    final query = _encodeQuery(_baseDownloadParams(item));
    return '${_client.baseUrl}/Items/$itemId/File${query.isEmpty ? '' : '?$query'}';
  }

  String _buildStaticVideoStreamUrl(String itemId, AggregatedItem item) {
    final query = _encodeQuery(_baseDownloadParams(item, isStatic: true));
    return '${_client.baseUrl}/Videos/$itemId/stream?$query';
  }

  List<String> _buildDownloadFallbackUrls(
    AggregatedItem item,
    {
    required String primaryUrl,
  }) {
    final candidates = <String>[
      if (item.type == 'Book')
        ...BookReaderService.buildDownloadUris(_client, item).map((u) => u.toString())
      else ...[
        if (_usesAudioDownloadEndpoint(item)) _buildAudioDownloadUrl(item.id, item),
        _buildDirectItemDownloadUrl(item.id, item),
        _buildDirectItemFileUrl(item.id, item),
        _buildStaticVideoStreamUrl(item.id, item),
      ],
    ];

    final fallbackUrls = <String>[];
    final primary = Uri.parse(primaryUrl).toString();
    final seen = <String>{primary};
    for (final candidate in candidates) {
      final normalized = Uri.parse(candidate).toString();
      if (seen.add(normalized)) {
        fallbackUrls.add(normalized);
      }
    }

    return fallbackUrls;
  }

  String _friendlyDioError(DioException e) {
    final status = e.response?.statusCode;
    if (status == 403) {
      return 'Download forbidden (403). Retried alternate endpoints but access was denied.';
    }
    if (status == 401) {
      return 'Download unauthorized (401). Please re-login and try again.';
    }
    if (status == 404) {
      return 'Download source not found (404). The file may no longer be available.';
    }
    return e.message ?? 'Download failed';
  }

  String _friendlyGenericError(Object e) {
    if (e is TimeoutException) {
      return 'Download timed out while waiting for transfer completion.';
    }

    return e.toString();
  }

  bool _isPrivateIpv4(String host) {
    final parts = host.split('.');
    if (parts.length != 4) {
      return false;
    }

    final octets = parts.map(int.tryParse).toList(growable: false);
    if (octets.any((o) => o == null)) {
      return false;
    }

    final a = octets[0]!;
    final b = octets[1]!;
    return a == 10 ||
        a == 127 ||
        (a == 172 && b >= 16 && b <= 31) ||
        (a == 192 && b == 168);
  }

  String _networkPath() {
    final uri = Uri.tryParse(_client.baseUrl);
    final host = uri?.host.toLowerCase() ?? '';
    if (host.isEmpty) {
      return 'unknown';
    }

    if (host == 'localhost' || host.endsWith('.local') || _isPrivateIpv4(host)) {
      return 'local-ip';
    }

    final isLikelyIpv4 = RegExp(r'^\d+\.\d+\.\d+\.\d+$').hasMatch(host);
    if (isLikelyIpv4) {
      return 'public-ip';
    }

    return 'domain';
  }

  String _endpointTypeFromUrl(String url) {
    final path = Uri.tryParse(url)?.path.toLowerCase() ?? url.toLowerCase();
    if (path.contains('/items/') && path.contains('/download')) {
      return 'download';
    }
    if (path.contains('/items/') && path.contains('/file')) {
      return 'file';
    }
    if (path.contains('/audio/')) {
      return 'audio';
    }
    if (path.contains('/videos/') && path.contains('/stream')) {
      return 'stream';
    }
    return 'unknown';
  }

  int? _expectedLengthFromResponse(Response? response) {
    final header = response?.headers.value('content-length');
    if (header == null) {
      return null;
    }
    return int.tryParse(header);
  }

  Map<String, Object?> _responseTelemetry(Response? response) {
    if (response == null) {
      return const {};
    }

    return {
      'statusCode': response.statusCode,
      'contentType': response.headers.value('content-type'),
      'contentLength': response.headers.value('content-length'),
      'acceptRanges': response.headers.value('accept-ranges'),
      'contentRange': response.headers.value('content-range'),
      'transferEncoding': response.headers.value('transfer-encoding'),
    };
  }

  String _validationReasonCodeFromError(Object error) {
    final msg = error.toString().toLowerCase();
    if (msg.contains('content-type')) return 'invalid_content_type';
    if (msg.contains('signature')) return 'signature_mismatch';
    if (msg.contains('html') || msg.contains('text/error')) return 'text_payload';
    if (msg.contains('content-length')) return 'length_mismatch';
    if (msg.contains('missing on disk')) return 'missing_file';
    if (msg.contains('0 bytes')) return 'zero_byte';
    if (msg.contains('timed out')) return 'timeout';
    return 'validation_failed';
  }

  Future<Uint8List> _readPrefix(File file, {int maxBytes = 512}) async {
    final length = await file.length();
    final toRead = length < maxBytes ? length : maxBytes;
    final chunks = await file.openRead(0, toRead).toList();
    return Uint8List.fromList(chunks.expand((c) => c).toList(growable: false));
  }

  bool _looksLikeTextPayload(Uint8List bytes) {
    if (bytes.isEmpty) {
      return false;
    }

    final sample = String.fromCharCodes(bytes).toLowerCase();
    return sample.contains('<html') ||
        sample.contains('<!doctype') ||
        sample.contains('{"error"') ||
        sample.contains('cloudflare') ||
        sample.contains('nginx') ||
        sample.contains('forbidden') ||
        sample.contains('unauthorized');
  }

  bool _hasMp4Signature(Uint8List bytes) {
    if (bytes.length < 12) {
      return false;
    }

    for (var i = 0; i <= bytes.length - 4 && i < 32; i++) {
      if (bytes[i] == 0x66 && bytes[i + 1] == 0x74 && bytes[i + 2] == 0x79 && bytes[i + 3] == 0x70) {
        return true;
      }
    }

    return false;
  }

  bool _signatureMatchesExtension(Uint8List bytes, String ext) {
    switch (ext) {
      case 'mp4':
      case 'm4v':
      case 'm4a':
        return _hasMp4Signature(bytes);
      case 'mkv':
      case 'webm':
        return bytes.length >= 4 && bytes[0] == 0x1A && bytes[1] == 0x45 && bytes[2] == 0xDF && bytes[3] == 0xA3;
      case 'mp3':
        return (bytes.length >= 3 && bytes[0] == 0x49 && bytes[1] == 0x44 && bytes[2] == 0x33) ||
            (bytes.length >= 2 && bytes[0] == 0xFF && (bytes[1] & 0xE0) == 0xE0);
      case 'flac':
        return bytes.length >= 4 && bytes[0] == 0x66 && bytes[1] == 0x4C && bytes[2] == 0x61 && bytes[3] == 0x43;
      case 'ogg':
      case 'opus':
        return bytes.length >= 4 && bytes[0] == 0x4F && bytes[1] == 0x67 && bytes[2] == 0x67 && bytes[3] == 0x53;
      case 'wav':
        return bytes.length >= 12 &&
            bytes[0] == 0x52 &&
            bytes[1] == 0x49 &&
            bytes[2] == 0x46 &&
            bytes[3] == 0x46 &&
            bytes[8] == 0x57 &&
            bytes[9] == 0x41 &&
            bytes[10] == 0x56 &&
            bytes[11] == 0x45;
      case 'pdf':
        return bytes.length >= 5 && bytes[0] == 0x25 && bytes[1] == 0x50 && bytes[2] == 0x44 && bytes[3] == 0x46 && bytes[4] == 0x2D;
      case 'epub':
      case 'cbz':
      case 'zip':
        return bytes.length >= 4 && bytes[0] == 0x50 && bytes[1] == 0x4B && bytes[2] == 0x03 && bytes[3] == 0x04;
      case 'cbr':
        return bytes.length >= 7 &&
            bytes[0] == 0x52 &&
            bytes[1] == 0x61 &&
            bytes[2] == 0x72 &&
            bytes[3] == 0x21 &&
            bytes[4] == 0x1A &&
            bytes[5] == 0x07;
      default:
        return true;
    }
  }

  Future<void> _validateDownloadedFile(
    File file,
    DownloadQuality quality, {
    required int bytesReceived,
    Response? response,
  }) async {
    if (!await file.exists()) {
      throw StateError('Downloaded file is missing on disk');
    }

    final fileSize = await file.length();
    if (fileSize <= 0) {
      throw StateError('Downloaded file is empty (0 bytes)');
    }

    final contentType = response?.headers.value('content-type')?.toLowerCase();
    if (contentType != null &&
        (contentType.startsWith('text/') ||
            contentType.contains('application/json') ||
            contentType.contains('text/html'))) {
      throw StateError('Download returned non-media content-type: $contentType');
    }

    final contentLength = response?.headers.value('content-length');
    if (contentLength != null) {
      final parsedLength = int.tryParse(contentLength);
      if (parsedLength != null && parsedLength > 0 && bytesReceived > 0 && bytesReceived != parsedLength) {
        throw StateError('Downloaded bytes do not match Content-Length (received=$bytesReceived expected=$parsedLength)');
      }
    }

    final prefix = await _readPrefix(file);
    if (_looksLikeTextPayload(prefix)) {
      throw StateError('Downloaded content appears to be an HTML/text error payload');
    }

    final ext = file.path.contains('.') ? file.path.split('.').last.toLowerCase() : '';
    if (ext.isNotEmpty && !_signatureMatchesExtension(prefix, ext)) {
      throw StateError('Downloaded file signature does not match extension .$ext');
    }

    if (quality.isTranscoded && !_signatureMatchesExtension(prefix, quality.container)) {
      throw StateError('Transcoded file signature does not match expected container ${quality.container}');
    }
  }

  String _buildAudioDownloadUrl(String itemId, AggregatedItem item) {
    final query = _encodeQuery(_baseDownloadParams(item, isStatic: true));
    return '${_client.baseUrl}/Audio/$itemId/stream?$query';
  }

  String _buildDirectItemDownloadUrl(String itemId, AggregatedItem item) {
    final query = _encodeQuery(_baseDownloadParams(item, includeMediaSourceId: false));
    return '${_client.baseUrl}/Items/$itemId/Download${query.isEmpty ? '' : '?$query'}';
  }

  String _buildDownloadUrl(String itemId, AggregatedItem item, DownloadQuality quality) {
    if (!quality.isTranscoded || !_supportsTranscodedDownload(item.type)) {
      return _buildDirectItemDownloadUrl(itemId, item);
    }

    final baseUrl = _client.baseUrl;
    final params = _baseDownloadParams(item);

    params['Static'] = 'false';
    params['videoCodec'] = quality.videoCodec;
    params['audioCodec'] = quality.audioCodec;
    if (quality.videoBitRate != null) {
      params['videoBitRate'] = quality.videoBitRate.toString();
    }
    if (quality.audioBitRate != null) {
      params['audioBitRate'] = quality.audioBitRate.toString();
    }
    if (quality.maxWidth != null) {
      params['maxWidth'] = quality.maxWidth.toString();
    }
    params['container'] = quality.container;
    if (quality.audioChannels != null) {
      params['audioChannels'] = quality.audioChannels.toString();
    }

    final query = _encodeQuery(params);
    return '$baseUrl/Videos/$itemId/stream?$query';
  }

  Future<AggregatedItem> _ensureFullItem(AggregatedItem item) async {
    if (item.mediaSources.isNotEmpty) return item;
    final data = await _client.itemsApi.getItem(item.id);
    return AggregatedItem(id: item.id, serverId: item.serverId, rawData: data);
  }

  Future<void> downloadItem(AggregatedItem item, {DownloadQuality quality = DownloadQuality.original}) async {
    if (_cancelAllRequested) {
      if (_canClearCancelAllGate()) {
        _cancelAllRequested = false;
      } else {
        return;
      }
    }
    if (isDownloading(item.id)) return;
    await _waitForDownloadSlot();
    if (_cancelAllRequested) {
      if (_canClearCancelAllGate()) {
        _cancelAllRequested = false;
      } else {
        return;
      }
    }

    String? savePath;
    var selectedUrl = '';
    var selectedEndpointType = 'unknown';
    var fallbackCount = 0;
    final networkPath = _networkPath();

    if (!await _checkWifiPolicy()) {
      _activeDownloads[item.id] = DownloadProgress(
        itemId: item.id,
        fileName: item.name,
        error: 'WiFi-only mode enabled. Connect to WiFi to download.',
      );
      unawaited(_logger.logWarn(item, 'Blocked — WiFi-only mode is enabled'));
      notifyListeners();
      return;
    }

    try {
      final fullItem = await _ensureFullItem(item);
      final estimatedSize =
          (fullItem.mediaSources.isNotEmpty ? fullItem.mediaSources.first['Size'] as int? : null) ?? 0;
      if (!await _checkStorageLimit(estimatedSize)) {
        _activeDownloads[item.id] = DownloadProgress(
          itemId: item.id,
          fileName: item.name,
          error: 'Storage limit reached. Free up space or increase the limit.',
        );
        unawaited(_logger.logWarn(item, 'Blocked — storage limit reached'));
        notifyListeners();
        return;
      }
      final downloadsDir = await _storagePath.getOfflineRoot();
      final subFolder = _buildSubFolder(fullItem);
      final fileName = _buildFileName(fullItem, quality);
      final dir = Directory('${downloadsDir.path}/$subFolder');
      if (!await dir.exists()) await dir.create(recursive: true);
      savePath = '${dir.path}/$fileName';

      await _offlineRepo.upsertItem(DownloadedItemsCompanion(
        itemId: Value(item.id),
        serverId: Value(item.serverId),
        type: Value(item.type ?? 'Unknown'),
        name: Value(item.name),
        metadataJson: Value(jsonEncode(fullItem.rawData)),
        downloadStatus: const Value(1),
        qualityPreset: Value(quality.name),
        seriesId: Value(item.seriesId),
        seasonId: Value(item.seasonId),
        seriesName: Value(item.seriesName),
        seasonName: Value(fullItem.rawData['SeasonName'] as String?),
        indexNumber: Value(item.indexNumber),
        parentIndexNumber: Value(item.parentIndexNumber),
      ));

      unawaited(_logger.logQueued(fullItem, quality, telemetry: {
        'qualityMode': quality.isTranscoded ? 'transcoded' : 'original',
        'networkPath': networkPath,
      }));

      final cancelToken = CancelToken();
      _cancelTokens[item.id] = cancelToken;
      _downloadStartTimes[item.id] = DateTime.now();

      if (!_hasAuthToken()) {
        throw StateError('Missing authentication token for download request. Please re-login and try again.');
      }

      final initialProgress = _initialProgressForQuality(quality);

      _activeDownloads[item.id] = DownloadProgress(
        itemId: item.id,
        fileName: fileName,
        progress: initialProgress,
      );
      await _notificationService.showProgress(
        itemName: item.name,
        progress: initialProgress,
        batchTotal: _totalQueued,
        batchCompleted: _completedCount,
      );
      notifyListeners();

      final url = _buildDownloadUrl(item.id, fullItem, quality);
      selectedUrl = url;
      selectedEndpointType = _endpointTypeFromUrl(selectedUrl);
      fallbackCount = 0;
      final headers = _buildDownloadRequestHeaders();
      final requestOptions = Options(headers: headers, method: 'GET');

      unawaited(_logger.logStarted(fullItem, quality, telemetry: {
        'endpointType': selectedEndpointType,
        'networkPath': networkPath,
        'terminalReason': 'started',
      }));

      void onReceiveProgress(int received, int total) {
        final rawProgress = _calculateProgress(
          received: received,
          total: total,
          estimatedSize: estimatedSize,
          quality: quality,
        );
        final progress = rawProgress >= 1.0 ? 0.99 : rawProgress;
        _activeDownloads[item.id] = DownloadProgress(
          itemId: item.id,
          fileName: fileName,
          progress: progress,
          bytesReceived: received,
        );
        _offlineRepo.updateDownloadStatus(
          item.id,
          1,
          progress: _storedProgress(progress),
        );
        _notificationService.showProgress(
          itemName: item.name,
          progress: progress,
          batchTotal: _totalQueued,
          batchCompleted: _completedCount,
        );
        unawaited(_logger.logProgress(fullItem, progress, received, telemetry: {
          'endpointType': selectedEndpointType,
          'networkPath': networkPath,
          'bytesReceived': received,
          'expectedLength': total > 0 ? total : null,
        }));
        notifyListeners();
      }

      Future<Response?> tryFallbackDownload() async {
        final fallbackUrls = _buildDownloadFallbackUrls(
          fullItem,
          primaryUrl: url,
        );

        for (final fallbackUrl in fallbackUrls) {
          try {
            final fallbackOptions = Options(
              headers: _buildDownloadRequestHeaders(),
              method: 'GET',
            );
            final response = await _downloadWithHangGuard(
              fallbackUrl,
              savePath!,
              options: fallbackOptions,
              cancelToken: cancelToken,
              estimatedSize: estimatedSize,
              onReceiveProgress: onReceiveProgress,
            );
            selectedUrl = fallbackUrl;
            selectedEndpointType = _endpointTypeFromUrl(selectedUrl);
            fallbackCount++;
            return response;
          } on DioException {
            continue;
          } on TimeoutException {
            continue;
          }
        }

        return null;
      }

      Response? downloadResponse;
      try {
        downloadResponse = await _downloadWithHangGuard(
          url,
          savePath,
          options: requestOptions,
          cancelToken: cancelToken,
          estimatedSize: estimatedSize,
          onReceiveProgress: onReceiveProgress,
        );
      } on DioException catch (e) {
        if (!_shouldRetryWithFallback(fullItem, quality, e)) {
          rethrow;
        }

        final fallbackResponse = await tryFallbackDownload();
        if (fallbackResponse == null) {
          rethrow;
        }
        downloadResponse = fallbackResponse;
      } on TimeoutException {

        final fallbackResponse = await tryFallbackDownload();
        if (fallbackResponse == null) {
          rethrow;
        }
        downloadResponse = fallbackResponse;
      }

      final savedFile = File(savePath);

      final currentProgress = _activeDownloads[item.id];
      final bytesReceived = currentProgress?.bytesReceived ?? 0;
      final expectedLength = _expectedLengthFromResponse(downloadResponse);

      _activeDownloads[item.id] = DownloadProgress(
        itemId: item.id,
        fileName: fileName,
        progress: 1.0,
        bytesReceived: bytesReceived,
      );
      await _offlineRepo.updateDownloadStatus(item.id, 1, progress: 1.0);
      notifyListeners();

      await _validateDownloadedFile(
        savedFile,
        quality,
        bytesReceived: bytesReceived,
        response: downloadResponse,
      );

      if (fullItem.type == 'Book') {
        final corrected = await _correctBookExtension(
          savedFile, downloadResponse,
        );
        if (corrected != null) {
          savePath = corrected;
        }
      }

      final finalSize = await File(savePath).length();
      unawaited(_logger.logFileVerified(fullItem, finalSize, telemetry: {
        'endpointType': selectedEndpointType,
        'networkPath': networkPath,
        'statusCode': downloadResponse.statusCode,
        'bytesReceived': bytesReceived,
        'expectedLength': expectedLength,
        'fallbackCount': fallbackCount,
        ..._responseTelemetry(downloadResponse),
      }));
      await _offlineRepo.setLocalFilePath(item.id, savePath, fileSize: finalSize);
      await _offlineRepo.updateDownloadStatus(item.id, 2);

      final elapsed = DateTime.now().difference(
        _downloadStartTimes[item.id] ?? DateTime.now(),
      );
      unawaited(_logger.logComplete(fullItem, quality, finalSize, elapsed, telemetry: {
        'endpointType': selectedEndpointType,
        'networkPath': networkPath,
        'statusCode': downloadResponse.statusCode,
        'bytesReceived': bytesReceived,
        'expectedLength': expectedLength,
        'fallbackCount': fallbackCount,
        'terminalReason': 'completed',
        ..._responseTelemetry(downloadResponse),
      }));
      unawaited(_logger.uploadToServer(_client));

      _activeDownloads[item.id] = DownloadProgress(
        itemId: item.id,
        fileName: fileName,
        progress: 1.0,
        isComplete: true,
      );
      _completedCount++;
      notifyListeners();

      unawaited(_runPostCompletionTasks(
        item: fullItem,
        savePath: savePath,
        dir: dir,
        fileName: fileName,
      ));
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel && !_isGuardTimeoutCancel(e)) {
        _activeDownloads.remove(item.id);
        final imageDir = await _storagePath.getImageCacheDir();
        if (savePath != null) {
          await _deleteFileArtifacts(savePath);
        }
        await _deleteItemImages(item.id, imageDir);
        await _offlineRepo.deleteItem(item.id);
        await _cleanupEpisodeContainers(item, imageDir);
        await _notificationService.dismiss();
        unawaited(_logger.logCancelled(item, telemetry: {
          'endpointType': selectedEndpointType,
          'networkPath': networkPath,
          'terminalReason': 'cancelled',
        }));
        unawaited(_logger.uploadToServer(_client));
      } else {
        final friendlyError = _friendlyDioError(e);
        final isGuardTimeout = _isGuardTimeoutCancel(e);
        if (savePath != null) {
          await _deleteFileArtifacts(savePath);
        }
        _activeDownloads[item.id] = DownloadProgress(
          itemId: item.id,
          fileName: item.name,
          error: friendlyError,
        );
        await _offlineRepo.updateDownloadStatus(item.id, 3, error: friendlyError);
        await _notificationService.showError(
          itemName: item.name,
          error: friendlyError,
        );
        unawaited(_logger.logFailed(item, quality, friendlyError, telemetry: {
          'endpointType': selectedEndpointType,
          'networkPath': networkPath,
          'statusCode': e.response?.statusCode,
          'terminalReason': isGuardTimeout ? 'timeout' : 'failed',
          'validationReasonCode': isGuardTimeout ? 'timeout' : null,
          ..._responseTelemetry(e.response),
        }));
        unawaited(_logger.uploadToServer(_client));
      }
    } on TimeoutException catch (e) {
      final friendlyError = _friendlyGenericError(e);
      if (savePath != null) {
        await _deleteFileArtifacts(savePath);
      }
      _activeDownloads[item.id] = DownloadProgress(
        itemId: item.id,
        fileName: item.name,
        error: friendlyError,
      );
      await _offlineRepo.updateDownloadStatus(item.id, 3, error: friendlyError);
      await _notificationService.showError(
        itemName: item.name,
        error: friendlyError,
      );
      unawaited(_logger.logFailed(item, quality, friendlyError, telemetry: {
        'endpointType': selectedEndpointType,
        'networkPath': networkPath,
        'terminalReason': 'timeout',
        'validationReasonCode': 'timeout',
      }));
      unawaited(_logger.uploadToServer(_client));
    } catch (e) {
      if (savePath != null) {
        await _deleteFileArtifacts(savePath);
      }
      _activeDownloads[item.id] = DownloadProgress(
        itemId: item.id,
        fileName: item.name,
        error: e.toString(),
      );
      await _offlineRepo.updateDownloadStatus(item.id, 3, error: e.toString());
      await _notificationService.showError(
        itemName: item.name,
        error: e.toString(),
      );
      final reasonCode = _validationReasonCodeFromError(e);
      unawaited(_logger.logFailed(item, quality, e.toString(), telemetry: {
        'endpointType': selectedEndpointType,
        'networkPath': networkPath,
        'terminalReason': 'failed',
        'validationReasonCode': reasonCode,
      }));
      unawaited(_logger.uploadToServer(_client));
    } finally {
      _downloadStartTimes.remove(item.id);
      _cancelTokens.remove(item.id);
      notifyListeners();
    }
  }

  Future<void> downloadItems(List<AggregatedItem> items, {DownloadQuality quality = DownloadQuality.original}) async {
    _cancelAllRequested = false;
    _totalQueued = items.length;
    _completedCount = 0;
    notifyListeners();

    final batchStart = DateTime.now();
    unawaited(_logger.logBatchStarted(items.length, quality));

    final concurrency = _concurrencyLimit();
    final queue = List<AggregatedItem>.from(items);
    final futures = <Future<void>>[];

    Future<void> processNext() async {
      while (!_cancelAllRequested && queue.isNotEmpty) {
        final item = queue.removeAt(0);
        await downloadItem(item, quality: quality);
      }
    }

    for (var i = 0; i < concurrency; i++) {
      futures.add(processNext());
    }
    await Future.wait(futures);

    if (!_cancelAllRequested) {
      unawaited(_logger.logBatchComplete(
        _completedCount,
        items.length,
        DateTime.now().difference(batchStart),
      ));
      unawaited(_logger.uploadToServer(_client));
    }

    _totalQueued = 0;
    _completedCount = 0;
    await _notificationService.dismiss();
    notifyListeners();
  }

  Future<List<AggregatedItem>> _getAllEpisodesForSeries(String seriesId) async {
    final seasonsData = await _client.itemsApi.getSeasons(seriesId);
    final seasons = (seasonsData['Items'] as List?) ?? [];
    final allEpisodes = <AggregatedItem>[];
    for (final season in seasons) {
      final seasonId = season['Id'] as String;
      final episodesData = await _client.itemsApi.getEpisodes(seriesId, seasonId: seasonId);
      final episodes = (episodesData['Items'] as List?) ?? [];
      for (final raw in episodes) {
        final ep = raw as Map<String, dynamic>;
        allEpisodes.add(AggregatedItem(
          id: ep['Id'] as String,
          serverId: _client.baseUrl,
          rawData: ep,
        ));
      }
    }
    return allEpisodes;
  }

  Future<void> downloadSeries(String seriesId, {DownloadQuality quality = DownloadQuality.original}) async {
    final episodes = await _getAllEpisodesForSeries(seriesId);
    await downloadItems(episodes, quality: quality);
  }

  Future<bool> deleteDownloadedItems(List<AggregatedItem> items) async {
    var allSucceeded = true;
    final seenIds = <String>{};

    for (final item in items) {
      if (!seenIds.add(item.id)) {
        continue;
      }

      final succeeded = await deleteDownloadedFiles(item);
      if (!succeeded) {
        allSucceeded = false;
      }
    }

    return allSucceeded;
  }

  Future<bool> deleteDownloadedFiles(AggregatedItem item) async {
    try {
      final downloadsDir = await _storagePath.getOfflineRoot();
      final subFolder = _buildSubFolder(item);
      final targetDir = Directory('${downloadsDir.path}/$subFolder');
      final imageDir = await _storagePath.getImageCacheDir();

      switch (item.type) {
        case 'Movie':
          if (await targetDir.exists()) await targetDir.delete(recursive: true);
          await _deleteItemImages(item.id, imageDir);
          await _offlineRepo.deleteItem(item.id);
          return true;

        case 'Episode':
          await _deleteCandidateFileArtifacts(targetDir, item, downloadsDir);
          await _deleteItemImages(item.id, imageDir);
          await _offlineRepo.deleteItem(item.id);
          await _cleanupEpisodeContainers(item, imageDir);
          return true;

        case 'Audio':
        case 'AudioBook':
        case 'Book':
          await _deleteCandidateFileArtifacts(targetDir, item, downloadsDir);
          await _deleteItemImages(item.id, imageDir);
          await _offlineRepo.deleteItem(item.id);
          return true;

        case 'Season':
          final seasonImageIds = await _relatedImageIds(item);
          if (await targetDir.exists()) {
            await targetDir.delete(recursive: true);
            final seriesDir = targetDir.parent;
            if (await seriesDir.exists()) {
              final remaining = await seriesDir.list().length;
              if (remaining == 0) await seriesDir.delete();
            }
          }
          await _deleteImagesForIds(seasonImageIds, imageDir);
          await _offlineRepo.deleteSeasonItems(item.id);
          return true;

        case 'Series':
          final seriesImageIds = await _relatedImageIds(item);
          final seriesName = _sanitizePath(item.seriesName ?? item.name);
          final seriesDir = Directory('${downloadsDir.path}/TV/$seriesName');
          if (await seriesDir.exists()) await seriesDir.delete(recursive: true);
          await _deleteImagesForIds(seriesImageIds, imageDir);
          await _offlineRepo.deleteSeriesItems(item.id);
          return true;

        default:
          final defaultDir = Directory('${downloadsDir.path}/Other/${_sanitizePath(item.name)}');
          if (await defaultDir.exists()) await defaultDir.delete(recursive: true);
          await _deleteItemImages(item.id, imageDir);
          await _offlineRepo.deleteItem(item.id);
          return true;
      }
    } catch (_) {
      return false;
    }
  }

  Future<void> _deleteItemImages(String itemId, Directory imageDir) async {
    final dir = Directory('${imageDir.path}/$itemId');
    if (await dir.exists()) await dir.delete(recursive: true);
  }

  Future<bool> hasDownloadedFiles(AggregatedItem item) async {
    return _offlineRepo.isAvailableOffline(item.id);
  }

  Future<void> _downloadLyrics(AggregatedItem item) async {
    try {
      final data = await _client.itemsApi.getLyrics(item.id);
      final lyrics = data['Lyrics'] as List?;
      if (lyrics == null || lyrics.isEmpty) return;
      final imageDir = await _storagePath.getImageCacheDir();
      final itemDir = Directory('${imageDir.path}/${item.id}');
      if (!await itemDir.exists()) await itemDir.create(recursive: true);
      await File('${itemDir.path}/lyrics.json').writeAsString(jsonEncode(data));
    } catch (_) {}
  }

  Future<void> _downloadImages(AggregatedItem item) async {
    try {
      final imageDir = await _storagePath.getImageCacheDir();
      final itemDir = Directory('${imageDir.path}/${item.id}');
      if (!await itemDir.exists()) await itemDir.create(recursive: true);

      final authOptions = Options(headers: _buildAuthHeaders());
      String? posterPath, backdropPath, logoPath;

      if (item.primaryImageTag != null) {
        final url = _client.imageApi.getPrimaryImageUrl(item.id, maxHeight: 500, tag: item.primaryImageTag);
        posterPath = '${itemDir.path}/poster.jpg';
        try {
          await _downloadDio.download(url, posterPath, options: authOptions);
        } catch (_) {
          posterPath = null;
        }
      }

      if (item.backdropImageTags.isNotEmpty) {
        final url = _client.imageApi.getBackdropImageUrl(item.id, maxWidth: 1920, tag: item.backdropImageTags.first);
        backdropPath = '${itemDir.path}/backdrop.jpg';
        try {
          await _downloadDio.download(url, backdropPath, options: authOptions);
        } catch (_) {
          backdropPath = null;
        }
      } else if (item.parentBackdropItemId != null && item.parentBackdropImageTags.isNotEmpty) {
        final url = _client.imageApi.getBackdropImageUrl(
          item.parentBackdropItemId!,
          maxWidth: 1920,
          tag: item.parentBackdropImageTags.first,
        );
        backdropPath = '${itemDir.path}/backdrop.jpg';
        try {
          await _downloadDio.download(url, backdropPath, options: authOptions);
        } catch (_) {
          backdropPath = null;
        }
      }

      if (item.logoImageTag != null) {
        final url = _client.imageApi.getLogoImageUrl(item.id, maxWidth: 500, tag: item.logoImageTag);
        logoPath = '${itemDir.path}/logo.png';
        try {
          await _downloadDio.download(url, logoPath, options: authOptions);
        } catch (_) {
          logoPath = null;
        }
      }

      await _offlineRepo.setImagePaths(
        item.id,
        poster: posterPath,
        backdrop: backdropPath,
        logo: logoPath,
      );
    } catch (_) {}
  }

  Future<void> _ensureParentContainers(AggregatedItem episode) async {
    if (episode.type != 'Episode') return;

    if (episode.seriesId != null) {
      final existing = await _offlineRepo.getItem(episode.seriesId!);
      if (existing == null) {
        try {
          final seriesData = await _client.itemsApi.getItem(episode.seriesId!);
          final seriesItem = AggregatedItem(id: episode.seriesId!, serverId: episode.serverId, rawData: seriesData);
          await _offlineRepo.upsertItem(DownloadedItemsCompanion(
            itemId: Value(episode.seriesId!),
            serverId: Value(episode.serverId),
            type: const Value('Series'),
            name: Value(seriesItem.name),
            metadataJson: Value(jsonEncode(seriesData)),
            downloadStatus: const Value(2),
            seriesName: Value(seriesItem.name),
          ));
          _downloadImages(seriesItem);
        } catch (_) {}
      }
    }

    if (episode.seasonId != null) {
      final existing = await _offlineRepo.getItem(episode.seasonId!);
      if (existing == null) {
        try {
          final seasonData = await _client.itemsApi.getItem(episode.seasonId!);
          final seasonItem = AggregatedItem(id: episode.seasonId!, serverId: episode.serverId, rawData: seasonData);
          await _offlineRepo.upsertItem(DownloadedItemsCompanion(
            itemId: Value(episode.seasonId!),
            serverId: Value(episode.serverId),
            type: const Value('Season'),
            name: Value(seasonItem.name),
            metadataJson: Value(jsonEncode(seasonData)),
            downloadStatus: const Value(2),
            seriesId: Value(episode.seriesId),
            seriesName: Value(episode.seriesName),
            seasonName: Value(seasonItem.name),
          ));
          _downloadImages(seasonItem);
        } catch (_) {}
      }
    }
  }

  Future<void> _downloadExternalSubtitles(AggregatedItem item, Directory dir, String fileNameBase) async {
    final mediaSources = item.mediaSources;
    if (mediaSources.isEmpty) return;
    final authOptions = Options(headers: _buildAuthHeaders());
    final streams = (mediaSources.first['MediaStreams'] as List?) ?? [];
    for (final stream in streams) {
      if (stream is! Map<String, dynamic>) continue;
      if (stream['Type'] != 'Subtitle') continue;
      final deliveryUrl = stream['DeliveryUrl'] as String?;
      if (deliveryUrl == null || deliveryUrl.isEmpty) continue;
      final isExternal = stream['IsExternal'] == true;
      final supportsExternal = stream['SupportsExternalStream'] == true;
      if (!isExternal && !supportsExternal) continue;
      final codec = (stream['Codec'] as String?) ?? 'srt';
      final index = stream['Index'] as int? ?? 0;
      final subPath = '${dir.path}/${fileNameBase}_sub_$index.$codec';
      final subUrl = '${_client.baseUrl}$deliveryUrl';
      try {
        await _downloadDio.download(subUrl, subPath, options: authOptions);
      } catch (_) {}
    }
  }

  void cancelDownload(String itemId) {
    _cancelTokens[itemId]?.cancel();
  }

  void cancelAll() {
    _cancelAllRequested = true;
    for (final token in _cancelTokens.values) {
      token.cancel();
    }
    _cancelTokens.clear();
    _totalQueued = 0;
    _completedCount = 0;
    _notificationService.dismiss();
    notifyListeners();
  }

  Future<void> clearAllDownloads() async {
    cancelAll();

    final allItems = await _offlineRepo.getItems();
    for (final item in allItems) {
      final path = item.localFilePath;
      if (path == null || path.isEmpty) {
        continue;
      }

      try {
        final f = File(path);
        if (await f.exists()) {
          await f.delete();
        }
      } catch (_) {}
    }

    final offlineRoot = await _storagePath.getOfflineRoot();
    const managedFolders = [
      'Movies',
      'TV',
      'Music',
      'Audiobooks',
      'Books',
      'Other',
      'images',
    ];

    for (final folder in managedFolders) {
      final dir = Directory('${offlineRoot.path}/$folder');
      try {
        if (await dir.exists()) {
          await dir.delete(recursive: true);
        }
      } catch (_) {}
    }

    await _offlineRepo.deleteAllItems();
    _activeDownloads.clear();
    _cancelTokens.clear();
    _downloadStartTimes.clear();
    _totalQueued = 0;
    _completedCount = 0;
    await _notificationService.dismiss();
    notifyListeners();
  }

  Future<void> recoverIncompleteDownloads() async {
    final allItems = await _offlineRepo.getItems();

    for (final item in allItems) {
      if (item.downloadStatus == 1) {
        if (item.localFilePath != null) {
          final file = File(item.localFilePath!);
          if (await file.exists()) await file.delete();
        }
        if (item.metadataJson.isNotEmpty) {
          final qualityName = item.qualityPreset;
          final quality = DownloadQuality.values.firstWhere(
            (q) => q.name == qualityName,
            orElse: () => DownloadQuality.original,
          );
          final isStatic = !quality.isTranscoded;
          if (isStatic) {
            await _offlineRepo.updateDownloadStatus(item.itemId, 0);
            unawaited(_logger.logRecovered(
              item.itemId,
              item.name,
              'Re-queued for download (static / resumable)',
            ));
          } else {
            await _offlineRepo.updateDownloadStatus(
              item.itemId, 3,
              error: 'Interrupted. Transcoded downloads cannot be resumed.',
            );
            unawaited(_logger.logRecovered(
              item.itemId,
              item.name,
              'Marked FAILED — transcoded download interrupted and cannot resume',
            ));
          }
        } else {
          await _offlineRepo.updateDownloadStatus(item.itemId, 3, error: 'Interrupted');
          unawaited(_logger.logRecovered(
            item.itemId,
            item.name,
            'Marked FAILED — no metadata, interrupted',
          ));
        }
      } else if (item.downloadStatus == 2) {
        if (item.localFilePath != null) {
          final file = File(item.localFilePath!);
          if (!await file.exists()) {
            await _offlineRepo.updateDownloadStatus(
              item.itemId, 3,
              error: 'File missing from disk',
            );
            unawaited(_logger.logRecovered(
              item.itemId,
              item.name,
              'Marked FAILED — file missing from disk (was status=complete in DB)',
            ));
          }
        }
      }
    }
  }

  @override
  void dispose() {
    cancelAll();
    _downloadDio.close();
    super.dispose();
  }
}
