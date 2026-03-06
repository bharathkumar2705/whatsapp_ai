import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/contact_provider.dart';
import '../widgets/user_avatar.dart';
import 'chat_room_page.dart';
import '../../data/models/chat_model.dart';
import '../../domain/entities/user_entity.dart';
import '../../data/repositories/user_repository.dart';
import 'add_contact_page.dart';

class ContactsPage extends StatefulWidget {
  const ContactsPage({super.key});

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  final _searchController = TextEditingController();
  String _searchQuery = "";
  List<UserEntity>? _allUsers;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ContactProvider>().syncGoogleContacts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final userRepository = UserRepository();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final contactProvider = Provider.of<ContactProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: _searchQuery.isEmpty
            ? const Text("Select Contact")
            : TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: "Search name or email...",
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
        actions: [
          IconButton(
            icon: Icon(_searchQuery.isEmpty ? Icons.search : Icons.close),
            onPressed: () {
              setState(() {
                if (_searchQuery.isNotEmpty) {
                  _searchQuery = "";
                  _searchController.clear();
                } else {
                  _searchQuery = " ";
                }
              });
            },
          ),
          if (_searchQuery.isEmpty) ...[
            IconButton(
              icon: const Icon(Icons.sync),
              tooltip: 'Sync phone contacts',
              onPressed: () => contactProvider.syncContacts(),
            ),
            IconButton(
              icon: contactProvider.isGoogleLoading
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.contacts),
              tooltip: 'Sync Google contacts',
              onPressed: () => contactProvider.syncGoogleContacts(),
            ),
          ],
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF25D366),
        onPressed: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const AddContactPage())),
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
      body: contactProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                // ── Permission banner ──────────────────────────────────
                if (contactProvider.permissionDenied)
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.red[50],
                    child: Row(
                      children: [
                        const Icon(Icons.error, color: Colors.red),
                        const SizedBox(width: 12),
                        const Expanded(
                            child: Text("Contact permission denied. Please enable it in settings.")),
                        TextButton(
                            onPressed: () => contactProvider.syncContacts(),
                            child: const Text("RETRY")),
                      ],
                    ),
                  ),

                // ── Fixed tiles ────────────────────────────────────────
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFF25D366),
                    child: Icon(Icons.share, color: Colors.white),
                  ),
                  title: const Text("Invite Friends",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  onTap: () => _showInviteDialog(context),
                ),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFF128C7E),
                    child: Icon(Icons.person_add, color: Colors.white),
                  ),
                  title: const Text('New Contact',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Add someone by phone number'),
                  onTap: () => Navigator.push(
                      context, MaterialPageRoute(builder: (_) => const AddContactPage())),
                ),
                const Divider(height: 1),

                if (contactProvider.googleSyncError != null)
                  Container(
                    color: Colors.red.withOpacity(0.1),
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Google Sync Error: ${contactProvider.googleSyncError}",
                            style: const TextStyle(color: Colors.red, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),

                // ── Main content: browse or search ─────────────────────
                if (_searchQuery.isEmpty) ...[
                  // ── Contacts from Google ─────────────────────────────
                  if (contactProvider.appUsersFromGoogle.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: Row(children: [
                        const Icon(Icons.contacts, size: 16, color: Color(0xFF128C7E)),
                        const SizedBox(width: 6),
                        Text('Contacts from Google',
                            style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.bold)),
                      ]),
                    ),
                    ...contactProvider.appUsersFromGoogle.map((user) => ListTile(
                          leading: UserAvatar(url: user.photoUrl),
                          title: Text(user.displayName),
                          subtitle: Text(
                              user.email.isNotEmpty ? user.email : user.about,
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          onTap: () => _openChat(context, authProvider, chatProvider, user),
                        )),
                    const Divider(),
                  ],

                  // ── Contacts on WhatsApp (phone sync) ────────────────
                  if (contactProvider.appUsersFromContacts.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text("Contacts on WhatsApp",
                          style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.bold)),
                    ),
                    ...contactProvider.appUsersFromContacts.map((user) => ListTile(
                          leading: UserAvatar(url: user.photoUrl),
                          title: Text(user.displayName),
                          subtitle: Text(user.about),
                          onTap: () => _openChat(context, authProvider, chatProvider, user),
                        )),
                  ],

                  // ── All Users ────────────────────────────────────────
                  FutureBuilder<List<UserEntity>>(
                    future: _allUsers == null
                        ? userRepository.getAllUsers()
                        : Future.value(_allUsers),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      _allUsers ??= snapshot.data;
                      final currentUserId = authProvider.user?.uid;
                      final filteredUsers = _allUsers!
                          .where((u) => u.uid != currentUserId)
                          .where((u) =>
                              !contactProvider.appUsersFromContacts
                                  .any((cu) => cu.uid == u.uid) &&
                              !contactProvider.appUsersFromGoogle
                                  .any((gu) => gu.uid == u.uid))
                          .toList();
                      if (filteredUsers.isEmpty) return const SizedBox.shrink();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text("All Users",
                                style: TextStyle(
                                    color: Colors.grey,
                                    fontWeight: FontWeight.bold)),
                          ),
                          ...filteredUsers.map((user) => ListTile(
                                leading: UserAvatar(url: user.photoUrl),
                                title: Text(user.displayName),
                                subtitle: Text(user.about),
                                onTap: () =>
                                    _openChat(context, authProvider, chatProvider, user),
                              )),
                        ],
                      );
                    },
                  ),

                  // ── Invite Phone Contacts ────────────────────────────
                  if (contactProvider.phoneContacts.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text("Invite Phone Contacts",
                          style: TextStyle(
                              color: Colors.grey, fontWeight: FontWeight.bold)),
                    ),
                    ...contactProvider.phoneContacts.map((contact) => ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.grey[200],
                            child: const Icon(Icons.person, color: Colors.grey),
                          ),
                          title: Text(contact.displayName),
                          subtitle: Text(contact.phones.isNotEmpty
                              ? contact.phones.first.number
                              : "No number"),
                          trailing: TextButton(
                            onPressed: () => _showInviteDialog(context),
                            child: const Text("INVITE"),
                          ),
                        )),
                  ],

                  // ── Invite from Google ───────────────────────────────
                  if (contactProvider.googleContacts.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text("Invite from Google",
                          style: TextStyle(
                              color: Colors.grey, fontWeight: FontWeight.bold)),
                    ),
                    ...contactProvider.googleContacts.map((gc) {
                      final name = gc['name'] ?? 'No Name';
                      final emails = (gc['emails'] as List<String>);
                      final phones = (gc['phones'] as List<String>);
                      final subtitle = emails.isNotEmpty 
                          ? emails.first 
                          : (phones.isNotEmpty ? phones.first : "No info");

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue[50],
                          child: const Icon(Icons.contact_mail, color: Colors.blue),
                        ),
                        title: Text(name),
                        subtitle: Text(subtitle),
                        trailing: TextButton(
                          onPressed: () => _showInviteDialog(context),
                          child: const Text("INVITE"),
                        ),
                      );
                    }),
                  ],
                ] else ...[
                  // ── Search Results ───────────────────────────────────
                  FutureBuilder<List<UserEntity>>(
                    future: _allUsers == null
                        ? userRepository.getAllUsers()
                        : Future.value(_allUsers),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(child: Text("No search results."));
                      }
                      _allUsers ??= snapshot.data;
                      final currentUserId = authProvider.user?.uid;
                      final query = _searchQuery.trim().toLowerCase();
                      final filteredUsers = _allUsers!
                          .where((u) => u.uid != currentUserId)
                          .where((u) =>
                              u.displayName.toLowerCase().contains(query) ||
                              u.email.toLowerCase().contains(query))
                          .toList();
                      return Column(
                        children: filteredUsers
                            .map((user) => ListTile(
                                  leading: UserAvatar(url: user.photoUrl),
                                  title: Text(user.displayName),
                                  subtitle: Text(user.about),
                                  onTap: () =>
                                      _openChat(context, authProvider, chatProvider, user),
                                ))
                            .toList(),
                      );
                    },
                  ),
                ],
              ],
            ),
    );
  }

  Future<void> _openChat(BuildContext context, AuthProvider authProvider,
      ChatProvider chatProvider, UserEntity user) async {
    final chatId = await chatProvider.startChat(authProvider.user!.uid, user.uid);
    if (context.mounted) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => ChatRoomPage(
          chat: ChatModel(
            id: chatId,
            participants: [authProvider.user!.uid, user.uid],
            lastMessageTime: DateTime.now(),
            isArchived: false,
          ),
          otherUserId: user.uid,
          otherUserName: user.displayName,
          otherUserImage: user.photoUrl ?? '',
        ),
      ));
    }
  }

  void _showInviteDialog(BuildContext context) {
    const inviteLink = "https://whatsapp-ai-ebb0a.web.app";
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Invite a Friend"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
                "Share this link with your friends so they can join you on WhatsApp AI:"),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(inviteLink,
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(const ClipboardData(text: inviteLink));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Link copied to clipboard!")),
              );
            },
            child: const Text("COPY LINK"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CLOSE"),
          ),
        ],
      ),
    );
  }
}
