import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../providers/auth_provider.dart';
import '../../data/models/chat_model.dart';
import '../../data/repositories/user_repository.dart';
import '../../data/repositories/storage_repository.dart';
import '../../domain/entities/user_entity.dart';
import '../widgets/user_avatar.dart';

class GroupInfoPage extends StatefulWidget {
  final ChatModel chat;
  const GroupInfoPage({super.key, required this.chat});

  @override
  State<GroupInfoPage> createState() => _GroupInfoPageState();
}

class _GroupInfoPageState extends State<GroupInfoPage> {
  final _userRepository = UserRepository();
  final _storageRepository = StorageRepository();
  bool _uploadingImage = false;

  // ── Edit group name ────────────────────────────────────────────────────────
  Future<void> _editGroupName(ChatProvider chatProvider) async {
    final controller = TextEditingController(text: widget.chat.groupName ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Group Name'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 50,
          decoration: const InputDecoration(hintText: 'Enter group name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result != null && result.isNotEmpty && result != widget.chat.groupName) {
      await chatProvider.updateGroupDetails(widget.chat.id, name: result);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Group name updated ✓')));
    }
  }

  // ── Edit group image ───────────────────────────────────────────────────────
  Future<void> _editGroupImage(ChatProvider chatProvider) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (image == null) return;

    setState(() => _uploadingImage = true);
    try {
      final bytes = await image.readAsBytes();
      // Store under chats/{chatId}/group_icon.jpg
      final url = await _storageRepository.uploadBytes(
        bytes,
        'chats/${widget.chat.id}/group_icon.jpg',
        contentType: 'image/jpeg',
      );
      await chatProvider.updateGroupDetails(widget.chat.id, imageUrl: url);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Group photo updated ✓')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _uploadingImage = false);
    }
  }

  // ── Add member ─────────────────────────────────────────────────────────────
  Future<void> _showAddMemberDialog(ChatProvider chatProvider) async {
    final allUsers = await _userRepository.getAllUsers();
    final eligible = allUsers.where((u) => !widget.chat.participants.contains(u.uid)).toList();

    if (!mounted) return;

    if (eligible.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No users to add')));
      return;
    }

    final selected = <String>{};
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Members'),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: ListView.builder(
              itemCount: eligible.length,
              itemBuilder: (_, i) {
                final user = eligible[i];
                return CheckboxListTile(
                  value: selected.contains(user.uid),
                  onChanged: (v) => setDialogState(() {
                    if (v == true) selected.add(user.uid);
                    else selected.remove(user.uid);
                  }),
                  title: Text(user.displayName),
                  secondary: UserAvatar(url: user.photoUrl, radius: 16),
                );
              },
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
            TextButton(
              onPressed: selected.isEmpty ? null : () => Navigator.pop(ctx),
              child: Text('ADD (${selected.length})'),
            ),
          ],
        ),
      ),
    );

    for (final uid in selected) {
      await chatProvider.addToGroup(widget.chat.id, uid);
    }
    if (selected.isNotEmpty && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${selected.length} member(s) added ✓')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final myUid = authProvider.user?.uid ?? '';
    final isAdmin = widget.chat.admins.contains(myUid);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Group Info'),
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.person_add),
              tooltip: 'Add member',
              onPressed: () => _showAddMemberDialog(chatProvider),
            ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 24),
          // ── Group avatar + name ──────────────────────────────────────────
          Center(
            child: Column(
              children: [
                Stack(
                  children: [
                    _uploadingImage
                        ? const CircleAvatar(radius: 50, child: CircularProgressIndicator())
                        : UserAvatar(url: widget.chat.groupImage, radius: 50),
                    if (isAdmin)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: GestureDetector(
                          onTap: () => _editGroupImage(chatProvider),
                          child: CircleAvatar(
                            radius: 16,
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.chat.groupName ?? 'Unnamed Group',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    if (isAdmin)
                      IconButton(
                        icon: Icon(Icons.edit, size: 18, color: Theme.of(context).colorScheme.onSurface.withAlpha(150)),
                        onPressed: () => _editGroupName(chatProvider),
                      ),
                  ],
                ),
                Text(
                  '${widget.chat.participants.length} participants',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withAlpha(150)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text('PARTICIPANTS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface.withAlpha(150))),
                const Spacer(),
                if (isAdmin)
                  TextButton.icon(
                    onPressed: () => _showAddMemberDialog(chatProvider),
                    icon: const Icon(Icons.person_add, size: 16),
                    label: const Text('Add'),
                  ),
              ],
            ),
          ),
          // ── Members list ─────────────────────────────────────────────────
          Expanded(
            child: ListView.builder(
              itemCount: widget.chat.participants.length,
              itemBuilder: (context, index) {
                final userId = widget.chat.participants[index];
                final isUserAdmin = widget.chat.admins.contains(userId);
                final isMe = userId == myUid;

                return FutureBuilder<UserEntity?>(
                  future: _userRepository.getUser(userId),
                  builder: (context, snapshot) {
                    final userName = snapshot.data?.displayName ?? 'User $userId';
                    final userPhoto = snapshot.data?.photoUrl ?? '';

                    return ListTile(
                      leading: UserAvatar(url: userPhoto, radius: 20),
                      title: Text(isMe ? '$userName (You)' : userName),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isUserAdmin)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                border: Border.all(color: Theme.of(context).colorScheme.primary),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text('Admin', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 10)),
                            ),
                          if (isAdmin && !isMe)
                            PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'promote') {
                                  chatProvider.promoteToAdmin(widget.chat.id, userId);
                                } else if (value == 'demote') {
                                  chatProvider.demoteFromAdmin(widget.chat.id, userId);
                                } else if (value == 'remove') {
                                  _confirmRemove(context, chatProvider, userId, userName);
                                }
                              },
                              itemBuilder: (_) => [
                                if (!isUserAdmin)
                                  const PopupMenuItem(value: 'promote', child: Text('Make Admin')),
                                if (isUserAdmin)
                                  const PopupMenuItem(value: 'demote', child: Text('Dismiss as Admin')),
                                PopupMenuItem(
                                  value: 'remove',
                                  child: Text('Remove', style: TextStyle(color: Theme.of(context).colorScheme.error)),
                                ),
                              ],
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _confirmRemove(BuildContext context, ChatProvider provider, String userId, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Remove $name?'),
        content: Text('Remove $name from this group?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
          TextButton(
            onPressed: () {
              provider.removeFromGroup(widget.chat.id, userId);
              Navigator.pop(ctx);
            },
            child: Text('REMOVE', style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
  }
}
