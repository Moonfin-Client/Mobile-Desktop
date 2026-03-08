class User {
  final String id;
  final String name;
  final String serverId;
  final String? primaryImageTag;

  const User({
    required this.id,
    required this.name,
    required this.serverId,
    this.primaryImageTag,
  });
}
