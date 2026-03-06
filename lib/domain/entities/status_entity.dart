class StatusEntity {
  final String id;
  final String userId;
  final String userName;
  final String? userImageUrl;
  final String contentUrl;
  final String type; // 'image', 'text', 'video', 'voice'
  final DateTime timestamp;
  final List<String> viewers;
  final String privacyType; // 'contacts', 'except', 'only'
  final List<String> privacyUidList;

  StatusEntity({
    required this.id,
    required this.userId,
    required this.userName,
    this.userImageUrl,
    required this.contentUrl,
    required this.type,
    required this.timestamp,
    this.viewers = const [],
    this.privacyType = 'contacts',
    this.privacyUidList = const [],
  });
}
