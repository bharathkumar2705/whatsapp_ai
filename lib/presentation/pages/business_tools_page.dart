import 'package:flutter/material.dart';
import 'business_profile_page.dart';
import 'catalog_manager_page.dart';
import 'automated_messages_page.dart';
import 'quick_replies_manager_page.dart';
import 'labels_manager_page.dart';

class BusinessToolsPage extends StatelessWidget {
  const BusinessToolsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Business tools"),
      ),
      body: ListView(
        children: [
          _buildToolTile(
            context,
            Icons.storefront,
            "Business profile",
            "Manage address, website, and hours",
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BusinessProfilePage())),
          ),
          _buildToolTile(
            context,
            Icons.inventory_2,
            "Catalog",
            "Showcase and share your products",
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CatalogManagerPage())),
          ),
          const Divider(),
          _buildToolTile(
            context,
            Icons.waving_hand,
            "Greeting message",
            "Welcome new customers automatically",
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AutomatedMessagesPage(type: 'greeting'))),
          ),
          _buildToolTile(
            context,
            Icons.timer_outlined,
            "Away message",
            "Reply automatically when you're away",
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AutomatedMessagesPage(type: 'away'))),
          ),
          _buildToolTile(
            context,
            Icons.flash_on,
            "Quick replies",
            "Reuse frequent messages",
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QuickRepliesManagerPage())),
          ),
          const Divider(),
          _buildToolTile(
            context,
            Icons.label,
            "Labels",
            "Organize chats and customers",
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LabelsManagerPage())),
          ),
        ],
      ),
    );
  }

  Widget _buildToolTile(BuildContext context, IconData icon, String title, String subtitle, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF00A884)),
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: onTap,
    );
  }
}
