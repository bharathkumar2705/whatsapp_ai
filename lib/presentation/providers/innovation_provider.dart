import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/message_model.dart';
import '../../domain/entities/message_entity.dart';
import 'package:uuid/uuid.dart';

class InnovationProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Update the pluginData of a specific message.
  /// This is used by interactive widgets like Tic Tac Toe or Expense Tracker.
  Future<void> updatePluginData({
    required String chatId,
    required String messageId,
    required Map<String, dynamic> newData,
  }) async {
    try {
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .update({'pluginData': newData});
    } catch (e) {
      debugPrint("Error updating plugin data: $e");
    }
  }

  /// Specialized helpers for specific plugins can be added here
  
  // Tic Tac Toe Move
  Future<void> makeTicTacToeMove({
    required String chatId,
    required String messageId,
    required List<int> board,
    required String nextTurnUid,
    String? winner,
  }) async {
    final data = {
      'type': 'tic_tac_toe',
      'board': board,
      'nextTurnUid': nextTurnUid,
      if (winner != null) 'winner': winner,
    };
    await updatePluginData(chatId: chatId, messageId: messageId, newData: data);
  }

  // Expense Tracker Update
  Future<void> addExpense({
    required String chatId,
    required String messageId,
    required List<dynamic> currentExpenses,
    required String description,
    required double amount,
    required String addedByUid,
  }) async {
    final newExpense = {
      'description': description,
      'amount': amount,
      'addedByUid': addedByUid,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    
    final updatedList = List.from(currentExpenses)..add(newExpense);
    final data = {
      'type': 'expense_tracker',
      'expenses': updatedList,
    };
    await updatePluginData(chatId: chatId, messageId: messageId, newData: data);
  }

  /// Start a new expense tracker (Used by Receipt Scanner)
  Future<void> startExpenseTracker({
    required String chatId,
    required String myUid,
    required String initialDescription,
    required double initialAmount,
  }) async {
    final messageId = Uuid().v4();
    final data = {
      'type': 'expense_tracker',
      'expenses': [
        {
          'description': initialDescription,
          'amount': initialAmount,
          'addedByUid': myUid,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        }
      ],
    };
    
    // Create the message in Firestore
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .set({
      'id': messageId,
      'chatId': chatId,
      'senderId': myUid,
      'receiverId': 'group', // Or specific user for p2p
      'text': "Shared Expense Tracker started",
      'type': 'plugin',
      'mediaUrl': '',
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'sent',
      'seenBy': [myUid],
      'pluginData': data,
    });
  }

  // Whiteboard: Sync Drawing Strokes
  Future<void> updateWhiteboardStrokes({
    required String chatId,
    required String messageId,
    required List<dynamic> strokes,
  }) async {
    final data = {
      'type': 'whiteboard',
      'strokes': strokes,
    };
    await updatePluginData(chatId: chatId, messageId: messageId, newData: data);
  }

  // Code Editor: Sync Content
  Future<void> updateCodeContent({
    required String chatId,
    required String messageId,
    required String content,
    required String language,
  }) async {
    final data = {
      'type': 'code_editor',
      'content': content,
      'language': language,
    };
    await updatePluginData(chatId: chatId, messageId: messageId, newData: data);
  }

  // Grocery List: Sync Items
  Future<void> updateGroceryItems({
    required String chatId,
    required String messageId,
    required List<dynamic> items,
  }) async {
    final data = {
      'type': 'grocery_list',
      'items': items,
    };
    await updatePluginData(chatId: chatId, messageId: messageId, newData: data);
  }

  /// Start a new whiteboard session
  Future<void> startWhiteboard({
    required String chatId,
    required String myUid,
  }) async {
    final messageId = const Uuid().v4();
    final data = {
      'type': 'whiteboard',
      'strokes': [],
    };
    
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .set({
      'id': messageId,
      'chatId': chatId,
      'senderId': myUid,
      'receiverId': 'everyone',
      'text': "Shared Whiteboard started",
      'type': 'plugin',
      'mediaUrl': '',
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'sent',
      'seenBy': [myUid],
      'pluginData': data,
    });
  }

  /// Start a new shared code editor
  Future<void> startCodeEditor({
    required String chatId,
    required String myUid,
    required String language,
  }) async {
    final messageId = const Uuid().v4();
    final data = {
      'type': 'code_editor',
      'content': '// Start coding here...',
      'language': language,
    };
    
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .set({
      'id': messageId,
      'chatId': chatId,
      'senderId': myUid,
      'receiverId': 'everyone',
      'text': "Shared Code Editor started",
      'type': 'plugin',
      'mediaUrl': '',
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'sent',
      'seenBy': [myUid],
      'pluginData': data,
    });
  }

  /// Start a new shared grocery list
  Future<void> startGroceryList({
    required String chatId,
    required String myUid,
  }) async {
    final messageId = const Uuid().v4();
    final data = {
      'type': 'grocery_list',
      'items': [],
    };
    
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .set({
      'id': messageId,
      'chatId': chatId,
      'senderId': myUid,
      'receiverId': 'everyone',
      'text': "Shared Grocery List started",
      'type': 'plugin',
      'mediaUrl': '',
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'sent',
      'seenBy': [myUid],
      'pluginData': data,
    });
  }

  /// Start a new quiz battle
  Future<void> startQuizBattle({
    required String chatId,
    required String myUid,
  }) async {
    final messageId = const Uuid().v4();
    final data = {
      'type': 'quiz_battle',
      'status': 'waiting',
      'question': 'Which programming language is known as the "Mother of all languages"?',
      'options': ['C', 'Fortran', 'Assembly', 'Java'],
      'scores': {},
    };
    
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .set({
      'id': messageId,
      'chatId': chatId,
      'senderId': myUid,
      'receiverId': 'everyone',
      'text': "Quiz Battle started",
      'type': 'plugin',
      'mediaUrl': '',
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'sent',
      'seenBy': [myUid],
      'pluginData': data,
    });
  }
}
