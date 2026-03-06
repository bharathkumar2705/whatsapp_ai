import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BackupPage extends StatefulWidget {
  const BackupPage({super.key});

  @override
  State<BackupPage> createState() => _BackupPageState();
}

class _BackupPageState extends State<BackupPage> {
  bool _includeMedia = true;
  bool _autoBackup = false;
  String? _lastGDriveBackup;
  String? _lastICloudBackup;
  bool _backingUpDrive = false;
  bool _backingUpCloud = false;

  Future<void> _runBackup(String provider) async {
    final isGDrive = provider == 'gdrive';
    setState(() => isGDrive ? _backingUpDrive = true : _backingUpCloud = true);

    await Future.delayed(const Duration(seconds: 2));
    final now = DateFormat('MMM d, yyyy • HH:mm').format(DateTime.now());

    setState(() {
      if (isGDrive) {
        _backingUpDrive = false;
        _lastGDriveBackup = now;
      } else {
        _backingUpCloud = false;
        _lastICloudBackup = now;
      }
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                "Backup to ${isGDrive ? 'Google Drive' : 'iCloud'} complete!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Chat backup")),
      body: ListView(
        children: [
          _header("Backup options"),
          SwitchListTile(
            secondary: const Icon(Icons.perm_media_outlined),
            title: const Text("Include media"),
            subtitle: const Text("Videos, photos and audio in backup"),
            value: _includeMedia,
            onChanged: (v) => setState(() => _includeMedia = v),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.schedule),
            title: const Text("Auto backup"),
            subtitle: const Text("Back up daily when on Wi-Fi and charging"),
            value: _autoBackup,
            onChanged: (v) => setState(() => _autoBackup = v),
          ),
          const Divider(),
          _header("Google Drive"),
          _BackupProviderCard(
            icon: Icons.drive_folder_upload_outlined,
            iconColor: const Color(0xFF4285F4),
            name: "Google Drive",
            lastBackup: _lastGDriveBackup ?? "Never",
            isLoading: _backingUpDrive,
            onBackup: () => _runBackup('gdrive'),
          ),
          const Divider(),
          _header("iCloud"),
          _BackupProviderCard(
            icon: Icons.cloud_outlined,
            iconColor: const Color(0xFF007AFF),
            name: "iCloud",
            lastBackup: _lastICloudBackup ?? "Never",
            isLoading: _backingUpCloud,
            onBackup: () => _runBackup('icloud'),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              "Your messages are secured by end-to-end encryption. Backups are encrypted before upload.",
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(String title) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
    child: Text(title,
        style: const TextStyle(
            color: Color(0xFF00A884),
            fontWeight: FontWeight.bold,
            fontSize: 13)),
  );
}

class _BackupProviderCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String name;
  final String lastBackup;
  final bool isLoading;
  final VoidCallback onBackup;

  const _BackupProviderCard({
    required this.icon,
    required this.iconColor,
    required this.name,
    required this.lastBackup,
    required this.isLoading,
    required this.onBackup,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: iconColor.withOpacity(0.1),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(name,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                lastBackup == "Never"
                    ? "No backup yet"
                    : "Last backup: $lastBackup",
                style:
                    TextStyle(color: Colors.grey[500], fontSize: 12)),
            const SizedBox(height: 8),
            SizedBox(
              height: 36,
              child: ElevatedButton(
                onPressed: isLoading ? null : onBackup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: iconColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text("Back up now",
                        style: TextStyle(fontSize: 13)),
              ),
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
}
