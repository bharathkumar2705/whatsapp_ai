import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import '../providers/agora_provider.dart';
import 'avatar_selection_page.dart';

class AgoraCallPage extends StatefulWidget {
  final String channelName;   // Use chatId as channel name
  final String calleeName;
  final String? calleeImageUrl;
  final bool isVideo;
  final bool isIncoming;

  const AgoraCallPage({
    super.key,
    required this.channelName,
    required this.calleeName,
    this.calleeImageUrl,
    this.isVideo = true,
    this.isIncoming = false,
  });

  @override
  State<AgoraCallPage> createState() => _AgoraCallPageState();
}

class _AgoraCallPageState extends State<AgoraCallPage> {
  Timer? _callTimer;
  int _callSeconds = 0;
  String _arFilter = 'none'; // 'none', 'sepia', 'bw', 'glow'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startCall());
  }

  Future<void> _startCall() async {
    final agora = Provider.of<AgoraProvider>(context, listen: false);
    await agora.startCall(
      channelName: widget.channelName,
      videoEnabled: widget.isVideo,
    );
    _callTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _callSeconds++);
    });
  }

  @override
  void dispose() {
    _callTimer?.cancel();
    super.dispose();
  }

  String _formatDuration(int totalSeconds) {
    final m = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _endCall() async {
    _callTimer?.cancel();
    final agora = Provider.of<AgoraProvider>(context, listen: false);
    await agora.endCall();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AgoraProvider>(
      builder: (context, agora, _) {
        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              // ─── Remote Video (fullscreen) ───────────────────────
              if (widget.isVideo && agora.isRemoteJoined)
                ColorFiltered(
                  colorFilter: _getArFilter(),
                  child: Container(color: Colors.black54,
                    child: const Center(child: Icon(Icons.videocam, color: Colors.white54, size: 80))),
                )
              else
                _buildWaitingView(agora),

              // ─── Local Video PiP (top-right) ──────────────────────
              if (widget.isVideo && !agora.isCameraOff)
                Positioned(
                  top: 60,
                  right: 16,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 120,
                      height: 180,
                      color: Colors.black45,
                      child: agora.isAvatarMode && agora.selectedAvatarUrl != null
                          ? ModelViewer(
                              backgroundColor: Colors.transparent,
                              src: agora.selectedAvatarUrl!,
                              alt: "3D Avatar",
                              autoRotate: true,
                              cameraControls: false,
                            )
                          : const Center(child: Icon(Icons.person, color: Colors.white54, size: 48)),
                    ),
                  ),
                ),

              // ─── Top bar: callee name + duration ──────────────────
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.calleeName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          agora.isRemoteJoined
                              ? _formatDuration(_callSeconds)
                              : 'Calling...',
                          style: const TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ─── Controls row (bottom) ────────────────────────────
              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Mute
                          _ControlButton(
                            icon: agora.isMuted ? Icons.mic_off : Icons.mic,
                            label: agora.isMuted ? 'Unmute' : 'Mute',
                            active: agora.isMuted,
                            onTap: () => agora.toggleMute(),
                          ),
                          const SizedBox(width: 16),
                          // Camera (video calls only)
                          if (widget.isVideo) ...[
                            _ControlButton(
                              icon: agora.isCameraOff ? Icons.videocam_off : Icons.videocam,
                              label: agora.isCameraOff ? 'Camera Off' : 'Camera',
                              active: agora.isCameraOff,
                              onTap: () => agora.toggleCamera(),
                            ),
                            const SizedBox(width: 16),
                          ],
                          // End Call
                          _ControlButton(
                            icon: Icons.call_end,
                            label: 'End',
                            active: true,
                            activeColor: Colors.red,
                            onTap: _endCall,
                            large: true,
                          ),
                          const SizedBox(width: 16),
                          // Speaker
                          _ControlButton(
                            icon: agora.isSpeakerOn ? Icons.volume_up : Icons.volume_off,
                            label: agora.isSpeakerOn ? 'Speaker' : 'Earpiece',
                            active: agora.isSpeakerOn,
                            onTap: () => agora.toggleSpeaker(),
                          ),
                          const SizedBox(width: 16),
                          // Flip camera (video calls only)
                          if (widget.isVideo) ...[
                            _ControlButton(
                              icon: Icons.flip_camera_ios_outlined,
                              label: 'Flip',
                              active: false,
                              onTap: () => agora.switchCamera(),
                            ),
                            const SizedBox(width: 16),
                          ],
                          // AR Filters
                          if (widget.isVideo) ...[
                            _ControlButton(
                              icon: Icons.auto_fix_high,
                              label: 'Filters',
                              active: _arFilter != 'none',
                              onTap: _showArFilters,
                            ),
                            const SizedBox(width: 16),
                          ],
                          // Avatar Mode
                          if (widget.isVideo) ...[
                            _ControlButton(
                              icon: agora.isAvatarMode ? Icons.face_retouching_natural : Icons.face,
                              label: 'Avatar',
                              active: agora.isAvatarMode,
                              activeColor: const Color(0xFF7B2FE0),
                              onTap: () {
                                if (agora.selectedAvatarUrl == null) {
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AvatarSelectionPage()));
                                } else {
                                  agora.toggleAvatarMode();
                                }
                              },
                            ),
                            const SizedBox(width: 16),
                          ],
                          // Pick Avatar
                          if (widget.isVideo && agora.isAvatarMode)
                            _ControlButton(
                              icon: Icons.edit,
                              label: 'Change',
                              active: false,
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AvatarSelectionPage())),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWaitingView(AgoraProvider agora) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Avatar
            CircleAvatar(
              radius: 64,
              backgroundColor: const Color(0xFF25D366).withOpacity(0.2),
              backgroundImage: widget.calleeImageUrl != null
                  ? NetworkImage(widget.calleeImageUrl!)
                  : null,
              child: widget.calleeImageUrl == null
                  ? const Icon(Icons.person, size: 70, color: Colors.white54)
                  : null,
            ),
            const SizedBox(height: 24),
            Text(
              widget.calleeName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              agora.isCallActive ? 'Waiting for answer...' : 'Connecting...',
              style: const TextStyle(color: Colors.white60, fontSize: 16),
            ),
            const SizedBox(height: 24),
            // Pulsing ring animation
            const _PulsingRing(),
          ],
        ),
      ),
    );
  }

  ColorFilter _getArFilter() {
    switch (_arFilter) {
      case 'sepia': return const ColorFilter.matrix([0.393, 0.769, 0.189, 0, 0, 0.349, 0.686, 0.168, 0, 0, 0.272, 0.534, 0.131, 0, 0, 0, 0, 0, 1, 0]);
      case 'bw': return const ColorFilter.matrix([0.2126, 0.7152, 0.0722, 0, 0, 0.2126, 0.7152, 0.0722, 0, 0, 0.2126, 0.7152, 0.0722, 0, 0, 0, 0, 0, 1, 0]);
      case 'glow': return ColorFilter.mode(const Color(0xFF7B2FE0).withOpacity(0.3), BlendMode.screen);
      default: return const ColorFilter.mode(Colors.transparent, BlendMode.dst);
    }
  }

  void _showArFilters() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF141828),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text("AR Video Filters", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          ListTile(title: const Text("None", style: TextStyle(color: Colors.white)), onTap: () { setState(() => _arFilter = 'none'); Navigator.pop(ctx); }),
          ListTile(title: const Text("Sepia (Classic)", style: TextStyle(color: Colors.white)), onTap: () { setState(() => _arFilter = 'sepia'); Navigator.pop(ctx); }),
          ListTile(title: const Text("B&W (Noir)", style: TextStyle(color: Colors.white)), onTap: () { setState(() => _arFilter = 'bw'); Navigator.pop(ctx); }),
          ListTile(title: const Text("Meta Glow (VR)", style: TextStyle(color: Colors.white)), onTap: () { setState(() => _arFilter = 'glow'); Navigator.pop(ctx); }),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// Compact circular control button used in the call controls bar.
class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final Color? activeColor;
  final VoidCallback onTap;
  final bool large;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
    this.activeColor,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? (activeColor ?? const Color(0xFF075E54)) : Colors.white24;
    final size = large ? 36.0 : 26.0;
    final radius = large ? 34.0 : 28.0;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: radius,
            backgroundColor: color,
            child: Icon(icon, color: Colors.white, size: size),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        ],
      ),
    );
  }
}

/// Simple CSS-style pulsing ring for the waiting state.
class _PulsingRing extends StatefulWidget {
  const _PulsingRing();
  @override
  State<_PulsingRing> createState() => _PulsingRingState();
}

class _PulsingRingState extends State<_PulsingRing> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 1))
      ..repeat(reverse: true);
    _anim = Tween(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _anim,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF25D366), width: 2.5),
        ),
        child: const Icon(Icons.phone, color: Color(0xFF25D366), size: 28),
      ),
    );
  }
}
