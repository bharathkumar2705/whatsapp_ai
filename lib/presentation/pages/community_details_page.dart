import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../../domain/entities/community_entity.dart';
import '../../domain/entities/chat_entity.dart';
import 'chat_room_page.dart';
import '../widgets/user_avatar.dart';
import '../../data/models/chat_model.dart';

class CommunityDetailsPage extends StatelessWidget {
  final CommunityEntity community;

  const CommunityDetailsPage({super.key, required this.community});

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(community.name),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: const Color(0xFF00A884).withOpacity(0.1),
                  child: Icon(_getIconData(community.icon), size: 40, color: const Color(0xFF00A884)),
                ),
                const SizedBox(height: 16),
                Text(community.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(community.description, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text("GROUPS IN THIS COMMUNITY", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
            ),
          ),
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, provider, child) {
                final communityGroups = provider.chats.where((c) => c.communityId == community.id).toList();
                
                if (communityGroups.isEmpty) {
                  return const Center(child: Text("No groups in this community yet."));
                }

                return ListView.builder(
                  itemCount: communityGroups.length,
                  itemBuilder: (context, index) {
                    final chat = communityGroups[index];
                    return ListTile(
                      leading: UserAvatar(url: chat.groupImage, radius: 20),
                      title: Text(chat.groupName ?? "Unnamed Group"),
                      subtitle: Text(chat.lastMessage),
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(
                          builder: (_) => ChatRoomPage(
                            chat: chat as ChatModel,
                            otherUserId: '',
                            otherUserName: chat.groupName ?? "Group",
                            otherUserImage: chat.groupImage ?? '',
                          ),
                        ));
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'school': return Icons.school;
      case 'computer': return Icons.computer;
      case 'assignment': return Icons.assignment;
      default: return Icons.groups;
    }
  }
}
