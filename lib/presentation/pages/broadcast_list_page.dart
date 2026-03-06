import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/chat_provider.dart';
import '../../domain/entities/broadcast_entity.dart';

class BroadcastListPage extends StatelessWidget {
  const BroadcastListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Broadcast lists"),
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text("Edit", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              "Only contacts with your number in their address book will receive your broadcast messages.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54, fontSize: 13),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: StreamBuilder<List<BroadcastEntity>>(
              stream: context.read<ChatProvider>().getBroadcastLists(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final lists = snapshot.data ?? [];
                if (lists.isEmpty) {
                  return const Center(
                    child: Text("No broadcast lists found.", style: TextStyle(color: Colors.grey)),
                  );
                }
                return ListView.builder(
                  itemCount: lists.length,
                  itemBuilder: (context, index) {
                    final list = lists[index];
                    return _buildBroadcastItem(
                      name: list.name,
                      recipients: "${list.recipientCount} recipients",
                      time: _formatDate(list.lastActive),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            child: TextButton(
              onPressed: () {},
              child: const Text(
                "New List",
                style: TextStyle(color: Color(0xFF00A884), fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (now.day == date.day && now.month == date.month && now.year == date.year) {
      return DateFormat('HH:mm').format(date);
    }
    return DateFormat('MMM d').format(date);
  }

  Widget _buildBroadcastItem({required String name, required String recipients, required String time}) {
    return Column(
      children: [
        ListTile(
          leading: const CircleAvatar(
            backgroundColor: Color(0xFF075E54),
            child: Icon(Icons.campaign, color: Colors.white, size: 20),
          ),
          title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(recipients),
          trailing: Text(time, style: const TextStyle(color: Colors.black45, fontSize: 12)),
          onTap: () {},
        ),
        const Divider(indent: 70, height: 1),
      ],
    );
  }
}
