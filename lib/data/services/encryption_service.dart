import 'dart:convert';
import 'package:flutter/foundation.dart';

class EncryptionService {
  // Simple Caesar-like XOR cipher for demo/simulation purposes.
  // In a production app, use 'encrypt' package with AES-256.
  static const String _key = "WHATSAPP_AI_DEMO_KEY";

  static String encryptMessage(String plainText) {
    if (plainText.isEmpty) return plainText;
    
    // Prefix to identify encrypted messages in the demo
    final bytes = utf8.encode(plainText);
    final encrypted = List<int>.generate(bytes.length, (i) {
      return bytes[i] ^ _key.codeUnitAt(i % _key.length);
    });
    
    return "E2EE:${base64Url.encode(encrypted)}";
  }

  static String decryptMessage(String cipherText) {
    if (!cipherText.startsWith("E2EE:")) return cipherText; // Not encrypted
    
    try {
      final base64Part = cipherText.substring(5);
      final bytes = base64Url.decode(base64Part);
      final decrypted = List<int>.generate(bytes.length, (i) {
        return bytes[i] ^ _key.codeUnitAt(i % _key.length);
      });
      return utf8.decode(decrypted);
    } catch (e) {
      debugPrint("EncryptionService: Decryption failed: $e");
      return "[Decryption Error]";
    }
  }
}
