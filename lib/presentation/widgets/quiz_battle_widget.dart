import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/innovation_provider.dart';

class QuizBattleWidget extends StatefulWidget {
  final String chatId;
  final String messageId;
  final Map<String, dynamic> data;

  const QuizBattleWidget({
    super.key,
    required this.chatId,
    required this.messageId,
    required this.data,
  });

  @override
  State<QuizBattleWidget> createState() => _QuizBattleWidgetState();
}

class _QuizBattleWidgetState extends State<QuizBattleWidget> {
  @override
  Widget build(BuildContext context) {
    final status = widget.data['status'] ?? 'waiting';
    final question = widget.data['question'] ?? 'Who is the father of AI?';
    final options = widget.data['options'] ?? ['Alan Turing', 'Elon Musk', 'Bill Gates', 'Steve Jobs'];
    final scores = widget.data['scores'] as Map<String, dynamic>? ?? {};

    return Container(
      width: 280,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.purple.withOpacity(0.3), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.quiz, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text("Quiz Battle", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Text(question, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          ...options.map((opt) => Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // In a real implementation, we'd check if the user already answered
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Answered: $opt")));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white24,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: Text(opt),
              ),
            ),
          )),
          const Divider(color: Colors.white24),
          Text(
            "Leaderboard: ${scores.entries.map((e) => '${e.key}: ${e.value}').join(', ')}",
            style: const TextStyle(color: Colors.white70, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
