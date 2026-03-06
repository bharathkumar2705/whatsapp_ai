import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class VoiceAssistantService {
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  late GenerativeModel _model;

  void init(String apiKey) {
    _model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);
  }

  Future<bool> initializeSpeech() async {
    return await _speechToText.initialize();
  }

  Future<void> startListening(Function(String) onResult) async {
    await _speechToText.listen(onResult: (result) {
      if (result.finalResult) {
        onResult(result.recognizedWords);
      }
    });
  }

  Future<void> stopListening() async {
    await _speechToText.stop();
  }

  Future<void> processVoiceCommand(String command, Function(String) onResponse) async {
    // Basic command parsing
    if (command.toLowerCase().contains("hello")) {
      await speak("Hello! How can I help you today?");
      onResponse("Hello! How can I help you today?");
      return;
    }

    // AI Processing
    try {
      final content = [Content.text("User said: $command. Respond concisely as a helpful WhatsApp AI assistant.")];
      final response = await _model.generateContent(content);
      final responseText = response.text ?? "I'm not sure how to help with that.";
      
      await speak(responseText);
      onResponse(responseText);
    } catch (e) {
      print("Voice Assistant Error: $e");
      await speak("Sorry, I encountered an error processing your request.");
    }
  }

  Future<void> speak(String text) async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setPitch(1.0);
    await _flutterTts.speak(text);
  }
}
