import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import 'backup_page.dart';

class ChatSettingsPage extends StatefulWidget {
  const ChatSettingsPage({super.key});

  @override
  State<ChatSettingsPage> createState() => _ChatSettingsPageState();
}

class _ChatSettingsPageState extends State<ChatSettingsPage> {
  bool _enterToSend = false;
  bool _mediaAutoDownload = true;
  int _wallpaperId = 0;

  static const List<Map<String, dynamic>> _wallpapers = [
    {'color': 0xFFECE5DD, 'label': 'Classic Beige'},
    {'color': 0xFF1A1A2E, 'label': 'Midnight Blue'},
    {'color': 0xFF0D3B1C, 'label': 'Forest Green'},
    {'color': 0xFF2C0A3E, 'label': 'Deep Purple'},
    {'color': 0xFF1C2B3A, 'label': 'Ocean Dark'},
    {'color': 0xFFFFF3E0, 'label': 'Warm Sand'},
    {'color': 0xFFE8F5E9, 'label': 'Mint Fresh'},
    {'color': 0xFFE3F2FD, 'label': 'Sky Blue'},
  ];

  String get _wallpaperName =>
      _wallpapers[_wallpaperId.clamp(0, _wallpapers.length - 1)]['label']
          as String;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Chats")),
      body: ListView(
        children: [
          _header("Display"),
          ListTile(
            leading: const Icon(Icons.dark_mode_outlined),
            title: const Text("Theme"),
            subtitle: Text(themeProvider.displayName),
            onTap: () => _showThemePicker(themeProvider),
          ),
          ListTile(
            leading: const Icon(Icons.wallpaper),
            title: const Text("Chat wallpaper"),
            subtitle: Text(_wallpaperName),
            onTap: () => _showWallpaperPicker(),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.keyboard),
            title: const Text("Enter to send"),
            subtitle: const Text("Press Enter to send a message"),
            value: _enterToSend,
            onChanged: (v) => setState(() => _enterToSend = v),
          ),
          const Divider(),
          _header("Media"),
          SwitchListTile(
            secondary: const Icon(Icons.download_outlined),
            title: const Text("Auto-download media"),
            subtitle: const Text("Automatically download photos and videos"),
            value: _mediaAutoDownload,
            onChanged: (v) => setState(() => _mediaAutoDownload = v),
          ),
          const Divider(),
          _header("Backup"),
          ListTile(
            leading: const Icon(Icons.backup_outlined),
            title: const Text("Chat backup"),
            subtitle: const Text("Back up to Google Drive or iCloud"),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BackupPage())),
          ),
          const Divider(),
          _header("History"),
          ListTile(
            leading: const Icon(Icons.archive_outlined),
            title: const Text("Archive all chats"),
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("All chats archived")),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            title: const Text("Clear all message history",
                style: TextStyle(color: Colors.red)),
            onTap: () => _showClearConfirm(),
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

  void _showThemePicker(ThemeProvider themeProvider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text("Choose theme",
                style:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          ...[
            (ThemeMode.system, 'System Default', Icons.brightness_auto),
            (ThemeMode.light, 'Light', Icons.light_mode_outlined),
            (ThemeMode.dark, 'Dark', Icons.dark_mode_outlined),
          ].map((t) => ListTile(
                leading: Icon(t.$3),
                title: Text(t.$2),
                trailing: themeProvider.themeMode == t.$1
                    ? const Icon(Icons.check, color: Color(0xFF00A884))
                    : null,
                onTap: () {
                  themeProvider.setTheme(t.$1);
                  Navigator.pop(context);
                },
              )),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _showWallpaperPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text("Chat wallpaper",
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 0.75,
                ),
                itemCount: _wallpapers.length,
                itemBuilder: (_, i) {
                  final w = _wallpapers[i];
                  final selected = _wallpaperId == i;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _wallpaperId = i);
                      setS(() {});
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                "Wallpaper set to \"${w['label']}\"")),
                      );
                    },
                    child: Stack(
                      alignment: Alignment.topRight,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Color(w['color'] as int),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: selected
                                  ? const Color(0xFF00A884)
                                  : Colors.transparent,
                              width: 2.5,
                            ),
                          ),
                          child: Center(
                            child: Text(w['label'] as String,
                                style: const TextStyle(
                                    fontSize: 9,
                                    color: Colors.black54),
                                textAlign: TextAlign.center),
                          ),
                        ),
                        if (selected)
                          const Padding(
                            padding: EdgeInsets.all(4),
                            child: CircleAvatar(
                              radius: 8,
                              backgroundColor: Color(0xFF00A884),
                              child: Icon(Icons.check,
                                  color: Colors.white, size: 10),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showClearConfirm() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Clear Message History?"),
        content:
            const Text("This will delete all messages permanently."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("CANCEL")),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text("All message history cleared")),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("CLEAR"),
          ),
        ],
      ),
    );
  }
}
