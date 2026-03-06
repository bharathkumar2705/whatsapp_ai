class CommunityEntity {
  final String id;
  final String name;
  final String description;
  final String icon;
  final int unreadCount;
  final List<String> groupIds;
  final List<String> adminIds;
  final int memberCount;

  CommunityEntity({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    this.unreadCount = 0,
    this.groupIds = const [],
    this.adminIds = const [],
    this.memberCount = 0,
  });
}
