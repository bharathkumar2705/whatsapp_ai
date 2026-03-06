import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/call_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/user_avatar.dart';
import 'agora_call_page.dart';

class CallsPage extends StatefulWidget {
  const CallsPage({super.key});

  @override
  State<CallsPage> createState() => _CallsPageState();
}

class _CallsPageState extends State<CallsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.user != null) {
        Provider.of<CallProvider>(context, listen: false).listenToCalls(authProvider.user!.uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final callProvider = Provider.of<CallProvider>(context);
    final myUid = Provider.of<AuthProvider>(context, listen: false).user?.uid;

    return Scaffold(
      body: callProvider.calls.isEmpty
          ? const Center(child: Text("No recent calls"))
          : ListView.builder(
              itemCount: callProvider.calls.length,
              itemBuilder: (context, index) {
                final call = callProvider.calls[index];
                if (index == 0) {
                  return Column(
                    children: [
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          child: const Icon(Icons.link, color: Colors.white),
                        ),
                        title: const Text("Create call link", style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: const Text("Share a link for your WhatsApp call"),
                        onTap: () => _showCreateLinkDialog(context),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Align(
                          alignment: Alignment.centerLeft,
                        child: Text("Recent", style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface.withAlpha(150))),
                        ),
                      ),
                      _buildCallTile(call, myUid),
                    ],
                  );
                }
                return _buildCallTile(call, myUid);
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showNewCallDialog(context),
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.add_call, color: Colors.white),
      ),
    );
  }

  void _showNewCallDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Call'),
        content: const Text('Enter a channel name (or chat ID) to start an Agora call.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AgoraCallPage(
                    channelName: 'test-channel',
                    calleeName: 'Group Call',
                    isVideo: true,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary),
            child: const Text('Start Video Call', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildCallTile(dynamic call, String? myUid) {
    final isOutgoing = call.callerId == myUid;
    final otherName = isOutgoing ? call.receiverName : call.callerName;
    final otherImage = isOutgoing ? call.receiverImage : call.callerImage;

    return ListTile(
      leading: UserAvatar(url: otherImage),
      title: Text(otherName),
      subtitle: Row(
        children: [
          Icon(
            isOutgoing ? Icons.call_made : Icons.call_received,
            size: 14,
            color: call.status == 'missed' ? Theme.of(context).colorScheme.error : Colors.green,
          ),
          const SizedBox(width: 4),
          Text(DateFormat('MMM dd, HH:mm').format(call.timestamp)),
        ],
      ),
      trailing: IconButton(
        icon: Icon(
          call.type == 'video' ? Icons.videocam : Icons.call,
          color: Theme.of(context).colorScheme.primary,
        ),
        tooltip: call.type == 'video' ? 'Video call back' : 'Call back',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AgoraCallPage(
                channelName: 'call_${call.callerId}_${call.receiverId}',
                calleeName: otherName,
                calleeImageUrl: otherImage,
                isVideo: call.type == 'video',
              ),
            ),
          );
        },
      ),
    );
  }

  void _showCreateLinkDialog(BuildContext context) {
    final roomId = DateTime.now().millisecondsSinceEpoch.toString();
    final link = "https://whatsapp-ai-ebb0a.web.app/call/$roomId";
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Call link"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Anyone with WhatsApp can use this link to join this call. Only share it with people you trust."),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.videocam, color: Theme.of(context).colorScheme.onSurface.withAlpha(150)),
              title: const Text("Call type"),
              subtitle: const Text("Video"),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(link, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: link));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Link copied to clipboard")));
            },
            child: const Text("COPY LINK"),
          ),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("DONE")),
        ],
      ),
    );
  }
}
