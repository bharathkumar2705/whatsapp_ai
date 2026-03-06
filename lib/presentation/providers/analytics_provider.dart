import 'package:flutter/material.dart';
import '../../domain/entities/message_entity.dart';
import '../../domain/entities/call_entity.dart';
import '../../domain/entities/chat_entity.dart';

class AnalyticsProvider extends ChangeNotifier {
  bool _isCalculating = false;
  bool get isCalculating => _isCalculating;

  // Personal Insights
  int _totalMessages = 0;
  int get totalMessages => _totalMessages;

  Map<String, int> _messagesPerContact = {}; // contactId -> count
  Map<String, int> get messagesPerContact => _messagesPerContact;

  Map<String, int> _streaks = {}; // contactId -> current streak
  Map<String, int> get streaks => _streaks;

  double _avgDailyTimeMinutes = 0.0;
  double get avgDailyTimeMinutes => _avgDailyTimeMinutes;

  // Relationship Strength Data (0-100)
  Map<String, double> _relationshipScores = {}; // contactId -> score
  Map<String, double> get relationshipScores => _relationshipScores;

  // Helper patterns for persona detection
  bool _isNightOwl = false;
  bool get isNightOwl => _isNightOwl;

  bool _isEmojiKing = false;
  bool get isEmojiKing => _isEmojiKing;

  Future<void> calculateAllStats({
    required String myUid,
    required List<ChatEntity> chats,
    required List<CallEntity> callHistory,
    required Future<List<MessageEntity>> Function(String chatId) getMessages,
  }) async {
    _isCalculating = true;
    notifyListeners();

    try {
      _totalMessages = 0;
      _messagesPerContact = {};
      _streaks = {};
      _relationshipScores = {};
      
      int emojiCount = 0;
      int nightMessages = 0;
      Map<DateTime, int> messagesPerDay = {};

      for (var chat in chats) {
        final otherUid = chat.participants.firstWhere((id) => id != myUid, orElse: () => '');
        if (otherUid.isEmpty) continue;

        final messages = await getMessages(chat.id);
        _totalMessages += messages.length;
        _messagesPerContact[otherUid] = messages.length;

        double chatScore = 0;
        
        // 1. Frequency (30 pts max)
        chatScore += (messages.length > 500 ? 30 : (messages.length / 500) * 30);

        // 2. Emoji Density (20 pts max)
        int chatEmojiCount = 0;
        final emojiRegex = RegExp(r'[\u{1F600}-\u{1F64F}\u{1F300}-\u{1F5FF}\u{1F680}-\u{1F6FF}\u{1F700}-\u{1F77F}\u{1F780}-\u{1F7FF}\u{1F800}-\u{1F8FF}\u{1F900}-\u{1F9FF}\u{1FA00}-\u{1FA6F}\u{1FA70}-\u{1FAFF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}]', unicode: true);
        
        // 3. Latency / Reply Time (30 pts max)
        Duration totalReplyDuration = Duration.zero;
        int replyCount = 0;

        for (int i = 0; i < messages.length - 1; i++) {
          final current = messages[i];
          final next = messages[i+1]; // next is older because messages are likely descending
          
          // Reply time: check if consecutive messages are from different people
          if (current.senderId != next.senderId) {
            final diff = current.timestamp.difference(next.timestamp).abs();
            if (diff.inHours < 4) { // Only count "active" responses
              totalReplyDuration += diff;
              replyCount++;
            }
          }

          // Metadata stats
          if (current.senderId == myUid) {
            chatEmojiCount += emojiRegex.allMatches(current.text).length;
            if (current.timestamp.hour >= 23 || current.timestamp.hour <= 4) {
              nightMessages++;
            }
          }

          final date = DateTime(current.timestamp.year, current.timestamp.month, current.timestamp.day);
          messagesPerDay[date] = (messagesPerDay[date] ?? 0) + 1;
        }

        emojiCount += chatEmojiCount;
        
        // Calculate Emoji Score
        if (messages.length > 0) {
          double emojiDensity = chatEmojiCount / messages.length;
          chatScore += (emojiDensity > 0.5 ? 20 : (emojiDensity / 0.5) * 20);
        }

        // Calculate Latency Score
        if (replyCount > 0) {
          double avgReplyMinutes = totalReplyDuration.inMinutes / replyCount;
          // Faster is better. Under 2 mins is perfect score.
          if (avgReplyMinutes < 2) chatScore += 30;
          else if (avgReplyMinutes < 60) chatScore += (1 - (avgReplyMinutes / 60)) * 30;
        }

        // 4. Call Activity (20 pts max)
        final relevantCalls = callHistory.where((c) => c.participants.contains(otherUid)).toList();
        int totalCallSeconds = relevantCalls.fold(0, (sum, c) => sum + (c.durationSeconds));
        
        double callScore = 0;
        if (relevantCalls.isNotEmpty) {
          // Count score (10 pts)
          callScore += (relevantCalls.length > 5 ? 10 : (relevantCalls.length / 5) * 10);
          // Duration score (10 pts) - 30 mins total is max points
          callScore += (totalCallSeconds > 1800 ? 10 : (totalCallSeconds / 1800) * 10);
        }
        chatScore += callScore;

        _relationshipScores[otherUid] = chatScore.clamp(0, 100);
        
        // Streaks (Simplified)
        _streaks[otherUid] = _calculateStreak(messages);
      }

      // Final Persona detection
      _isNightOwl = nightMessages > (_totalMessages * 0.3);
      _isEmojiKing = emojiCount > (_totalMessages * 1.5);
      
      // Daily Time Estimation
      if (messagesPerDay.isNotEmpty) {
        // Assume 2 minutes per message average engagement
        _avgDailyTimeMinutes = (_totalMessages * 1.5) / messagesPerDay.length;
      }

    } catch (e) {
      debugPrint("Analytics Error: $e");
    } finally {
      _isCalculating = false;
      notifyListeners();
    }
  }

  int _calculateStreak(List<MessageEntity> messages) {
    if (messages.isEmpty) return 0;
    
    final dates = messages.map((m) => DateTime(m.timestamp.year, m.timestamp.month, m.timestamp.day)).toSet().toList();
    dates.sort((a, b) => b.compareTo(a)); // Newest first

    int streak = 0;
    DateTime today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    
    // If the last message wasn't today or yesterday, streak is broken
    if (dates.first.isBefore(today.subtract(const Duration(days: 1)))) return 0;

    DateTime currentCheck = dates.first;
    streak = 1;

    for (int i = 1; i < dates.length; i++) {
      if (dates[i] == currentCheck.subtract(const Duration(days: 1))) {
        streak++;
        currentCheck = dates[i];
      } else if (dates[i] == currentCheck) {
        continue;
      } else {
        break;
      }
    }
    return streak;
  }
}
