import 'dart:typed_data';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';
import 'package:geolocator/geolocator.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../../data/models/chat_model.dart';
import '../../data/models/message_model.dart';
import '../../domain/entities/message_entity.dart';
import '../../domain/entities/user_entity.dart';
import '../../data/repositories/user_repository.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/ai_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/reward_provider.dart';
import 'package:whatsapp/presentation/providers/innovation_provider.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/message_input_field.dart';
import '../widgets/user_avatar.dart';
import '../providers/task_provider.dart';
import '../../domain/entities/task_entity.dart';
import 'group_info_page.dart';
import '../../core/web_utils.dart';
import 'package:whatsapp/presentation/pages/gif_search_page.dart';
import 'package:whatsapp/presentation/pages/video_call_page.dart';
import 'package:whatsapp/presentation/pages/view_once_media_page.dart';
import 'chat_export_page.dart';
import 'virtual_space_page.dart';
import '../../data/services/export_service.dart';
import '../../data/services/security_service.dart';
import 'agora_call_page.dart';
import 'package:uuid/uuid.dart';
import '../providers/status_provider.dart';
import 'send_payment_page.dart';
import 'receipt_scanner_page.dart';
import 'time_capsule_page.dart';
import 'voice_room_page.dart';
import 'contact_info_page.dart';
import 'location_picker_page.dart';

class ChatRoomPage extends StatefulWidget {
  final ChatModel chat;
  final String otherUserId;
  final String otherUserName;
  final String otherUserImage;

  const ChatRoomPage({
    super.key,
    required this.chat,
    required this.otherUserId,
    required this.otherUserName,
    required this.otherUserImage,
  });

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final UserRepository _userRepository = UserRepository();
  bool _isSearching = false;
  String _searchQuery = "";
  MessageEntity? _replyingTo;
  MessageEntity? _editingMessage;
  final SecurityService _securityService = SecurityService();
  bool _isChatLocked = false;
  List<UserEntity> _mentionCandidates = [];
  bool _showMentionPicker = false;
  List<Map<String, dynamic>> _quickReplies = [];
  bool _showQuickReplyPicker = false;
  bool _screenshotDetected = false;
  final ScrollController _scrollController = ScrollController();
  int _previousMessageCount = 0;

  @override
  void initState() {
    super.initState();
    _isChatLocked = widget.chat.isLocked;
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });
    
    _messageController.addListener(_onMessageChanged);
    _messageController.addListener(() {
      final text = _messageController.text;
      Provider.of<AiProvider>(context, listen: false).autoScanTasks(text);
    });

    if (_isChatLocked) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _authenticateLock());
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,  // reverse:true means 0 is the bottom
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _onMessageChanged() {
    final text = _messageController.text;
    if (text.startsWith('/')) {
      _loadQuickReplies();
    } else if (_showQuickReplyPicker && !text.startsWith('/')) {
      setState(() => _showQuickReplyPicker = false);
    }
    
    if (text.endsWith('@')) {
      _loadMentionCandidates();
    } else if (_showMentionPicker && !text.contains('@')) {
      setState(() => _showMentionPicker = false);
    }
  }

  Future<void> _loadQuickReplies() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final replies = await authProvider.getQuickReplies().first;
    setState(() {
      _quickReplies = replies;
      _showQuickReplyPicker = replies.isNotEmpty;
    });
  }

  Future<void> _loadMentionCandidates() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final candidates = <UserEntity>[];
    for (var uid in widget.chat.participants) {
      if (uid != authProvider.user?.uid) {
        final user = await _userRepository.getUser(uid);
        if (user != null) candidates.add(user);
      }
    }
    setState(() {
      _mentionCandidates = candidates;
      _showMentionPicker = candidates.isNotEmpty;
    });
  }



  void _addMention(UserEntity user) {
    final text = _messageController.text;
    final lastAt = text.lastIndexOf('@');
    final newText = text.substring(0, lastAt + 1) + user.displayName + " ";
    _messageController.text = newText;
    _messageController.selection = TextSelection.fromPosition(TextPosition(offset: newText.length));
    setState(() => _showMentionPicker = false);
  }

  Future<void> _authenticateLock() async {
    bool authenticated = await _securityService.authenticate();
    if (!authenticated) {
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _toggleLock(ChatProvider chatProvider) async {
    bool authenticated = await _securityService.authenticate();
    if (authenticated) {
      await chatProvider.toggleChatLock(widget.chat.id, !_isChatLocked);
      setState(() => _isChatLocked = !_isChatLocked);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isChatLocked ? "Chat Locked" : "Chat Unlocked")),
        );
      }
    }
  }

  void _onReplySelected(MessageEntity message) {
    setState(() => _replyingTo = message);
  }

  void _cancelReply() {
    setState(() => _replyingTo = null);
  }

  void _onEditSelected(MessageEntity message) {
    setState(() {
      _editingMessage = message;
      _messageController.text = message.text;
    });
  }

  void _cancelEdit() {
    setState(() {
      _editingMessage = null;
      _messageController.clear();
    });
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        _searchQuery = "";
      }
    });
  }

  String _formatLastSeen(DateTime lastSeen) {
    final now = DateTime.now();
    final difference = now.difference(lastSeen);
    if (difference.inMinutes < 1) return 'just now';
    if (difference.inHours < 1) return '${difference.inMinutes}m ago';
    if (difference.inDays < 1) return DateFormat('HH:mm').format(lastSeen);
    return DateFormat('MMM d, HH:mm').format(lastSeen);
  }

  @override
  void dispose() {
    _messageController.removeListener(_onMessageChanged);
    _messageController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final aiProvider = Provider.of<AiProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final myUid = authProvider.user?.uid ?? '';
    final me = authProvider.userModel;

    bool isBlockedByMe = me?.blockedUsers.contains(widget.otherUserId) ?? false;

    return Scaffold(
      appBar: AppBar(
        title: _isSearching 
          ? TextField(
              controller: _searchController,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: "Search messages...",
                hintStyle: TextStyle(color: Colors.white70),
                border: InputBorder.none,
              ),
            )
          : Row(
              children: [
                UserAvatar(radius: 18, url: widget.otherUserImage),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    onTap: widget.chat.isGroup ? () {
                      Navigator.push(context, MaterialPageRoute(
                        builder: (_) => GroupInfoPage(chat: widget.chat),
                      ));
                    } : () {
                      Navigator.push(context, MaterialPageRoute(
                        builder: (_) => ContactInfoPage(
                          otherUserId: widget.otherUserId,
                          otherUserName: widget.otherUserName,
                          otherUserImage: widget.otherUserImage,
                          chat: widget.chat,
                        ),
                      ));
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Text(widget.otherUserName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            FutureBuilder<UserEntity?>(
                              future: _userRepository.getUser(widget.otherUserId),
                              builder: (context, snapshot) {
                                if (snapshot.hasData && snapshot.data!.isVerified) {
                                  return const Padding(
                                    padding: EdgeInsets.only(left: 4),
                                    child: Icon(Icons.verified, color: Colors.blue, size: 16),
                                  );
                                }
                                return const SizedBox();
                              },
                            ),
                            if (widget.chat.isFavorite)
                              const Padding(
                                padding: EdgeInsets.only(left: 4),
                                child: Icon(Icons.star, size: 14, color: Colors.amber),
                              ),
                          ],
                        ),
                        if (!widget.chat.isGroup)
                          StreamBuilder<UserEntity>(
                            stream: _userRepository.getUserStream(widget.otherUserId),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData || isBlockedByMe) return const SizedBox.shrink();
                              final otherUser = snapshot.data!;
                              
                              bool blockedUs = otherUser.blockedUsers.contains(myUid);
                              if (blockedUs) return const SizedBox.shrink();

                              bool canSeeLastSeen = otherUser.privacySettings['lastSeen'] == 'Everyone' || 
                                  (otherUser.privacySettings['lastSeen'] == 'My contacts');

                              if (otherUser.isOnline) {
                                return Text("online", style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onPrimary));
                              } else if (canSeeLastSeen) {
                                return Text(
                                  "last seen ${DateFormat('HH:mm').format(otherUser.lastSeen)}", 
                                  style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onPrimary.withAlpha(200))
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        if (widget.chat.isGroup)
                          Text(
                            "${widget.chat.participants.length} participants",
                            style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onPrimary.withAlpha(200)),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
        actions: [
          IconButton(
            icon: const Icon(Icons.videocam),
            tooltip: 'Video call',
            onPressed: isBlockedByMe ? null : () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AgoraCallPage(
                    channelName: widget.chat.id,
                    calleeName: widget.otherUserName,
                    calleeImageUrl: widget.otherUserImage.isNotEmpty ? widget.otherUserImage : null,
                    isVideo: true,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.call),
            tooltip: 'Voice call',
            onPressed: isBlockedByMe ? null : () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AgoraCallPage(
                    channelName: widget.chat.id,
                    calleeName: widget.otherUserName,
                    calleeImageUrl: widget.otherUserImage.isNotEmpty ? widget.otherUserImage : null,
                    isVideo: false,
                  ),
                ),
              );
            },
          ),
          Consumer2<AiProvider, ThemeProvider>(
            builder: (context, ai, theme, _) {
              // Sync mood theme
              WidgetsBinding.instance.addPostFrameCallback((_) {
                theme.updateThemeBasedOnMood(ai.currentMoodEmoji);
              });
              return Tooltip(
                message: "Conversation Mood Pulse",
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(ai.currentMoodEmoji, style: const TextStyle(fontSize: 22)),
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.auto_awesome),
            tooltip: "AI Actions",
            onPressed: () => _showAiActions(aiProvider, chatProvider),
          ),
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: _toggleSearch,
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'block') {
                authProvider.toggleBlockUser(widget.otherUserId);
              } else if (value == 'report') {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("User reported. Thank you for making WhatsApp AI safer!")));
              } else if (value == 'lock') {
                _toggleLock(chatProvider);
              } else if (value == 'group_settings') {
                _showGroupSettings(chatProvider);
              } else if (value == 'join_requests') {
                _showJoinRequests(chatProvider);
              } else if (value == 'invite_link') {
                _showInviteLink(chatProvider);
              } else if (value == 'export') {
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => ChatExportPage(
                    chat: widget.chat,
                    chatName: widget.otherUserName,
                  ),
                ));
              } else if (value == 'disappearing') {
                chatProvider.toggleDisappearingMessages(widget.chat.id, !widget.chat.disappearingEnabled);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(widget.chat.disappearingEnabled ? "Disappearing messages off" : "Disappearing messages on (24h)"),
                ));
              } else if (value == 'clear_chat') {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text("Clear chat"),
                    content: const Text("All messages will be deleted. This cannot be undone."),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL")),
                      TextButton(
                        onPressed: () async {
                          Navigator.pop(ctx);
                          final msgs = await chatProvider.getMessagesOnce(widget.chat.id);
                          for (final m in msgs) {
                            await chatProvider.deleteMessage(widget.chat.id, m.id);
                          }
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Chat cleared")));
                        },
                        child: const Text("CLEAR", style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              } else if (value == 'delete_chat') {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text("Delete chat"),
                    content: const Text("This chat will be removed from your list."),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL")),
                      TextButton(
                        onPressed: () async {
                          Navigator.pop(ctx);
                          await chatProvider.deleteChat(widget.chat.id, myUid);
                          if (mounted) Navigator.pop(context);
                        },
                        child: const Text("DELETE", style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'disappearing',
                child: Row(children: [Icon(Icons.timer_outlined, size: 18), SizedBox(width: 10), Text("Disappearing messages")]),
              ),
              PopupMenuItem(
                value: 'lock',
                child: Row(children: [Icon(_isChatLocked ? Icons.lock_open : Icons.lock_outline, size: 18), const SizedBox(width: 10), Text(_isChatLocked ? "Unlock Chat" : "Lock Chat")]),
              ),
              if (widget.chat.isGroup && widget.chat.admins.contains(myUid)) ...[
                const PopupMenuItem(value: 'group_settings', child: Row(children: [Icon(Icons.settings, size: 18), SizedBox(width: 10), Text("Group Settings")])),
                const PopupMenuItem(value: 'join_requests', child: Row(children: [Icon(Icons.how_to_reg, size: 18), SizedBox(width: 10), Text("Join Requests")])),
                const PopupMenuItem(value: 'invite_link', child: Row(children: [Icon(Icons.link, size: 18), SizedBox(width: 10), Text("Invite Link")])),
              ],
              if (!widget.chat.isGroup)
                PopupMenuItem(
                  value: 'block',
                  child: Row(children: [Icon(Icons.block, size: 18), const SizedBox(width: 10), Text(isBlockedByMe ? "Unblock" : "Block")]),
                ),
              const PopupMenuItem(
                value: 'report',
                child: Row(children: [Icon(Icons.flag_outlined, size: 18), SizedBox(width: 10), Text("Report")]),
              ),
              const PopupMenuItem(
                value: 'export',
                child: Row(children: [Icon(Icons.ios_share, size: 18), SizedBox(width: 10), Text("Export chat")]),
              ),
              const PopupMenuItem(
                value: 'clear_chat',
                child: Row(children: [Icon(Icons.cleaning_services_outlined, size: 18, color: Colors.red), SizedBox(width: 10), Text("Clear chat", style: TextStyle(color: Colors.red))]),
              ),
              const PopupMenuItem(
                value: 'delete_chat',
                child: Row(children: [Icon(Icons.delete_outline, size: 18, color: Colors.red), SizedBox(width: 10), Text("Delete chat", style: TextStyle(color: Colors.red))]),
              ),
            ],
          ),
        ],
      ),
      backgroundColor: context.watch<ThemeProvider>().moodColor == Colors.transparent 
          ? null 
          : context.watch<ThemeProvider>().moodColor.withOpacity(0.05),
      body: SafeArea(
        top: false,
        maintainBottomViewPadding: true,
        child: Column(
          children: [
            if (_screenshotDetected)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red, width: 2),
                ),
                child: Row(
                  children: [
                  const Icon(Icons.security, color: Colors.red),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "🚨 Privacy Alert: A screenshot was detected! Ghost Mode is active.",
                      style: TextStyle(color: Colors.red[900], fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () => setState(() => _screenshotDetected = false),
                  )
                ],
              ),
            ),
          
          _buildAiTaskSuggestionChip(),

          Expanded(
            child: StreamBuilder<List<MessageEntity>>(
              stream: chatProvider.getMessages(widget.chat.id),
              builder: (context, snapshot) {
                // Only show spinner if we have NO data yet (first load)
                if (!snapshot.hasData && snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  debugPrint('ChatRoomPage stream error: ${snapshot.error}');
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 48),
                        const SizedBox(height: 12),
                        const Text("Could not load messages.", style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('${snapshot.error}', style: const TextStyle(fontSize: 11, color: Colors.grey), textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () => setState(() {}),
                          child: const Text("RETRY"),
                        ),
                      ],
                    ),
                  );
                }

                // No error, no data — treat as empty chat
                if (!snapshot.hasData) {
                  return const Center(child: Text("No messages yet. Say hi! 👋"));
                }
                
                final allMessages = snapshot.data ?? [];
                final messages = _searchQuery.isEmpty 
                    ? allMessages 
                    : allMessages.where((m) => m.text.toLowerCase().contains(_searchQuery)).toList();

                // Trigger smart replies when the newest message is from the other person
                if (allMessages.isNotEmpty && allMessages.first.senderId != myUid) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    final ai = Provider.of<AiProvider>(context, listen: false);
                    if (ai.smartReplies.isEmpty && !ai.isAnalyzing) {
                      ai.fetchSmartReplies(allMessages.take(10).toList());
                    }
                    // Refresh mood trend if messages changed
                    if (!ai.isAnalyzing) {
                      ai.fetchMoodTrend(allMessages.take(20).toList(), widget.chat.id);
                    }
                    // Auto-scan last incoming message for toxicity
                    if (allMessages.isNotEmpty) {
                      final lastMsg = allMessages.first;
                      if (lastMsg.senderId != myUid) {
                        if (ai.getToxicityAlert(lastMsg.id) == null) {
                          ai.checkToxicity(lastMsg.text, lastMsg.id);
                        }
                        if (ai.getSafetyAlert(lastMsg.id) == null) {
                          ai.runSafetyCheck(lastMsg.text, lastMsg.id);
                        }
                      }
                    }
                  });
                }

                if (messages.isEmpty) {
                  return const Center(child: Text("No messages found."));
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == myUid;
                    
                    final isSeen = message.seenBy.contains(myUid);
                    if (!isMe && !isSeen) {
                      chatProvider.markAsSeen(widget.chat.id, message.id, myUid);
                    }

                    return StreamBuilder<UserEntity>(
                      stream: _userRepository.getUserStream(message.senderId),
                      builder: (context, userSnapshot) {
                        String senderName = "User ${message.senderId}";
                        if (userSnapshot.hasData) {
                          senderName = userSnapshot.data!.displayName;
                        }
                        return ChatBubble(
                          text: message.text,
                          isMe: isMe,
                          timestamp: message.timestamp,
                          type: message.type,
                          mediaUrl: message.mediaUrl,
                          status: message.status,
                          reactions: message.reactions,
                          replyText: message.replyText,
                          showName: widget.chat.isGroup,
                          senderName: senderName,
                          isStarred: message.isStarred,
                          isForwarded: message.isForwarded,
                          isEdited: message.isEdited,
                          isViewOnce: message.isViewOnce,
                          isHd: message.isHd,
                          latitude: message.latitude,
                          longitude: message.longitude,
                          toxicityAlert: aiProvider.getToxicityAlert(message.id),
                          safetyAlert: aiProvider.getSafetyAlert(message.id),
                          messageId: message.id,
                          chatId: widget.chat.id,
                          pluginData: message.pluginData,
                          onReaction: (emoji) => chatProvider.toggleReaction(
                            widget.chat.id,
                            message.id,
                            emoji,
                            message.reactions,
                          ),
                          onSwipe: () => _onReplySelected(message),
                          onStar: (starred) => chatProvider.toggleStarMessage(
                            widget.chat.id,
                            message.id,
                            starred,
                          ),
                          onEdit: isMe && message.type == 'text' ? (text) => _onEditSelected(message) : null,
                          onDelete: (isMe || (widget.chat.isGroup && widget.chat.admins.contains(myUid))) ? () => _showDeleteConfirmation(message) : null,
                          onForward: () => _forwardToUser(message),
                          onViewOnceOpen: message.isViewOnce && !isMe && message.status != 'opened' ? () {
                            Navigator.push(context, MaterialPageRoute(
                              builder: (_) => ViewOnceMediaPage(
                                chatId: widget.chat.id,
                                messageId: message.id,
                                mediaUrl: message.mediaUrl,
                                type: message.type,
                              ),
                            ));
                          } : null,
                          pollOptions: message.pollOptions,
                          eventData: message.eventData,
                          contactData: message.contactData,
                          onTranslate: (lang) async {
                        final translation = await aiProvider.translateMessage(message.text, lang);
                        if (mounted) {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text("Translation ($lang)"),
                              content: Text(translation),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text("OK"),
                                ),
                              ],
                            ),
                          );
                        }
                      },
                    );
                  },
                );
              },
                );
              },
            ),
          ),
          _buildAiSmartBar(aiProvider, Provider.of<TaskProvider>(context)),
          if (aiProvider.smartReplies.isNotEmpty)
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: aiProvider.smartReplies.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: ActionChip(
                      label: Text(aiProvider.smartReplies[index]),
                      onPressed: isBlockedByMe ? null : () {
                        chatProvider.sendMessage(
                          widget.chat.id,
                          myUid,
                          widget.otherUserId,
                          aiProvider.smartReplies[index],
                        );
                        aiProvider.clearReplies();
                      },
                    ),
                  );
                },
              ),
            ),
          if (_showMentionPicker)
            Container(
              height: 150,
              color: Theme.of(context).colorScheme.surface,
              child: ListView.builder(
                itemCount: _mentionCandidates.length,
                itemBuilder: (context, index) {
                  final user = _mentionCandidates[index];
                  return ListTile(
                    leading: UserAvatar(url: user.photoUrl, radius: 15),
                    title: Text(user.displayName),
                    onTap: () => _addMention(user),
                  );
                },
              ),
            ),
          if (widget.chat.isGroup && widget.chat.adminOnly && !widget.chat.admins.contains(myUid))
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.grey[200],
              child: const Text(
                "Only admins can send messages",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            )
          else if (isBlockedByMe)
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.red[50],
              child: const Text(
                "You blocked this contact. Unblock to send messages.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red, fontSize: 13),
              ),
            )
          else
            if (_showQuickReplyPicker) _buildQuickReplyPicker(),
          MessageInputField(
              controller: _messageController,
              onSend: () {
                if (_messageController.text.trim().isNotEmpty) {
                  if (_editingMessage != null) {
                    chatProvider.editMessage(widget.chat.id, _editingMessage!.id, _messageController.text.trim());
                    _cancelEdit();
                  } else {
                    chatProvider.sendMessage(
                      widget.chat.id,
                      myUid,
                      widget.otherUserId,
                      _messageController.text.trim(),
                      replyToId: _replyingTo?.id,
                      replyText: _replyingTo?.text,
                    );
                    context.read<RewardProvider>().rewardMessageSent();
                    _messageController.clear();
                    _cancelReply();
                  }
                }
              },
              onAttachment: () => _handleAttachment(chatProvider, myUid),
              onVoiceSend: (file) => _handleVoiceSend(chatProvider, myUid, file),
              replyingTo: _replyingTo,
              editingMessage: _editingMessage,
              onCancelReply: _cancelReply,
              onCancelEdit: _cancelEdit,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAiSmartBar(AiProvider ai, TaskProvider taskProvider) {
    if (ai.isAnalyzing) return const LinearProgressIndicator(minHeight: 2);
    if (ai.extractedTasks.isEmpty && ai.eventSuggestions.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 40,
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(100),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        children: [
          ...ai.extractedTasks.map((t) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              avatar: const Icon(Icons.checklist, size: 14),
              label: Text("Add Task: ${t.title}", style: const TextStyle(fontSize: 11)),
              onPressed: () {
                taskProvider.addTask(t);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Task added to to-do!")));
              },
            ),
          )),
          ...ai.eventSuggestions.map((e) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              avatar: const Icon(Icons.calendar_today, size: 14),
              label: Text("Schedule: ${e['title']}", style: const TextStyle(fontSize: 11)),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Calendar integration coming soon!")));
              },
            ),
          )),
        ],
      ),
    );
  }

  void _showAiActions(AiProvider ai, ChatProvider chat) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("AI Assistant & Innovations", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  _aiActionTile(
                    icon: Icons.summarize,
                    color: Colors.blue,
                    title: "Summarize Conversation",
                    subtitle: "Get a quick recap of the recent chat",
                    onTap: () async {
                      final msgs = await chat.getMessages(widget.chat.id).first;
                      final summary = await ai.summarizeChat(msgs);
                      if (mounted) {
                        Navigator.pop(context);
                        showDialog(context: context, builder: (c) => AlertDialog(
                          title: const Text("AI Summary"), 
                          content: SingleChildScrollView(child: Text(summary)),
                          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close"))],
                        ));
                      }
                    },
                  ),
                  _aiActionTile(
                    icon: Icons.checklist_rtl,
                    color: Colors.teal,
                    title: "Extract Tasks",
                    subtitle: "Detect actionable items in this chat",
                    onTap: () async {
                      final msgs = await chat.getMessages(widget.chat.id).first;
                      await ai.extractTasks(msgs, widget.chat.id);
                      if (mounted) Navigator.pop(context);
                    },
                  ),
                  _aiActionTile(
                    icon: Icons.account_balance_wallet,
                    color: Colors.purple,
                    title: "Shared Expense Tracker",
                    subtitle: "Track group costs and split bills",
                    onTap: () {
                      final myUid = Provider.of<AuthProvider>(context, listen: false).user?.uid;
                      if (myUid == null) return;
                      chat.sendMessage(
                        widget.chat.id, 
                        myUid, 
                        widget.otherUserId, 
                        "Shared Expense Tracker started",
                        pluginData: {'type': 'expense_tracker', 'expenses': []},
                      );
                      Navigator.pop(context);
                    },
                  ),
                  _aiActionTile(
                    icon: Icons.videogame_asset,
                    color: Colors.indigo,
                    title: "Start Tic Tac Toe",
                    subtitle: "Challenge the group to a quick game",
                    onTap: () {
                      final myUid = Provider.of<AuthProvider>(context, listen: false).user?.uid;
                      if (myUid == null) return;
                      chat.sendMessage(
                        widget.chat.id, 
                        myUid, 
                        widget.otherUserId, 
                        "Tic Tac Toe game started",
                        pluginData: {
                          'type': 'tic_tac_toe',
                          'board': List.filled(9, 0),
                          'nextTurnUid': myUid,
                        },
                      );
                      Navigator.pop(context);
                    },
                  ),
                  _aiActionTile(
                    icon: Icons.timer,
                    color: Colors.deepOrange,
                    title: "Group Study Timer",
                    subtitle: "Focus together with group pomodoro",
                    onTap: () {
                      final myUid = Provider.of<AuthProvider>(context, listen: false).user?.uid;
                      if (myUid == null) return;
                      chat.sendMessage(
                        widget.chat.id, 
                        myUid, 
                        widget.otherUserId, 
                        "Study Timer started",
                        pluginData: {
                          'type': 'study_timer',
                          'duration': 25 * 60,
                          'startTime': null,
                          'isPaused': false,
                        },
                      );
                      Navigator.pop(context);
                    },
                  ),
                  _aiActionTile(
                    icon: Icons.event,
                    color: Colors.orange,
                    title: "Plan Events",
                    subtitle: "Identify meeting times and locations",
                    onTap: () async {
                      final msgs = await chat.getMessages(widget.chat.id).first;
                      await ai.suggestEvents(msgs);
                      if (mounted) Navigator.pop(context);
                    },
                  ),
                  _aiActionTile(
                    icon: Icons.security,
                    color: Colors.redAccent,
                    title: "Check for Spam",
                    subtitle: "Scan chat for potential threats",
                    onTap: () async {
                      final msgs = await chat.getMessages(widget.chat.id).first;
                      if (msgs.isNotEmpty) {
                        final isSpam = await ai.checkSpam(msgs.first.text);
                        if (mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(isSpam ? "⚠️ High Risk! This message looks like spam." : "Message analysis: Safe."),
                            backgroundColor: isSpam ? Colors.red : Colors.green,
                          ));
                        }
                      }
                    },
                  ),
                  _aiActionTile(
                    icon: Icons.screenshot_monitor,
                    color: Colors.blueGrey,
                    title: "Simulate Screenshot",
                    subtitle: "Test the privacy detection system",
                    onTap: () {
                      Navigator.pop(context);
                      setState(() => _screenshotDetected = true);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text("AI Insight: User screenshot detected!"),
                        backgroundColor: Colors.orange,
                      ));
                    },
                  ),
                  _aiActionTile(
                    icon: Icons.vrpano,
                    color: Colors.cyan,
                    title: "VR Group Room",
                    subtitle: "Enter a 3D meeting space",
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => VirtualSpacePage(roomId: widget.chat.id)));
                    },
                  ),
                  _aiActionTile(
                    icon: Icons.inventory,
                    color: Colors.deepPurple,
                    title: "AI Productivity",
                    subtitle: "PDF Export, Minutes & Notes",
                    onTap: () => _showProductivityMenu(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _aiActionTile({required IconData icon, required Color color, required String title, required String subtitle, required VoidCallback onTap}) {
    return ListTile(
      leading: CircleAvatar(backgroundColor: color.withAlpha(40), child: Icon(icon, color: color)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      onTap: onTap,
    );
  }

  Future<void> _handleAttachment(ChatProvider chatProvider, String myUid) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
        child: GridView.count(
          shrinkWrap: true,
          crossAxisCount: 4,
          mainAxisSpacing: 10,
          crossAxisSpacing: 8,
          childAspectRatio: 0.70,
          children: [
            _buildAttachmentItem(
              icon: Icons.description,
              color: Colors.deepPurple,
              label: "Document",
              onTap: () => _handleDocumentPick(chatProvider, myUid),
            ),
            _buildAttachmentItem(
              icon: Icons.camera_alt,
              color: Colors.pink,
              label: "Camera",
              onTap: () => _handleCameraPick(chatProvider, myUid),
            ),
            _buildAttachmentItem(
              icon: Icons.photo,
              color: Colors.indigo,
              label: "Gallery",
              onTap: () => _handleImagePick(chatProvider, myUid),
            ),
            _buildAttachmentItem(
              icon: Icons.high_quality,
              color: Colors.blueAccent,
              label: "HD Gallery",
              onTap: () => _handleImagePick(chatProvider, myUid, isHd: true),
            ),
            _buildAttachmentItem(
              icon: Icons.headset,
              color: Colors.orange,
              label: "Audio",
              onTap: () => _handleAudioPick(chatProvider, myUid),
            ),
            _buildAttachmentItem(
              icon: Icons.location_on,
              color: Colors.green,
              label: "Location",
              onTap: () => _handleLocationSend(chatProvider, myUid),
            ),
            _buildAttachmentItem(
              icon: Icons.person,
              color: Colors.blue,
              label: "Contact",
              onTap: () => _showContactPicker(chatProvider, myUid),
            ),
            _buildAttachmentItem(
              icon: Icons.looks_one,
              color: Colors.teal,
              label: "View Once",
              onTap: () => _handleViewOncePick(chatProvider, myUid),
            ),
            _buildAttachmentItem(
              icon: Icons.poll,
              color: Colors.orangeAccent,
              label: "Poll",
              onTap: () => _showPollDialog(chatProvider, myUid),
            ),
            _buildAttachmentItem(
              icon: Icons.event,
              color: Colors.pinkAccent,
              label: "Event",
              onTap: () => _showEventDialog(chatProvider, myUid),
            ),
            _buildAttachmentItem(
              icon: Icons.gif,
              color: Colors.pink,
              label: "GIF",
              onTap: () => _handleGifSearch(chatProvider, myUid),
            ),
            _buildAttachmentItem(
              icon: Icons.videocam_outlined,
              color: Colors.red,
              label: "Video",
              onTap: () => _handleVideoPick(chatProvider, myUid),
            ),
            _buildAttachmentItem(
              icon: Icons.payments,
              color: Colors.green,
              label: "Payment",
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => SendPaymentPage(
                    chatId: widget.chat.id,
                    otherUserId: widget.otherUserId,
                    otherUserName: widget.otherUserName,
                  ),
                ));
              },
            ),
            _buildAttachmentItem(
              icon: Icons.receipt_long,
              color: Colors.blueGrey,
              label: "Scan Bill",
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => ReceiptScannerPage(chatId: widget.chat.id),
                ));
              },
            ),
            _buildAttachmentItem(
              icon: Icons.hourglass_bottom,
              color: Colors.amber,
              label: "Time Capsule",
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => TimeCapsulePage(
                    chatId: widget.chat.id,
                    otherUserId: widget.otherUserId,
                  ),
                ));
              },
            ),
            _buildAttachmentItem(
              icon: Icons.mic_external_on,
              color: Colors.blueAccent,
              label: "Voice Room",
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => VoiceRoomPage(
                    roomId: widget.chat.id,
                    roomName: widget.chat.isGroup ? (widget.chat.groupName ?? 'Group') : widget.otherUserName,
                  ),
                ));
              },
            ),
            _buildAttachmentItem(
              icon: Icons.edit_note,
              color: Colors.purple,
              label: "Whiteboard",
              onTap: () {
                context.read<InnovationProvider>().startWhiteboard(chatId: widget.chat.id, myUid: myUid);
              },
            ),
            _buildAttachmentItem(
              icon: Icons.code,
              color: Colors.cyan,
              label: "Code",
              onTap: () {
                context.read<InnovationProvider>().startCodeEditor(chatId: widget.chat.id, myUid: myUid, language: 'dart');
              },
            ),
            _buildAttachmentItem(
              icon: Icons.shopping_basket,
              color: Colors.orange,
              label: "Grocery List",
              onTap: () {
                context.read<InnovationProvider>().startGroceryList(chatId: widget.chat.id, myUid: myUid);
              },
            ),
            _buildAttachmentItem(
              icon: Icons.quiz,
              color: Colors.indigo,
              label: "Quiz",
              onTap: () {
                context.read<InnovationProvider>().startQuizBattle(chatId: widget.chat.id, myUid: myUid);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentItem({required IconData icon, required Color color, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: color.withOpacity(0.1),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: Colors.black54),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Future<void> _handleDocumentPick(ChatProvider chatProvider, String myUid) async {
    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Opening file picker...")));
      }

      XFile? file;
      if (kIsWeb) {
        file = await WebUtils.pickFile();
      } else {
        try {
          final result = await FilePicker.platform.pickFiles(
            type: FileType.any,
            allowMultiple: false,
            withData: true, // Crucial for some Android devices
          );
          if (result != null && result.files.isNotEmpty) {
            final picked = result.files.single;
            if (picked.bytes != null) {
              // Creating XFile directly from bytes is safer on Android 11+ scoped storage
              file = XFile.fromData(picked.bytes!, name: picked.name);
            } else if (picked.path != null) {
              file = XFile(picked.path!, name: picked.name);
            }
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Picker Error: $e")));
          }
          return;
        }
      }

      if (file == null) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No file selected.")));
        return;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Uploading ${file.name}... ⏳"), duration: const Duration(seconds: 60)),
        );
      }
      
      try {
        await chatProvider.sendDocumentMessage(
          widget.chat.id, myUid, widget.otherUserId, file, file.name,
        );
      } catch (uploadError) {
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Upload Failed: $uploadError")));
        }
        return;
      }

      // Dismiss the uploading snackbar and show success
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("✅ ${file.name} sent!"), duration: const Duration(seconds: 2)),
        );
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint("Error picking document: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Unexpected Error: $e")));
      }
    }
  }

  Future<void> _handleCameraPick(ChatProvider chatProvider, String myUid) async {
    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Opening camera... (On Web, browsers may show a file picker)"),
          duration: Duration(seconds: 2),
        ));
      }
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.camera);
      if (image != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Sending photo...")));
        }
        await chatProvider.sendMediaMessage(widget.chat.id, myUid, widget.otherUserId, image, 'image');
      }
    } catch (e) {
      debugPrint("Error with camera: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Camera Error: $e")));
      }
    }
  }

  Future<void> _handleAudioPick(ChatProvider chatProvider, String myUid) async {
    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Opening audio picker...")));
      }
      final file = await WebUtils.pickFile(accept: 'audio/*');
      if (file != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Sending audio...")));
        }
        await chatProvider.sendMediaMessage(widget.chat.id, myUid, widget.otherUserId, file, 'audio');
      }
    } catch (e) {
      debugPrint("Error picking audio: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Audio Error: $e")));
      }
    }
  }

  void _showStickerPicker(ChatProvider chatProvider, String myUid) {
    final stickers = ['🚀', '✨', '🔥', '💎', '🎉', '🌟', '🍀', '🍎', '🤖', '👾'];
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        height: 200,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text("Select Sticker", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5),
                itemCount: stickers.length,
                itemBuilder: (context, index) => GestureDetector(
                  onTap: () {
                    chatProvider.sendMessage(widget.chat.id, myUid, widget.otherUserId, stickers[index]);
                    Navigator.pop(context);
                  },
                  child: Center(child: Text(stickers[index], style: const TextStyle(fontSize: 40))),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showContactPicker(ChatProvider chatProvider, String myUid) async {
    if (kIsWeb) {
      _showManualContactDialog(chatProvider, myUid);
      return;
    }
    try {
      if (await FlutterContacts.requestPermission()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Fetching contacts...")));
        }
        List<Contact> contacts = await FlutterContacts.getContacts(withProperties: true);
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text("Select Contact"),
              content: SizedBox(
                width: double.maxFinite,
                child: contacts.isEmpty 
                  ? const Center(child: Text("No contacts found"))
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: contacts.length,
                      itemBuilder: (context, index) {
                        final contact = contacts[index];
                        final phone = contact.phones.isNotEmpty ? contact.phones.first.number : "No phone";
                        return ListTile(
                          leading: CircleAvatar(
                            child: Text(contact.displayName[0]),
                          ),
                          title: Text(contact.displayName),
                          subtitle: Text(phone),
                          onTap: () {
                            chatProvider.sendContactMessage(widget.chat.id, myUid, widget.otherUserId, contact.displayName, phone);
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
              ],
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Contact permission denied. Please enable it in settings.")));
        }
      }
    } catch (e) {
      debugPrint("Error picking contact: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Contacts Error: $e. Using manual entry instead.")));
      }
      _showManualContactDialog(chatProvider, myUid);
    }
  }

  void _showManualContactDialog(ChatProvider chatProvider, String myUid) {
    String name = '';
    String phone = '';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Share Contact"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: "Name"),
              onChanged: (val) => name = val,
            ),
            TextField(
              decoration: const InputDecoration(labelText: "Phone Number"),
              keyboardType: TextInputType.phone,
              onChanged: (val) => phone = val,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              if (name.isNotEmpty && phone.isNotEmpty) {
                chatProvider.sendContactMessage(widget.chat.id, myUid, widget.otherUserId, name, phone);
                Navigator.pop(context);
              }
            },
            child: const Text("Share"),
          ),
        ],
      ),
    );
  }

  void _showPollDialog(ChatProvider chatProvider, String myUid) {
    String question = '';
    List<String> options = ['', ''];
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Create Poll"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: const InputDecoration(labelText: "Question"),
                  onChanged: (val) => question = val,
                ),
                ...List.generate(options.length, (index) => TextField(
                  decoration: InputDecoration(labelText: "Option ${index + 1}"),
                  onChanged: (val) => options[index] = val,
                )),
                TextButton(
                  onPressed: () => setDialogState(() => options.add('')),
                  child: const Text("Add Option"),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            TextButton(
              onPressed: () {
                if (question.isNotEmpty && options.any((o) => o.isNotEmpty)) {
                  chatProvider.sendPollMessage(widget.chat.id, myUid, widget.otherUserId, question, options.where((o) => o.isNotEmpty).toList());
                  Navigator.pop(context);
                }
              },
              child: const Text("Send"),
            ),
          ],
        ),
      ),
    );
  }

  void _showEventDialog(ChatProvider chatProvider, String myUid) {
    String title = '';
    String description = '';
    DateTime date = DateTime.now();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Create Event"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: "Title"),
              onChanged: (val) => title = val,
            ),
            TextField(
              decoration: const InputDecoration(labelText: "Description"),
              onChanged: (val) => description = val,
            ),
            ListTile(
              title: const Text("Date"),
              subtitle: Text("${date.toLocal()}".split(' ')[0]),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: date,
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2100),
                );
                if (picked != null) date = picked;
              },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              if (title.isNotEmpty) {
                chatProvider.sendEventMessage(widget.chat.id, myUid, widget.otherUserId, title, description, date);
                Navigator.pop(context);
              }
            },
            child: const Text("Send"),
          ),
        ],
      ),
    );
  }

  Future<void> _handleImagePick(ChatProvider chatProvider, String myUid, {bool isHd = false}) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: isHd ? 100 : 75,
    );
    if (image == null) return;

    // ── Show preview before sending ──────────────────────────────────────
    final captionController = TextEditingController();
    final shouldSend = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFF075E54),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.image, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    isHd ? 'Send HD Photo' : 'Send Photo',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(ctx, false),
                  ),
                ],
              ),
            ),
            // Image preview
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.45,
              ),
              child: FutureBuilder<Uint8List>(
                future: image.readAsBytes(),
                builder: (_, snap) {
                  if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                  return Image.memory(snap.data!, fit: BoxFit.contain);
                },
              ),
            ),
            // Caption field
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: TextField(
                controller: captionController,
                decoration: InputDecoration(
                  hintText: 'Add a caption...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
            ),
            // Actions
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('CANCEL'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                    icon: const Icon(Icons.send, color: Colors.white, size: 18),
                    label: const Text('SEND', style: TextStyle(color: Colors.white)),
                    onPressed: () => Navigator.pop(ctx, true),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    captionController.dispose();

    if (shouldSend != true) return;

    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Uploading image...')));
    try {
      await chatProvider.sendMediaMessage(
        widget.chat.id, myUid, widget.otherUserId, image, 'image', isHd: isHd,
      );
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Image sent ✓')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  Future<void> _handleVideoPick(ChatProvider chatProvider, String myUid) async {
    final picker = ImagePicker();
    final XFile? video = await picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(minutes: 5),
    );
    if (video == null) return;

    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Uploading video... this may take a moment')),
    );
    try {
      await chatProvider.sendMediaMessage(
        widget.chat.id, myUid, widget.otherUserId, video, 'video',
      );
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Video sent ✓')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Video upload failed: $e')));
    }
  }

  Future<void> _handleLocationSend(ChatProvider chatProvider, String myUid) async {
    debugPrint("ChatRoomPage: _handleLocationSend called");
    try {
      final LatLng? pickedLocation = await Navigator.push<LatLng>(
        context,
        MaterialPageRoute(builder: (_) => const LocationPickerPage()),
      );

      if (pickedLocation != null) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Sharing location...")));
        await chatProvider.sendLocationMessage(
          widget.chat.id,
          myUid,
          widget.otherUserId,
          pickedLocation.latitude,
          pickedLocation.longitude,
        );
      }
    } catch (e) {
      debugPrint("ChatRoomPage Error sharing location: $e");
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<void> _handleVoiceSend(ChatProvider chatProvider, String myUid, XFile file) async {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Sending voice message...")));
    }
    try {
      await chatProvider.sendMediaMessage(
        widget.chat.id,
        myUid,
        widget.otherUserId,
        file,
        'voice',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Voice message sent!")));
      }
    } catch (e) {
      debugPrint("ChatRoomPage Error sending voice: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to send voice: $e")));
      }
    }
  }

  void _handleViewOncePick(ChatProvider chatProvider, String myUid) async {
    Navigator.pop(context);
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      chatProvider.sendViewOnceMedia(widget.chat.id, myUid, widget.otherUserId, image, 'image');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Sending view-once photo...")));
      }
    }
  }



  void _forwardToUser(MessageEntity message) async {
    final users = await _userRepository.getAllUsers();
    if (!mounted) return;
    
    showModalBottomSheet(
      context: context,
      builder: (context) => ListView.builder(
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          if (user.uid == Provider.of<AuthProvider>(context, listen: false).user?.uid) return const SizedBox();
          
          return ListTile(
            leading: UserAvatar(url: user.photoUrl),
            title: Text(user.displayName),
            onTap: () async {
              // Safety Verification
              final ai = Provider.of<AiProvider>(context, listen: false);
              final safety = ai.getSafetyAlert(message.id);
              final toxicity = ai.getToxicityAlert(message.id);

              if (safety != null || (toxicity != null && toxicity['isToxic'] == true)) {
                final bool? proceed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Row(
                      children: [
                        Icon(Icons.gpp_maybe, color: Colors.orange),
                        SizedBox(width: 8),
                        Text("Safety Warning"),
                      ],
                    ),
                    content: Text(
                      "Our AI has flagged this content as potentially unsafe, toxic, or misinformation. "
                      "Are you sure you want to forward this to ${user.displayName}?"
                    ),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("CANCEL")),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true), 
                        child: const Text("PROCEED", style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
                if (proceed != true) return;
              }

              Provider.of<ChatProvider>(context, listen: false).forwardMessage(
                message, 
                'pending', 
                Provider.of<AuthProvider>(context, listen: false).user!.uid, 
                user.uid
              );
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Forwarded to ${user.displayName}")));
            },
          );
        },
      ),
    );
  }

  void _handleGifSearch(ChatProvider chatProvider, String myUid) async {
    final String? gifUrl = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const GifSearchPage()),
    );
    
    if (gifUrl != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Sending GIF...")));
      }
      await chatProvider.sendGifMessage(
        widget.chat.id,
        myUid,
        widget.otherUserId,
        gifUrl,
      );
    }
  }

  void _showDeleteConfirmation(MessageEntity message) {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final myUid = authProvider.user?.uid ?? '';
    final isAdmin = widget.chat.isGroup && widget.chat.admins.contains(myUid);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete message?"),
        content: const Text("This message will be deleted for everyone in this chat."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
          TextButton(
            onPressed: () {
              if (isAdmin && message.senderId != myUid) {
                chatProvider.adminDeleteMessage(widget.chat.id, message.id);
              } else {
                chatProvider.deleteMessage(widget.chat.id, message.id);
              }
              Navigator.pop(context);
            },
            child: const Text("DELETE FOR EVERYONE"),
          ),
        ],
      ),
    );
  }

  void _showGroupSettings(ChatProvider chatProvider) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Group Settings"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: const Text("Admin Only Messages"),
                subtitle: const Text("Only admins can send messages"),
                value: widget.chat.adminOnly,
                onChanged: (val) async {
                  await chatProvider.toggleAdminOnly(widget.chat.id, val);
                  setDialogState(() {});
                  setState(() {});
                },
              ),
              SwitchListTile(
                title: const Text("Approve New Members"),
                subtitle: const Text("Require admin approval to join"),
                value: widget.chat.approvalRequired,
                onChanged: (val) async {
                  await chatProvider.toggleApprovalRequired(widget.chat.id, val);
                  setDialogState(() {});
                  setState(() {});
                },
              ),
            ],
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("CLOSE"))],
        ),
      ),
    );
  }

  void _showJoinRequests(ChatProvider chatProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Join Requests"),
        content: widget.chat.joinRequests.isEmpty
            ? const Text("No pending requests")
            : SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: widget.chat.joinRequests.length,
                  itemBuilder: (context, index) {
                    final userId = widget.chat.joinRequests[index];
                    return FutureBuilder<UserEntity?>(
                      future: _userRepository.getUser(userId),
                      builder: (context, snapshot) {
                        return ListTile(
                          title: Text(snapshot.data?.displayName ?? userId),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.check, color: Colors.green),
                                onPressed: () {
                                  chatProvider.approveRequest(widget.chat.id, userId, true);
                                  Navigator.pop(context);
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.red),
                                onPressed: () {
                                  chatProvider.approveRequest(widget.chat.id, userId, false);
                                  Navigator.pop(context);
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("CLOSE"))],
      ),
    );
  }

  void _showInviteLink(ChatProvider chatProvider) {
    final inviteLink = widget.chat.inviteLink ?? "https://whatsapp-ai.web.app/join/${widget.chat.id}";
    if (widget.chat.inviteLink == null) {
      chatProvider.updateInviteLink(widget.chat.id, inviteLink);
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Group Invite Link"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Share this link to invite others to this group."),
            const SizedBox(height: 16),
            SelectableText(
              inviteLink,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: inviteLink));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Link copied to clipboard!")));
            },
            child: const Text("COPY LINK"),
          ),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CLOSE")),
        ],
      ),
    );
  }
  Widget _buildQuickReplyPicker() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      color: Colors.white,
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: _quickReplies.length,
        itemBuilder: (context, index) {
          final reply = _quickReplies[index];
          return ListTile(
            leading: const Icon(Icons.flash_on, color: Color(0xFF00A884)),
            title: Text("/${reply['shortcut']}"),
            subtitle: Text(reply['message']),
            onTap: () {
              setState(() {
                _messageController.text = reply['message'];
                _showQuickReplyPicker = false;
              });
            },
          );
        },
      ),
    );
  }

  void _showProductivityMenu() {
    Navigator.pop(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF141828),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text("AI Productivity Suite", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          _prodMenuItem(ctx, Icons.picture_as_pdf, "Export as PDF", () => _exportChat('pdf')),
          _prodMenuItem(ctx, Icons.summarize, "Generate Meeting Minutes", () => _exportChat('minutes')),
          _prodMenuItem(ctx, Icons.description, "Create Professional Notes", () => _exportChat('notes')),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _prodMenuItem(BuildContext ctx, IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF7B2FE0)),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      onTap: onTap,
    );
  }

  Future<void> _exportChat(String mode) async {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("AI is processing your chat... 🧠")));
    
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final aiProvider = Provider.of<AiProvider>(context, listen: false);
    final messages = await chatProvider.getMessagesOnce(widget.chat.id);

    try {
      if (mode == 'pdf') {
        await ExportService.exportChatToPdf(chatName: widget.otherUserName, messages: messages);
      } else if (mode == 'minutes') {
        final minutes = await aiProvider.generateMeetingMinutes(messages);
        await ExportService.shareTextAsNote("Meeting_Minutes", minutes);
      } else if (mode == 'notes') {
        final notes = await aiProvider.generateProfessionalNotes(messages);
        await ExportService.shareTextAsNote("Study_Notes", notes);
      }
    } catch (e) {
       if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Export failed: $e")));
    }
  }

  Widget _buildAiTaskSuggestionChip() {
    return Consumer<AiProvider>(
      builder: (context, ai, _) {
        if (ai.taskSuggestion == null) return const SizedBox();
        final task = ai.taskSuggestion!;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: const Color(0xFF141828),
          child: Row(
            children: [
              const Icon(Icons.lightbulb, color: Colors.amber, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Create reminder: \"${task['title']}\"?",
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton(
                onPressed: () {
                  final tp = Provider.of<TaskProvider>(context, listen: false);
                  tp.addTask(TaskEntity(
                    id: const Uuid().v4(),
                    title: task['title'] ?? 'Untitled',
                    description: task['description'] ?? '',
                    sourceChatId: widget.chat.id,
                    createdAt: DateTime.now(),
                    dueDate: task['dueDate'] != null ? DateTime.tryParse(task['dueDate']) : null,
                  ));
                  ai.clearTaskSuggestion();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Reminder saved to Action Center! ✅")));
                },
                child: const Text("SAVE", style: TextStyle(color: Color(0xFF7B2FE0), fontWeight: FontWeight.bold)),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.grey, size: 18),
                onPressed: () => ai.clearTaskSuggestion(),
              ),
            ],
          ),
        );
      },
    );
  }
}
