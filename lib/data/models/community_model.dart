import '../../domain/entities/community_entity.dart';

class CommunityModel extends CommunityEntity {
  CommunityModel({
    required super.id,
    required super.name,
    required super.description,
    required super.icon,
    super.unreadCount = 0,
    super.groupIds = const [],
    super.adminIds = const [],
    super.memberCount = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'icon': icon,
      'unreadCount': unreadCount,
      'groupIds': groupIds,
      'adminIds': adminIds,
      'memberCount': memberCount,
    };
  }

  factory CommunityModel.fromMap(Map<String, dynamic> map, String id) {
    return CommunityModel(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      icon: map['icon'] ?? 'groups',
      unreadCount: map['unreadCount'] ?? 0,
      groupIds: List<String>.from(map['groupIds'] ?? []),
      adminIds: List<String>.from(map['adminIds'] ?? []),
      memberCount: map['memberCount'] ?? 0,
    );
  }
}
