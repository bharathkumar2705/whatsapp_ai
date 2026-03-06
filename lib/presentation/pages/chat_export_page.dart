import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/chat_provider.dart';
import '../../domain/entities/chat_entity.dart';

class ChatExportPage extends StatefulWidget {
  final ChatEntity chat;
  final String chatName;

  const ChatExportPage({super.key, required this.chat, required this.chatName});

  @override
  State<ChatExportPage> createState() => _ChatExportPageState();
}

class _ChatExportPageState extends State<ChatExportPage> {
  bool _includeMedia = false;
  bool _exporting = false;
  String? _preview;

  @override
  void initState() {
    super.initState();
    _generatePreview();
  }

  Future<void> _generatePreview() async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final messages = await chatProvider.getMessagesOnce(widget.chat.id);
    final buf = StringBuffer();
    buf.writeln("WhatsApp Chat Export — ${widget.chatName}");
    buf.writeln("Exported: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}");
    buf.writeln("─" * 40);
    for (final msg in messages) {
      final time = DateFormat('dd/MM/yyyy, HH:mm').format(msg.timestamp);
      if (msg.type == 'text') {
        buf.writeln("[$time] ${msg.senderId}: ${msg.text}");
      } else if (_includeMedia && msg.mediaUrl.isNotEmpty) {
        buf.writeln("[$time] ${msg.senderId}: <${msg.type.toUpperCase()}> ${msg.mediaUrl}");
      } else {
        buf.writeln("[$time] ${msg.senderId}: <${msg.type.toUpperCase()} omitted>");
      }
    }
    setState(() => _preview = buf.toString());
  }

  Future<void> _export() async {
    setState(() => _exporting = true);
    await _generatePreview();
    if (_preview != null) {
      await Clipboard.setData(ClipboardData(text: _preview!));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Chat exported to clipboard!")),
        );
      }
    }
    setState(() => _exporting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Export — ${widget.chatName}"),
        actions: [
          if (_exporting)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            IconButton(
              icon: const Icon(Icons.copy),
              tooltip: "Copy to clipboard",
              onPressed: _export,
            ),
        ],
      ),
      body: Column(
        children: [
          // Options
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF00A884).withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF00A884).withOpacity(0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Export options", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text("Include media links"),
                  subtitle: const Text("Attach media URLs in the transcript"),
                  value: _includeMedia,
                  onChanged: (v) {
                    setState(() => _includeMedia = v);
                    _generatePreview();
                  },
                ),
              ],
            ),
          ),

          // Preview
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text("Preview", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00A884))),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _preview == null
                ? const Center(child: CircularProgressIndicator())
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          _preview!,
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                        ),
                      ),
                    ),
                  ),
          ),

          // Export button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.ios_share, color: Colors.white),
                label: const Text("Export to clipboard", style: TextStyle(color: Colors.white)),
                onPressed: _exporting ? null : _export,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00A884),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
