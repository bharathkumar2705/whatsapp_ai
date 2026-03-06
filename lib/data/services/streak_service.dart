import 'package:cloud_firestore/cloud_firestore.dart';

class StreakService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> updateStreak(String chatId, String userId) async {
    final streakRef = _firestore.collection('chats').doc(chatId).collection('streaks').doc(userId);
    
    final doc = await streakRef.get();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (!doc.exists) {
      await streakRef.set({
        'count': 1,
        'lastActive': today.millisecondsSinceEpoch,
      });
      return;
    }

    final data = doc.data()!;
    final lastActiveEpoch = data['lastActive'] as int;
    final lastActive = DateTime.fromMillisecondsSinceEpoch(lastActiveEpoch);
    final diff = today.difference(lastActive).inDays;

    if (diff == 1) {
      // Streak continues
      await streakRef.update({
        'count': FieldValue.increment(1),
        'lastActive': today.millisecondsSinceEpoch,
      });
    } else if (diff > 1) {
      // Streak broken
      await streakRef.set({
        'count': 1,
        'lastActive': today.millisecondsSinceEpoch,
      });
    }
    // If diff == 0, already active today, do nothing.
  }

  Stream<int> getStreak(String chatId, String userId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('streaks')
        .doc(userId)
        .snapshots()
        .map((doc) => doc.exists ? (doc.data()?['count'] ?? 0) : 0);
  }
}
