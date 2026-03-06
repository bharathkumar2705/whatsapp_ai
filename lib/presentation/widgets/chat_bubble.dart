import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../pages/map_viewer_page.dart';
import '../providers/ai_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/innovation_provider.dart';
import 'voice_player.dart';
import 'plugins/expense_tracker_widget.dart';
import 'plugins/tic_tac_toe_widget.dart';
import 'plugins/study_timer_widget.dart';
import 'whiteboard_widget.dart';
import 'code_editor_widget.dart';
import 'grocery_list_widget.dart';
import 'quiz_battle_widget.dart';

class ChatBubble extends StatelessWidget {
  final String text;
  final bool isMe;
  final DateTime timestamp;
  final String type;
  final String mediaUrl;
  final String status;
  final List<String> reactions;
  final String? replyText;
  final String? senderName;
  final bool showName;
  final bool isStarred;
  final double? latitude;
  final double? longitude;
  final Function(String)? onReaction;
  final VoidCallback? onSwipe;
  final Function(bool)? onStar;
  final Function(String)? onTranslate;
  final List<String>? pollOptions;
  final Map<String, dynamic>? eventData;
  final Map<String, dynamic>? contactData;
  final bool isForwarded;
  final bool isEdited;
  final bool isViewOnce;
  final VoidCallback? onViewOnceOpen;
  final Function(String)? onEdit;
  final VoidCallback? onForward;
  final VoidCallback? onDelete;
  final bool isHd;
  final Map<String, dynamic>? toxicityAlert;
  final Map<String, dynamic>? safetyAlert;
  final String? messageId;
  final String? chatId;
  final Map<String, dynamic>? pluginData;

  const ChatBubble({
    super.key,
    required this.text,
    required this.isMe,
    required this.timestamp,
    this.type = 'text',
    this.mediaUrl = '',
    this.status = 'sent',
    this.reactions = const [],
    this.replyText,
    this.senderName,
    this.showName = false,
    this.isStarred = false,
    this.latitude,
    this.longitude,
    this.onReaction,
    this.onSwipe,
    this.onStar,
    this.onTranslate,
    this.pollOptions,
    this.eventData,
    this.contactData,
    this.isForwarded = false,
    this.isEdited = false,
    this.isViewOnce = false,
    this.onViewOnceOpen,
    this.onEdit,
    this.onForward,
    this.onDelete,
    this.isHd = false,
    this.toxicityAlert,
    this.safetyAlert,
    this.messageId,
    this.chatId,
    this.pluginData,
  });

  Widget _buildPlugin(BuildContext context, Map<String, dynamic> data) {
    final String pluginType = data['type'] ?? '';
    // We need chatId and messageId. 
    // This is a bit of a hack: ChatBubble doesn't have messageId. 
    // I need to add it to ChatBubble so we can update state.
    // Wait, I'll check ChatRoomPage.
    
    // Actually, I'll pass chatId and messageId to ChatBubble.
    // Let's assume for now they are available in a future update or I'll just use dummy for UI first.
    // CRITICAL: I need messageId and chatId for the buttons to work.
    
    switch (pluginType) {
      case 'expense_tracker':
        return ExpenseTrackerWidget(chatId: chatId ?? 'temp', messageId: messageId ?? 'temp', data: data); 
      case 'tic_tac_toe':
        return TicTacToeWidget(chatId: chatId ?? 'temp', messageId: messageId ?? 'temp', data: data);
      case 'study_timer':
        return StudyTimerWidget(chatId: chatId ?? 'temp', messageId: messageId ?? 'temp', data: data);
      case 'whiteboard':
        return WhiteboardWidget(chatId: chatId ?? 'temp', messageId: messageId ?? 'temp', initialStrokes: data['strokes'] ?? []);
      case 'code_editor':
        return CodeEditorWidget(
          chatId: chatId ?? 'temp', 
          messageId: messageId ?? 'temp', 
          initialContent: data['content'] ?? '', 
          language: data['language'] ?? 'dart',
        );
      case 'grocery_list':
        return GroceryListWidget(chatId: chatId ?? 'temp', messageId: messageId ?? 'temp', items: data['items'] ?? []);
      case 'quiz_battle':
        return QuizBattleWidget(chatId: chatId ?? 'temp', messageId: messageId ?? 'temp', data: data);
      default:
        return const Text("Unknown Plugin");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: UniqueKey(),
      direction: DismissDirection.startToEnd,
      confirmDismiss: (direction) async {
        if (onSwipe != null) onSwipe!();
        return false; // Don't actually dismiss the widget
      },
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: const Icon(Icons.reply, color: Color(0xFF075E54)),
      ),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onLongPress: () => _showReactionPicker(context),
              child: Stack(
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isMe
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isMe ? 16 : 0),
                        bottomRight: Radius.circular(isMe ? 0 : 16),
                      ),
                    ),
                    child: IntrinsicWidth(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (toxicityAlert != null && toxicityAlert!['isToxic'] == true)
                        Padding(
                          padding: const EdgeInsets.only(left: 8, top: 4, bottom: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.gpp_maybe, color: Colors.orange, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                "AI Insight: Possible ${toxicityAlert!['severity'] ?? 'Toxic'} Content",
                                style: const TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      if (safetyAlert != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 8, top: 4, bottom: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (safetyAlert!['isMisinformation'] == true)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.fact_check, color: Colors.blueAccent, size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      "AI Check: ${safetyAlert!['reason'] ?? 'Potential Misinformation'}",
                                      style: const TextStyle(color: Colors.blueAccent, fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              if (safetyAlert!['isSuspicious'] == true)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.link_off, color: Colors.redAccent, size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      "Safety Alert: ${safetyAlert!['warning'] ?? 'Suspicious Link'}",
                                      style: const TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      if (showName && !isMe && senderName != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0, top: 4.0, bottom: 2.0),
                          child: Text(
                            senderName!,
                            style: TextStyle(
                              fontWeight: FontWeight.bold, 
                              color: Theme.of(context).colorScheme.primary, 
                              fontSize: 12
                            ),
                          ),
                        ),
                      if (isForwarded)
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0, top: 4.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.forward, size: 12, color: Theme.of(context).colorScheme.onSurface.withAlpha(120)),
                              const SizedBox(width: 4),
                              Text("Forwarded", style: TextStyle(fontStyle: FontStyle.italic, color: Theme.of(context).colorScheme.onSurface.withAlpha(120), fontSize: 11)),
                            ],
                          ),
                        ),
                      if (replyText != null)
                        Container(
                          padding: const EdgeInsets.all(8),
                          margin: const EdgeInsets.only(bottom: 4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.onSurface.withAlpha(15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border(left: BorderSide(color: Theme.of(context).colorScheme.primary, width: 4)),
                          ),
                          child: Text(
                            replyText!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withAlpha(180)),
                          ),
                        ),
                      if (type == 'plugin' && pluginData != null)
                        _buildPlugin(context, pluginData!)
                      else
                        Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (type == 'image')
                            Stack(
                              alignment: Alignment.topRight,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    mediaUrl,
                                    width: 200,
                                    height: 200,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 100),
                                  ),
                                ),
                                if (mediaUrl.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.all(4),
                                    child: GestureDetector(
                                      onTap: () async {
                                        final uri = Uri.parse(mediaUrl);
                                        if (await canLaunchUrl(uri)) launchUrl(uri, mode: LaunchMode.externalApplication);
                                      },
                                      child: CircleAvatar(
                                        radius: 14,
                                        backgroundColor: Colors.black54,
                                        child: const Icon(Icons.download, color: Colors.white, size: 16),
                                      ),
                                    ),
                                  ),
                              ],
                            )
                          else if (type == 'voice' || type == 'audio')
                            VoicePlayer(url: mediaUrl)
                          else if (type == 'file')
                            InkWell(
                              onTap: () async {
                                if (mediaUrl.isNotEmpty) {
                                  final uri = Uri.parse(mediaUrl);
                                  if (await canLaunchUrl(uri)) launchUrl(uri, mode: LaunchMode.externalApplication);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.insert_drive_file, color: Color(0xFF075E54)),
                                    const SizedBox(width: 8),
                                    Flexible(child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold))),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.download, size: 18, color: Color(0xFF075E54)),
                                  ],
                                ),
                              ),
                            )
                          else if (type == 'poll')
                            _buildPoll(context)
                          else if (type == 'event')
                            _buildEvent(context)
                          else if (type == 'contact')
                            _buildContact(context)
                          else if (type == 'payment')
                            _buildPayment(context)
                          else if (type == 'location')
                            GestureDetector(
                              onTap: () {
                                if (latitude != null && longitude != null) {
                                  Navigator.of(context).push(MaterialPageRoute(
                                    builder: (_) => MapViewerPage(latitude: latitude!, longitude: longitude!),
                                  ));
                                }
                              },
                              child: Container(
                                width: 200,
                                height: 150,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.location_on, size: 48, color: Colors.red),
                                    const SizedBox(height: 8),
                                    const Text("Shared Location", style: TextStyle(fontWeight: FontWeight.bold)),
                                    Text("${latitude?.toStringAsFixed(4)}, ${longitude?.toStringAsFixed(4)}", style: const TextStyle(fontSize: 12)),
                                  ],
                                ),
                              ),
                            )
                          else
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: isViewOnce ? _buildViewOnceContent(context) : _buildTextContent(context),
                            ),
                          const SizedBox(height: 2),
                          Padding(
                            padding: const EdgeInsets.only(right: 8, bottom: 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  DateFormat('HH:mm').format(timestamp),
                                  style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurface.withAlpha(140)),
                                ),
                                if (isEdited) ...[
                                  const SizedBox(width: 4),
                                  Text("edited", style: TextStyle(fontSize: 10, color: Colors.grey[600], fontStyle: FontStyle.italic)),
                                ],
                                if (isStarred) ...[
                                  const SizedBox(width: 4),
                                  const Icon(Icons.star, size: 12, color: Colors.orange),
                                ],
                                if (isHd) ...[
                                  const SizedBox(width: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey[600]!, width: 1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      "HD",
                                      style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.grey[600]),
                                    ),
                                  ),
                                ],
                                if (isMe) ...[
                                  const SizedBox(width: 4),
                                  _buildStatusIcon(),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
                  // ── Small dropdown arrow (like real WhatsApp) ──────────────
                  Positioned(
                    top: 6,
                    right: isMe ? 16 : null,
                    left: isMe ? null : 16,
                    child: Builder(builder: (btnCtx) {
                      return GestureDetector(
                        onTap: () => _showDropdownMenu(btnCtx),
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.18),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.white),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
            if (reactions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Wrap(
                  spacing: 4,
                  children: reactions.map((r) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Theme.of(context).colorScheme.surface, width: 2),
                    ),
                    child: Text(r, style: const TextStyle(fontSize: 12)),
                  )).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon() {
    return Builder(builder: (context) {
      final scheme = Theme.of(context).colorScheme;
      if (status == 'seen') {
        return const Icon(Icons.done_all, size: 16, color: Colors.blue);
      } else if (status == 'delivered') {
        return Icon(Icons.done_all, size: 16, color: scheme.onSurface.withAlpha(100));
      } else {
        return Icon(Icons.done, size: 16, color: scheme.onSurface.withAlpha(100));
      }
    });
  }

  void _showDropdownMenu(BuildContext btnCtx) async {
    final RenderBox btn = btnCtx.findRenderObject() as RenderBox;
    final RenderBox overlay = Navigator.of(btnCtx).overlay!.context.findRenderObject() as RenderBox;
    final Offset btnPos = btn.localToGlobal(Offset.zero, ancestor: overlay);
    final RelativeRect position = RelativeRect.fromLTRB(
      isMe ? btnPos.dx - 180 : btnPos.dx,
      btnPos.dy + btn.size.height + 4,
      isMe ? btnPos.dx + btn.size.width : btnPos.dx + 200,
      0,
    );

    final result = await showMenu<String>(
      context: btnCtx,
      position: position,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      items: [
        _popupItem('info',     Icons.info_outline,             'Message info'),
        _popupItem('reply',    Icons.reply,                     'Reply'),
        _popupItem('react',    Icons.emoji_emotions_outlined,   'React'),
        if (type == 'text' || type == 'deleted')
          _popupItem('copy',   Icons.copy_outlined,             'Copy'),
        if (mediaUrl.isNotEmpty)
          _popupItem('download', Icons.download_outlined,       'Download'),
        if (onForward != null)
          _popupItem('forward', Icons.forward,                  'Forward'),
        _popupItem('pin',      Icons.push_pin_outlined,         'Pin'),
        _popupItem('star',     isStarred ? Icons.star : Icons.star_border,
                               isStarred ? 'Unstar' : 'Star'),
        if (onEdit != null)
          _popupItem('edit',   Icons.edit_outlined,             'Edit'),
        _popupItem('delete',   Icons.delete_outline,            'Delete', color: Colors.red),
      ],
    );

    if (result == null) return;
    // ignore: use_build_context_synchronously
    switch (result) {
      case 'reply':
        if (onSwipe != null) onSwipe!();
        break;
      case 'react':
        // ignore: use_build_context_synchronously
        _showEmojiPicker(btnCtx);
        break;
      case 'copy':
        Clipboard.setData(ClipboardData(text: text));
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(btnCtx).showSnackBar(
          const SnackBar(content: Text('Copied'), duration: Duration(seconds: 1)),
        );
        break;
      case 'edit':
        if (onEdit != null) onEdit!(text);
        break;
      case 'download':
        if (mediaUrl.isNotEmpty) {
          final uri = Uri.parse(mediaUrl);
          if (await canLaunchUrl(uri)) launchUrl(uri, mode: LaunchMode.externalApplication);
        }
        break;
      case 'forward':
        if (onForward != null) onForward!();
        break;
      case 'star':
        if (onStar != null) onStar!(!isStarred);
        break;
      case 'delete':
        if (onDelete != null) onDelete!();
        break;
      case 'info':
      case 'pin':
        break;
    }
  }

  PopupMenuItem<String> _popupItem(String value, IconData icon, String label, {Color? color}) {
    return PopupMenuItem<String>(
      value: value,
      height: 48,
      child: Row(
        children: [
          Icon(icon, size: 20, color: color ?? Colors.grey[700]),
          const SizedBox(width: 16),
          Text(label, style: TextStyle(fontSize: 15, color: color ?? Colors.black87)),
        ],
      ),
    );
  }

  void _showEmojiPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(ctx).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: ['❤️', '😂', '😮', '😢', '🙏', '👍'].map((emoji) =>
              GestureDetector(
                onTap: () {
                  if (onReaction != null) onReaction!(emoji);
                  Navigator.pop(ctx);
                },
                child: Text(emoji, style: const TextStyle(fontSize: 36)),
              ),
            ).toList(),
          ),
        ),
      ),
    );
  }

  // Long-press still works — opens same dropdown anchored to the bubble center
  void _showReactionPicker(BuildContext context) => _showDropdownMenu(context);


  Widget _buildTextContent(BuildContext context) {
    final emojiRegExp = RegExp(r'^(\u00a9|\u00ae|[\u2000-\u3300]|\ud83c[\ud000-\udfff]|\ud83d[\ud000-\udfff]|\ud83e[\ud000-\udfff])$');
    final isSingleEmoji = emojiRegExp.hasMatch(text.trim());
    
    if (isSingleEmoji) {
      return Text(text, style: const TextStyle(fontSize: 48));
    }

    return RichText(
      text: TextSpan(
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface, 
          fontSize: 16,
          fontFamily: 'Inter',
        ),
        children: _parseFormattedText(text, context),
      ),
    );
  }

  List<TextSpan> _parseFormattedText(String text, BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    List<TextSpan> spans = [];
    final regExp = RegExp(r'(\*.*?\*|__.*?__|_.*?_|~.*?~|`.*?`|@[\w\s]+(?=\s|$))');
    int lastMatchEnd = 0;

    for (final match in regExp.allMatches(text)) {
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(text: text.substring(lastMatchEnd, match.start)));
      }

      String token = match.group(0)!;
      if (token.startsWith('@')) {
        spans.add(TextSpan(text: token, style: TextStyle(color: scheme.primary, fontWeight: FontWeight.bold)));
      } else if (token.startsWith('*') && token.endsWith('*')) {
        spans.add(TextSpan(text: token.substring(1, token.length - 1), style: const TextStyle(fontWeight: FontWeight.bold)));
      } else if ((token.startsWith('__') && token.endsWith('__')) || (token.startsWith('_') && token.endsWith('_'))) {
        int start = token.startsWith('__') ? 2 : 1;
        spans.add(TextSpan(text: token.substring(start, token.length - start), style: const TextStyle(fontStyle: FontStyle.italic)));
      } else if (token.startsWith('~') && token.endsWith('~')) {
        spans.add(TextSpan(text: token.substring(1, token.length - 1), style: const TextStyle(decoration: TextDecoration.lineThrough)));
      } else if (token.startsWith('`') && token.endsWith('`')) {
        spans.add(TextSpan(text: token.substring(1, token.length - 1), style: TextStyle(fontFamily: 'monospace', backgroundColor: scheme.onSurface.withAlpha(30))));
      }

      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastMatchEnd)));
    }

    return spans;
  }

  Widget _buildViewOnceContent(BuildContext context) {
    return GestureDetector(
      onTap: onViewOnceOpen,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onSurface.withAlpha(20),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.looks_one, color: Theme.of(context).colorScheme.primary, size: 18),
            const SizedBox(width: 8),
            Text(type == 'image' ? "Photo" : "Video", style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildContact(BuildContext context) {
    final name = contactData?['name'] ?? 'Contact';
    final phone = contactData?['phone'] ?? '';
    final scheme = Theme.of(context).colorScheme;
    
    return Container(
      width: 220,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.onSurface.withAlpha(30)),
      ),
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: scheme.primary.withAlpha(20),
            child: Icon(Icons.person, color: scheme.primary),
          ),
          const SizedBox(height: 8),
          Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(phone, style: TextStyle(fontSize: 12, color: scheme.onSurface.withAlpha(150))),
          const Divider(),
          TextButton(
            onPressed: () {},
            child: const Text("Message", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildPoll(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 250,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.onSurface.withAlpha(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.poll, color: scheme.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(text.replaceFirst('📊 Poll: ', ''), style: const TextStyle(fontWeight: FontWeight.bold))),
            ],
          ),
          const Divider(),
          if (pollOptions != null)
            ...pollOptions!.map((opt) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: scheme.onSurface.withAlpha(30)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.radio_button_off, size: 16, color: scheme.onSurface.withAlpha(100)),
                    const SizedBox(width: 8),
                    Text(opt),
                  ],
                ),
              ),
            )),
          const SizedBox(height: 8),
          Center(child: Text("VIEW VOTES", style: TextStyle(color: scheme.primary, fontWeight: FontWeight.bold, fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildPayment(BuildContext context) {
    final amount = pluginData?['amount'] ?? 0.0;
    final note = pluginData?['note'] ?? '';
    final status = pluginData?['status'] ?? 'completed';
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isMe ? scheme.onPrimary.withAlpha(20) : scheme.primary.withAlpha(20),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.primary.withAlpha(40)),
      ),
      child: Column(
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 32),
          const SizedBox(height: 8),
          Text(
            "\$${amount.toStringAsFixed(2)}",
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const Text("Payment Successful", style: TextStyle(fontSize: 12, color: Colors.green)),
          if (note.isNotEmpty) ...[
            const Divider(),
            Text(
              note,
              style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEvent(BuildContext context) {
    final title = eventData?['title'] ?? 'Untitled Event';
    final desc = eventData?['description'] ?? '';
    final dateMillis = eventData?['date'] as int?;
    final date = dateMillis != null ? DateTime.fromMillisecondsSinceEpoch(dateMillis) : DateTime.now();
    final scheme = Theme.of(context).colorScheme;
    
    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.onSurface.withAlpha(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: scheme.primary,
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
            ),
            child: Row(
              children: [
                const Icon(Icons.event, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(desc, style: const TextStyle(fontSize: 13)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 14, color: scheme.onSurface.withAlpha(150)),
                    const SizedBox(width: 4),
                    Text(DateFormat('MMM dd, yyyy').format(date), style: TextStyle(fontSize: 12, color: scheme.onSurface.withAlpha(150))),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
