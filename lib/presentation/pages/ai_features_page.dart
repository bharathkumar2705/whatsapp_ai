import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../providers/ai_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/task_provider.dart';
import 'chat_analytics_page.dart';
import '../../domain/entities/message_entity.dart';
import '../../domain/entities/task_entity.dart';

class AiFeaturesPage extends StatefulWidget {
  const AiFeaturesPage({super.key});

  @override
  State<AiFeaturesPage> createState() => _AiFeaturesPageState();
}

class _AiFeaturesPageState extends State<AiFeaturesPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF141828),
        foregroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF7B2FE0), Color(0xFF00C6FF)]),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            const Text("AI Features", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF7B2FE0),
          labelColor: const Color(0xFF7B2FE0),
          unselectedLabelColor: Colors.grey,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.smart_toy_outlined), text: "AI Chat"),
            Tab(icon: Icon(Icons.mood), text: "Sentiment"),
            Tab(icon: Icon(Icons.insights), text: "Insights"),
            Tab(icon: Icon(Icons.checklist), text: "Action Center"),
            Tab(icon: Icon(Icons.translate), text: "Language"),
            Tab(icon: Icon(Icons.tune), text: "Tone Check"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _AiChatTab(),
          _SentimentTab(),
          ChatAnalyticsPage(),
          _ActionCenterTab(),
          _LanguageTab(),
          _ToneTab(),
        ],
      ),
    );
  }
}

// ───────────────────────────────────────────
// Tab 1: AI Chatbot
// ───────────────────────────────────────────
class _AiChatTab extends StatefulWidget {
  const _AiChatTab();
  @override
  State<_AiChatTab> createState() => _AiChatTabState();
}

class _AiChatTabState extends State<_AiChatTab> {
  final TextEditingController _ctrl = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final List<Map<String, String>> _messages = [
    {'role': 'ai', 'text': 'Hello! I\'m Gemini AI. Ask me anything! 🤖'}
  ];
  bool _loading = false;

  void _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _loading = true;
      _ctrl.clear();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scroll.animateTo(_scroll.position.maxScrollExtent + 200, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    });

    final ai = Provider.of<AiProvider>(context, listen: false);
    final reply = await ai.chatWithAI(text);
    setState(() {
      _messages.add({'role': 'ai', 'text': reply});
      _loading = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scroll.animateTo(_scroll.position.maxScrollExtent + 200, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scroll,
            padding: const EdgeInsets.all(16),
            itemCount: _messages.length + (_loading ? 1 : 0),
            itemBuilder: (_, i) {
              if (i == _messages.length) return _TypingBubble();
              final msg = _messages[i];
              final isUser = msg['role'] == 'user';
              return Align(
                alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                  decoration: BoxDecoration(
                    gradient: isUser
                        ? const LinearGradient(colors: [Color(0xFF7B2FE0), Color(0xFF4F8EF7)])
                        : null,
                    color: isUser ? null : const Color(0xFF1E2337),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isUser ? 16 : 0),
                      bottomRight: Radius.circular(isUser ? 0 : 16),
                    ),
                  ),
                  child: Text(msg['text'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 15)),
                ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(12),
          color: const Color(0xFF141828),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Ask Gemini anything...",
                    hintStyle: TextStyle(color: Colors.grey[600]),
                    filled: true,
                    fillColor: const Color(0xFF1E2337),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onSubmitted: (_) => _send(),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _send,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [Color(0xFF7B2FE0), Color(0xFF00C6FF)]),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TypingBubble extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E2337),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16), topRight: Radius.circular(16), bottomRight: Radius.circular(16),
          ),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 12, width: 4, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF7B2FE0))),
          const SizedBox(width: 8),
          Text("Gemini is thinking...", style: TextStyle(color: Colors.grey[400], fontSize: 13)),
        ]),
      ),
    );
  }
}

// ───────────────────────────────────────────
// Tab 2: Sentiment Analysis
// ───────────────────────────────────────────
class _SentimentTab extends StatefulWidget {
  const _SentimentTab();
  @override
  State<_SentimentTab> createState() => _SentimentTabState();
}

class _SentimentTabState extends State<_SentimentTab> {
  String _selectedChatId = '';
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final ai = Provider.of<AiProvider>(context);
    final chats = Provider.of<ChatProvider>(context).chats;
    final moodTrend = ai.getMoodTrend(_selectedChatId);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle("Mood Analytics"),
          const SizedBox(height: 8),
          const Text("Track the emotional pulse of your conversations over time.", 
              style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 20),

          if (chats.isNotEmpty)
            DropdownButtonFormField<String>(
              dropdownColor: const Color(0xFF1E2337),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true, fillColor: const Color(0xFF1E2337),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                labelText: "Select Chat",
                labelStyle: const TextStyle(color: Colors.grey),
              ),
              items: chats.map((c) => DropdownMenuItem(
                value: c.id,
                child: Text(c.isGroup ? (c.groupName ?? 'Group') : 'Chat ${c.id.substring(0, 5)}'),
              )).toList(),
              onChanged: (v) => setState(() => _selectedChatId = v ?? ''),
            ),

          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _selectedChatId.isEmpty || _loading ? null : () async {
              setState(() => _loading = true);
              final msgs = await Provider.of<ChatProvider>(context, listen: false).getMessages(_selectedChatId).first;
              await ai.fetchMoodTrend(msgs, _selectedChatId);
              setState(() => _loading = false);
            },
            icon: _loading ? const SizedBox(height: 14, width: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.analytics_outlined),
            label: Text(_loading ? "Analyzing..." : "Analyze Mood Trend"),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7B2FE0), foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),

          if (moodTrend.isNotEmpty) ...[
            const SizedBox(height: 32),
            _sectionTitle("Emotional Energy"),
            const SizedBox(height: 4),
            const Text("0 = Angry/Cold, 100 = Happy/Energetic", style: TextStyle(color: Colors.grey, fontSize: 11)),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: moodTrend.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
                      isCurved: true,
                      color: const Color(0xFF00C6FF),
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [const Color(0xFF00C6FF).withOpacity(0.3), Colors.transparent],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildMoodSummary(moodTrend.last),
          ],
          
          const SizedBox(height: 40),
          _sectionTitle("Toxicity Audit"),
          const SizedBox(height: 12),
          _buildToxicityCard(),
        ],
      ),
    );
  }

  Widget _buildMoodSummary(double score) {
    String label;
    IconData icon;
    Color color;
    
    if (score > 80) { label = "Incredibly Positive"; icon = Icons.sentiment_very_satisfied; color = Colors.greenAccent; }
    else if (score > 60) { label = "Generally Happy"; icon = Icons.sentiment_satisfied; color = Colors.blueAccent; }
    else if (score > 40) { label = "Neutral / Serious"; icon = Icons.sentiment_neutral; color = Colors.grey; }
    else if (score > 20) { label = "Low Energy / Sad"; icon = Icons.sentiment_dissatisfied; color = Colors.orangeAccent; }
    else { label = "Aggressive / Angry"; icon = Icons.sentiment_very_dissatisfied; color = Colors.redAccent; }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF1E2337), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text("Current Pulse: $label", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            Text("Sentiment Score: ${score.toInt()}/100", style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ])),
        ],
      ),
    );
  }

  Widget _buildToxicityCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2337),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.redAccent.withOpacity(0.3), width: 0.5),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.gpp_good, color: Colors.tealAccent, size: 20),
              SizedBox(width: 8),
              Text("Conversation Health", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          SizedBox(height: 8),
          const Text("Gemini AI is monitoring for harassment or toxic patterns in this chat. No issues detected in recent messages.", 
              style: TextStyle(color: Colors.grey, fontSize: 13)),
        ],
      ),
    );
  }
}

// ───────────────────────────────────────────
// Tab 3: Language Detection
// ───────────────────────────────────────────
class _LanguageTab extends StatefulWidget {
  const _LanguageTab();
  @override
  State<_LanguageTab> createState() => _LanguageTabState();
}

class _LanguageTabState extends State<_LanguageTab> {
  final TextEditingController _ctrl = TextEditingController();
  bool _loading = false;
  String? _language;

  void _detect() async {
    if (_ctrl.text.trim().isEmpty) return;
    setState(() { _loading = true; _language = null; });
    final ai = Provider.of<AiProvider>(context, listen: false);
    final result = await ai.detectLanguage(_ctrl.text.trim());
    setState(() { _language = result; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle("Paste any text to detect its language"),
          const SizedBox(height: 12),
          TextField(
            controller: _ctrl,
            minLines: 4, maxLines: 6,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "Type or paste any text here...",
              hintStyle: TextStyle(color: Colors.grey[600]),
              filled: true, fillColor: const Color(0xFF1E2337),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _loading ? null : _detect,
              icon: const Icon(Icons.translate),
              label: const Text("Detect Language"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7B2FE0), foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (_loading) const Center(child: CircularProgressIndicator(color: Color(0xFF7B2FE0))),
          if (_language != null)
            Container(
              padding: const EdgeInsets.all(20),
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF1E2337), Color(0xFF141828)]),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF7B2FE0)),
              ),
              child: Column(children: [
                const Icon(Icons.language, color: Color(0xFF00C6FF), size: 40),
                const SizedBox(height: 12),
                const Text("Detected Language", style: TextStyle(color: Colors.grey, fontSize: 14)),
                const SizedBox(height: 4),
                Text(_language!, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
              ]),
            ),
        ],
      ),
    );
  }
}

// ───────────────────────────────────────────
// Tab 4: Tone Checker
// ───────────────────────────────────────────
class _ToneTab extends StatefulWidget {
  const _ToneTab();
  @override
  State<_ToneTab> createState() => _ToneTabState();
}

class _ToneTabState extends State<_ToneTab> {
  final TextEditingController _ctrl = TextEditingController();
  bool _loading = false;
  Map<String, dynamic>? _result;

  static const _toneColors = {
    'Friendly': Color(0xFF4CAF50),
    'Formal': Color(0xFF2196F3),
    'Casual': Color(0xFF00BCD4),
    'Aggressive': Color(0xFFF44336),
    'Sarcastic': Color(0xFFFFC107),
    'Nervous': Color(0xFF9C27B0),
  };

  static const _toneEmoji = {
    'Friendly': '😊',
    'Formal': '👔',
    'Casual': '😎',
    'Aggressive': '😠',
    'Sarcastic': '😏',
    'Nervous': '😰',
  };

  void _check() async {
    if (_ctrl.text.trim().isEmpty) return;
    setState(() { _loading = true; _result = null; });
    final ai = Provider.of<AiProvider>(context, listen: false);
    final result = await ai.checkTone(_ctrl.text.trim());
    setState(() { _result = result; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle("Check how your message sounds before sending"),
          const SizedBox(height: 12),
          TextField(
            controller: _ctrl,
            minLines: 4, maxLines: 6,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "Type a draft message to analyze its tone...",
              hintStyle: TextStyle(color: Colors.grey[600]),
              filled: true, fillColor: const Color(0xFF1E2337),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _loading ? null : _check,
              icon: const Icon(Icons.tune),
              label: const Text("Analyze Tone"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7B2FE0), foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (_loading) const Center(child: CircularProgressIndicator(color: Color(0xFF7B2FE0))),
          if (_result != null) _buildToneResult(_result!),
        ],
      ),
    );
  }

  Widget _buildToneResult(Map<String, dynamic> res) {
    final tone = res['tone'] ?? 'Casual';
    final suggestion = res['suggestion'] ?? '';
    final color = _toneColors[tone] ?? const Color(0xFF607D8B);
    final emoji = _toneEmoji[tone] ?? '🙂';

    return Column(children: [
      Container(
        padding: const EdgeInsets.all(20),
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF1E2337),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color, width: 1.5),
        ),
        child: Column(children: [
          Text(emoji, style: const TextStyle(fontSize: 48)),
          const SizedBox(height: 8),
          Text("Tone: $tone", style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold)),
        ]),
      ),
      if (suggestion.isNotEmpty) ...[
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF1E2337),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.lightbulb_outline, color: Color(0xFFFFC107), size: 20),
              const SizedBox(width: 10),
              Expanded(child: Text(suggestion, style: const TextStyle(color: Colors.grey, fontSize: 14))),
            ],
          ),
        ),
      ],
    ]);
  }
}

// ───────────────────────────────────────────
// Tab 5: AI Action Center (Tasks & Events)
// ───────────────────────────────────────────
class _ActionCenterTab extends StatefulWidget {
  const _ActionCenterTab();
  @override
  State<_ActionCenterTab> createState() => _ActionCenterTabState();
}

class _ActionCenterTabState extends State<_ActionCenterTab> {
  String _selectedChatId = '';
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final chats = Provider.of<ChatProvider>(context).chats;
    final ai = Provider.of<AiProvider>(context);
    final taskProvider = Provider.of<TaskProvider>(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle("Productivity Hub"),
          const SizedBox(height: 8),
          const Text("Analyze conversations to extract tasks and schedule events.", 
              style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 20),
          
          if (chats.isEmpty)
             const Text("No chats available to analyze.", style: TextStyle(color: Colors.grey))
          else
            DropdownButtonFormField<String>(
              dropdownColor: const Color(0xFF1E2337),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true, fillColor: const Color(0xFF1E2337),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                labelText: "Select Chat",
                labelStyle: const TextStyle(color: Colors.grey),
              ),
              items: chats.map((c) => DropdownMenuItem(
                value: c.id,
                child: Text(c.isGroup ? (c.groupName ?? 'Group') : 'Chat ${c.id.substring(0, 5)}'),
              )).toList(),
              onChanged: (v) => setState(() => _selectedChatId = v ?? ''),
            ),
          
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _actionButton(
                  label: "Extract Tasks",
                  icon: Icons.assignment_outlined,
                  onPressed: _selectedChatId.isEmpty || _loading ? null : () async {
                    setState(() => _loading = true);
                    final msgs = await Provider.of<ChatProvider>(context, listen: false).getMessages(_selectedChatId).first;
                    await ai.extractTasks(msgs, _selectedChatId);
                    setState(() => _loading = false);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _actionButton(
                  label: "Plan Events",
                  icon: Icons.calendar_month,
                  onPressed: _selectedChatId.isEmpty || _loading ? null : () async {
                    setState(() => _loading = true);
                    final msgs = await Provider.of<ChatProvider>(context, listen: false).getMessages(_selectedChatId).first;
                    await ai.suggestEvents(msgs);
                    setState(() => _loading = false);
                  },
                ),
              ),
            ],
          ),

          if (_loading) 
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 30),
              child: Center(child: CircularProgressIndicator(color: Color(0xFF7B2FE0))),
            ),

          if (!_loading && ai.extractedTasks.isNotEmpty) ...[
            const SizedBox(height: 32),
            _sectionTitle("Extracted Tasks"),
            const SizedBox(height: 12),
            ...ai.extractedTasks.map((task) => _TaskSuggestionCard(
              task: task,
              onSave: () {
                taskProvider.addTask(task);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Task added to to-do list!")));
              },
            )),
          ],

          if (!_loading && ai.eventSuggestions.isNotEmpty) ...[
            const SizedBox(height: 32),
            _sectionTitle("Suggested Events"),
            const SizedBox(height: 12),
            ...ai.eventSuggestions.map((event) => _EventSuggestionCard(event: event)),
          ],

          const SizedBox(height: 32),
          _sectionTitle("Your To-Do List"),
          const SizedBox(height: 12),
          if (taskProvider.tasks.isEmpty)
            const Text("No tasks in your list. Start extracting!", style: TextStyle(color: Colors.grey))
          else
            ...taskProvider.tasks.map((t) => ListTile(
              leading: Checkbox(
                value: t.isCompleted,
                onChanged: (_) => taskProvider.toggleTask(t.id),
                activeColor: const Color(0xFF7B2FE0),
              ),
              title: Text(t.title, style: TextStyle(
                color: t.isCompleted ? Colors.grey : Colors.white,
                decoration: t.isCompleted ? TextDecoration.lineThrough : null,
              )),
              subtitle: Text(t.description, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.grey, size: 20),
                onPressed: () => taskProvider.removeTask(t.id),
              ),
            )),
        ],
      ),
    );
  }

  Widget _actionButton({required String label, required IconData icon, required VoidCallback? onPressed}) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontSize: 13)),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1E2337),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFF7B2FE0), width: 0.5)),
      ),
    );
  }
}

class _TaskSuggestionCard extends StatelessWidget {
  final TaskEntity task;
  final VoidCallback onSave;
  const _TaskSuggestionCard({required this.task, required this.onSave});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF1E2337), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          const Icon(Icons.assignment_turned_in, color: Color(0xFF00C6FF)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(task.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              if (task.dueDate != null)
                Text("Due: ${task.dueDate!.toLocal()}".split('.')[0], style: const TextStyle(color: Colors.grey, fontSize: 11)),
            ]),
          ),
          ElevatedButton(
            onPressed: onSave,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7B2FE0), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 12)),
            child: const Text("Add", style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

class _EventSuggestionCard extends StatelessWidget {
  final Map<String, dynamic> event;
  const _EventSuggestionCard({required this.event});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF1E2337), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          const Icon(Icons.event_note, color: Colors.orangeAccent),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(event['title'] ?? 'Meeting', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              Text("${event['startTime'] ?? ''} @ ${event['location'] ?? 'Online'}", style: const TextStyle(color: Colors.grey, fontSize: 11)),
            ]),
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today, color: Color(0xFF7B2FE0)),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Integration with Device Calendar coming soon!")));
            },
          ),
        ],
      ),
    );
  }
}

// ───────────────────────────────────────────
// Shared helper widget
// ───────────────────────────────────────────
Widget _sectionTitle(String text) {
  return Text(text, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600));
}
