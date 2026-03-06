import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/chat_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/user_avatar.dart';
import 'chat_room_page.dart';
import '../../data/models/chat_model.dart';

class ArchivedChatsPage extends StatelessWidget {
  const ArchivedChatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final archivedChats = chatProvider.chats.where((c) => c.isArchived).toList();

    return Scaffold(
      appBar: AppBar(title: const Text("Archived Chats")),
      body: archivedChats.isEmpty
          ? const Center(child: Text("No archived chats"))
          : ListView.builder(
              itemCount: archivedChats.length,
              itemBuilder: (context, index) {
                final chat = archivedChats[index];
                String title;
                String? imageUrl;
                String otherParticipantId = '';

                if (chat.isGroup) {
                  title = chat.groupName ?? 'Group';
                  imageUrl = chat.groupImage;
                } else {
                  otherParticipantId = chat.participants.firstWhere((id) => id != authProvider.user?.uid);
                  title = "User $otherParticipantId";
                }

                return Dismissible(
                  key: Key(chat.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: const Color(0xFF075E54),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.unarchive, color: Colors.white),
                  ),
                  onDismissed: (_) {
                    chatProvider.toggleArchiveChat(chat.id, false);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Chat unarchived")));
                  },
                  child: ListTile(
                    leading: UserAvatar(url: imageUrl),
                    title: Text(title),
                    subtitle: Text(chat.lastMessage, maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: Text(DateFormat('HH:mm').format(chat.lastMessageTime)),
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => ChatRoomPage(
                          chat: chat as ChatModel, 
                          otherUserId: otherParticipantId,
                          otherUserName: title,
                          otherUserImage: imageUrl ?? '',
                        ),
                      ));
                    },
                  ),
                );
              },
            ),
    );
  }
}
