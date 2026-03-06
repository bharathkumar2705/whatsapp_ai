import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';

class ViewOnceMediaPage extends StatefulWidget {
  final String chatId;
  final String messageId;
  final String mediaUrl;
  final String type;

  const ViewOnceMediaPage({
    super.key,
    required this.chatId,
    required this.messageId,
    required this.mediaUrl,
    required this.type,
  });

  @override
  State<ViewOnceMediaPage> createState() => _ViewOnceMediaPageState();
}

class _ViewOnceMediaPageState extends State<ViewOnceMediaPage> {
  @override
  void dispose() {
    // When the user leaves the page, mark the message as opened
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    chatProvider.markViewOnceAsOpened(widget.chatId, widget.messageId);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: widget.type == 'image'
            ? Image.network(
                widget.mediaUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const CircularProgressIndicator(color: Colors.white);
                },
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, color: Colors.white, size: 50),
              )
            : const Text("Video playback not implemented in this demo", style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
