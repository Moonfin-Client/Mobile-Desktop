abstract class InstantMixApi {
  Future<Map<String, dynamic>> getInstantMix(
    String itemId, {
    int? limit,
  });
}
