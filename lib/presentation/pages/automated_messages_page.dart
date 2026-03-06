import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class AutomatedMessagesPage extends StatefulWidget {
  final String type; // 'greeting' or 'away'
  const AutomatedMessagesPage({super.key, required this.type});

  @override
  State<AutomatedMessagesPage> createState() => _AutomatedMessagesPageState();
}

class _AutomatedMessagesPageState extends State<AutomatedMessagesPage> {
  final _controller = TextEditingController();
  bool _isEnabled = false;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).userModel;
    if (user != null) {
      if (widget.type == 'greeting') {
        _controller.text = user.greetingMessage ?? '';
        _isEnabled = user.greetingMessage?.isNotEmpty == true;
      } else {
        _controller.text = user.awayMessage ?? '';
        _isEnabled = user.awayMessage?.isNotEmpty == true;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.type == 'greeting' ? "Greeting message" : "Away message";
    final helpText = widget.type == 'greeting' 
        ? "Greet customers when they message you for the first time or after 14 days of no activity."
        : "Automatically reply with a message when you're away.";

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text("SAVE", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: const Text("Send message"),
            value: _isEnabled,
            activeColor: const Color(0xFF00A884),
            onChanged: (val) => setState(() => _isEnabled = val),
          ),
          const Divider(),
          if (_isEnabled) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text("Message", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00A884))),
            ),
            TextField(
              controller: _controller,
              maxLines: 5,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Type your message here...",
              ),
            ),
            const SizedBox(height: 16),
            Text(helpText, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ],
        ],
      ),
    );
  }

  void _save() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final fieldName = widget.type == 'greeting' ? 'greetingMessage' : 'awayMessage';
    final pageTitle = widget.type == 'greeting' ? 'Greeting message' : 'Away message';
    await auth.updateBusinessProfile({
      fieldName: _isEnabled ? _controller.text : '',
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("$pageTitle updated!")),
      );
      Navigator.pop(context);
    }
  }
}
