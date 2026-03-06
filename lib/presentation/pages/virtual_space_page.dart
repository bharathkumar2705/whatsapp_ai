import 'package:flutter/material.dart';
import 'package:o3d/o3d.dart';
import 'package:provider/provider.dart';
import '../providers/agora_provider.dart';

class VirtualSpacePage extends StatefulWidget {
  final String roomId;
  const VirtualSpacePage({super.key, required this.roomId});

  @override
  State<VirtualSpacePage> createState() => _VirtualSpacePageState();
}

class _VirtualSpacePageState extends State<VirtualSpacePage> {
  final O3DController _o3dController = O3DController();
  double _userX = 0;
  double _userY = 0;
  bool _isJoined = false;

  @override
  void initState() {
    super.initState();
    _joinVirtualSpace();
  }

  Future<void> _joinVirtualSpace() async {
    final agora = Provider.of<AgoraProvider>(context, listen: false);
    await agora.startCall(channelName: "vr_${widget.roomId}", videoEnabled: false);
    setState(() => _isJoined = true);
  }

  void _updatePosition(double dx, double dy) {
    setState(() {
      _userX += dx;
      _userY += dy;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ─── 3D Environment ──────────────────────────────────────────
          O3D(
            controller: _o3dController,
            src: 'https://modelviewer.dev/shared-assets/models/glTF-Sample-Models/2.0/EnvironmentTest/glTF-Binary/EnvironmentTest.glb',
            autoRotate: false,
            cameraControls: true,
            backgroundColor: Colors.black,
          ),

          // ─── HUD Overlay ──────────────────────────────────────────
          Positioned(
            top: 60,
            left: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Virtual Room: ${widget.roomId}",
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _isJoined ? Colors.green : Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isJoined ? "Spatial Audio Active" : "Connecting...",
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ─── Movement Controls ─────────────────────────────────────
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(40),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _moveButton(Icons.arrow_back, () => _updatePosition(-1.0, 0)),
                    const SizedBox(width: 20),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _moveButton(Icons.arrow_upward, () => _updatePosition(0, 1.0)),
                        const SizedBox(height: 20),
                        _moveButton(Icons.arrow_downward, () => _updatePosition(0, -1.0)),
                      ],
                    ),
                    const SizedBox(width: 20),
                    _moveButton(Icons.arrow_forward, () => _updatePosition(1.0, 0)),
                  ],
                ),
              ),
            ),
          ),

          // ─── Exit ──────────────────────────────────────────────────
          Positioned(
            top: 60,
            right: 20,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 32),
              onPressed: () {
                Provider.of<AgoraProvider>(context, listen: false).endCall();
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _moveButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        radius: 28,
        backgroundColor: Colors.white24,
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}
