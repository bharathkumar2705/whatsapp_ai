class MessageEntity {
  final String id;
  final String chatId;
  final String senderId;
  final String receiverId;
  final String text;
  final String type;
  final String mediaUrl;
  final DateTime timestamp;
  final String status;
  final List<String> reactions;
  final List<String> seenBy;
  final String? replyToId;
  final String? replyText;
  final bool isStarred;
  final double? latitude;
  final double? longitude;
  final List<String>? pollOptions;
  final Map<String, dynamic>? eventData;
  final Map<String, dynamic>? contactData;
  final bool isForwarded;
  final bool isViewOnce;
  final bool isEdited;
  final bool isHd;
  final Map<String, dynamic>? pluginData;

  MessageEntity({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.type,
    required this.mediaUrl,
    required this.timestamp,
    required this.status,
    this.reactions = const [],
    this.seenBy = const [],
    this.replyToId,
    this.replyText,
    this.isStarred = false,
    this.latitude,
    this.longitude,
    this.pollOptions,
    this.eventData,
    this.contactData,
    this.isForwarded = false,
    this.isViewOnce = false,
    this.isEdited = false,
    this.isHd = false,
    this.pluginData,
  });
}
