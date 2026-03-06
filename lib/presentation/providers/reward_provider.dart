import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RewardProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  int _coins = 0;
  String? _userId;

  int get coins => _coins;

  StreamSubscription? _subscription;

  void init(String userId) {
    if (userId.isEmpty || _userId == userId) return;
    _userId = userId;
    _listenToRewards();
  }

  void clear() {
    _userId = null;
    _coins = 0;
    _subscription?.cancel();
    _subscription = null;
    notifyListeners();
  }

  void _listenToRewards() {
    if (_userId == null || _userId!.isEmpty) return;
    _subscription?.cancel();
    _subscription = _firestore.collection('users').doc(_userId).snapshots().listen((doc) {
      if (doc.exists) {
        _coins = doc.data()?['coins'] ?? 0;
        notifyListeners();
      }
    });
  }

  Future<void> addReward(int amount, String reason) async {
    if (_userId == null || _userId!.isEmpty) return;
    
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

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  // Common reward events
  Future<void> rewardMessageSent() => addReward(1, "Message Sent");
  Future<void> rewardAiUsed() => addReward(5, "AI Feature Used");
  Future<void> rewardStreakMaintained(int streak) => addReward(streak * 2, "Streak Bonus ($streak days)");
}
