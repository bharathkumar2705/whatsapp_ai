import 'package:flutter/material.dart';
// Note: This is a mockup/logic shell for flutter_nearby_connections
// In a real environment, you would add the package to pubspec.yaml

class OfflineMessagingPage extends StatefulWidget {
  const OfflineMessagingPage({super.key});

  @override
  State<OfflineMessagingPage> createState() => _OfflineMessagingPageState();
}

class _OfflineMessagingPageState extends State<OfflineMessagingPage> {
  bool _isBroadcasting = false;
  List<String> _foundDevices = ["Device-A (Nearby)", "Device-B (Nearby)"];
  List<Map<String, dynamic>> _messages = [];
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Offline P2P Messaging"),
        backgroundColor: Colors.blueGrey[800],
        actions: [
          Switch(
            value: _isBroadcasting,
            onChanged: (val) => setState(() => _isBroadcasting = val),
            activeColor: Colors.blueAccent,
          )
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.blueGrey[900],
            child: Row(
              children: [
                const Icon(Icons.bluetooth, color: Colors.blueAccent),
                const SizedBox(width: 8),
                Text(
                  _isBroadcasting ? "Broadcasting... Nearby devices can find you." : "Offline. Enable Bluetooth to start.",
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          if (_isBroadcasting) ...[
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text("FOUND DEVICES", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
            ),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _foundDevices.length,
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: ActionChip(
                    avatar: const Icon(Icons.devices, size: 16),
                    label: Text(_foundDevices[index]),
                    onPressed: () => _connectToDevice(_foundDevices[index]),
                  ),
                ),
              ),
            ),
          ],
          const Divider(),
          Expanded(
            child: _messages.isEmpty 
                ? const Center(child: Text("No offline messages yet."))
                : ListView.builder(
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final m = _messages[index];
                      return ListTile(
                        leading: Icon(m['isMe'] ? Icons.call_made : Icons.call_received, size: 16),
                        title: Text(m['text']),
                        subtitle: Text(m['from']),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: "Send offline message...",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blueAccent),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _connectToDevice(String device) {
     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Connecting to $device...")));
  }

  void _sendMessage() {
    if (_controller.text.trim().isEmpty) return;
    setState(() {
      _messages.add({
        'text': _controller.text.trim(),
        'from': 'You',
        'isMe': true,
      });
      _controller.clear();
    });
  }
}
