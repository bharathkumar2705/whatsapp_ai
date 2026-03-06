import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../domain/entities/user_entity.dart';
import '../../data/repositories/user_repository.dart';
import 'chat_room_page.dart';
import '../../data/models/chat_model.dart';
import '../providers/chat_provider.dart';
import '../providers/auth_provider.dart';
import 'package:provider/provider.dart';

class QrScannerPage extends StatefulWidget {
  const QrScannerPage({super.key});

  @override
  State<QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<QrScannerPage> {
  final UserRepository _userRepository = UserRepository();
  bool _isScanning = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Scan QR Code", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          MobileScanner(
            onDetect: (capture) async {
              if (!_isScanning) return;
              
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                final String? code = barcode.rawValue;
                if (code != null) {
                  setState(() => _isScanning = false);
                  _handleScan(code);
                  break;
                }
              }
            },
          ),
          // Scanner Overlay
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF25D366), width: 4),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF25D366).withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 10,
                  ),
                ],
              ),
            ),
          ),
          // Hint Text
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Text(
                  "Align QR code within the frame",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleScan(String code) async {
    // 0. Clean the code (remove whitespace, hidden characters)
    final trimmedCode = code.trim().replaceAll(RegExp(r'[\u200b-\u200d\uFEFF]'), '');
    String? uid;
    String? phone;

    debugPrint("QR Scanner: Scanned raw: '$code'");
    debugPrint("QR Scanner: Scanned cleaned: '$trimmedCode'");

    // 1. Parse based on protocol
    if (trimmedCode.startsWith("wa_ai://user/")) {
      uid = trimmedCode.replaceFirst("wa_ai://user/", "");
    } else if (trimmedCode.startsWith("wa_ai://phone/")) {
      phone = trimmedCode.replaceFirst("wa_ai://phone/", "");
    } else if (trimmedCode.length >= 20) {
      // Potentially a raw UID (Firebase UIDs are ~28 chars)
      uid = trimmedCode;
    } else {
      // Fallback: treat as phone number if it contains minimum digits
      final numericOnly = trimmedCode.replaceAll(RegExp(r'\D'), '');
      if (numericOnly.length >= 7) phone = trimmedCode;
    }

    UserEntity? otherUser;
    
    // 2. Try identifying by UID first
    if (uid != null && uid.isNotEmpty) {
      debugPrint("QR Scanner: Looking up UID: $uid");
      otherUser = await _userRepository.getUser(uid);
    }
    
    // 3. Try identifying by phone if UID failed or wasn't provided
    if (otherUser == null && phone != null && phone.isNotEmpty) {
      final normalizedPhone = phone.replaceAll(RegExp(r'\D'), '');
      debugPrint("QR Scanner: UID lookup failed. Trying phone lookup for: $phone (normalized: $normalizedPhone)");
      
      otherUser = await _userRepository.getUserByPhone(phone);
      if (otherUser == null && !phone.startsWith('+')) {
         otherUser = await _userRepository.getUserByPhone('+$phone');
      }
      // Final fallback search with normalized numeric string
      if (otherUser == null) {
         otherUser = await _userRepository.getUserByPhone('+$normalizedPhone');
      }
    }

    final userToChat = otherUser;
    if (userToChat != null) {
      debugPrint("QR Scanner: User found! ${userToChat.displayName}");
      final myUid = Provider.of<AuthProvider>(context, listen: false).user?.uid ?? "";
      final targetUid = userToChat.uid;
      
      if (myUid == targetUid) {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("You cannot start a chat with yourself via QR code."),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
            ),
          );
          setState(() => _isScanning = true);
        }
        return;
      }

      final chat = ChatModel(
        id: myUid.compareTo(targetUid) < 0 ? "${myUid}_$targetUid" : "${targetUid}_$myUid",
        participants: [myUid, targetUid],
        lastMessage: "",
        lastMessageTime: DateTime.now(),
        isArchived: false,
      );

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => ChatRoomPage(
              chat: chat,
              otherUserId: userToChat.uid,
              otherUserName: userToChat.displayName,
              otherUserImage: userToChat.photoUrl,
            ),
          ),
        );
      }
    } else {
      debugPrint("QR Scanner: No user found for scanned data.");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Invalid QR Code: '$trimmedCode'\nUser not found in database."),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: "RETRY",
              textColor: Colors.white,
              onPressed: () => setState(() => _isScanning = true),
            ),
          ),
        );
        setState(() => _isScanning = true);
      }
    }
  }
}
