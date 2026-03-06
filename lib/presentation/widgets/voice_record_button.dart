import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

// STUB: record package removed to fix build incompatibility.
// Voice recording is temporarily disabled.

class VoiceRecordButton extends StatelessWidget {
  final Function(XFile) onRecordComplete;
  const VoiceRecordButton({super.key, required this.onRecordComplete});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Voice recording coming soon')),
        );
      },
      child: const CircleAvatar(
        backgroundColor: Color(0xFF075E54),
        child: Icon(Icons.mic_none, color: Colors.white),
      ),
    );
  }
}
