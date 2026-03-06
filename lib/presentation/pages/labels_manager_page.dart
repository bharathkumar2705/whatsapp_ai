import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';

class LabelsManagerPage extends StatefulWidget {
  const LabelsManagerPage({super.key});

  @override
  State<LabelsManagerPage> createState() => _LabelsManagerPageState();
}

class _LabelsManagerPageState extends State<LabelsManagerPage> {
  // Static predefined labels for this demo
  final List<Map<String, dynamic>> _defaultLabels = [
    {'name': 'New customer', 'color': Colors.blue},
    {'name': 'New order', 'color': Colors.yellow},
    {'name': 'Pending payment', 'color': Colors.red},
    {'name': 'Paid', 'color': Colors.green},
    {'name': 'Order complete', 'color': Colors.grey},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Labels"),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: () {}),
        ],
      ),
      body: ListView.builder(
        itemCount: _defaultLabels.length,
        itemBuilder: (context, index) {
          final label = _defaultLabels[index];
          return ListTile(
            leading: Icon(Icons.label, color: label['color']),
            title: Text(label['name']),
            trailing: const Text("0", style: TextStyle(color: Colors.grey)),
            onTap: () {
              // Show chats with this label
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Showing chats for: ${label['name']}")),
              );
            },
          );
        },
      ),
    );
  }
}
