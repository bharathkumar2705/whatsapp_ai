import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'account_settings_page.dart';
import 'chat_settings_page.dart';
import 'notification_settings_page.dart';
import 'storage_data_page.dart';
import 'help_page.dart';
import 'privacy_settings_page.dart';
import 'profile_page.dart';
import 'my_qr_page.dart';
import 'business_profile_page.dart';
import 'business_tools_page.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/user_avatar.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final user = authProvider.userModel;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
      ),
      body: ListView(
        children: [
          // ─── Profile Banner ─────────────────────────────────────────────
          ListTile(
            leading: UserAvatar(url: user?.photoUrl, radius: 25),
            title: Text(user?.displayName ?? "User",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            subtitle: Text(user?.about ?? "Hey there! I am using WhatsApp AI."),
            trailing: IconButton(
              icon: Icon(Icons.qr_code, color: scheme.primary),
              tooltip: "My QR Code",
              onPressed: () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const MyQrPage())),
            ),
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const ProfilePage())),
          ),
          const Divider(),

          // ─── Dark Mode Toggle ────────────────────────────────────────────
          SwitchListTile(
            secondary: Icon(
              themeProvider.isDark ? Icons.dark_mode : Icons.light_mode,
              color: scheme.primary,
            ),
            title: const Text('Dark mode'),
            subtitle: Text(themeProvider.displayName),
            value: themeProvider.isDark,
            onChanged: (_) => themeProvider.toggleDark(),
          ),
          ListTile(
            leading: Icon(Icons.contrast, color: scheme.primary),
            title: const Text('Theme'),
            subtitle: Text(themeProvider.displayName),
            onTap: () => _showThemeDialog(context, themeProvider),
          ),
          const Divider(),

          // ─── Settings Tiles ──────────────────────────────────────────────
          _buildSettingsTile(context, Icons.storefront, "Business tools",
              "Profile, catalog, greeting message", () {
            Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const BusinessToolsPage()));
          }),
          _buildSettingsTile(context, Icons.key, "Account",
              "Security notifications, change number", () {
            Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const AccountSettingsPage()));
          }),
          _buildSettingsTile(context, Icons.lock, "Privacy",
              "Block contacts, disappearing messages", () {
            Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const PrivacySettingsPage()));
          }),
          _buildSettingsTile(context, Icons.chat, "Chats",
              "Wallpapers, chat history", () {
            Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const ChatSettingsPage()));
          }),
          _buildSettingsTile(context, Icons.notifications, "Notifications",
              "Message, group & call tones", () {
            Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const NotificationSettingsPage()));
          }),
          _buildSettingsTile(context, Icons.data_usage, "Storage and data",
              "Network usage, auto-download", () {
            Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const StorageDataPage()));
          }),
          _buildSettingsTile(context, Icons.language, "App language", "English", () {
            _showLanguageDialog(context);
          }),
          _buildSettingsTile(context, Icons.help_outline, "Help",
              "Help center, contact us, privacy policy", () {
            Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const HelpPage()));
          }),
          _buildSettingsTile(context, Icons.group_add, "Invite a friend",
              "Share the app with your friends", () {
            _showInviteDialog(context);
          }),
        ],
      ),
    );
  }

  void _showThemeDialog(BuildContext context, ThemeProvider themeProvider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Choose theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              title: const Text('Light'),
              value: ThemeMode.light,
              groupValue: themeProvider.themeMode,
              onChanged: (v) { themeProvider.setTheme(v!); Navigator.pop(ctx); },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Dark'),
              value: ThemeMode.dark,
              groupValue: themeProvider.themeMode,
              onChanged: (v) { themeProvider.setTheme(v!); Navigator.pop(ctx); },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('System default'),
              value: ThemeMode.system,
              groupValue: themeProvider.themeMode,
              onChanged: (v) { themeProvider.setTheme(v!); Navigator.pop(ctx); },
            ),
          ],
        ),
      ),
    );
  }


  void _showInviteDialog(BuildContext context) {
    const inviteLink = "https://whatsapp-ai-ebb0a.web.app";
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Invite a friend"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Tell your friends to join you on WhatsApp AI!"),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
              child: const Text(inviteLink, style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: inviteLink));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Link copied to clipboard!")));
            },
            child: const Text("COPY LINK"),
          ),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CLOSE")),
        ],
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("App language"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text("English"),
              value: "en",
              groupValue: "en", // Placeholder
              onChanged: (val) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Language changed to English")));
              },
            ),
            RadioListTile<String>(
              title: const Text("Español (Spanish)"),
              value: "es",
              groupValue: "en", // Placeholder
              onChanged: (val) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Language changed to Spanish")));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTile(BuildContext context, IconData icon, String title,
      String subtitle, VoidCallback onTap) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(icon, color: scheme.onSurface.withAlpha(140)),
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: onTap,
    );
  }
}
