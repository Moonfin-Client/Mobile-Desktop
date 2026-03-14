import 'package:dio/dio.dart';
import 'package:server_core/server_core.dart';

class EmbyPlaybackApi implements PlaybackApi {
  final Dio _dio;
  final String Function() _getBaseUrl;

  EmbyPlaybackApi(this._dio, this._getBaseUrl);

  @override
  Future<void> reportPlaybackStart(Map<String, dynamic> info) async {
    await _dio.post('/Sessions/Playing', data: info);
  }

  @override
  Future<void> reportPlaybackProgress(Map<String, dynamic> info) async {
    await _dio.post('/Sessions/Playing/Progress', data: info);
  }

  @override
  Future<void> reportPlaybackStopped(Map<String, dynamic> info) async {
    await _dio.post('/Sessions/Playing/Stopped', data: info);
  }

  @override
  Future<Map<String, dynamic>> getPlaybackInfo(
    String itemId, {
    Map<String, dynamic>? requestBody,
    String? userId,
  }) async {
    final response = await _dio.post(
      '/Items/$itemId/PlaybackInfo',
      data: requestBody,
      queryParameters: {
        if (userId != null) 'userId': userId,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  @override
  String getStreamUrl(
    String itemId, {
    String? mediaSourceId,
    String? audioStreamIndex,
    String? subtitleStreamIndex,
  }) {
    final params = <String, String>{
      if (mediaSourceId != null) 'MediaSourceId': mediaSourceId,
      if (audioStreamIndex != null) 'AudioStreamIndex': audioStreamIndex,
      if (subtitleStreamIndex != null)
        'SubtitleStreamIndex': subtitleStreamIndex,
      'Static': 'true',
    };
    final uri = Uri.parse('${_getBaseUrl()}/Videos/$itemId/stream')
        .replace(queryParameters: params);
    return uri.toString();
  }
}
