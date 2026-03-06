import 'package:flutter/material.dart';

class GifSearchPage extends StatefulWidget {
  const GifSearchPage({super.key});

  @override
  State<GifSearchPage> createState() => _GifSearchPageState();
}

class _GifSearchPageState extends State<GifSearchPage> {
  final _searchController = TextEditingController();
  final List<String> _trendingGifs = [
    "https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExNHJ4eXhxZ3R4eHhxZ3R4eHhxZ3R4eHhxZ3R4eHhxZ3R4eHhxZ3R4JmVwPXYxX2ludGVybmFsX2dpZl9ieV9pZCZjdD1n/3o7TKMGpxx87D6B90A/giphy.gif",
    "https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExNHJ4eXhxZ3R4eHhxZ3R4eHhxZ3R4eHhxZ3R4eHhxZ3R4eHhxZ3R4JmVwPXYxX2ludGVybmFsX2dpZl9ieV9pZCZjdD1n/l0HlIDlUuW7z9rXjO/giphy.gif",
    "https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExNHJ4eXhxZ3R4eHhxZ3R4eHhxZ3R4eHhxZ3R4eHhxZ3R4eHhxZ3R4JmVwPXYxX2ludGVybmFsX2dpZl9ieV9pZCZjdD1n/3o7TKSjP9+9I7O7C1y/giphy.gif",
    "https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExNHJ4eXhxZ3R4eHhxZ3R4eHhxZ3R4eHhxZ3R4eHhxZ3R4eHhxZ3R4JmVwPXYxX2ludGVybmFsX2dpZl9ieV9pZCZjdD1n/l41lTfGjWvYyS+O00/giphy.gif",
    "https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExNHJ4eXhxZ3R4eHhxZ3R4eHhxZ3R4eHhxZ3R4eHhxZ3R4eHhxZ3R4JmVwPXYxX2ludGVybmFsX2dpZl9ieV9pZCZjdD1n/3o7TKMGpxx87D6B90A/giphy.gif",
    "https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExNHJ4eXhxZ3R4eHhxZ3R4eHhxZ3R4eHhxZ3R4eHhxZ3R4eHhxZ3R4JmVwPXYxX2ludGVybmFsX2dpZl9ieV9pZCZjdD1n/l0HlIDlUuW7z9rXjO/giphy.gif"
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "Search GIFs on GIPHY",
            hintStyle: TextStyle(color: Colors.white70),
            border: InputBorder.none,
          ),
        ),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.5,
        ),
        itemCount: _trendingGifs.length,
        itemBuilder: (context, index) => GestureDetector(
          onTap: () => Navigator.pop(context, _trendingGifs[index]),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              _trendingGifs[index],
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: Colors.grey[300],
                child: const Icon(Icons.gif, size: 40, color: Colors.grey),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
