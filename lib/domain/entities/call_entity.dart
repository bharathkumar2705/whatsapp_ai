class CallEntity {
  final String id;
  final String callerId;
  final String callerName;
  final String? callerImage;
  final String receiverId;
  final String receiverName;
  final String? receiverImage;
  final DateTime timestamp;
  final String type; // 'voice' or 'video'
  final String status; // 'missed', 'incoming', 'outgoing'
  final List<String> participants;
  final bool isGroupCall;
  final int durationSeconds;

  CallEntity({
    required this.id,
    required this.callerId,
    required this.callerName,
    this.callerImage,
    required this.receiverId,
    required this.receiverName,
    this.receiverImage,
    required this.timestamp,
    required this.type,
    required this.status,
    this.participants = const [],
    this.isGroupCall = false,
    this.durationSeconds = 0,
  });
}
