import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../providers/auth_provider.dart';

class CreateCommunityPage extends StatefulWidget {
  const CreateCommunityPage({super.key});

  @override
  State<CreateCommunityPage> createState() => _CreateCommunityPageState();
}

class _CreateCommunityPageState extends State<CreateCommunityPage> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedIcon = 'groups';

  final List<Map<String, dynamic>> _icons = [
    {'name': 'groups', 'icon': Icons.groups},
    {'name': 'school', 'icon': Icons.school},
    {'name': 'computer', 'icon': Icons.computer},
    {'name': 'assignment', 'icon': Icons.assignment},
    {'name': 'work', 'icon': Icons.work},
    {'name': 'home', 'icon': Icons.home},
  ];

  bool _isCreating = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("New Community"),
        actions: [
          TextButton(
            onPressed: (_isCreating || _nameController.text.isEmpty) ? null : _createCommunity,
            child: const Text("CREATE", style: TextStyle(color: Color(0xFF00A884), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Icon(
                      _icons.firstWhere((i) => i['name'] == _selectedIcon)['icon'],
                      size: 50,
                      color: const Color(0xFF00A884),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _showIconPicker,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Color(0xFF00A884),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.edit, color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: "Community name",
                hintText: "Enter a name for your community",
                border: UnderlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: "Description",
                hintText: "What's this community about?",
                border: UnderlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 32),
            const Text(
              "Your community brings members together in topic-based groups, and makes it easy to send announcements.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  void _showIconPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Select Community Icon", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 20),
            GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
              ),
              itemCount: _icons.length,
              itemBuilder: (context, index) {
                final iconData = _icons[index];
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedIcon = iconData['name']);
                    Navigator.pop(context);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: _selectedIcon == iconData['name'] 
                          ? const Color(0xFF00A884).withOpacity(0.1) 
                          : Colors.transparent,
                      border: Border.all(
                        color: _selectedIcon == iconData['name'] ? const Color(0xFF00A884) : Colors.grey[300]!,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(iconData['icon'], color: const Color(0xFF00A884)),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createCommunity() async {
    setState(() => _isCreating = true);
    try {
      final uid = context.read<AuthProvider>().user?.uid ?? '';
      await context.read<ChatProvider>().createCommunity(
        _nameController.text,
        _descriptionController.text,
        _selectedIcon,
        uid,
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Community created successfully!")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }
}
