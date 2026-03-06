import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../domain/entities/message_entity.dart';

class AiService {
  final String apiKey;
  late final GenerativeModel _model;
  late final ChatSession _chatSession;

  AiService({required this.apiKey}) {
    _model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: apiKey);
    _chatSession = _model.startChat();
  }

  Future<List<String>> getSmartReplies(List<MessageEntity> recentMessages) async {
    if (recentMessages.isEmpty) return [];

    final context = recentMessages.reversed
        .map((m) => "${m.senderId == recentMessages.first.senderId ? 'Other' : 'Me'}: ${m.text}")
        .toList()
        .join("\n");

    final prompt = """
    Based on the following conversation context in a WhatsApp-style chat, suggest 3 short, natural, and friendly replies for 'Me'.
    Context:
    $context
    
    Return only the 3 suggestions, one per line, no numbering, no extra text.
    """;

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      final text = response.text ?? '';
      return text.split('\n').where((s) => s.trim().isNotEmpty).take(3).toList();
    } catch (e) {
      return [];
    }
  }

  Future<String> summarizeConversation(List<MessageEntity> messages) async {
    if (messages.isEmpty) return "No messages to summarize.";

    final context = messages.reversed
        .map((m) => "${m.senderId}: ${m.text}")
        .join("\n");

    final prompt = """
    Summarize the following chat conversation history into a concise bulleted list of key points.
    Conversation:
    $context
    """;

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text ?? "Could not generate summary.";
    } catch (e) {
      return "Error generating summary.";
    }
  }

  Future<bool> isSpam(String message) async {
    final prompt = "Analyze if the following message is spam, phishing, or highly suspicious. Return only 'YES' or 'NO'.\nMessage: $message";
    
    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text?.trim().toUpperCase() == 'YES';
    } catch (e) {
      return false;
    }
  }

  Future<String> translateText(String text, String targetLanguage) async {
    final prompt = "Translate the following text to $targetLanguage. Return only the translated text, no extra explanation.\nText: $text";
    
    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text ?? "Translation failed.";
    } catch (e) {
      return "Translation error: $e";
    }
  }

  /// NEW: Detect the language of a message
  Future<String> detectLanguage(String text) async {
    final prompt = "Identify the language of the following text. Return only the language name (e.g., 'English', 'Spanish', 'Hindi'). Text: $text";
    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text?.trim() ?? "Unknown";
    } catch (e) {
      return "Unknown";
    }
  }

  /// NEW: Analyze the emotional sentiment of a conversation
  Future<Map<String, dynamic>> analyzeSentiment(List<MessageEntity> messages) async {
    if (messages.isEmpty) return {'sentiment': 'Neutral', 'emoji': '😐', 'description': 'No messages to analyze.'};

    final context = messages.take(10).map((m) => m.text).join(" | ");
    final prompt = "Analyze the overall emotional tone of this conversation snippet. "
        "Return a JSON object with three fields: 'sentiment' (one of: Happy, Neutral, Serious, Angry, Sad, Excited), "
        "'emoji' (a single relevant emoji), and 'description' (one short sentence). "
        "Respond with ONLY valid JSON, no markdown. Conversation: $context";

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      final text = response.text?.trim() ?? '{}';
      // Parse simple JSON manually to avoid adding a JSON dependency
      final sentiment = _extractJsonField(text, 'sentiment') ?? 'Neutral';
      final emoji = _extractJsonField(text, 'emoji') ?? '😐';
      final description = _extractJsonField(text, 'description') ?? '';
      return {'sentiment': sentiment, 'emoji': emoji, 'description': description};
    } catch (e) {
      return {'sentiment': 'Neutral', 'emoji': '😐', 'description': 'Could not analyze sentiment.'};
    }
  }

  /// NEW: Check the tone of a draft message before sending
  Future<Map<String, dynamic>> checkTone(String draftMessage) async {
    final prompt = "Analyze the tone of this message: \"$draftMessage\". "
        "Return a JSON object with 'tone' (one of: Friendly, Formal, Casual, Aggressive, Sarcastic, Nervous) "
        "and 'suggestion' (a one-sentence advice on how to improve it). "
        "Respond with ONLY valid JSON, no markdown.";

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      final text = response.text?.trim() ?? '{}';
      final tone = _extractJsonField(text, 'tone') ?? 'Casual';
      final suggestion = _extractJsonField(text, 'suggestion') ?? '';
      return {'tone': tone, 'suggestion': suggestion};
    } catch (e) {
      return {'tone': 'Casual', 'suggestion': ''};
    }
  }

  /// Direct chat with Gemini AI (for the AI Chatbot feature)
  Future<String> chatWithAI(String userMessage) async {
    try {
      final response = await _chatSession.sendMessage(Content.text(userMessage));
      return response.text ?? "I couldn't generate a response.";
    } catch (e) {
      return "Error: $e";
    }
  }

  /// NEW: Extract tasks/to-dos from conversation
  Future<List<Map<String, dynamic>>> extractTasks(List<MessageEntity> messages) async {
    if (messages.isEmpty) return [];

    final context = messages.reversed.take(15).map((m) => "${m.senderId}: ${m.text}").join("\n");
    final prompt = """
    Extract actionable tasks from this WhatsApp conversation. 
    Return a JSON array of objects. Each object must have:
    'title' (short name of task), 'description' (optional detail), 'dueDate' (ISO format if mention, else null).
    Respond with ONLY valid JSON, no markdown. 
    Conversation:
    $context
    """;

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      final text = response.text?.trim() ?? '[]';
      // Simple manual regex for JSON array of objects if standard parsing isn't imported
      // For this implementation, we expect a clean JSON array string.
      return _parseJsonArray(text);
    } catch (e) {
      return [];
    }
  }

  /// NEW: Suggest calendar events from conversation
  Future<List<Map<String, dynamic>>> suggestCalendarEvents(List<MessageEntity> messages) async {
    if (messages.isEmpty) return [];

    final context = messages.reversed.take(15).map((m) => "${m.senderId}: ${m.text}").join("\n");
    final prompt = """
    Identify potential meetings or events to schedule from this chat.
    Return a JSON array of objects. Each object must have:
    'title' (event name), 'startTime' (ISO format), 'location' (if mentioned).
    Respond with ONLY valid JSON, no markdown.
    Conversation:
    $context
    """;

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      return _parseJsonArray(response.text?.trim() ?? '[]');
    } catch (e) {
      return [];
    }
  }

  /// NEW: Summarize specifically for Action Items
  Future<String> summarizeActionItems(List<MessageEntity> messages) async {
    if (messages.isEmpty) return "No messages.";

    final context = messages.reversed.take(20).map((m) => "${m.senderId}: ${m.text}").join("\n");
    final prompt = "Read this chat and list only the pending action items and decisions made in bullet points. Be very concise.\n$context";

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text ?? "No action items identified.";
    } catch (e) {
      return "Error identifying action items.";
    }
  }

  /// NEW: Generate formatted Meeting Minutes
  Future<String> generateMeetingMinutes(List<MessageEntity> messages) async {
    if (messages.isEmpty) return "No data.";
    final context = messages.reversed.take(30).map((m) => "${m.senderId}: ${m.text}").join("\n");
    final prompt = """
    Convert this chat transcript into professional Meeting Minutes.
    Include these sections:
    1. Meeting Summary (Brief overview)
    2. Attendees (List of unique sender names)
    3. Key Decisions (Bulleted list)
    4. Action Items (Bulleted list with assignees if mentioned)
    5. Next Steps
    
    Transcript:
    $context
    """;

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text ?? "Could not generate minutes.";
    } catch (e) {
      return "Error generating minutes.";
    }
  }

  /// NEW: Generate structured Study/Work Notes
  Future<String> generateProfessionalNotes(List<MessageEntity> messages) async {
    if (messages.isEmpty) return "No data.";
    final context = messages.reversed.take(30).map((m) => "${m.senderId}: ${m.text}").join("\n");
    final prompt = """
    Transform this conversation into structured Study or Professional Notes.
    Format it with clear headings, bolded key terms, and organized concepts.
    Focus on informational content and explanations shared in the chat.
    
    Chat:
    $context
    """;

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text ?? "Could not generate notes.";
    } catch (e) {
      return "Error generating notes.";
    }
  }

  /// Helper to parse a JSON array string into List<Map>
  Future<Map<String, dynamic>> checkMisinformation(String text) async {
    final prompt = """
    Analyze if the following text contains potential misinformation, fake news, or sensationalized untruths.
    Look for: 
    - Factual inconsistencies
    - Lack of sources
    - Emotional manipulation
    - Sensational headlines vs content
    Return a JSON object with: 
    'isMisinformation' (boolean), 
    'confidence' (0-100), 
    'reason' (short string), 
    'severity' (Low, Medium, High).
    Respond with ONLY valid JSON, no markdown. 
    Text: $text
    """;

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      final resText = response.text?.trim() ?? '{}';
      final cleaned = resText.replaceAll('```json', '').replaceAll('```', '').trim();
      final decoded = jsonDecode(cleaned);
      return Map<String, dynamic>.from(decoded);
    } catch (e) {
      return {'isMisinformation': false, 'confidence': 0, 'reason': '', 'severity': 'Low'};
    }
  }

  Future<Map<String, dynamic>> analyzeLinkSafety(String url) async {
    final prompt = """
    Analyze if the following URL is suspicious, a known phishing attempt, or a malicious redirect.
    URL: $url
    Return a JSON object with: 
    'isSuspicious' (boolean), 
    'riskLevel' (Low, Medium, High), 
    'type' (Phishing, Spam, Safe, etc.),
    'warning' (short user-facing warning).
    Respond with ONLY valid JSON, no markdown. 
    """;

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      final resText = response.text?.trim() ?? '{}';
      final cleaned = resText.replaceAll('```json', '').replaceAll('```', '').trim();
      final decoded = jsonDecode(cleaned);
      return Map<String, dynamic>.from(decoded);
    } catch (e) {
      return {'isSuspicious': false, 'riskLevel': 'Low', 'type': 'Unknown', 'warning': ''};
    }
  }

  List<Map<String, dynamic>> _parseJsonArray(String jsonStr) {
    // Clean up markdown if AI ignored the 'no markdown' instruction
    String cleaned = jsonStr.replaceAll('```json', '').replaceAll('```', '').trim();
    if (!cleaned.startsWith('[')) {
      // Try to find the first '[' and last ']'
      final start = cleaned.indexOf('[');
      final end = cleaned.lastIndexOf(']');
      if (start != -1 && end != -1 && end > start) {
        cleaned = cleaned.substring(start, end + 1);
      } else {
        return [];
      }
    }
    
    try {
      final decoded = jsonDecode(cleaned);
      if (decoded is List) {
        return List<Map<String, dynamic>>.from(decoded);
      }
      return [];
    } catch (e) {
      debugPrint("JSON Parse Error: $e");
      return [];
    }
  }

  /// Helper to extract a field from a simple JSON string
  String? _extractJsonField(String json, String field) {
    final pattern = RegExp('"$field"\\s*:\\s*"([^"]*)"');
    final match = pattern.firstMatch(json);
    return match?.group(1);
  }

  /// NEW: Analyze mood trend for graphing
  Future<List<double>> analyzeMoodTrend(List<MessageEntity> messages) async {
    if (messages.isEmpty) return [];

    final context = messages.reversed.take(20).map((m) => m.text).join(" | ");
    final prompt = """
    Analyze the emotional journey of this conversation. 
    Break it into 5 chronological segments. 
    For each segment, assign a 'Mood Score' from 0 (very angry/sad) to 100 (very happy/excited). 
    Neutral is 50.
    Return ONLY a JSON array of 5 numbers, e.g., [50, 70, 40, 60, 80].
    No markdown, no text.
    Conversation: $context
    """;

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      final text = response.text?.trim() ?? '[50, 50, 50, 50, 50]';
      final cleaned = text.replaceAll('```json', '').replaceAll('```', '').trim();
      final decoded = jsonDecode(cleaned);
      if (decoded is List) {
        return decoded.map((e) => (e as num).toDouble()).toList();
      }
      return [50, 50, 50, 50, 50];
    } catch (e) {
      return [50, 50, 50, 50, 50];
    }
  }

  /// NEW: Check if a message is toxic
  Future<Map<String, dynamic>> checkToxicity(String text) async {
    final prompt = """
    Analyze if the following message is toxic (hateful, aggressive, harassing, or harmful).
    Return a JSON object with: 
    'isToxic' (boolean), 
    'reason' (short string), 
    'severity' (string: Low, Medium, High).
    Respond with ONLY valid JSON, no markdown. 
    Message: $text
    """;

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      final resText = response.text?.trim() ?? '{}';
      final cleaned = resText.replaceAll('```json', '').replaceAll('```', '').trim();
      final decoded = jsonDecode(cleaned);
      return Map<String, dynamic>.from(decoded);
    } catch (e) {
      return {'isToxic': false, 'reason': '', 'severity': 'Low'};
    }
  }
}
