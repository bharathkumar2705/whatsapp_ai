import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/ai_service.dart';
import '../../domain/entities/message_entity.dart';

import '../../domain/entities/task_entity.dart';
import 'package:uuid/uuid.dart';

class AiProvider extends ChangeNotifier {
  AiService? _aiService;
  List<String> _smartReplies = [];
  List<TaskEntity> _extractedTasks = [];
  List<Map<String, dynamic>> _eventSuggestions = [];
  Map<String, List<double>> _moodHistory = {}; // chatId -> list of scores
  Map<String, Map<String, dynamic>> _toxicityAlerts = {}; // messageId -> toxicityInfo
  Map<String, Map<String, dynamic>> _safetyAlerts = {}; // messageId -> safetyInfo (spam, fake news)
  bool _isAnalyzing = false;
  String _currentMoodEmoji = '😐';
  
  Map<String, dynamic>? _taskSuggestion; // Current real-time task suggestion
  Map<String, dynamic>? get taskSuggestion => _taskSuggestion;

  List<String> get smartReplies => _smartReplies;
  List<TaskEntity> get extractedTasks => _extractedTasks;
  List<Map<String, dynamic>> get eventSuggestions => _eventSuggestions;
  List<double> getMoodTrend(String chatId) => _moodHistory[chatId] ?? [];
  Map<String, dynamic>? getToxicityAlert(String messageId) => _toxicityAlerts[messageId];
  Map<String, dynamic>? getSafetyAlert(String messageId) => _safetyAlerts[messageId];
  bool get isAnalyzing => _isAnalyzing;
  String get currentMoodEmoji => _currentMoodEmoji;

  void init(String apiKey) {
    _aiService = AiService(apiKey: apiKey);
  }

  Future<void> runSafetyCheck(String text, String messageId) async {
    if (_aiService == null) return;
    
    // Check for fake news / misinformation
    final misinfo = await _aiService!.checkMisinformation(text);
    if (misinfo['isMisinformation'] == true) {
      _safetyAlerts[messageId] = misinfo;
    }

    // Check for links
    final urlRegex = RegExp(r'https?:\/\/[^\s]+');
    final match = urlRegex.firstMatch(text);
    if (match != null) {
      final url = match.group(0)!;
      final linkSafety = await _aiService!.analyzeLinkSafety(url);
      if (linkSafety['isSuspicious'] == true) {
        // Merge or replace safety alert
        final existing = _safetyAlerts[messageId] ?? {};
        _safetyAlerts[messageId] = {...existing, ...linkSafety};
      }
    }
    
    notifyListeners();
  }

  Future<void> fetchMoodTrend(List<MessageEntity> messages, String chatId) async {
    if (_aiService == null) return;
    _isAnalyzing = true;
    notifyListeners();
    try {
      final trend = await _aiService!.analyzeMoodTrend(messages);
      _moodHistory[chatId] = trend;
      
      // Update pulse emoji based on last score
      if (trend.isNotEmpty) {
        double last = trend.last;
        if (last > 80) _currentMoodEmoji = '🔥';
        else if (last > 65) _currentMoodEmoji = '😊';
        else if (last > 45) _currentMoodEmoji = '😐';
        else if (last > 30) _currentMoodEmoji = '😟';
        else _currentMoodEmoji = '😠';
      }
    } finally {
      _isAnalyzing = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> checkToxicity(String text, String messageId) async {
    if (_aiService == null) return {'isToxic': false};
    final res = await _aiService!.checkToxicity(text);
    if (res['isToxic'] == true) {
      _toxicityAlerts[messageId] = res;
      notifyListeners();
    }
    return res;
  }

  Future<void> fetchSmartReplies(List<MessageEntity> messages) async {
    if (_aiService == null) return;
    _isAnalyzing = true;
    notifyListeners();
    try {
      _smartReplies = await _aiService!.getSmartReplies(messages);
    } finally {
      _isAnalyzing = false;
      notifyListeners();
    }
  }

  Future<void> extractTasks(List<MessageEntity> messages, String chatId) async {
    if (_aiService == null) return;
    _isAnalyzing = true;
    notifyListeners();
    try {
      final rawTasks = await _aiService!.extractTasks(messages);
      _extractedTasks = rawTasks.map((t) => TaskEntity(
        id: const Uuid().v4(),
        title: t['title'] ?? 'Untitled Task',
        description: t['description'] ?? '',
        sourceChatId: chatId,
        createdAt: DateTime.now(),
        dueDate: t['dueDate'] != null ? DateTime.tryParse(t['dueDate']) : null,
      )).toList();
    } finally {
      _isAnalyzing = false;
      notifyListeners();
    }
  }

  Future<void> suggestEvents(List<MessageEntity> messages) async {
    if (_aiService == null) return;
    _isAnalyzing = true;
    notifyListeners();
    try {
      _eventSuggestions = await _aiService!.suggestCalendarEvents(messages);
    } finally {
      _isAnalyzing = false;
      notifyListeners();
    }
  }

  Future<String> summarizeActionItems(List<MessageEntity> messages) async {
    if (_aiService == null) return "AI Service not initialized.";
    return await _aiService!.summarizeActionItems(messages);
  }

  Future<String> generateMeetingMinutes(List<MessageEntity> messages) async {
    if (_aiService == null) return "AI Service not initialized.";
    return await _aiService!.generateMeetingMinutes(messages);
  }

  Future<String> generateProfessionalNotes(List<MessageEntity> messages) async {
    if (_aiService == null) return "AI Service not initialized.";
    return await _aiService!.generateProfessionalNotes(messages);
  }

  Future<String> summarizeChat(List<MessageEntity> messages) async {
    if (_aiService == null) return "AI Service not initialized.";
    return await _aiService!.summarizeConversation(messages);
  }

  Future<bool> checkSpam(String text) async {
    if (_aiService == null) return false;
    return await _aiService!.isSpam(text);
  }

  Future<String> translateMessage(String text, String targetLanguage) async {
    if (_aiService == null) return "AI Service not initialized.";
    return await _aiService!.translateText(text, targetLanguage);
  }

  // --- New AI Features ---

  Future<String> detectLanguage(String text) async {
    if (_aiService == null) return "Unknown";
    return await _aiService!.detectLanguage(text);
  }

  Future<Map<String, dynamic>> analyzeSentiment(List<MessageEntity> messages) async {
    if (_aiService == null) return {'sentiment': 'Neutral', 'emoji': '😐', 'description': 'AI not initialized.'};
    return await _aiService!.analyzeSentiment(messages);
  }

  Future<Map<String, dynamic>> checkTone(String draftMessage) async {
    if (_aiService == null) return {'tone': 'Casual', 'suggestion': ''};
    return await _aiService!.checkTone(draftMessage);
  }

  Future<String> chatWithAI(String message) async {
    if (_aiService == null) return "AI Service not initialized.";
    return await _aiService!.chatWithAI(message);
  }

  Future<void> autoScanTasks(String text) async {
    if (_aiService == null || text.trim().isEmpty) return;
    
    // Fast path: Only scan if it looks relevant
    final triggers = ['remind', 'task', 'do', 'submit', 'complete', 'send', 'call', 'meeting'];
    if (!triggers.any((t) => text.toLowerCase().contains(t))) {
      _taskSuggestion = null;
      notifyListeners();
      return;
    }

    final tasks = await _aiService!.extractTasks([
      MessageEntity(id: '', chatId: '', senderId: 'user', receiverId: 'bot', text: text, type: 'text', timestamp: DateTime.now(), status: 'sent', mediaUrl: '')
    ]);

    if (tasks.isNotEmpty) {
      _taskSuggestion = tasks.first;
    } else {
      _taskSuggestion = null;
    }
    notifyListeners();
  }

  void clearTaskSuggestion() {
    _taskSuggestion = null;
    notifyListeners();
  }

  void clearReplies() {
    _smartReplies = [];
    notifyListeners();
  }
}
