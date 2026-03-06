import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../data/repositories/user_repository.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/entities/chat_entity.dart';
import '../providers/auth_provider.dart';

class ContactInfoPage extends StatefulWidget {
  final String otherUserId;
  final String otherUserName;
  final String otherUserImage;
  final ChatEntity chat;

  const ContactInfoPage({
    super.key,
    required this.otherUserId,
    required this.otherUserName,
    required this.otherUserImage,
    required this.chat,
  });

  @override
  State<ContactInfoPage> createState() => _ContactInfoPageState();
}

class _ContactInfoPageState extends State<ContactInfoPage> {
  final UserRepository _userRepository = UserRepository();
  bool _muted = false;

  @override
  Widget build(BuildContext context) {
    final myUid = context.read<AuthProvider>().user?.uid ?? '';
    final scheme = Theme.of(context).colorScheme;
    final bool isBlockedByMe = context.watch<AuthProvider>().userModel?.blockedUsers.contains(widget.otherUserId) ?? false;

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      body: StreamBuilder<UserEntity>(
        stream: _userRepository.getUserStream(widget.otherUserId),
        builder: (context, snapshot) {
          final user = snapshot.data;
          return CustomScrollView(
            slivers: [
              // ── App Bar ──────────────────────────────────────────────────
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () {},
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    color: scheme.surface,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 80),
                        // Profile photo
                        CircleAvatar(
                          radius: 60,
                          backgroundImage: (user?.photoUrl ?? widget.otherUserImage).isNotEmpty
                              ? NetworkImage(user?.photoUrl ?? widget.otherUserImage)
                              : null,
                          child: (user?.photoUrl ?? widget.otherUserImage).isEmpty
                              ? const Icon(Icons.person, size: 60)
                              : null,
                        ),
                        const SizedBox(height: 12),
                        // Name
                        Text(
                          user?.displayName ?? widget.otherUserName,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        // Phone
                        if ((user?.phoneNumber ?? '').isNotEmpty)
                          Text(
                            user!.phoneNumber,
                            style: TextStyle(fontSize: 14, color: scheme.onSurface.withOpacity(0.6)),
                          ),
                      ],
                    ),
                  ),
                  title: const Text('Contact info'),
                ),
              ),

              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Action buttons (Search) ─────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _actionButton(context, Icons.search, 'Search', () => Navigator.pop(context)),
                        ],
                      ),
                    ),

                    // ── About ───────────────────────────────────────────────
                    _sectionCard([
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('About', style: TextStyle(fontSize: 12, color: scheme.primary)),
                            const SizedBox(height: 4),
                            Text(
                              user?.about ?? 'Hey there! I am using WhatsApp.',
                              style: const TextStyle(fontSize: 15),
                            ),
                          ],
                        ),
                      ),
                    ]),

                    // ── Media, links and docs ──────────────────────────────
                    _sectionCard([
                      ListTile(
                        leading: const Icon(Icons.photo_library_outlined),
                        title: const Text('Media, links and docs'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('0', style: TextStyle(color: scheme.onSurface.withOpacity(0.5))),
                            const Icon(Icons.chevron_right),
                          ],
                        ),
                        onTap: () {},
                      ),
                    ]),

                    // ── Starred messages ────────────────────────────────────
                    _sectionCard([
                      ListTile(
                        leading: const Icon(Icons.star_outline),
                        title: const Text('Starred messages'),
                        onTap: () {},
                      ),
                    ]),

                    // ── Chat settings ───────────────────────────────────────
                    _sectionCard([
                      SwitchListTile(
                        secondary: const Icon(Icons.notifications_outlined),
                        title: const Text('Mute notifications'),
                        value: _muted,
                        onChanged: (val) => setState(() => _muted = val),
                      ),
                      const Divider(height: 1, indent: 56),
                      ListTile(
                        leading: const Icon(Icons.timer_outlined),
                        title: const Text('Disappearing messages'),
                        subtitle: Text(
                          widget.chat.disappearingEnabled ? 'On' : 'Off',
                          style: TextStyle(color: scheme.onSurface.withOpacity(0.5)),
                        ),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Disappearing messages setting coming soon')),
                          );
                        },
                      ),
                      const Divider(height: 1, indent: 56),
                      ListTile(
                        leading: const Icon(Icons.lock_outline),
                        title: const Text('Advanced chat privacy'),
                        subtitle: Text('Off', style: TextStyle(color: scheme.onSurface.withOpacity(0.5))),
                        onTap: () {},
                      ),
                    ]),

                    // ── Encryption ──────────────────────────────────────────
                    _sectionCard([
                      ListTile(
                        leading: const Icon(Icons.lock),
                        title: const Text('Encryption'),
                        subtitle: Text(
                          'Messages are end-to-end encrypted. Tap to verify.',
                          style: TextStyle(color: scheme.primary, fontSize: 13),
                        ),
                        onTap: () {},
                      ),
                    ]),

                    // ── Common Groups ───────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                      child: Text('Groups in common', style: TextStyle(color: scheme.onSurface.withOpacity(0.6), fontSize: 13)),
                    ),
                    _sectionCard([
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: scheme.primaryContainer,
                          child: Icon(Icons.group, color: scheme.primary),
                        ),
                        title: const Text('No groups in common'),
                        subtitle: const Text('You and this contact share no groups'),
                      ),
                    ]),

                    const SizedBox(height: 16),

                    // ── Bottom actions ──────────────────────────────────────
                    _sectionCard([
                      ListTile(
                        leading: const Icon(Icons.favorite_border),
                        title: const Text('Add to favourites'),
                        onTap: () {},
                      ),
                      const Divider(height: 1, indent: 56),
                      ListTile(
                        leading: const Icon(Icons.playlist_add),
                        title: const Text('Add to list'),
                        onTap: () {},
                      ),
                    ]),

                    _sectionCard([
                      ListTile(
                        leading: const Icon(Icons.block, color: Colors.red),
                        title: Text(
                          isBlockedByMe ? 'Unblock ${widget.otherUserName}' : 'Block ${widget.otherUserName}',
                          style: const TextStyle(color: Colors.red),
                        ),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(isBlockedByMe ? '${widget.otherUserName} unblocked' : '${widget.otherUserName} blocked')),
                          );
                        },
                      ),
                      const Divider(height: 1, indent: 56),
                      ListTile(
                        leading: const Icon(Icons.thumb_down_outlined, color: Colors.red),
                        title: Text(
                          'Report ${widget.otherUserName}',
                          style: const TextStyle(color: Colors.red),
                        ),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('${widget.otherUserName} reported.')),
                          );
                          Navigator.pop(context);
                        },
                      ),
                      const Divider(height: 1, indent: 56),
                      ListTile(
                        leading: const Icon(Icons.delete_outline, color: Colors.red),
                        title: const Text('Delete chat', style: TextStyle(color: Colors.red)),
                        onTap: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Delete chat'),
                              content: const Text('This chat will be removed from your list.'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCEL')),
                                TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('DELETE', style: TextStyle(color: Colors.red))),
                              ],
                            ),
                          );
                          if (confirm == true && context.mounted) {
                            await FirebaseFirestore.instance
                                .collection('chats')
                                .doc(widget.chat.id)
                                .update({'deletedBy': FieldValue.arrayUnion([myUid])});
                            if (context.mounted) Navigator.of(context).popUntil((r) => r.isFirst);
                          }
                        },
                      ),
                    ]),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _sectionCard(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      color: Theme.of(context).colorScheme.surface,
      child: Column(children: children),
    );
  }

  Widget _actionButton(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: scheme.onSurface.withOpacity(0.15)),
          borderRadius: BorderRadius.circular(12),
          color: scheme.surface,
        ),
        child: Column(
          children: [
            Icon(icon, color: scheme.primary),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: scheme.primary, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
