import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/status_provider.dart';
import '../providers/auth_provider.dart';
import 'package:intl/intl.dart';
import 'status_view_page.dart';
import '../widgets/user_avatar.dart';
import '../widgets/voice_record_button.dart';
import '../../domain/entities/status_entity.dart';
import 'package:file_picker/file_picker.dart';

class StatusPage extends StatefulWidget {
  const StatusPage({super.key});

  @override
  State<StatusPage> createState() => _StatusPageState();
}

class _StatusPageState extends State<StatusPage> {
  String _currentPrivacy = 'contacts';
  List<String> _privacyList = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<StatusProvider>(context, listen: false).listenToStatuses();
    });
  }

  Future<void> _handleImageStatus(StatusProvider statusProvider, String userId, String userName, String? userImage) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      await statusProvider.postImageStatus(userId, userName, userImage, image, privacyType: _currentPrivacy, privacyList: _privacyList);
    }
  }

  Future<void> _handleVideoStatus(StatusProvider statusProvider, String userId, String userName, String? userImage) async {
    final picker = ImagePicker();
    final video = await picker.pickVideo(source: ImageSource.gallery);
    if (video != null) {
      await statusProvider.postVideoStatus(userId, userName, userImage, video, privacyType: _currentPrivacy, privacyList: _privacyList);
    }
  }

  void _handleVoiceStatus(StatusProvider statusProvider, String userId, String userName, String? userImage, XFile file) {
    statusProvider.postVoiceStatus(userId, userName, userImage, file, privacyType: _currentPrivacy, privacyList: _privacyList);
  }

  void _showPrivacySettings() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Status Privacy"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile(
                title: const Text("My contacts"),
                value: 'contacts',
                groupValue: _currentPrivacy,
                onChanged: (val) => setDialogState(() => setState(() => _currentPrivacy = val as String)),
              ),
              RadioListTile(
                title: const Text("My contacts except..."),
                value: 'except',
                groupValue: _currentPrivacy,
                onChanged: (val) => setDialogState(() => setState(() => _currentPrivacy = val as String)),
              ),
              RadioListTile(
                title: const Text("Only share with..."),
                value: 'only',
                groupValue: _currentPrivacy,
                onChanged: (val) => setDialogState(() => setState(() => _currentPrivacy = val as String)),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Done")),
          ],
        ),
      ),
    );
  }

  void _handleTextStatus(StatusProvider statusProvider, String userId, String userName, String? userImage) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Post Status"),
        content: TextField(controller: controller, autofocus: true, decoration: const InputDecoration(hintText: "What's on your mind?")),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                statusProvider.postTextStatus(
                  userId, userName, userImage, controller.text.trim(),
                  privacyType: _currentPrivacy, privacyList: _privacyList,
                );
                Navigator.pop(context);
              }
            }, 
            child: const Text("Post"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusProvider = Provider.of<StatusProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Status"),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: _showPrivacySettings,
          ),
        ],
      ),
      body: ListView(
        children: [
          ListTile(
            leading: Stack(
              alignment: Alignment.bottomRight,
              children: [
                UserAvatar(radius: 24, url: user?.photoURL),
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, shape: BoxShape.circle),
                  child: const Icon(Icons.add, size: 16, color: Colors.white),
                ),
              ],
            ),
            title: const Text("My status"),
            subtitle: const Text("Tap to add status update"),
            onTap: () => _handleImageStatus(statusProvider, user?.uid ?? '', user?.displayName ?? 'User', user?.photoURL),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text("Recent updates", style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface.withAlpha(150))),
          ),
          ..._groupStatuses(statusProvider.statuses).map((group) {
            final latestStatus = group.statuses.last;
            final unreadCount = group.statuses.where((StatusEntity s) => !s.viewers.contains(user?.uid)).length;
            
            return ListTile(
              leading: _StatusAvatar(
                imageUrl: latestStatus.userImageUrl,
                statusCount: group.statuses.length,
                unreadCount: unreadCount,
              ),
              title: Text(latestStatus.userName),
              subtitle: Text(DateFormat('HH:mm').format(latestStatus.timestamp)),
              onTap: () {
                 Navigator.push(context, MaterialPageRoute(builder: (_) => StatusViewPage(statuses: group.statuses)));
              },
            );
          }),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () => _handleTextStatus(statusProvider, user?.uid ?? '', user?.displayName ?? 'User', user?.photoURL),
            mini: true,
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Icon(Icons.edit, color: Theme.of(context).colorScheme.onSurface),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            onPressed: () => _handleVideoStatus(statusProvider, user?.uid ?? '', user?.displayName ?? 'User', user?.photoURL),
            mini: true,
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Icon(Icons.videocam, color: Theme.of(context).colorScheme.onSurface),
          ),
          const SizedBox(height: 16),
          VoiceRecordButton(
            onRecordComplete: (file) => _handleVoiceStatus(statusProvider, user?.uid ?? '', user?.displayName ?? 'User', user?.photoURL, file),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            onPressed: () => _handleImageStatus(statusProvider, user?.uid ?? '', user?.displayName ?? 'User', user?.photoURL),
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: const Icon(Icons.camera_alt, color: Colors.white),
          ),
        ],
      ),
    );
  }

  List<_StatusGroup> _groupStatuses(List<StatusEntity> statuses) {
    Map<String, List<StatusEntity>> groups = {};
    for (var status in statuses) {
      groups.putIfAbsent(status.userId, () => []).add(status);
    }
    return groups.values.map((s) => _StatusGroup(statuses: s)).toList();
  }
}

class _StatusGroup {
  final List<StatusEntity> statuses;
  _StatusGroup({required this.statuses});
}

class _StatusAvatar extends StatelessWidget {
  final String? imageUrl;
  final int statusCount;
  final int unreadCount;

  const _StatusAvatar({required this.imageUrl, required this.statusCount, required this.unreadCount});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52,
      height: 52,
      child: CustomPaint(
        painter: StatusPainter(statusCount: statusCount, unreadCount: unreadCount),
        child: Center(
          child: UserAvatar(radius: 22, url: imageUrl),
        ),
      ),
    );
  }
}

class StatusPainter extends CustomPainter {
  final int statusCount;
  final int unreadCount;

  StatusPainter({required this.statusCount, required this.unreadCount});

  @override
  void paint(Canvas canvas, Size size) {
    if (statusCount == 0) return;

    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final double arcLength = (2 * 3.14159 - (statusCount * 0.2)) / statusCount;
    final double radius = size.width / 2;
    final Rect rect = Rect.fromCircle(center: Offset(radius, radius), radius: radius - 2);

    for (int i = 0; i < statusCount; i++) {
       paint.color = i < (statusCount - unreadCount) 
           ? Colors.grey.withAlpha(100) 
           : const Color(0xFF25D366); // Status ring green is usually constant but could be theme.primary
       canvas.drawArc(rect, -3.14159 / 2 + i * (arcLength + 0.2), arcLength, false, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
