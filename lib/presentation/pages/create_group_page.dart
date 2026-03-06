import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../widgets/user_avatar.dart';
import '../../data/repositories/user_repository.dart';
import '../../data/models/user_model.dart';
import '../../domain/entities/user_entity.dart';

class CreateGroupPage extends StatefulWidget {
  const CreateGroupPage({super.key});

  @override
  State<CreateGroupPage> createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends State<CreateGroupPage> {
  final TextEditingController _groupNameController = TextEditingController();
  final List<String> _selectedUserIds = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _groupNameController.dispose();
    super.dispose();
  }

  void _toggleUserSelection(String uid) {
    setState(() {
      if (_selectedUserIds.contains(uid)) {
        _selectedUserIds.remove(uid);
      } else {
        _selectedUserIds.add(uid);
      }
    });
  }

  Future<void> _createGroup(ChatProvider chatProvider, String myUid) async {
    if (_groupNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter group name")));
      return;
    }
    if (_selectedUserIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Select at least one participant")));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final participants = [myUid, ..._selectedUserIds];
      await chatProvider.createGroup(_groupNameController.text.trim(), participants, myUid);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Group created!")));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userRepository = UserRepository();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final myUid = authProvider.user?.uid ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text("New Group")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _groupNameController,
              decoration: const InputDecoration(
                labelText: "Group Name",
                hintText: "Enter group name",
                prefixIcon: Icon(Icons.group),
              ),
            ),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text("Select Participants", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<UserEntity>>(
              future: userRepository.getAllUsers(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                
                final users = snapshot.data!.where((u) => u.uid != myUid).toList();
                
                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    final isSelected = _selectedUserIds.contains(user.uid);
                    
                    return CheckboxListTile(
                      value: isSelected,
                      onChanged: (_) => _toggleUserSelection(user.uid),
                      title: Text(user.displayName),
                      secondary: UserAvatar(url: user.photoUrl),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isLoading ? null : () => _createGroup(chatProvider, myUid),
        backgroundColor: const Color(0xFF25D366),
        child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Icon(Icons.check, color: Colors.white),
      ),
    );
  }
}
