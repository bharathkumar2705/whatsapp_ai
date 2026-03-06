import '../../domain/entities/quick_reply.dart';

class QuickReplyModel extends QuickReply {
  QuickReplyModel({
    required super.id,
    required super.shortcut,
    required super.message,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'shortcut': shortcut,
      'message': message,
    };
  }

  factory QuickReplyModel.fromMap(Map<String, dynamic> map, String id) {
    return QuickReplyModel(
      id: id,
      shortcut: map['shortcut'] ?? '',
      message: map['message'] ?? '',
    );
  }
}
