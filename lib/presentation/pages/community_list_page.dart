import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../../domain/entities/community_entity.dart';
import 'community_details_page.dart';
import 'create_community_page.dart';

class CommunityListPage extends StatelessWidget {
  const CommunityListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Communities"),
        actions: [
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      body: StreamBuilder<List<CommunityEntity>>(
        stream: context.read<ChatProvider>().getCommunities(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final communities = snapshot.data ?? [];
          if (communities.isEmpty) {
            return _buildEmptyState(context);
          }
          return ListView.builder(
            itemCount: communities.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Column(
                  children: [
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.groups, color: Color(0xFF00A884)),
                      ),
                      title: const Text("New Community", style: TextStyle(fontWeight: FontWeight.bold)),
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateCommunityPage()));
                      },
                    ),
                    const Divider(),
                  ],
                );
              }
              final community = communities[index - 1];
              return _buildCommunityItem(
                context,
                community: community,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.groups, color: Color(0xFF00A884)),
          ),
          title: const Text("New Community", style: TextStyle(fontWeight: FontWeight.bold)),
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateCommunityPage()));
          },
        ),
        const Divider(),
        const Expanded(
          child: Center(
            child: Text("No communities found.", style: TextStyle(color: Colors.grey)),
          ),
        ),
      ],
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

  Widget _buildCommunityItem(BuildContext context, {required CommunityEntity community}) {
    return Column(
      children: [
        ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF00A884).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_getIconData(community.icon), color: const Color(0xFF00A884)),
          ),
          title: Text(community.name, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(community.description),
          onTap: () {
            Navigator.push(context, MaterialPageRoute(
              builder: (_) => CommunityDetailsPage(community: community),
            ));
          },
        ),
        Padding(
          padding: const EdgeInsets.only(left: 72),
          child: ListTile(
            leading: const Icon(Icons.announcement, color: Color(0xFF00A884), size: 20),
            title: const Text("Announcements", style: TextStyle(fontSize: 14)),
            trailing: community.unreadCount > 0 ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF25D366),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text("${community.unreadCount}", style: const TextStyle(color: Colors.white, fontSize: 10)),
            ) : null,
            onTap: () {},
          ),
        ),
        const Divider(),
      ],
    );
  }
}
