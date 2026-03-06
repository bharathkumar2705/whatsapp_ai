import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../../data/services/signaling_service.dart';

class CallSessionPage extends StatefulWidget {
  final String? roomId;
  final String callerId;
  final String receiverId;
  final bool isIncoming;
  final bool isVideo;

  const CallSessionPage({
    super.key,
    this.roomId,
    required this.callerId,
    required this.receiverId,
    required this.isIncoming,
    this.isVideo = true,
  });

  @override
  State<CallSessionPage> createState() => _CallSessionPageState();
}

class _CallSessionPageState extends State<CallSessionPage> {
  SignalingService signaling = SignalingService();
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  String? roomId;

  bool _isMuted = false;
  bool _isCameraOff = false;
  bool _isScreenSharing = false;

  @override
  void initState() {
    super.initState();
    _isCameraOff = !widget.isVideo;
    _localRenderer.initialize();
    _remoteRenderer.initialize();

    signaling.onAddRemoteStream = ((stream) {
      _remoteRenderer.srcObject = stream;
      setState(() {});
    });

    _startCall();
  }

  Future<void> _startCall() async {
    await signaling.openUserMedia(_localRenderer, _remoteRenderer, isVideo: widget.isVideo);

    if (widget.isIncoming && widget.roomId != null) {
      await signaling.joinRoom(widget.roomId!, _remoteRenderer);
    } else {
      roomId = await signaling.createRoom(_remoteRenderer, widget.callerId, widget.receiverId);
      setState(() {});
    }
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Remote Video
          Positioned.fill(
            child: RTCVideoView(_remoteRenderer),
          ),
          // Local Video
          Positioned(
            top: 40,
            right: 20,
            child: SizedBox(
              width: 120,
              height: 180,
              child: RTCVideoView(_localRenderer, mirror: true),
            ),
          ),
          // Controls
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.red,
                  child: IconButton(
                    icon: const Icon(Icons.call_end, color: Colors.white),
                    onPressed: () {
                      signaling.hangUp(_localRenderer);
                      Navigator.pop(context);
                    },
                  ),
                ),
                CircleAvatar(
                  radius: 25,
                  backgroundColor: _isCameraOff ? Colors.red : Colors.white30,
                  child: IconButton(
                    icon: Icon(_isCameraOff ? Icons.videocam_off : Icons.videocam, color: Colors.white),
                    onPressed: () {
                      setState(() => _isCameraOff = !_isCameraOff);
                      signaling.localStream?.getVideoTracks().forEach((track) {
                        track.enabled = !_isCameraOff;
                      });
                    },
                  ),
                ),
                CircleAvatar(
                  radius: 25,
                  backgroundColor: _isMuted ? Colors.red : Colors.white30,
                  child: IconButton(
                    icon: Icon(_isMuted ? Icons.mic_off : Icons.mic, color: Colors.white),
                    onPressed: () {
                      setState(() => _isMuted = !_isMuted);
                      signaling.localStream?.getAudioTracks().forEach((track) {
                        track.enabled = !_isMuted;
                      });
                    },
                  ),
                ),
                CircleAvatar(
                  radius: 25,
                  backgroundColor: _isScreenSharing ? Colors.green : Colors.white30,
                  child: IconButton(
                    icon: Icon(_isScreenSharing ? Icons.stop_screen_share : Icons.screen_share, color: Colors.white),
                    onPressed: () {
                      if (_isScreenSharing) {
                        signaling.stopScreenSharing(_localRenderer);
                      } else {
                        signaling.startScreenSharing(_localRenderer);
                      }
                      setState(() => _isScreenSharing = !_isScreenSharing);
                    },
                  ),
                ),
              ],
            ),
          ),
          if (!widget.isVideo)
             Center(
               child: Column(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: [
                   const CircleAvatar(
                     radius: 50,
                     backgroundColor: Colors.white24,
                     child: Icon(Icons.person, size: 60, color: Colors.white),
                   ),
                   const SizedBox(height: 16),
                   Text(widget.receiverId, style: const TextStyle(color: Colors.white, fontSize: 18)),
                   const SizedBox(height: 8),
                   const Text("Voice Call", style: TextStyle(color: Colors.white70, fontSize: 14)),
                 ],
               ),
             ),
          if (roomId != null && !widget.isIncoming)
            Positioned(
              top: 50,
              left: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(16)),
                child: Text("Room ID: $roomId", style: const TextStyle(color: Colors.white, fontSize: 12)),
              ),
            ),
        ],
      ),
    );
  }
}
