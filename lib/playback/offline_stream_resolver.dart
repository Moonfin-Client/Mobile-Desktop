import 'dart:convert';
import 'dart:io';

import '../data/repositories/offline_repository.dart';

class OfflineStreamResult {
  final String url;
  final List<Map<String, dynamic>> mediaStreams;
  final String itemId;
  final String serverId;
  final Duration duration;
  final List<OfflineSubtitle> externalSubtitles;

  const OfflineStreamResult({
    required this.url,
    required this.mediaStreams,
    required this.itemId,
    required this.serverId,
    required this.duration,
    this.externalSubtitles = const [],
  });
}

class OfflineSubtitle {
  final String path;
  final String? title;
  final String? language;
  final int index;

  const OfflineSubtitle({
    required this.path,
    this.title,
    this.language,
    required this.index,
  });
}

class OfflineStreamResolver {
  final OfflineRepository _offlineRepo;

  OfflineStreamResolver(this._offlineRepo);

  Future<OfflineStreamResult?> resolve(String itemId, String serverId) async {
    final item = await _offlineRepo.getItem(itemId, serverId);
    if (item == null || item.downloadStatus != 2 || item.localFilePath == null) {
      return null;
    }

    final file = File(item.localFilePath!);
    if (!await file.exists()) {
      await _offlineRepo.updateDownloadStatus(itemId, serverId, 3, error: 'File not found');
      return null;
    }

    final metadata = jsonDecode(item.metadataJson) as Map<String, dynamic>;
    final rawStreams = (metadata['MediaStreams'] as List?) ?? [];
    final mediaStreams = rawStreams.cast<Map<String, dynamic>>();

    final runTimeTicks = metadata['RunTimeTicks'] as int? ?? 0;
    final duration = Duration(microseconds: runTimeTicks ~/ 10);

    final parentDir = file.parent;
    final fileNameBase = file.uri.pathSegments.last.replaceAll(RegExp(r'\.[^.]+$'), '');
    final externalSubs = <OfflineSubtitle>[];
    for (final stream in mediaStreams) {
      if (stream['Type'] != 'Subtitle') continue;
      final deliveryUrl = stream['DeliveryUrl'] as String?;
      if (deliveryUrl == null || deliveryUrl.isEmpty) continue;
      final isExternal = stream['IsExternal'] == true;
      final supportsExternal = stream['SupportsExternalStream'] == true;
      if (!isExternal && !supportsExternal) continue;
      final codec = (stream['Codec'] as String?) ?? 'srt';
      final index = stream['Index'] as int? ?? 0;
      final subFile = File('${parentDir.path}/${fileNameBase}_sub_$index.$codec');
      if (await subFile.exists()) {
        externalSubs.add(OfflineSubtitle(
          path: subFile.uri.toString(),
          title: stream['DisplayTitle'] as String? ?? stream['Title'] as String?,
          language: stream['Language'] as String?,
          index: index,
        ));
      }
    }

    return OfflineStreamResult(
      url: file.uri.toString(),
      mediaStreams: mediaStreams,
      itemId: itemId,
      serverId: serverId,
      duration: duration,
      externalSubtitles: externalSubs,
    );
  }
}
