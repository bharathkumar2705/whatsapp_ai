import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/chat_entity.dart';

class ChatModel extends ChatEntity {
  ChatModel({
    required super.id,
    required super.participants,
    super.lastMessage = '',
    required super.lastMessageTime,
    super.unreadCount = const {},
    super.isGroup = false,
    super.groupName,
    super.groupImage,
    super.admins = const [],
    required super.isArchived,
    super.isFavorite = false,
    super.isPinned = false,
    super.isCommunity = false,
    super.disappearingEnabled = false,
    super.disappearingDuration = 0,
    super.isLocked = false,
    super.adminOnly = false,
    super.approvalRequired = false,
    super.joinRequests = const [],
    super.inviteLink,
    super.communityId,
    super.labels = const [],
    super.deletedFor = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'participants': participants,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime.millisecondsSinceEpoch,
      'unreadCount': unreadCount,
      'isGroup': isGroup,
      'groupName': groupName,
      'groupImage': groupImage,
      'admins': admins,
      'isArchived': isArchived,
      'isFavorite': isFavorite,
      'isPinned': isPinned,
      'isCommunity': isCommunity,
      'disappearingEnabled': disappearingEnabled,
      'disappearingDuration': disappearingDuration,
      'isLocked': isLocked,
      'adminOnly': adminOnly,
      'approvalRequired': approvalRequired,
      'joinRequests': joinRequests,
      'inviteLink': inviteLink,
      'communityId': communityId,
      'labels': labels,
      'deletedFor': deletedFor,
    };
  }

  factory ChatModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime lastMessageTime;
    final lmt = map['lastMessageTime'];
    if (lmt is int) {
      lastMessageTime = DateTime.fromMillisecondsSinceEpoch(lmt);
    } else if (lmt is Timestamp) {
      lastMessageTime = lmt.toDate();
    } else {
      lastMessageTime = DateTime.fromMillisecondsSinceEpoch(0);
    }

    return ChatModel(
      id: id,
      participants: List<String>.from(map['participants'] ?? []),
      lastMessage: map['lastMessage'] ?? '',
      lastMessageTime: lastMessageTime,
      unreadCount: Map<String, int>.from(map['unreadCount'] ?? {}),
      isGroup: map['isGroup'] ?? false,
      groupName: map['groupName'],
      groupImage: map['groupImage'],
      admins: List<String>.from(map['admins'] ?? []),
      isArchived: map['isArchived'] ?? false,
      isFavorite: map['isFavorite'] ?? false,
      isPinned: map['isPinned'] ?? false,
      isCommunity: map['isCommunity'] ?? false,
      disappearingEnabled: map['disappearingEnabled'] ?? false,
      disappearingDuration: map['disappearingDuration'] ?? 0,
      isLocked: map['isLocked'] ?? false,
      adminOnly: map['adminOnly'] ?? false,
      approvalRequired: map['approvalRequired'] ?? false,
      joinRequests: List<String>.from(map['joinRequests'] ?? []),
      inviteLink: map['inviteLink'],
      communityId: map['communityId'],
      labels: List<String>.from(map['labels'] ?? []),
      deletedFor: List<String>.from(map['deletedFor'] ?? []),
    );
  }
}
