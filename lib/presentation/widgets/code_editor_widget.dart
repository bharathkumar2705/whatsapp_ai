import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/innovation_provider.dart';

class CodeEditorWidget extends StatefulWidget {
  final String chatId;
  final String messageId;
  final String initialContent;
  final String language;

  const CodeEditorWidget({
    super.key,
    required this.chatId,
    required this.messageId,
    required this.initialContent,
    required this.language,
  });

  @override
  State<CodeEditorWidget> createState() => _CodeEditorWidgetState();
}

class _CodeEditorWidgetState extends State<CodeEditorWidget> {
  late TextEditingController _controller;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialContent);
  }

  @override
  void didUpdateWidget(CodeEditorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialContent != oldWidget.initialContent && !_isEditing) {
      _controller.text = widget.initialContent;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    // Sync to other users
    context.read<InnovationProvider>().updateCodeContent(
      chatId: widget.chatId,
      messageId: widget.messageId,
      content: value,
      language: widget.language,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      constraints: const BoxConstraints(maxHeight: 400),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E), // VS Code Dark bg
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blueAccent.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                const Icon(Icons.code, color: Colors.blueAccent, size: 16),
                const SizedBox(width: 8),
                Text(
                  "Code Editor (${widget.language})",
                  style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                const Icon(Icons.sync, color: Colors.greenAccent, size: 14),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Focus(
                onFocusChange: (focused) {
                   setState(() => _isEditing = focused);
                },
                child: TextField(
                  controller: _controller,
                  maxLines: null,
                  onChanged: _onChanged,
                  style: const TextStyle(
                    color: Color(0xFFD4D4D4),
                    fontFamily: 'Courier', // Use a monospace font
                    fontSize: 13,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  cursorColor: Colors.blueAccent,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
