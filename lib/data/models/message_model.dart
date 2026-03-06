import '../../domain/entities/message_entity.dart';
import '../services/encryption_service.dart';

class MessageModel extends MessageEntity {
  MessageModel({
    required super.id,
    required super.chatId,
    required super.senderId,
    required super.receiverId,
    required super.text,
    super.type = 'text',
    super.mediaUrl = '',
    required super.timestamp,
    super.status = 'sent',
    super.reactions = const [],
    super.seenBy = const [],
    super.replyToId,
    super.replyText,
    super.isStarred = false,
    super.latitude,
    super.longitude,
    super.pollOptions,
    super.eventData,
    super.contactData,
    super.isForwarded = false,
    super.isViewOnce = false,
    super.isEdited = false,
    super.isHd = false,
    super.pluginData,
  });

  Map<String, dynamic> toMap() {
    return {
      'chatId': chatId,
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'type': type,
      'mediaUrl': mediaUrl,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'status': status,
      'reactions': reactions,
      'seenBy': seenBy,
      'replyToId': replyToId,
      'replyText': replyText,
      'isStarred': isStarred,
      'latitude': latitude,
      'longitude': longitude,
      'pollOptions': pollOptions,
      'eventData': eventData,
      'contactData': contactData,
      'isForwarded': isForwarded,
      'isViewOnce': isViewOnce,
      'isEdited': isEdited,
      'isHd': isHd,
      'pluginData': pluginData,
    };
  }

  factory MessageModel.fromMap(Map<String, dynamic> map, String id) {
    return MessageModel(
      id: id,
      chatId: map['chatId'] ?? '',
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      text: EncryptionService.decryptMessage(map['text'] ?? ''),
      type: map['type'] ?? 'text',
      mediaUrl: map['mediaUrl'] ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? 0),
      status: map['status'] ?? 'sent',
      reactions: List<String>.from(map['reactions'] ?? []),
      seenBy: List<String>.from(map['seenBy'] ?? []),
      replyToId: map['replyToId'],
      replyText: map['replyText'],
      isStarred: map['isStarred'] ?? false,
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
      pollOptions: map['pollOptions'] != null ? List<String>.from(map['pollOptions']) : null,
      eventData: map['eventData'] != null ? Map<String, dynamic>.from(map['eventData']) : null,
      contactData: map['contactData'] != null ? Map<String, dynamic>.from(map['contactData']) : null,
      isForwarded: map['isForwarded'] ?? false,
      isViewOnce: map['isViewOnce'] ?? false,
      isEdited: map['isEdited'] ?? false,
      isHd: map['isHd'] ?? false,
      pluginData: map['pluginData'] != null ? Map<String, dynamic>.from(map['pluginData']) : null,
    );
  }
}
