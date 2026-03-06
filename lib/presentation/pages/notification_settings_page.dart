import 'package:flutter/material.dart';
import 'data_usage_page.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState
    extends State<NotificationSettingsPage> {
  bool _msgNotify = true;
  bool _groupNotify = true;
  bool _callNotify = true;
  bool _vibrate = true;
  bool _previewMsg = true;
  String _msgTone = 'Default';
  String _groupTone = 'Default';
  String _callRingtone = 'Default';

  static const List<String> _tones = [
    'Default',
    'None',
    'Chime',
    'Ping',
    'Tone',
    'Beep',
    'Alert',
  ];

  void _pickTone(
      String label, String current, Function(String) onPicked) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text("$label tone",
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          ..._tones.map((t) => ListTile(
                leading: Icon(
                  t == 'None'
                      ? Icons.volume_off
                      : Icons.music_note_outlined,
                  color: t == current
                      ? const Color(0xFF00A884)
                      : null,
                ),
                title: Text(t),
                trailing: t == current
                    ? const Icon(Icons.check,
                        color: Color(0xFF00A884))
                    : null,
                onTap: () {
                  onPicked(t);
                  Navigator.pop(context);
                },
              )),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Notifications")),
      body: ListView(
        children: [
          _header("Messages"),
          SwitchListTile(
            secondary: const Icon(Icons.chat_bubble_outline),
            title: const Text("Conversation notifications"),
            subtitle:
                const Text("Show notifications for new messages"),
            value: _msgNotify,
            onChanged: (v) => setState(() => _msgNotify = v),
          ),
          ListTile(
            leading: const Icon(Icons.music_note_outlined),
            title: const Text("Notification tone"),
            subtitle: Text(_msgTone),
            onTap: () => _pickTone('Message', _msgTone, (t) {
              setState(() => _msgTone = t);
            }),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.preview_outlined),
            title: const Text("Show preview"),
            subtitle: const Text(
                "Show message content in notifications"),
            value: _previewMsg,
            onChanged: (v) => setState(() => _previewMsg = v),
          ),
          const Divider(),
          _header("Groups"),
          SwitchListTile(
            secondary: const Icon(Icons.group_outlined),
            title: const Text("Group notifications"),
            value: _groupNotify,
            onChanged: (v) => setState(() => _groupNotify = v),
          ),
          ListTile(
            leading: const Icon(Icons.music_note_outlined),
            title: const Text("Group notification tone"),
            subtitle: Text(_groupTone),
            onTap: () => _pickTone('Group', _groupTone, (t) {
              setState(() => _groupTone = t);
            }),
          ),
          const Divider(),
          _header("Calls"),
          SwitchListTile(
            secondary: const Icon(Icons.call_outlined),
            title: const Text("Call notifications"),
            value: _callNotify,
            onChanged: (v) => setState(() => _callNotify = v),
          ),
          ListTile(
            leading: const Icon(Icons.music_note_outlined),
            title: const Text("Ringtone"),
            subtitle: Text(_callRingtone),
            onTap: () => _pickTone('Ringtone', _callRingtone, (t) {
              setState(() => _callRingtone = t);
            }),
          ),
          const Divider(),
          _header("Other"),
          SwitchListTile(
            secondary: const Icon(Icons.vibration),
            title: const Text("Vibrate"),
            value: _vibrate,
            onChanged: (v) => setState(() => _vibrate = v),
          ),
          const Divider(),
          _header("Data Usage"),
          ListTile(
            leading: const Icon(Icons.data_usage),
            title: const Text("Data and storage usage"),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const DataUsagePage())),
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
