import 'package:flutter/material.dart';

class StorageDataPage extends StatelessWidget {
  const StorageDataPage({super.key});

  // Simulated usage data (in MB)
  static const Map<String, double> _usage = {
    'Photos': 124.5,
    'Videos': 310.2,
    'Audio': 45.8,
    'Documents': 28.1,
    'Other': 12.0,
  };

  static const Map<String, IconData> _icons = {
    'Photos': Icons.image_outlined,
    'Videos': Icons.videocam_outlined,
    'Audio': Icons.audiotrack_outlined,
    'Documents': Icons.description_outlined,
    'Other': Icons.folder_outlined,
  };

  static const Map<String, Color> _colors = {
    'Photos': Color(0xFF00A884),
    'Videos': Color(0xFF4285F4),
    'Audio': Color(0xFFFF9800),
    'Documents': Color(0xFF9C27B0),
    'Other': Color(0xFF607D8B),
  };

  @override
  Widget build(BuildContext context) {
    final totalMb = _usage.values.fold(0.0, (a, b) => a + b);

    return Scaffold(
      appBar: AppBar(title: const Text("Storage and Data")),
      body: ListView(
        children: [
          // Storage section
          const _SectionHeader("Storage"),

          // Visual usage bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Used", style: TextStyle(fontWeight: FontWeight.bold)),
                    Text("${totalMb.toStringAsFixed(1)} MB of ~1.0 GB",
                        style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: SizedBox(
                    height: 14,
                    child: Row(
                      children: _usage.entries.map((e) {
                        return Flexible(
                          flex: (e.value * 100).toInt(),
                          child: Container(color: _colors[e.key]),
                        );
                      }).toList()
                        ..add(Flexible(
                          flex: ((1024 - totalMb) * 100).toInt().clamp(0, 999999),
                          child: Container(color: Colors.grey[300]),
                        )),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Legend
                Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  children: _usage.entries.map((e) => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 10, height: 10,
                          decoration: BoxDecoration(color: _colors[e.key], shape: BoxShape.circle)),
                      const SizedBox(width: 4),
                      Text("${e.key} ${e.value.toStringAsFixed(0)}MB",
                          style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  )).toList(),
                ),
              ],
            ),
          ),

          // Per category tiles
          ..._usage.entries.map((e) => ListTile(
            leading: CircleAvatar(
              backgroundColor: _colors[e.key]!.withOpacity(0.12),
              child: Icon(_icons[e.key], color: _colors[e.key], size: 20),
            ),
            title: Text(e.key),
            trailing: Text("${e.value.toStringAsFixed(1)} MB",
                style: const TextStyle(color: Colors.grey)),
          )),

          ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0x1FFF0000),
              child: Icon(Icons.delete_outline, color: Colors.red, size: 20),
            ),
            title: const Text("Clear cache", style: TextStyle(color: Colors.red)),
            subtitle: const Text("Frees temporary files"),
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Cache cleared (0 MB freed in demo)")),
            ),
          ),

          const Divider(),

          // Network section
          const _SectionHeader("Network"),
          ListTile(
            leading: const Icon(Icons.arrow_upward, color: Colors.green),
            title: const Text("Data sent"),
            trailing: const Text("18.3 MB", style: TextStyle(color: Colors.grey)),
          ),
          ListTile(
            leading: const Icon(Icons.arrow_downward, color: Colors.blue),
            title: const Text("Data received"),
            trailing: const Text("102.6 MB", style: TextStyle(color: Colors.grey)),
          ),

          const Divider(),

          // Media auto-download section
          const _SectionHeader("Media auto-download"),
          ListTile(
            leading: const Icon(Icons.wifi),
            title: const Text("When connected to Wi-Fi"),
            subtitle: const Text("Photos, Videos, Documents, Audio"),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Auto-download: All media on Wi-Fi")),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.signal_cellular_alt),
            title: const Text("When using mobile data"),
            subtitle: const Text("Photos only"),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Mobile data: Photos only")),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(title,
          style: const TextStyle(color: Color(0xFF00A884), fontWeight: FontWeight.bold, fontSize: 13)),
    );
  }
}
