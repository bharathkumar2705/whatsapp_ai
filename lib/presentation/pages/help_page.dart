import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Help")),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text("Help Center"),
            subtitle: const Text("Find answers to common questions"),
            onTap: () => _showFaq(context),
          ),
          ListTile(
            leading: const Icon(Icons.contact_support_outlined),
            title: const Text("Contact us"),
            subtitle: const Text("Report a problem or ask a question"),
            onTap: () {
              Clipboard.setData(const ClipboardData(text: "support@whatsapp-ai.com"));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Support email copied: support@whatsapp-ai.com")),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text("Privacy Policy"),
            onTap: () => _showPrivacyPolicy(context),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text("Terms of Service"),
            onTap: () => _showTerms(context),
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text("App version"),
            subtitle: Text("WhatsApp AI v1.0.0"),
          ),
        ],
      ),
    );
  }

  void _showFaq(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Frequently Asked Questions"),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text("Q: How do I send a message?", style: TextStyle(fontWeight: FontWeight.bold)),
              Text("A: Open a chat from your contact list, type in the message box at the bottom and tap Send.\n"),
              Text("Q: How do I send an image?", style: TextStyle(fontWeight: FontWeight.bold)),
              Text("A: Tap the 📎 attachment icon in the chat, then select 'Image' from your gallery.\n"),
              Text("Q: How do I post a Status?", style: TextStyle(fontWeight: FontWeight.bold)),
              Text("A: Go to the Status tab and tap the camera/edit button.\n"),
            ],
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("CLOSE"))],
      ),
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Privacy Policy"),
        content: const SingleChildScrollView(
          child: Text(
            "WhatsApp AI is committed to protecting your privacy.\n\n"
            "• We collect only the data necessary to provide the service.\n"
            "• Your messages are stored securely on Firebase.\n"
            "• We do not sell or share your data with third parties.\n"
            "• You may request deletion of your data at any time.\n\n"
            "For more information, please contact us.",
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))],
      ),
    );
  }

  void _showTerms(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Terms of Service"),
        content: const SingleChildScrollView(
          child: Text(
            "By using WhatsApp AI, you agree to:\n\n"
            "• Use the service in compliance with all laws.\n"
            "• Not use the service for spam or harmful activities.\n"
            "• Respect other users' privacy.\n"
            "• Accept that service may change or be discontinued.\n\n"
            "These terms are subject to change at any time.",
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))],
      ),
    );
  }
}
