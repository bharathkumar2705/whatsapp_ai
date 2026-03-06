import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:provider/provider.dart';
import '../providers/agora_provider.dart';

class AvatarSelectionPage extends StatefulWidget {
  const AvatarSelectionPage({super.key});

  @override
  State<AvatarSelectionPage> createState() => _AvatarSelectionPageState();
}

class _AvatarSelectionPageState extends State<AvatarSelectionPage> {
  final List<Map<String, String>> _avatars = [
    {
      'name': 'Astronaut',
      'url': 'https://modelviewer.dev/shared-assets/models/Astronaut.glb',
    },
    {
      'name': 'Robot',
      'url': 'https://modelviewer.dev/shared-assets/models/RobotExpressive.glb',
    },
    {
      'name': 'Fox',
      'url': 'https://raw.githubusercontent.com/KhronosGroup/glTF-Sample-Models/master/2.0/Fox/glTF-Binary/Fox.glb',
    },
  ];

  String? _selectedUrl;

  @override
  Widget build(BuildContext context) {
    final agora = Provider.of<AgoraProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text("Select 3D Avatar", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: Container(
              margin: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white10),
              ),
              child: _selectedUrl == null
                  ? const Center(child: Text("Pick an avatar below", style: TextStyle(color: Colors.white54)))
                  : ModelViewer(
                      backgroundColor: Colors.transparent,
                      src: _selectedUrl!,
                      alt: "A 3D model",
                      autoRotate: true,
                      cameraControls: true,
                    ),
            ),
          ),
          Expanded(
            flex: 1,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _avatars.length,
              itemBuilder: (context, index) {
                final avatar = _avatars[index];
                bool isSelected = _selectedUrl == avatar['url'];

                return GestureDetector(
                  onTap: () => setState(() => _selectedUrl = avatar['url']),
                  child: Container(
                    width: 120,
                    margin: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF7B2FE0).withOpacity(0.2) : Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isSelected ? const Color(0xFF7B2FE0) : Colors.white10, width: 2),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person, color: isSelected ? const Color(0xFF7B2FE0) : Colors.white54, size: 40),
                        const SizedBox(height: 8),
                        Text(avatar['name']!, style: TextStyle(color: isSelected ? Colors.white : Colors.white70, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: ElevatedButton(
              onPressed: _selectedUrl == null
                  ? null
                  : () {
                      agora.setSelectedAvatar(_selectedUrl!);
                      Navigator.pop(context);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7B2FE0),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text("USE THIS AVATAR", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
