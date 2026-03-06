class BroadcastEntity {
  final String id;
  final String name;
  final int recipientCount;
  final DateTime lastActive;

  BroadcastEntity({
    required this.id,
    required this.name,
    required this.recipientCount,
    required this.lastActive,
  });
}
