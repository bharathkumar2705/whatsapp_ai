import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class QuickRepliesManagerPage extends StatelessWidget {
  const QuickRepliesManagerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Quick replies"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddReplyDialog(context),
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: auth.getQuickReplies(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final replies = snapshot.data!;
          if (replies.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.flash_on, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text("No quick replies", style: TextStyle(color: Colors.grey)),
                  Text("Create shortcuts for frequent messages"),
                ],
              ),
            );
          }
          return ListView.builder(
            itemCount: replies.length,
            itemBuilder: (context, index) {
              final reply = replies[index];
              return ListTile(
                leading: const Icon(Icons.flash_on, color: Color(0xFF00A884)),
                title: Text("/${reply['shortcut']}"),
                subtitle: Text(reply['message'], maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => auth.deleteQuickReply(reply['id']),
                ),
                onTap: () => _showAddReplyDialog(context, reply: reply),
              );
            },
          );
        },
      ),
    );
  }

  void _showAddReplyDialog(BuildContext context, {Map<String, dynamic>? reply}) {
    final shortcutController = TextEditingController(text: reply?['shortcut']);
    final messageController = TextEditingController(text: reply?['message']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(reply == null ? "Add Quick Reply" : "Edit Quick Reply"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: shortcutController,
              decoration: const InputDecoration(labelText: "Shortcut", prefixText: "/"),
            ),
            TextField(
              controller: messageController,
              decoration: const InputDecoration(labelText: "Message"),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
          TextButton(
            onPressed: () {
              final auth = Provider.of<AuthProvider>(context, listen: false);
              final data = {
                'shortcut': shortcutController.text,
                'message': messageController.text,
              };
              if (reply == null) {
                auth.addQuickReply(data);
              } else {
                auth.updateQuickReply(reply['id'], data);
              }
              Navigator.pop(context);
            },
            child: const Text("SAVE"),
          ),
        ],
      ),
    );
  }
}
