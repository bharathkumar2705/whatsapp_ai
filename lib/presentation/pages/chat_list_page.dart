import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../widgets/user_avatar.dart';
import 'chat_room_page.dart';
import 'profile_page.dart';
import 'contacts_page.dart';
import 'status_page.dart';
import 'calls_page.dart';
import 'settings_page.dart';
import 'create_group_page.dart';
import 'archived_chats_page.dart';
import 'starred_messages_page.dart';
import 'ai_features_page.dart';
import 'linked_devices_page.dart';
import 'payments_page.dart';
import 'community_list_page.dart';
import 'broadcast_list_page.dart';
import 'rewards_page.dart';
import 'video_call_page.dart';
import '../providers/call_provider.dart';
import '../providers/reward_provider.dart';
import '../../data/services/voice_assistant_service.dart';
import 'my_qr_page.dart';
import 'qr_scanner_page.dart';
import 'secret_vault_page.dart';
import '../providers/secret_vault_provider.dart';
import '../../data/services/streak_service.dart';
import '../../data/models/chat_model.dart';
import '../../data/repositories/user_repository.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/entities/chat_entity.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  bool _isListening = false;
  String _voiceText = "";
  String _currentFilter = 'All'; // All, Unread, Favorites, Groups
  bool _isSearching = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final UserRepository _userRepository = UserRepository();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final authProvider = Provider.of<AuthProvider>(context);
    final uid = authProvider.user?.uid;
    if (uid != null) {
      Provider.of<ChatProvider>(context, listen: false).listenToChats(uid);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final uid = authProvider.user?.uid;

      if (uid != null) {
        Provider.of<ChatProvider>(context, listen: false).listenToChats(uid);
      }

      if (authProvider.isAuthenticated) {
        Provider.of<CallProvider>(context, listen: false).listenToCalls(authProvider.user!.uid);
        Provider.of<CallProvider>(context, listen: false).setOnIncomingCall((roomId, callerId) {
          _showIncomingCallDialog(roomId, callerId);
        });
      }
    });
  }

  void _listen(VoiceAssistantService voiceService) async {
    if (!_isListening) {
      bool available = await voiceService.initializeSpeech();
      if (available) {
        setState(() => _isListening = true);
        voiceService.startListening((text) {
           setState(() {
             _voiceText = text;
           });
           if (text.isNotEmpty) {
             _handleVoiceCommand(text, voiceService);
           }
        });
      }
    } else {
      setState(() => _isListening = false);
      voiceService.stopListening();
    }
  }

  void _handleVoiceCommand(String command, VoiceAssistantService voiceService) async {
    setState(() => _isListening = false);
    voiceService.stopListening();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Assistant: Processing '$command'..."))
    );

    await voiceService.processVoiceCommand(command, (response) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: const [
                Icon(Icons.assistant, color: Color(0xFF075E54)),
                SizedBox(width: 8),
                Text("AI Assistant"),
              ],
            ),
            content: Text(response),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))
            ],
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final voiceService = Provider.of<VoiceAssistantService>(context, listen: false);

    return DefaultTabController(
      length: 4,
      initialIndex: 1,
      child: Scaffold(
        appBar: AppBar(
          title: GestureDetector(
            onLongPress: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SecretVaultPage()));
            },
            child: const Text("WhatsApp AI"),
          ),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(icon: Icon(Icons.groups, size: 20)),
              Tab(text: "CHATS"),
              Tab(text: "STATUS"),
              Tab(text: "CALLS"),
            ],
            indicatorColor: Colors.white,
          ),
          actions: [
            // Coins badge
            Consumer<RewardProvider>(
              builder: (context, rewards, _) => GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RewardsPage())),
                child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.monetization_on, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text("${rewards.coins}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.amber)),
                    ],
                  ),
                ),
              ),
              ),
            ),
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF7B2FE0), Color(0xFF00C6FF)]),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
              ),
              tooltip: "AI Features",
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AiFeaturesPage())),
            ),
            IconButton(
              icon: const Icon(Icons.qr_code_scanner),
              tooltip: "Scan QR",
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QrScannerPage())),
            ),
            IconButton(
              icon: const Icon(Icons.qr_code),
              tooltip: "My QR",
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyQrPage())),
            ),
            IconButton(
              icon: const Icon(Icons.search),
              tooltip: 'Search chats',
              onPressed: () => setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _searchQuery = '';
                }
              }),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'Profile') {
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfilePage()));
                } else if (value == 'New Group') {
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CreateGroupPage()));
                } else if (value == 'Starred Messages') {
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StarredMessagesPage()));
                } else if (value == 'New Community') {
                   Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CommunityListPage()));
                } else if (value == 'New Broadcast') {
                   Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BroadcastListPage()));
                } else if (value == 'Linked Devices') {
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LinkedDevicesPage()));
                } else if (value == 'Payments') {
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PaymentsPage()));
                } else if (value == 'Settings') {
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsPage()));
                } else if (value == 'Read All') {
                  if (authProvider.user?.uid != null) {
                    chatProvider.markAllReadTotal(authProvider.user!.uid);
                  }
                } else if (value == 'Logout') {
                  authProvider.signOut();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'Profile', child: Text('Profile')),
                const PopupMenuItem(value: 'New Group', child: Text('New Group')),
                const PopupMenuItem(value: 'New Community', child: Text('New Community')),
                const PopupMenuItem(value: 'New Broadcast', child: Text('New Broadcast')),
                const PopupMenuItem(value: 'Linked Devices', child: Text('Linked Devices')),
                const PopupMenuItem(value: 'Payments', child: Text('Payments')),
                const PopupMenuItem(value: 'Starred Messages', child: Text('Starred Messages')),
                const PopupMenuItem(value: 'Read All', child: Text('Read All')),
                const PopupMenuItem(value: 'Settings', child: Text('Settings')),
                const PopupMenuItem(value: 'Logout', child: Text('Logout')),
              ],
            ),
          ],
        ),
        body: TabBarView(
          children: [
            const CommunityListPage(),
            // Chats Tab
            Consumer<ChatProvider>(
              builder: (context, chatProvider, child) {
                if (chatProvider.isLoading) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          color: Theme.of(context).colorScheme.primary,
                          strokeWidth: 2.5,
                        ),
                        const SizedBox(height: 16),
                        Text('Loading chats…',
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  );
                }
                
                final myUid = authProvider.user?.uid ?? '';
                final vault = context.watch<SecretVaultProvider>();
                var allChats = chatProvider.chats.where((c) => !c.isArchived && !vault.hiddenChatIds.contains(c.id)).toList();

                // Sort by pinned first, then by time
                allChats.sort((a, b) {
                  if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
                  return b.lastMessageTime.compareTo(a.lastMessageTime);
                });

                // Apply Chat Filters
                var activeChats = allChats;
                if (_currentFilter == 'Unread') {
                  activeChats = allChats.where((c) => (c.unreadCount[myUid] ?? 0) > 0).toList();
                } else if (_currentFilter == 'Favorites') {
                  activeChats = allChats.where((c) => c.isFavorite).toList();
                } else if (_currentFilter == 'Groups') {
                  activeChats = allChats.where((c) => c.isGroup).toList();
                }

                // Apply search filter
                if (_searchQuery.isNotEmpty) {
                  final q = _searchQuery.toLowerCase();
                  activeChats = activeChats.where((c) {
                    final name = (c.isGroup ? (c.groupName ?? '') : c.lastMessage).toLowerCase();
                    return name.contains(q) || c.lastMessage.toLowerCase().contains(q);
                  }).toList();
                }

                final archivedCount = chatProvider.chats.where((c) => c.isArchived).length;
                final scheme = Theme.of(context).colorScheme;

                return Column(
                  children: [
                    // ── Search bar ──────────────────────────────────────────
                    if (_isSearching)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                        child: TextField(
                          controller: _searchController,
                          autofocus: true,
                          decoration: InputDecoration(
                            hintText: 'Search chats...',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => setState(() {
                                _isSearching = false;
                                _searchController.clear();
                                _searchQuery = '';
                              }),
                            ),
                          ),
                          onChanged: (v) => setState(() => _searchQuery = v),
                        ),
                      ),

                    // ── Filter chips — always visible ───────────────────────
                    Container(
                      height: 50,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          _buildFilterChip('All'),
                          const SizedBox(width: 8),
                          _buildFilterChip('Unread'),
                          const SizedBox(width: 8),
                          _buildFilterChip('Favorites'),
                          const SizedBox(width: 8),
                          _buildFilterChip('Groups'),
                        ],
                      ),
                    ),

                    // ── Content ─────────────────────────────────────────────
                    Expanded(
                      child: activeChats.isEmpty && archivedCount == 0
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      color: scheme.primary.withAlpha(20),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.chat_bubble_outline_rounded,
                                      size: 64,
                                      color: scheme.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    'No chats yet',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Tap the chat icon below to start a conversation',
                                    style: Theme.of(context).textTheme.bodySmall,
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            )
                          : ListView(
                              children: [
                                if (archivedCount > 0 && _currentFilter == 'All')
                                  ListTile(
                                    leading: Icon(Icons.archive_outlined, color: scheme.primary),
                                    title: const Text("Archived"),
                                    trailing: Text("$archivedCount",
                                        style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w600)),
                                    onTap: () => Navigator.of(context).push(
                                        MaterialPageRoute(builder: (_) => const ArchivedChatsPage())),
                                  ),
                                ...activeChats.map((chat) {
                                  if (chat.isGroup) {
                                    return _buildChatTile(chat, chat.groupName ?? 'Group',
                                        chat.groupImage, '', authProvider, chatProvider);
                                  } else {
                                    final otherParticipantId = chat.participants.firstWhere(
                                      (id) => id != authProvider.user?.uid,
                                      orElse: () => authProvider.user?.uid ?? '',
                                    );
                                    return StreamBuilder<UserEntity>(
                                      stream: _userRepository.getUserStream(otherParticipantId),
                                      builder: (context, snapshot) {
                                        String title = "User";
                                        String? imageUrl;
                                        if (snapshot.hasData) {
                                          title = snapshot.data!.displayName;
                                          imageUrl = snapshot.data!.photoUrl;
                                          if (otherParticipantId == authProvider.user?.uid) {
                                            title += " (You)";
                                          }
                                        }
                                        return _buildChatTile(chat, title, imageUrl,
                                            otherParticipantId, authProvider, chatProvider);
                                      },
                                    );
                                  }
                                }),
                              ],
                            ),
                    ),
                  ],
                );
              },
            ),
            const StatusPage(),
            const CallsPage(),
          ],
        ),
        floatingActionButton: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton(
              heroTag: 'ai_voice',
              onPressed: () => _listen(voiceService),
              backgroundColor: _isListening ? Colors.red : const Color(0xFF075E54),
              child: Icon(_isListening ? Icons.mic : Icons.assistant, color: Colors.white),
            ),
            const SizedBox(height: 16),
            FloatingActionButton(
              heroTag: 'chat_new',
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ContactsPage()));
              },
              backgroundColor: const Color(0xFF25D366),
              child: const Icon(Icons.chat, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  void _showIncomingCallDialog(String roomId, String callerId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Incoming Video Call"),
        content: Text("Call from $callerId"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Decline", style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CallSessionPage(
                    roomId: roomId,
                    callerId: callerId,
                    receiverId: Provider.of<AuthProvider>(context, listen: false).user!.uid,
                    isIncoming: true,
                    isVideo: true, // Default to video for this listener
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text("Accept"),
          ),
        ],
      ),
    );
  }

  Widget _buildChatTile(ChatEntity chat, String title, String? imageUrl, String otherParticipantId, AuthProvider authProvider, ChatProvider chatProvider) {
    return Dismissible(
      key: Key(chat.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: const Color(0xFF075E54),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.archive, color: Colors.white),
      ),
      onDismissed: (_) {
        chatProvider.toggleArchiveChat(chat.id, true);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Chat archived")));
      },
      child: ListTile(
        leading: UserAvatar(url: imageUrl),
        title: Row(
          children: [
            Expanded(child: Text(title, overflow: TextOverflow.ellipsis)),
            if (chat.isFavorite)
              const Icon(Icons.star, size: 14, color: Colors.amber),
            if (chat.isPinned)
              const Padding(
                padding: EdgeInsets.only(left: 4.0),
                child: Icon(Icons.push_pin, size: 14, color: Colors.grey),
              ),
            if (chat.isLocked)
              const Padding(
                padding: EdgeInsets.only(left: 4.0),
                child: Icon(Icons.lock, size: 14, color: Color(0xFF25D366)),
              ),
            // Streak Display
            StreamBuilder<int>(
              stream: StreakService().getStreak(chat.id, authProvider.user?.uid ?? ''),
              builder: (context, snap) {
                final count = snap.data ?? 0;
                if (count < 1) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(left: 4.0),
                  child: Row(
                    children: [
                      const Text("🔥", style: TextStyle(fontSize: 12)),
                      Text("$count", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orange)),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
        subtitle: Text(chat.lastMessage, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(DateFormat('HH:mm').format(chat.lastMessageTime), style: const TextStyle(fontSize: 12)),
            if ((chat.unreadCount[authProvider.user?.uid ?? ''] ?? 0) > 0)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.all(5),
                decoration: const BoxDecoration(color: Color(0xFF25D366), shape: BoxShape.circle),
                child: Text(
                  "${chat.unreadCount[authProvider.user?.uid ?? '']}",
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => ChatRoomPage(
              chat: chat as ChatModel,
              otherUserId: otherParticipantId,
              otherUserName: title,
              otherUserImage: imageUrl ?? '',
            ),
          ));
        },
        onLongPress: () {
          _showChatOptions(context, chat, chatProvider);
        },
      ),
    );
  }

  void _showChatOptions(BuildContext context, ChatEntity chat, ChatProvider chatProvider) {
    final myUid = Provider.of<AuthProvider>(context, listen: false).user?.uid ?? '';
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(chat.isPinned ? Icons.push_pin : Icons.push_pin_outlined),
              title: Text(chat.isPinned ? 'Unpin Chat' : 'Pin Chat'),
              onTap: () {
                chatProvider.togglePinChat(chat.id, !chat.isPinned);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: Icon(chat.isFavorite ? Icons.star : Icons.star_border),
              title: Text(chat.isFavorite ? 'Remove from Favorites' : 'Add to Favorites'),
              onTap: () {
                chatProvider.toggleFavoriteChat(chat.id, !chat.isFavorite);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: Icon(chat.disappearingEnabled ? Icons.history : Icons.history_outlined),
              title: Text(chat.disappearingEnabled ? 'Disable Disappearing Messages' : 'Enable Disappearing Messages'),
              onTap: () {
                chatProvider.toggleDisappearingMessages(chat.id, !chat.disappearingEnabled);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.archive_outlined),
              title: const Text('Archive Chat'),
              onTap: () {
                chatProvider.toggleArchiveChat(chat.id, true);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.visibility_off_outlined),
              title: const Text('Hide Chat'),
              onTap: () {
                context.read<SecretVaultProvider>().hideChat(chat.id);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Chat hidden in vault")));
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Delete Chat', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                showDialog(
                  context: context,
                  builder: (dCtx) => AlertDialog(
                    title: const Text('Delete Chat?'),
                    content: const Text('This will delete the chat from your view only. The other person will still see their messages.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text('CANCEL')),
                      TextButton(
                        onPressed: () {
                          chatProvider.deleteChat(chat.id, myUid);
                          Navigator.pop(dCtx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Chat deleted')),
                          );
                        },
                        child: const Text('DELETE', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _currentFilter == label;
    return Builder(builder: (context) {
      final scheme = Theme.of(context).colorScheme;
      return GestureDetector(
        onTap: () => setState(() => _currentFilter = label),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? scheme.primary.withAlpha(30) : scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? scheme.primary : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? scheme.primary : scheme.onSurface.withAlpha(160),
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              fontSize: 12,
            ),
          ),
        ),
      );
    });
  }
}
