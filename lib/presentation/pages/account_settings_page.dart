import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class AccountSettingsPage extends StatelessWidget {
  const AccountSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.userModel;

    return Scaffold(
      appBar: AppBar(title: const Text("Account")),
      body: ListView(
        children: [
          _tile(Icons.email_outlined, "Email", user?.email ?? "-", null),
          _tile(Icons.security, "Two-step verification", "Add extra security to your account", () {
            _showTwoStepSetup(context, auth);
          }),
          _tile(Icons.notifications_active_outlined, "Security notifications", "Notify me of new login activity", () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Security notifications enabled (default)")),
            );
          }),
          const Divider(),
          _tile(Icons.delete_outline, "Delete my account", "Delete your account and all data", () {
            _showDeleteConfirm(context, auth);
          }, color: Colors.red),
          _tile(Icons.logout, "Log out", "Sign out from this device", () async {
            await auth.signOut();
          }, color: Colors.red),
        ],
      ),
    );
  }

  Widget _tile(IconData icon, String title, String subtitle, VoidCallback? onTap, {Color? color}) {
    return ListTile(
      leading: Icon(icon, color: color ?? Colors.grey[700]),
      title: Text(title, style: TextStyle(color: color)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 13)),
      onTap: onTap,
    );
  }

  void _showDeleteConfirm(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Account?"),
        content: const Text("This will permanently delete your account and all associated data. This action cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL")),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await auth.signOut();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("DELETE"),
          ),
        ],
      ),
    );
  }

  void _showTwoStepSetup(BuildContext context, AuthProvider authProvider) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Set 6-digit PIN"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          maxLength: 6,
          obscureText: true,
          decoration: const InputDecoration(
            hintText: "Enter PIN",
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF075E54))),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              if (controller.text.length == 6) {
                authProvider.updatePrivacySettings({
                  'twoStepEnabled': true,
                  'twoStepPin': controller.text,
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Two-step verification enabled!")),
                );
              }
            },
            child: const Text("Enable", style: TextStyle(color: Color(0xFF075E54))),
          ),
        ],
      ),
    );
  }
}
