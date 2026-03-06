import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../../data/services/security_service.dart';
import '../../data/services/backup_service.dart';

class PrivacySettingsPage extends StatefulWidget {
  const PrivacySettingsPage({super.key});

  @override
  State<PrivacySettingsPage> createState() => _PrivacySettingsPageState();
}

class _PrivacySettingsPageState extends State<PrivacySettingsPage> {
  final SecurityService _securityService = SecurityService();
  final BackupService _backupService = BackupService();

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final settings = authProvider.userModel?.privacySettings ?? {};

    return Scaffold(
      appBar: AppBar(title: const Text("Privacy")),
      body: ListView(
        children: [
          _buildDropdownTile(
            "Last seen",
            settings['lastSeen'] ?? 'Everyone',
            ['Everyone', 'My contacts', 'Nobody'],
            (value) => authProvider.updatePrivacySettings({'lastSeen': value}),
          ),
          _buildDropdownTile(
            "Profile photo",
            settings['profilePhoto'] ?? 'Everyone',
            ['Everyone', 'My contacts', 'Nobody'],
            (value) => authProvider.updatePrivacySettings({'profilePhoto': value}),
          ),
          const Divider(),
          SwitchListTile(
            title: const Text("App lock"),
            subtitle: const Text("Use Fingerprint or FaceID to unlock WhatsApp AI"),
            value: settings['appLock'] ?? false,
            activeColor: const Color(0xFF075E54),
            onChanged: (value) async {
              if (value) {
                bool canAuth = await _securityService.canCheckBiometrics();
                if (canAuth) {
                  bool authenticated = await _securityService.authenticate();
                  if (authenticated) {
                    authProvider.updatePrivacySettings({'appLock': true});
                  }
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Biometric authentication not supported on this device.")),
                    );
                  }
                }
              } else {
                authProvider.updatePrivacySettings({'appLock': false});
              }
            },
          ),
          const Divider(),
          SwitchListTile(
            title: const Text("Two-step verification"),
            subtitle: const Text("For added security, enable two-step verification, which will require a PIN when registering your phone number with WhatsApp AI again."),
            value: settings['twoStepEnabled'] ?? false,
            activeColor: const Color(0xFF075E54),
            onChanged: (value) {
              if (value) {
                _showTwoStepSetup(authProvider);
              } else {
                authProvider.updatePrivacySettings({'twoStepEnabled': false, 'twoStepPin': null});
              }
            },
          ),
          SwitchListTile(
            title: const Text("Read receipts"),
            subtitle: const Text("If turned off, you won't send or receive Read receipts. Read receipts are always sent for group chats."),
            value: settings['readReceipts'] ?? true,
            activeColor: const Color(0xFF075E54),
            onChanged: (value) => authProvider.updatePrivacySettings({'readReceipts': value}),
          ),
          const Divider(),
          ListTile(
            title: const Text("Blocked contacts"),
            subtitle: Text("${authProvider.userModel?.blockedUsers.length ?? 0} contacts"),
            onTap: () {
              // TODO: Navigate to BlockedContactsPage
            },
          ),
          ListTile(
            leading: const Icon(Icons.backup_outlined),
            title: const Text("Chat backup"),
            subtitle: const Text("Encrypted backup on your device"),
            onTap: () => _showBackupDialog(),
          ),
        ],
      ),
    );
  }

  void _showBackupDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Create Encrypted Backup"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Your backup will be protected with a password."),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              obscureText: true,
              decoration: const InputDecoration(hintText: "Enter Backup Password"),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Creating backup...")));
                await _backupService.createEncryptedBackup([], controller.text);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Backup successful!")));
                }
              }
            },
            child: const Text("Backup"),
          ),
        ],
      ),
    );
  }

  void _showTwoStepSetup(AuthProvider authProvider) {
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
          decoration: const InputDecoration(hintText: "Enter PIN"),
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
              }
            },
            child: const Text("Enable"),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownTile(String title, String value, List<String> options, Function(String) onChanged) {
    return ListTile(
      title: Text(title),
      subtitle: Text(value),
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: options.map((opt) => RadioListTile<String>(
                title: Text(opt),
                value: opt,
                groupValue: value,
                onChanged: (val) {
                  if (val != null) {
                    onChanged(val);
                    Navigator.pop(context);
                  }
                },
              )).toList(),
            ),
          ),
        );
      },
    );
  }
}
