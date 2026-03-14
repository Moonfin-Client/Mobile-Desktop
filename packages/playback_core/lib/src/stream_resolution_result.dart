enum StreamPlayMethod { directPlay, directStream, transcode }

class ExternalSubtitle {
  final String deliveryUrl;
  final String? title;
  final String? language;
  final String codec;
  final bool isDefault;
  final bool isForced;
  final int? streamIndex;

  const ExternalSubtitle({
    required this.deliveryUrl,
    this.title,
    this.language,
    required this.codec,
    this.isDefault = false,
    this.isForced = false,
    this.streamIndex,
  });
}

class StreamResolutionResult {
  final String streamUrl;
  final String mediaSourceId;
  final String? playSessionId;
  final StreamPlayMethod playMethod;
  final List<ExternalSubtitle> externalSubtitles;
  final List<Map<String, dynamic>> mediaStreams;

  const StreamResolutionResult({
    required this.streamUrl,
    required this.mediaSourceId,
    this.playSessionId,
    required this.playMethod,
    this.externalSubtitles = const [],
    this.mediaStreams = const [],
  });
}
