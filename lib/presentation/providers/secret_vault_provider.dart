import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecretVaultProvider extends ChangeNotifier {
  bool _isVisible = false;
  List<String> _hiddenChatIds = [];

  bool get isVisible => _isVisible;
  List<String> get hiddenChatIds => _hiddenChatIds;

  SecretVaultProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _hiddenChatIds = prefs.getStringList('hidden_chats') ?? [];
    notifyListeners();
  }

  Future<void> toggleVisibility(bool visible) async {
    _isVisible = visible;
    notifyListeners();
  }

  Future<void> hideChat(String chatId) async {
    if (!_hiddenChatIds.contains(chatId)) {
      _hiddenChatIds.add(chatId);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('hidden_chats', _hiddenChatIds);
      notifyListeners();
    }
  }

  Future<void> unhideChat(String chatId) async {
    if (_hiddenChatIds.contains(chatId)) {
      _hiddenChatIds.remove(chatId);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('hidden_chats', _hiddenChatIds);
      notifyListeners();
    }
  }
}
