class ChatEntity {
  final String id;
  final List<String> participants;
  final String lastMessage;
  final DateTime lastMessageTime;
  final Map<String, int> unreadCount;
  final bool isGroup;
  final String? groupName;
  final String? groupImage;
  final List<String> admins;

  final bool isArchived;
  final bool isFavorite;
  final bool isPinned;
  final bool isCommunity;
  final bool disappearingEnabled;
  final int disappearingDuration;
  final bool isLocked;
  final bool adminOnly;
  final bool approvalRequired;
  final List<String> joinRequests;
  final String? inviteLink;
  final String? communityId;
  final List<String> labels;
  final List<String> deletedFor;

  ChatEntity({
    required this.id,
    required this.participants,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.unreadCount,
    this.isGroup = false,
    this.groupName,
    this.groupImage,
    this.admins = const [],
    this.isArchived = false,
    this.isFavorite = false,
    this.isPinned = false,
    this.isCommunity = false,
    this.disappearingEnabled = false,
    this.disappearingDuration = 0,
    this.isLocked = false,
    this.adminOnly = false,
    this.approvalRequired = false,
    this.joinRequests = const [],
    this.inviteLink,
    this.communityId,
    this.labels = const [],
    this.deletedFor = const [],
  });
}
