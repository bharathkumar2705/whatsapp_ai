import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class AvatarCreationPage extends StatefulWidget {
  const AvatarCreationPage({super.key});

  @override
  State<AvatarCreationPage> createState() => _AvatarCreationPageState();
}

class _AvatarCreationPageState extends State<AvatarCreationPage> {
  Color _backgroundColor = Colors.blue;
  String _emoji = "😀";
  final List<Color> _colors = [
    Colors.blue, Colors.red, Colors.green, Colors.orange, 
    Colors.purple, Colors.pink, Colors.teal, Colors.amber
  ];
  final List<String> _emojis = [
    "😀", "😎", "🐱", "🐶", "🦊", "🦁", "🤖", "👾", 
    "👻", "🚀", "🌈", "🔥", "💎", "⭐", "🍀", "🍎"
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Your Avatar"),
      ),
      body: Column(
        children: [
          const SizedBox(height: 40),
          Center(
            child: CircleAvatar(
              radius: 80,
              backgroundColor: _backgroundColor,
              child: Text(_emoji, style: const TextStyle(fontSize: 80)),
            ),
          ),
          const SizedBox(height: 40),
          const Text("Choose Background Color", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _colors.length,
              itemBuilder: (context, index) => GestureDetector(
                onTap: () => setState(() => _backgroundColor = _colors[index]),
                child: Container(
                  width: 40,
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  decoration: BoxDecoration(
                    color: _colors[index],
                    shape: BoxShape.circle,
                    border: _backgroundColor == _colors[index] 
                      ? Border.all(color: Colors.white, width: 3) 
                      : null,
                    boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),
          const Text("Choose Your Character", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
              ),
              itemCount: _emojis.length,
              itemBuilder: (context, index) => GestureDetector(
                onTap: () => setState(() => _emoji = _emojis[index]),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    border: _emoji == _emojis[index] 
                      ? Border.all(color: Colors.blue, width: 2) 
                      : null,
                  ),
                  child: Text(_emojis[index], style: const TextStyle(fontSize: 30)),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  // In a real app, we'd save this to Firestore. 
                  // For now, we simulate success.
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Avatar updated successfully!")),
                  );
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF075E54)),
                child: const Text("SAVE AVATAR", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
