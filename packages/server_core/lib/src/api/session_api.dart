abstract class SessionApi {
  Future<void> reportCapabilities(Map<String, dynamic> capabilities);
  Future<List<Map<String, dynamic>>> getSessions({String? controllableByUserId});

  Future<void> sendPlayCommand(
    String sessionId, {
    required String playCommand,
    required List<String> itemIds,
    int? startPositionTicks,
    String? mediaSourceId,
    int? audioStreamIndex,
    int? subtitleStreamIndex,
    int? startIndex,
  });

  Future<void> sendPlayStateCommand(
    String sessionId,
    String command, {
    int? seekPositionTicks,
  });

  Future<void> sendMessage(
    String sessionId,
    String text, {
    String? header,
    int? timeoutMs,
  });

  Future<void> sendGeneralCommand(
    String sessionId,
    String commandName, {
    Map<String, String>? arguments,
  });
}
