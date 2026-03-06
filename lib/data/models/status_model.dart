import '../../domain/entities/status_entity.dart';

class StatusModel extends StatusEntity {
  StatusModel({
    required super.id,
    required super.userId,
    required super.userName,
    super.userImageUrl,
    required super.contentUrl,
    required super.type,
    required super.timestamp,
    super.viewers = const [],
    super.privacyType = 'contacts',
    super.privacyUidList = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userImageUrl': userImageUrl,
      'contentUrl': contentUrl,
      'type': type,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'viewers': viewers,
      'privacyType': privacyType,
      'privacyUidList': privacyUidList,
    };
  }

  factory StatusModel.fromMap(Map<String, dynamic> map, String id) {
    return StatusModel(
      id: id,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userImageUrl: map['userImageUrl'],
      contentUrl: map['contentUrl'] ?? '',
      type: map['type'] ?? 'image',
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? 0),
      viewers: List<String>.from(map['viewers'] ?? []),
      privacyType: map['privacyType'] ?? 'contacts',
      privacyUidList: List<String>.from(map['privacyUidList'] ?? []),
    );
  }
}
