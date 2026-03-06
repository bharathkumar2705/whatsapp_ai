import '../../domain/entities/call_entity.dart';

class CallModel extends CallEntity {
  CallModel({
    required super.id,
    required super.callerId,
    required super.callerName,
    super.callerImage,
    required super.receiverId,
    required super.receiverName,
    super.receiverImage,
    required super.timestamp,
    required super.type,
    required super.status,
    super.participants = const [],
    super.isGroupCall = false,
    super.durationSeconds = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'callerId': callerId,
      'callerName': callerName,
      'callerImage': callerImage,
      'receiverId': receiverId,
      'receiverName': receiverName,
      'receiverImage': receiverImage,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'type': type,
      'status': status,
      'participants': participants,
      'isGroupCall': isGroupCall,
      'durationSeconds': durationSeconds,
    };
  }

  factory CallModel.fromMap(Map<String, dynamic> map, String id) {
    return CallModel(
      id: id,
      callerId: map['callerId'] ?? '',
      callerName: map['callerName'] ?? '',
      callerImage: map['callerImage'],
      receiverId: map['receiverId'] ?? '',
      receiverName: map['receiverName'] ?? '',
      receiverImage: map['receiverImage'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? 0),
      type: map['type'] ?? 'voice',
      status: map['status'] ?? 'missed',
      participants: List<String>.from(map['participants'] ?? []),
      isGroupCall: map['isGroupCall'] ?? false,
      durationSeconds: map['durationSeconds'] ?? 0,
    );
  }
}
