import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/chat_entity.dart';
import '../../domain/entities/message_entity.dart';
import '../../domain/repositories/chat_repository_interface.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../../domain/entities/community_entity.dart';
import '../../domain/entities/broadcast_entity.dart';
import '../../domain/entities/transaction_entity.dart';
import '../services/encryption_service.dart';

class ChatRepository implements IChatRepository {
  FirebaseFirestore get _firestore {
    if (Firebase.apps.isEmpty) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'no-app',
        message: 'Firebase is not initialized.',
      );
    }
    return FirebaseFirestore.instance;
  }

  @override
  Stream<List<ChatEntity>> getMyChats(String uid) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: uid)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  @override
  Stream<List<MessageEntity>> getMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .snapshots()
        .map((snapshot) {
          final messages = snapshot.docs
              .map((doc) => MessageModel.fromMap(doc.data(), doc.id))
              .toList();
          // Sort in memory so no Firestore index is required
          messages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          return messages;
        });
  }

  @override
  Future<void> sendMessage(MessageEntity message) async {
    final chatRef = _firestore.collection('chats').doc(message.chatId);
    
    final model = MessageModel(
      id: message.id,
      chatId: message.chatId,
      senderId: message.senderId,
      receiverId: message.receiverId,
      text: EncryptionService.encryptMessage(message.text),
      type: message.type,
      mediaUrl: message.mediaUrl,
      timestamp: message.timestamp,
      status: message.status,
      reactions: message.reactions,
      seenBy: message.seenBy,
      replyToId: message.replyToId,
      replyText: message.replyText,
      isStarred: message.isStarred,
      latitude: message.latitude,
      longitude: message.longitude,
      pollOptions: message.pollOptions,
      eventData: message.eventData,
      contactData: message.contactData,
      pluginData: message.pluginData,
    );

    await chatRef.collection('messages').add(model.toMap());
    
    await chatRef.update({
      'lastMessage': message.text,
      'lastMessageTime': message.timestamp.millisecondsSinceEpoch,
    });
  }

  @override
  Future<String> createChat(List<String> participants) async {
    final existing = await _firestore
        .collection('chats')
        .where('participants', arrayContains: participants[0])
        .get();
    
    for (var doc in existing.docs) {
      List<String> parts = List<String>.from(doc['participants']);
      if (parts.length == 2 && parts.contains(participants[1])) {
        return doc.id;
      }
    }

    final newChat = await _firestore.collection('chats').add({
      'participants': participants,
      'lastMessage': '',
      'lastMessageTime': DateTime.now().millisecondsSinceEpoch,
      'unreadCount': {},
    });
    return newChat.id;
  }

  @override
  Future<void> markMessageAsSeen(String chatId, String messageId, String uid) async {
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update({
      'seenBy': FieldValue.arrayUnion([uid]),
      'status': 'seen',
    });
  }

  @override
  Future<void> updateMessageReactions(String chatId, String messageId, List<String> reactions) async {
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update({
      'reactions': reactions,
    });
  }

  @override
  Future<String> createGroup(String name, List<String> participants, String creatorId, {String? image}) async {
    final newGroup = await _firestore.collection('chats').add({
      'participants': participants,
      'lastMessage': 'Group created',
      'lastMessageTime': DateTime.now().millisecondsSinceEpoch,
      'unreadCount': {},
      'isGroup': true,
      'groupName': name,
      'groupImage': image,
      'admins': [creatorId],
    });
    return newGroup.id;
  }

  @override
  Future<void> toggleStarMessage(String chatId, String messageId, bool isStarred) async {
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update({'isStarred': isStarred});
  }

  @override
  Future<void> toggleArchiveChat(String chatId, bool isArchived) async {
    await _firestore
        .collection('chats')
        .doc(chatId)
        .update({'isArchived': isArchived});
  }

  @override
  Future<void> toggleFavoriteChat(String chatId, bool isFavorite) async {
    await _firestore
        .collection('chats')
        .doc(chatId)
        .update({'isFavorite': isFavorite});
  }

  @override
  Future<void> togglePinChat(String chatId, bool isPinned) async {
    await _firestore.collection('chats').doc(chatId).update({'isPinned': isPinned});
  }

  @override
  Future<void> markViewOnceAsOpened(String chatId, String messageId) async {
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update({
      'text': 'Opened',
      'mediaUrl': '',
      'status': 'opened',
    });
  }

  @override
  Future<void> toggleAdminOnly(String chatId, bool enabled) async {
    await _firestore.collection('chats').doc(chatId).update({'adminOnly': enabled});
  }

  @override
  Future<void> promoteToAdmin(String chatId, String userId) async {
    await _firestore.collection('chats').doc(chatId).update({
      'admins': FieldValue.arrayUnion([userId])
    });
  }

  @override
  Future<void> demoteFromAdmin(String chatId, String userId) async {
    await _firestore.collection('chats').doc(chatId).update({
      'admins': FieldValue.arrayRemove([userId])
    });
  }

  @override
  Future<void> removeFromGroup(String chatId, String userId) async {
    await _firestore.collection('chats').doc(chatId).update({
      'participants': FieldValue.arrayRemove([userId])
    });
  }

  @override
  Future<void> addToGroup(String chatId, String userId) async {
    await _firestore.collection('chats').doc(chatId).update({
      'participants': FieldValue.arrayUnion([userId])
    });
  }

  @override
  Future<void> updateGroupDetails(String chatId, {String? name, String? imageUrl}) async {
    final Map<String, dynamic> data = {};
    if (name != null) data['groupName'] = name;
    if (imageUrl != null) data['groupImage'] = imageUrl;
    if (data.isNotEmpty) {
      await _firestore.collection('chats').doc(chatId).update(data);
    }
  }

  @override
  Future<void> markAllAsRead(String chatId, String uid) async {
    final messages = await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .get();
    
    final batch = _firestore.batch();
    for (var doc in messages.docs) {
      List<String> seenBy = List<String>.from(doc.data()['seenBy'] ?? []);
      if (!seenBy.contains(uid)) {
        batch.update(doc.reference, {
          'seenBy': FieldValue.arrayUnion([uid]),
          'status': 'seen',
        });
      }
    }
    await batch.commit();
  }

  @override
  Future<void> updateMessage(String chatId, String messageId, String newText) async {
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update({
      'text': EncryptionService.encryptMessage(newText),
      'isEdited': true,
    });
  }

  @override
  Future<void> deleteMessage(String chatId, String messageId) async {
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update({
      'text': '🚫 This message was deleted',
      'type': 'deleted',
      'mediaUrl': '',
      'isEdited': false,
    });
  }

  @override
  Future<void> toggleDisappearingMessages(String chatId, bool enabled) async {
    await _firestore
        .collection('chats')
        .doc(chatId)
        .update({
      'disappearingEnabled': enabled,
      'disappearingDuration': enabled ? 86400 : 0,
    });
  }

  @override
  Future<void> toggleChatLock(String chatId, bool isLocked) async {
    await _firestore.collection('chats').doc(chatId).update({'isLocked': isLocked});
  }

  @override
  Future<void> deleteChat(String chatId, String uid) async {
    // Uses a "deletedFor" array so each user can delete their own copy
    // without losing the other person's chat history.
    await _firestore.collection('chats').doc(chatId).update({
      'deletedFor': FieldValue.arrayUnion([uid]),
    });
  }

  @override
  Future<void> toggleApprovalRequired(String chatId, bool enabled) async {
    await _firestore.collection('chats').doc(chatId).update({'approvalRequired': enabled});
  }

  @override
  Future<void> requestToJoin(String chatId, String userId) async {
    await _firestore.collection('chats').doc(chatId).update({
      'joinRequests': FieldValue.arrayUnion([userId])
    });
  }

  @override
  Future<void> approveRequest(String chatId, String userId, bool approved) async {
    if (approved) {
      await _firestore.collection('chats').doc(chatId).update({
        'participants': FieldValue.arrayUnion([userId]),
        'joinRequests': FieldValue.arrayRemove([userId])
      });
    } else {
      await _firestore.collection('chats').doc(chatId).update({
        'joinRequests': FieldValue.arrayRemove([userId])
      });
    }
  }

  @override
  Future<void> adminDeleteMessage(String chatId, String messageId) async {
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update({
      'text': '🚫 This message was deleted by admin',
      'type': 'deleted',
      'mediaUrl': '',
      'isEdited': false,
    });
  }

  @override
  Future<void> updateInviteLink(String chatId, String? inviteLink) async {
    await _firestore.collection('chats').doc(chatId).update({'inviteLink': inviteLink});
  }

  @override
  Stream<List<CommunityEntity>> getCommunities() {
    return _firestore.collection('communities').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return CommunityEntity(
          id: doc.id,
          name: data['name'] ?? 'Community',
          description: data['description'] ?? '',
          icon: data['icon'] ?? 'groups',
          unreadCount: data['unreadCount'] ?? 0,
        );
      }).toList();
    });
  }

  @override
  Future<String> createCommunity(String name, String description, String icon, String adminId) async {
    final doc = await _firestore.collection('communities').add({
      'name': name,
      'description': description,
      'icon': icon,
      'adminIds': [adminId],
      'unreadCount': 0,
    });
    return doc.id;
  }

  @override
  Stream<List<BroadcastEntity>> getBroadcastLists() {
    return _firestore.collection('broadcasts').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return BroadcastEntity(
          id: doc.id,
          name: data['name'] ?? 'Broadcast',
          recipientCount: data['recipientCount'] ?? 0,
          lastActive: DateTime.fromMillisecondsSinceEpoch(data['lastActive'] ?? DateTime.now().millisecondsSinceEpoch),
        );
      }).toList();
    });
  }

  @override
  Stream<List<TransactionEntity>> getTransactions(String uid) {
    return _firestore
        .collection('transactions')
        .where('userId', isEqualTo: uid)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return TransactionEntity(
          id: doc.id,
          title: data['title'] ?? 'Payment',
          amount: (data['amount'] ?? 0.0).toDouble(),
          date: DateTime.fromMillisecondsSinceEpoch(data['date'] ?? DateTime.now().millisecondsSinceEpoch),
          status: data['status'] ?? 'completed',
        );
      }).toList();
    });
  }

  @override
  Future<void> updateChatLabels(String chatId, List<String> labels) async {
    await _firestore.collection('chats').doc(chatId).update({'labels': labels});
  }
}
