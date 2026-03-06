import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../providers/secret_vault_provider.dart';
import '../widgets/user_avatar.dart';
import 'chat_room_page.dart';

class SecretVaultPage extends StatelessWidget {
  const SecretVaultPage({super.key});

  @override
  Widget build(BuildContext context) {
    final vault = context.watch<SecretVaultProvider>();
    final chatProvider = context.watch<ChatProvider>();
    
    final hiddenChats = chatProvider.chats.where((c) => vault.hiddenChatIds.contains(c.id)).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.lock_outline, color: Colors.blueAccent),
            SizedBox(width: 8),
            Text("Secret Vault"),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.visibility_off),
            onPressed: () {
              vault.toggleVisibility(false);
              Navigator.pop(context);
            },
          )
        ],
      ),
      body: hiddenChats.isEmpty 
          ? const Center(child: Text("No hidden chats yet."))
          : ListView.builder(
              itemCount: hiddenChats.length,
              itemBuilder: (context, index) {
                final chat = hiddenChats[index];
                // Note: Simplified for MVP. Reuse chat list tile logic if possible.
                return ListTile(
                  title: Text(chat.isGroup ? (chat.groupName ?? 'Group') : 'Private Chat'),
                  subtitle: Text(chat.lastMessage),
                  onLongPress: () => _showOptions(context, vault, chat.id),
                  onTap: () {
                    // Navigate to chat
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => ChatRoomPage(
                        chat: chat as dynamic, // Simplified
                        otherUserId: '', // Needs proper info
                        otherUserName: '',
                        otherUserImage: '',
                      ),
                    ));
                  },
                );
              },
            ),
    );
  }

  void _showOptions(BuildContext context, SecretVaultProvider vault, String chatId) {
    showModalBottomSheet(
      context: context,
      builder: (context) => ListTile(
        leading: const Icon(Icons.visibility),
        title: const Text("Unhide Chat"),
        onTap: () {
          vault.unhideChat(chatId);
          Navigator.pop(context);
        },
      ),
    );
  }
}
