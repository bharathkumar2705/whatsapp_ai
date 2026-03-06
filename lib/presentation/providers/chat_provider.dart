import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/repositories/chat_repository.dart';
import '../../data/repositories/storage_repository.dart';
import '../../domain/usecases/get_my_chats_usecase.dart';
import '../../domain/usecases/send_message_usecase.dart';
import '../../domain/usecases/upload_media_usecase.dart';
import '../../domain/entities/chat_entity.dart';
import '../../domain/entities/message_entity.dart';
import '../../domain/entities/community_entity.dart';
import '../../domain/entities/broadcast_entity.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../data/services/streak_service.dart';

class ChatProvider extends ChangeNotifier {
  final ChatRepository _chatRepository = ChatRepository();
  final StorageRepository _storageRepository = StorageRepository();
  final StreakService _streakService = StreakService();
  late final GetMyChatsUseCase _getMyChatsUseCase;
  late final SendMessageUseCase _sendMessageUseCase;
  late final UploadMediaUseCase _uploadMediaUseCase;
  
  List<ChatEntity> _chats = [];
  bool _isLoading = false;

  List<ChatEntity> get chats => _chats;
  bool get isLoading => _isLoading;

  ChatProvider() {
    _getMyChatsUseCase = GetMyChatsUseCase(_chatRepository);
    _sendMessageUseCase = SendMessageUseCase(_chatRepository);
    _uploadMediaUseCase = UploadMediaUseCase(_storageRepository);
  }

  StreamSubscription? _chatSubscription;
  String? _currentUid;

  @override
  void dispose() {
    _chatSubscription?.cancel();
    super.dispose();
  }

  void listenToChats(String uid) {
    if (_chatSubscription != null && _currentUid == uid) return; // already listening to this user
    
    _chatSubscription?.cancel();
    _currentUid = uid;
    _isLoading = true;
    notifyListeners();
    _chatSubscription = _getMyChatsUseCase(uid).listen(
      (chats) {
        _chats = chats.where((c) => !c.deletedFor.contains(uid)).toList();
        _isLoading = false;
        notifyListeners();
      },
      onError: (e) {
        debugPrint('ChatProvider stream error: $e');
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Stream<List<MessageEntity>> getMessages(String chatId) {
    return _chatRepository.getMessages(chatId);
  }

  Future<List<MessageEntity>> getMessagesOnce(String chatId) {
    return _chatRepository.getMessages(chatId).first;
  }

  Future<void> sendMessage(String chatId, String senderId, String receiverId, String text, {String? replyToId, String? replyText, Map<String, dynamic>? pluginData}) async {
    debugPrint("ChatProvider: sendMessage called for $chatId");
    final message = MessageEntity(
      id: '',
      chatId: chatId,
      senderId: senderId,
      receiverId: receiverId,
      text: text,
      type: pluginData != null ? 'plugin' : 'text',
      mediaUrl: '',
      timestamp: DateTime.now(),
      status: 'sent',
      replyToId: replyToId,
      replyText: replyText,
      pluginData: pluginData,
    );
    try {
      await _sendMessageUseCase(message);
      await _streakService.updateStreak(chatId, senderId);
      debugPrint("ChatProvider: sendMessage success");
    } catch (e) {
      debugPrint("ChatProvider Error in sendMessage: $e");
      rethrow;
    }
  }

  Future<void> sendMediaMessage(String chatId, String senderId, String receiverId, XFile file, String type, {bool isHd = false}) async {
    debugPrint("ChatProvider: sendMediaMessage called, type: $type, isHd: $isHd");
    try {
      final mediaUrl = await _uploadMediaUseCase(file, chatId);
      debugPrint("ChatProvider: Media uploaded, URL: $mediaUrl");
      
      String text = '📄 File';
      if (type == 'image') text = '📷 Photo';
      else if (type == 'video') text = '🎥 Video';
      else if (type == 'voice') text = '🎤 Voice message';
      else if (type == 'audio') text = '🎵 Audio';
      else if (type == 'file') text = '📄 Document';

      if (isHd) text += ' (HD)';

      final message = MessageEntity(
        id: '',
        chatId: chatId,
        senderId: senderId,
        receiverId: receiverId,
        text: text,
        type: type,
        mediaUrl: mediaUrl,
        timestamp: DateTime.now(),
        status: 'sent',
        isHd: isHd,
      );
      await _sendMessageUseCase(message);
      await _streakService.updateStreak(chatId, senderId);
      debugPrint("ChatProvider: Media message sent");
    } catch (e) {
      debugPrint("ChatProvider Error in sendMediaMessage: $e");
      rethrow;
    }
  }

  Future<void> sendDocumentMessage(String chatId, String senderId, String receiverId, XFile file, String fileName) async {
    debugPrint("ChatProvider: sendDocumentMessage called, file: $fileName");
    try {
      final mediaUrl = await _uploadMediaUseCase(file, chatId);
      debugPrint("ChatProvider: Document uploaded, URL: $mediaUrl");
      final message = MessageEntity(
        id: '',
        chatId: chatId,
        senderId: senderId,
        receiverId: receiverId,
        text: '📄 $fileName',
        type: 'file',
        mediaUrl: mediaUrl,
        timestamp: DateTime.now(),
        status: 'sent',
      );
      await _sendMessageUseCase(message);
      await _streakService.updateStreak(chatId, senderId);
      debugPrint("ChatProvider: Document message sent");
    } catch (e) {
      debugPrint("ChatProvider Error in sendDocumentMessage: $e");
      rethrow;
    }
  }

  Future<void> markAsSeen(String chatId, String messageId, String uid) async {
    await _chatRepository.markMessageAsSeen(chatId, messageId, uid);
  }

  Future<void> toggleReaction(String chatId, String messageId, String emoji, List<String> currentReactions) async {
    final reactions = List<String>.from(currentReactions);
    if (reactions.contains(emoji)) {
      reactions.remove(emoji);
    } else {
      reactions.add(emoji);
    }
    await _chatRepository.updateMessageReactions(chatId, messageId, reactions);
  }

  Future<String> startChat(String myUid, String otherUid) async {
    return await _chatRepository.createChat([myUid, otherUid]);
  }

  Future<String> createGroup(String name, List<String> participants, String creatorId) async {
    return await _chatRepository.createGroup(name, participants, creatorId);
  }

  Future<void> toggleStarMessage(String chatId, String messageId, bool isStarred) async {
    await _chatRepository.toggleStarMessage(chatId, messageId, isStarred);
  }

  Future<void> toggleArchiveChat(String chatId, bool isArchived) async {
    await _chatRepository.toggleArchiveChat(chatId, isArchived);
  }

  Future<void> sendLocationMessage(String chatId, String senderId, String receiverId, double latitude, double longitude) async {
    debugPrint("ChatProvider: sendLocationMessage called for $chatId");
    final message = MessageEntity(
      id: '',
      chatId: chatId,
      senderId: senderId,
      receiverId: receiverId,
      text: '📍 Location',
      type: 'location',
      mediaUrl: '',
      timestamp: DateTime.now(),
      status: 'sent',
      latitude: latitude,
      longitude: longitude,
    );
    try {
      await _sendMessageUseCase(message);
      debugPrint("ChatProvider: Location message sent");
    } catch (e) {
      debugPrint("ChatProvider Error in sendLocationMessage: $e");
      rethrow;
    }
  }

  Future<void> sendPollMessage(String chatId, String senderId, String receiverId, String question, List<String> options) async {
    final message = MessageEntity(
      id: '',
      chatId: chatId,
      senderId: senderId,
      receiverId: receiverId,
      text: '📊 Poll: $question',
      type: 'poll',
      mediaUrl: '',
      timestamp: DateTime.now(),
      status: 'sent',
      pollOptions: options,
    );
    await _sendMessageUseCase(message);
  }

  Future<void> sendEventMessage(String chatId, String senderId, String receiverId, String title, String description, DateTime date) async {
    final message = MessageEntity(
      id: '',
      chatId: chatId,
      senderId: senderId,
      receiverId: receiverId,
      text: '📅 Event: $title',
      type: 'event',
      mediaUrl: '',
      timestamp: DateTime.now(),
      status: 'sent',
      eventData: {
        'title': title,
        'description': description,
        'date': date.millisecondsSinceEpoch,
      },
    );
    await _sendMessageUseCase(message);
  }

  Future<void> sendContactMessage(String chatId, String senderId, String receiverId, String name, String phone) async {
    final message = MessageEntity(
      id: '',
      chatId: chatId,
      senderId: senderId,
      receiverId: receiverId,
      text: '👤 Contact: $name',
      type: 'contact',
      mediaUrl: '',
      timestamp: DateTime.now(),
      status: 'sent',
      contactData: {
        'name': name,
        'phone': phone,
      },
    );
    await _sendMessageUseCase(message);
  }

  Future<void> sendViewOnceMedia(String chatId, String senderId, String receiverId, XFile file, String type) async {
    try {
      final url = await _uploadMediaUseCase(file, chatId);
      if (url != null) {
        final message = MessageEntity(
          id: '',
          chatId: chatId,
          senderId: senderId,
          receiverId: receiverId,
          text: type == 'image' ? '📸 Photo' : '🎥 Video',
          type: type,
          mediaUrl: url,
          timestamp: DateTime.now(),
          status: 'sent',
          isViewOnce: true,
        );
        await _sendMessageUseCase(message);
      }
    } catch (e) {
      debugPrint("ChatProvider Error in sendViewOnceMedia: $e");
      rethrow;
    }
  }

  Future<void> toggleFavoriteChat(String chatId, bool isFavorite) async {
    await _chatRepository.toggleFavoriteChat(chatId, isFavorite);
    notifyListeners();
  }

  Future<void> markAllAsRead(String chatId, String uid) async {
    await _chatRepository.markAllAsRead(chatId, uid);
    notifyListeners();
  }

  Future<void> markAllReadTotal(String uid) async {
    for (var chat in _chats) {
      if (chat.unreadCount[uid] != null && chat.unreadCount[uid]! > 0) {
        await markAllAsRead(chat.id, uid);
      }
    }
  }

  Future<void> editMessage(String chatId, String messageId, String newText) async {
    await _chatRepository.updateMessage(chatId, messageId, newText);
  }

  Future<void> deleteMessage(String chatId, String messageId) async {
    await _chatRepository.deleteMessage(chatId, messageId);
  }

  Future<void> togglePinChat(String chatId, bool isPinned) async {
    await _chatRepository.togglePinChat(chatId, isPinned);
  }

  Future<void> toggleDisappearingMessages(String chatId, bool enabled) async {
    await _chatRepository.toggleDisappearingMessages(chatId, enabled);
  }

  Future<void> markViewOnceAsOpened(String chatId, String messageId) async {
    await _chatRepository.markViewOnceAsOpened(chatId, messageId);
    notifyListeners();
  }

  // Group Admin
  Future<void> toggleAdminOnly(String chatId, bool enabled) async {
    await _chatRepository.toggleAdminOnly(chatId, enabled);
    notifyListeners();
  }

  Future<void> promoteToAdmin(String chatId, String userId) async {
    await _chatRepository.promoteToAdmin(chatId, userId);
    notifyListeners();
  }

  Future<void> demoteFromAdmin(String chatId, String userId) async {
    await _chatRepository.demoteFromAdmin(chatId, userId);
    notifyListeners();
  }

  Future<void> removeFromGroup(String chatId, String userId) async {
    await _chatRepository.removeFromGroup(chatId, userId);
    notifyListeners();
  }

  Future<void> addToGroup(String chatId, String userId) async {
    await _chatRepository.addToGroup(chatId, userId);
    notifyListeners();
  }

  Future<void> updateGroupDetails(String chatId, {String? name, String? imageUrl}) async {
    await _chatRepository.updateGroupDetails(chatId, name: name, imageUrl: imageUrl);
    notifyListeners();
  }

  Future<void> forwardMessage(MessageEntity originalMessage, String targetChatId, String senderId, String receiverId) async {
    final forwardedMessage = MessageEntity(
      id: '',
      chatId: targetChatId,
      senderId: senderId,
      receiverId: receiverId,
      text: originalMessage.text,
      type: originalMessage.type,
      mediaUrl: originalMessage.mediaUrl,
      timestamp: DateTime.now(),
      status: 'sent',
      isForwarded: true,
      latitude: originalMessage.latitude,
      longitude: originalMessage.longitude,
      pollOptions: originalMessage.pollOptions,
      eventData: originalMessage.eventData,
      contactData: originalMessage.contactData,
    );
    await _sendMessageUseCase(forwardedMessage);
  }

  Stream<List<CommunityEntity>> getCommunities() {
    return _chatRepository.getCommunities();
  }

  Future<String> createCommunity(String name, String description, String icon, String adminId) async {
    final id = await _chatRepository.createCommunity(name, description, icon, adminId);
    notifyListeners();
    return id;
  }

  Stream<List<BroadcastEntity>> getBroadcastLists() {
    return _chatRepository.getBroadcastLists();
  }

  Stream<List<TransactionEntity>> getTransactions(String uid) {
    return _chatRepository.getTransactions(uid);
  }

  Future<void> sendGifMessage(String chatId, String senderId, String receiverId, String gifUrl) async {
    final message = MessageEntity(
      id: '',
      chatId: chatId,
      senderId: senderId,
      receiverId: receiverId,
      text: '👾 GIF',
      type: 'image',
      mediaUrl: gifUrl,
      timestamp: DateTime.now(),
      status: 'sent',
    );
    await _sendMessageUseCase(message);
  }

  Future<void> toggleChatLock(String chatId, bool isLocked) async {
    await _chatRepository.toggleChatLock(chatId, isLocked);
    notifyListeners();
  }

  Future<void> deleteChat(String chatId, String uid) async {
    await _chatRepository.deleteChat(chatId, uid);
    notifyListeners();
  }

  Future<void> toggleApprovalRequired(String chatId, bool enabled) async {
    await _chatRepository.toggleApprovalRequired(chatId, enabled);
    notifyListeners();
  }

  Future<void> requestToJoin(String chatId, String userId) async {
    await _chatRepository.requestToJoin(chatId, userId);
    notifyListeners();
  }

  Future<void> approveRequest(String chatId, String userId, bool approved) async {
    await _chatRepository.approveRequest(chatId, userId, approved);
    notifyListeners();
  }

  Future<void> adminDeleteMessage(String chatId, String messageId) async {
    await _chatRepository.adminDeleteMessage(chatId, messageId);
    notifyListeners();
  }

  Future<void> updateInviteLink(String chatId, String? inviteLink) async {
    await _chatRepository.updateInviteLink(chatId, inviteLink);
    notifyListeners();
  }

  Future<void> updateChatLabels(String chatId, List<String> labels) async {
    await _chatRepository.updateChatLabels(chatId, labels);
    notifyListeners();
  }
}
