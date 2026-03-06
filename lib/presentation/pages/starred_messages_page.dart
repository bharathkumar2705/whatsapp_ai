import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../widgets/chat_bubble.dart';
import '../../domain/entities/message_entity.dart';

class StarredMessagesPage extends StatelessWidget {
  const StarredMessagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    
    // In a real app, you might want a specific stream for all starred messages
    // but here we can just fetch messages from active chats and filter (simplified)
    
    return Scaffold(
      appBar: AppBar(title: const Text("Starred Messages")),
      body: FutureBuilder<List<MessageEntity>>(
        future: _fetchStarredMessages(chatProvider),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final messages = snapshot.data!;
          if (messages.isEmpty) return const Center(child: Text("No starred messages yet."));

          return ListView.builder(
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final message = messages[index];
              return ChatBubble(
                text: message.text,
                isMe: false, // Simplified
                timestamp: message.timestamp,
                isStarred: true,
                type: message.type,
                mediaUrl: message.mediaUrl,
              );
            },
          );
        },
      ),
    );
  }

  Future<List<MessageEntity>> _fetchStarredMessages(ChatProvider chatProvider) async {
    // This is a placeholder implementation. 
    // Ideally, Firestore would have a query for this across all chats.
    return []; 
  }
}
