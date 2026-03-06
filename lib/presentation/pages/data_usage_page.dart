import 'package:flutter/material.dart';

class DataUsagePage extends StatefulWidget {
  const DataUsagePage({super.key});

  @override
  State<DataUsagePage> createState() => _DataUsagePageState();
}

class _DataUsagePageState extends State<DataUsagePage> {
  bool _reduceData = false;
  bool _autoPhotoMobile = true;
  bool _autoVideoMobile = false;
  bool _autoAudioMobile = true;
  bool _backgroundData = true;
  bool _callDataSaver = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Data usage")),
      body: ListView(
        children: [
          _header("General"),
          SwitchListTile(
            secondary: const Icon(Icons.data_saver_on_outlined),
            title: const Text("Reduce data usage"),
            subtitle: const Text("Lower media quality when on mobile data"),
            value: _reduceData,
            onChanged: (v) => setState(() => _reduceData = v),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.data_usage),
            title: const Text("Background data"),
            subtitle: const Text("Allow app to sync in the background"),
            value: _backgroundData,
            onChanged: (v) => setState(() => _backgroundData = v),
          ),
          const Divider(),
          _header("Auto-download on mobile data"),
          SwitchListTile(
            secondary: const Icon(Icons.image_outlined),
            title: const Text("Photos"),
            value: _autoPhotoMobile,
            onChanged: (v) => setState(() => _autoPhotoMobile = v),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.videocam_outlined),
            title: const Text("Videos"),
            value: _autoVideoMobile,
            onChanged: (v) => setState(() => _autoVideoMobile = v),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.audiotrack_outlined),
            title: const Text("Audio"),
            value: _autoAudioMobile,
            onChanged: (v) => setState(() => _autoAudioMobile = v),
          ),
          const Divider(),
          _header("Calls"),
          SwitchListTile(
            secondary: const Icon(Icons.call_outlined),
            title: const Text("Low data usage for calls"),
            subtitle: const Text("Reduces call quality to save data"),
            value: _callDataSaver,
            onChanged: (v) => setState(() => _callDataSaver = v),
          ),
        ],
      ),
    );
  }

  Widget _header(String title) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
    child: Text(
      title,
      style: const TextStyle(
          color: Color(0xFF00A884), fontWeight: FontWeight.bold, fontSize: 13),
    ),
  );
}
