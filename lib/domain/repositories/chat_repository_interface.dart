import '../entities/chat_entity.dart';
import '../entities/message_entity.dart';
import '../entities/community_entity.dart';
import '../entities/broadcast_entity.dart';
import '../entities/transaction_entity.dart';

abstract class IChatRepository {
  Stream<List<ChatEntity>> getMyChats(String uid);
  Stream<List<MessageEntity>> getMessages(String chatId);
  Future<void> sendMessage(MessageEntity message);
  Future<String> createChat(List<String> participants);
  Future<void> markMessageAsSeen(String chatId, String messageId, String uid);
  Future<void> updateMessageReactions(String chatId, String messageId, List<String> reactions);
  Future<String> createGroup(String name, List<String> participants, String creatorId, {String? image});
  Future<void> toggleStarMessage(String chatId, String messageId, bool isStarred);
  Future<void> toggleArchiveChat(String chatId, bool isArchived);
  Future<void> toggleFavoriteChat(String chatId, bool isFavorite);
  Future<void> togglePinChat(String chatId, bool isPinned);
  Future<void> markViewOnceAsOpened(String chatId, String messageId);
  Future<void> markAllAsRead(String chatId, String uid);
  
  // Group Admin
  Future<void> toggleAdminOnly(String chatId, bool enabled);
  Future<void> promoteToAdmin(String chatId, String userId);
  Future<void> demoteFromAdmin(String chatId, String userId);
  Future<void> removeFromGroup(String chatId, String userId);
  Future<void> toggleApprovalRequired(String chatId, bool enabled);
  Future<void> requestToJoin(String chatId, String userId);
  Future<void> approveRequest(String chatId, String userId, bool approved);
  Future<void> adminDeleteMessage(String chatId, String messageId);
  Future<void> updateInviteLink(String chatId, String? inviteLink);
  
  // Wave 17
  Future<void> updateMessage(String chatId, String messageId, String newText);
  Future<void> deleteMessage(String chatId, String messageId);
  Future<void> toggleDisappearingMessages(String chatId, bool enabled);
  Future<void> toggleChatLock(String chatId, bool isLocked);

  Stream<List<CommunityEntity>> getCommunities();
  Future<String> createCommunity(String name, String description, String icon, String adminId);
  Stream<List<BroadcastEntity>> getBroadcastLists();
  Stream<List<TransactionEntity>> getTransactions(String uid);
  
  // Wave 8: Business
  Future<void> updateChatLabels(String chatId, List<String> labels);
}
