import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../providers/analytics_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/call_provider.dart';
import '../providers/ai_provider.dart';

class ChatAnalyticsPage extends StatefulWidget {
  const ChatAnalyticsPage({super.key});

  @override
  State<ChatAnalyticsPage> createState() => _ChatAnalyticsPageState();
}

class _ChatAnalyticsPageState extends State<ChatAnalyticsPage> {
  bool _isInit = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      _loadStats();
      _isInit = true;
    }
  }

  Future<void> _loadStats() async {
    final myUid = Provider.of<AuthProvider>(context, listen: false).user?.uid;
    if (myUid == null) return;

    final chats = Provider.of<ChatProvider>(context, listen: false).chats;
    final callHistory = Provider.of<CallProvider>(context, listen: false).calls;
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final aiProvider = Provider.of<AiProvider>(context, listen: false);

    final analytics = Provider.of<AnalyticsProvider>(context, listen: false);
    await analytics.calculateAllStats(
      myUid: myUid,
      chats: chats,
      callHistory: callHistory,
      getMessages: (chatId) => chatProvider.getMessagesOnce(chatId),
    );

    // Auto-analyze sentiment for top relationship
    if (analytics.relationshipScores.isNotEmpty) {
      final topUid = analytics.relationshipScores.keys.first;
      final topChat = chats.firstWhere((c) => c.participants.contains(topUid));
      final messages = await chatProvider.getMessagesOnce(topChat.id);
      await aiProvider.fetchMoodTrend(messages, topChat.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final analytics = Provider.of<AnalyticsProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        title: const Text("Chat Insights", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF141828),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadStats(),
          ),
        ],
      ),
      body: analytics.isCalculating
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF7B2FE0)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeadline("Personal Stats"),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildMetricCard("Total Messages", analytics.totalMessages.toString(), Icons.message, Colors.blue)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildMetricCard("Daily Avg", "${analytics.avgDailyTimeMinutes.toInt()}m", Icons.timer, Colors.orange)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildMetricCard("Personal Personas", "", Icons.face, Colors.purple, 
                    subtitleWidget: Wrap(
                      spacing: 8,
                      children: [
                        if (analytics.isNightOwl) _buildBadge("Night Owl 🦉", Colors.deepPurple),
                        if (analytics.isEmojiKing) _buildBadge("Emoji King 👑", Colors.amber),
                        if (!analytics.isNightOwl && !analytics.isEmojiKing) _buildBadge("Casual Chater", Colors.teal),
                      ],
                    )
                  ),
                  
                  const SizedBox(height: 32),
                  _buildHeadline("Emotional Engine"),
                  const SizedBox(height: 12),
                  _buildSentimentChart(context, analytics),

                  const SizedBox(height: 32),
                  _buildHeadline("Relationship Strength"),
                  const SizedBox(height: 8),
                  const Text("Based on frequency, reply time, and calls.", style: TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(height: 20),
                  _buildRelationshipList(analytics),

                  const SizedBox(height: 32),
                  _buildHeadline("Conversation Streaks"),
                  const SizedBox(height: 16),
                  _buildStreakList(analytics),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildHeadline(String text) {
    return Text(text.toUpperCase(), style: const TextStyle(
      color: Colors.white,
      fontSize: 12,
      fontWeight: FontWeight.bold,
      letterSpacing: 1.5,
    ));
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color, {Widget? subtitleWidget}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2337),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 4),
          if (value.isNotEmpty)
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          if (subtitleWidget != null) ...[
            const SizedBox(height: 8),
            subtitleWidget,
          ]
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildRelationshipList(AnalyticsProvider analytics) {
    if (analytics.relationshipScores.isEmpty) {
      return const Text("No data yet.", style: TextStyle(color: Colors.grey));
    }

    final sortedUids = analytics.relationshipScores.keys.toList()
      ..sort((a, b) => analytics.relationshipScores[b]!.compareTo(analytics.relationshipScores[a]!));

    return Column(
      children: sortedUids.take(5).map((uid) {
        final score = analytics.relationshipScores[uid]!;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E2337),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Identity #$uid", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  Text("${score.toInt()}% Strength", style: TextStyle(color: _getScoreColor(score), fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: score / 100,
                  backgroundColor: Colors.white.withOpacity(0.05),
                  color: _getScoreColor(score),
                  minHeight: 8,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStreakList(AnalyticsProvider analytics) {
    final activeStreaks = analytics.streaks.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (activeStreaks.isEmpty) {
      return const Text("Start chatting to build a streak!", style: TextStyle(color: Colors.grey));
    }

    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: activeStreaks.length,
        itemBuilder: (context, index) {
          final entry = activeStreaks[index];
          return Container(
            width: 100,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF5F6D), Color(0xFFFFC371)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.local_fire_department, color: Colors.white, size: 28),
                const SizedBox(height: 4),
                Text(entry.value.toString(), style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const Text("DAYS", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w500)),
              ],
            ),
          );
        },
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score > 80) return Colors.pinkAccent;
    if (score > 60) return Colors.purpleAccent;
    if (score > 40) return Colors.blueAccent;
    return Colors.tealAccent;
  }

  Widget _buildSentimentChart(BuildContext context, AnalyticsProvider analytics) {
    if (analytics.relationshipScores.isEmpty) return const SizedBox();
    
    final topUid = analytics.relationshipScores.keys.first;
    final chats = Provider.of<ChatProvider>(context).chats;
    final topChat = chats.firstWhere((c) => c.participants.contains(topUid), orElse: () => chats.first);
    final moodTrend = Provider.of<AiProvider>(context).getMoodTrend(topChat.id);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2337),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Emotional Trend (Top Contact)", style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
              Icon(Icons.auto_awesome, color: Colors.purple[300], size: 16),
            ],
          ),
          const SizedBox(height: 24),
          if (moodTrend.isEmpty)
             const Center(child: Text("AI Analyzing Sentiment...", style: TextStyle(color: Colors.grey, fontSize: 12)))
          else
            SizedBox(
              height: 120,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: moodTrend.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
                      isCurved: true,
                      color: const Color(0xFF7B2FE0),
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [const Color(0xFF7B2FE0).withOpacity(0.2), Colors.transparent],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
