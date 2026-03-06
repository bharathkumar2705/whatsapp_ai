import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/status_provider.dart';
import '../providers/auth_provider.dart';
import '../../domain/entities/status_entity.dart';
import 'package:video_player/video_player.dart';
import 'package:audioplayers/audioplayers.dart';

class StatusViewPage extends StatefulWidget {
  final List<StatusEntity> statuses;
  final int initialIndex;

  const StatusViewPage({super.key, required this.statuses, this.initialIndex = 0});

  @override
  State<StatusViewPage> createState() => _StatusViewPageState();
}

class _StatusViewPageState extends State<StatusViewPage> with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _animationController;
  int _currentIndex = 0;
  VideoPlayerController? _videoController;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    _animationController = AnimationController(vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadStatus(status: widget.statuses[_currentIndex]);
      }
    });
    
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _nextStatus();
      }
    });
  }

  void _loadStatus({required StatusEntity status, bool animateToPage = true}) {
    _animationController.stop();
    _animationController.reset();
    
    if (status.type == 'video') {
      _videoController?.dispose();
      _videoController = VideoPlayerController.networkUrl(Uri.parse(status.contentUrl))
        ..initialize().then((_) {
          setState(() {});
          _animationController.duration = _videoController!.value.duration;
          _videoController!.play();
          _animationController.forward();
        });
    } else if (status.type == 'voice') {
      _audioPlayer.play(UrlSource(status.contentUrl)).then((_) {
        // We'll set a fixed 10s for voice if duration is unknown, or usually they are short
        _animationController.duration = const Duration(seconds: 10);
        _animationController.forward();
      });
    } else {
      _animationController.duration = const Duration(seconds: 5);
      _animationController.forward();
    }

    if (animateToPage && _pageController.hasClients) {
      _pageController.jumpToPage(_currentIndex);
    }

    // Mark as seen
    final myUid = Provider.of<AuthProvider>(context, listen: false).user?.uid;
    if (myUid != null && status.userId != myUid && !status.viewers.contains(myUid)) {
      Provider.of<StatusProvider>(context, listen: false).markSeen(status.id, myUid);
    }
  }

  void _nextStatus() {
    if (_currentIndex + 1 < widget.statuses.length) {
      setState(() {
        _currentIndex++;
      });
      _loadStatus(status: widget.statuses[_currentIndex]);
    } else {
      Navigator.pop(context);
    }
  }

  void _showViewers() {
    final status = widget.statuses[_currentIndex];
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Viewed by ${status.viewers.length}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const Divider(),
            if (status.viewers.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: Text("No views yet")),
              )
            else
              ...status.viewers.map((v) => ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text("User $v"),
              )),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _audioPlayer.dispose();
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final myUid = Provider.of<AuthProvider>(context, listen: false).user?.uid;
    final isMyStatus = widget.statuses[_currentIndex].userId == myUid;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapDown: (details) {
          final width = MediaQuery.of(context).size.width;
          if (details.globalPosition.dx < width / 3) {
            if (_currentIndex > 0) {
              setState(() => _currentIndex--);
              _loadStatus(status: widget.statuses[_currentIndex]);
            }
          } else if (details.globalPosition.dx > 2 * width / 3) {
            _nextStatus();
          }
        },
        onLongPressStart: (_) => _animationController.stop(),
        onLongPressEnd: (_) => _animationController.forward(),
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.statuses.length,
              itemBuilder: (context, index) {
                final status = widget.statuses[index];
                if (status.type == 'image') {
                  return Center(child: Image.network(status.contentUrl, fit: BoxFit.contain));
                } else if (status.type == 'video') {
                  return _videoController != null && _videoController!.value.isInitialized
                      ? Center(
                          child: AspectRatio(
                            aspectRatio: _videoController!.value.aspectRatio,
                            child: VideoPlayer(_videoController!),
                          ),
                        )
                      : const Center(child: CircularProgressIndicator(color: Colors.white));
                } else if (status.type == 'voice') {
                  return Container(
                    color: Colors.blueGrey[900],
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.mic, color: Colors.blue, size: 80),
                          const SizedBox(height: 20),
                          const Text("Voice Status", style: TextStyle(color: Colors.white, fontSize: 20)),
                          const SizedBox(height: 10),
                          StreamBuilder<Duration>(
                            stream: _audioPlayer.onPositionChanged,
                            builder: (context, snapshot) {
                              return Text(
                                snapshot.data?.toString().split('.').first ?? '0:00',
                                style: const TextStyle(color: Colors.white70),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                } else {
                  return Container(
                    color: Colors.blueGrey[900],
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Text(
                          status.contentUrl,
                          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  );
                }
              },
            ),
            Positioned(
              top: 40,
              left: 10,
              right: 10,
              child: Column(
                children: [
                  Row(
                    children: widget.statuses.asMap().entries.map((entry) {
                       return Expanded(
                         child: Padding(
                           padding: const EdgeInsets.symmetric(horizontal: 2),
                           child: AnimatedBuilder(
                             animation: _animationController,
                             builder: (context, child) {
                               return LinearProgressIndicator(
                                 value: entry.key == _currentIndex 
                                    ? _animationController.value 
                                    : (entry.key < _currentIndex ? 1.0 : 0.0),
                                 backgroundColor: Colors.white30,
                                 valueColor: const AlwaysStoppedAnimation(Colors.white),
                               );
                             },
                           ),
                         ),
                       );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      CircleAvatar(backgroundImage: widget.statuses[_currentIndex].userImageUrl != null ? NetworkImage(widget.statuses[_currentIndex].userImageUrl!) : null),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(widget.statuses[_currentIndex].userName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            Text(
                              "${widget.statuses[_currentIndex].timestamp.hour}:${widget.statuses[_currentIndex].timestamp.minute.toString().padLeft(2, '0')}",
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (isMyStatus) 
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.keyboard_arrow_up, color: Colors.white),
                      onPressed: _showViewers,
                    ),
                    const Text("Viewers", style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
