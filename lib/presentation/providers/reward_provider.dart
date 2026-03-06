import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RewardProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  int _coins = 0;
  String? _userId;

  int get coins => _coins;

  void init(String userId) {
    _userId = userId;
    _listenToRewards();
  }

  void _listenToRewards() {
    if (_userId == null) return;
    _firestore.collection('users').doc(_userId).snapshots().listen((doc) {
      if (doc.exists) {
        _coins = doc.data()?['coins'] ?? 0;
        notifyListeners();
      }
    });
  }

  Future<void> addReward(int amount, String reason) async {
    if (_userId == null) return;
    
    await _firestore.collection('users').doc(_userId).update({
      'coins': FieldValue.increment(amount),
    });

    // Log the reward
    await _firestore.collection('users').doc(_userId).collection('rewards_log').add({
      'amount': amount,
      'reason': reason,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Common reward events
  Future<void> rewardMessageSent() => addReward(1, "Message Sent");
  Future<void> rewardAiUsed() => addReward(5, "AI Feature Used");
  Future<void> rewardStreakMaintained(int streak) => addReward(streak * 2, "Streak Bonus ($streak days)");
}
