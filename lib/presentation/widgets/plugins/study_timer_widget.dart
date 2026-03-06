import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/innovation_provider.dart';
import '../../providers/auth_provider.dart';

class StudyTimerWidget extends StatefulWidget {
  final String chatId;
  final String messageId;
  final Map<String, dynamic> data;

  const StudyTimerWidget({
    super.key,
    required this.chatId,
    required this.messageId,
    required this.data,
  });

  @override
  State<StudyTimerWidget> createState() => _StudyTimerWidgetState();
}

class _StudyTimerWidgetState extends State<StudyTimerWidget> {
  Timer? _localTimer;
  int _remainingSeconds = 0;

  @override
  void initState() {
    super.initState();
    _syncTimer();
  }

  @override
  void didUpdateWidget(StudyTimerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.data != oldWidget.data) {
      _syncTimer();
    }
  }

  void _syncTimer() {
    final int duration = widget.data['duration'] ?? 25 * 60; // default 25 mins
    final int? startTime = widget.data['startTime']; // null = stopped
    final bool isPaused = widget.data['isPaused'] ?? false;
    final int? pauseTimeSeconds = widget.data['pauseTimeSeconds'];

    _localTimer?.cancel();

    if (startTime == null) {
      _remainingSeconds = duration;
    } else if (isPaused) {
      _remainingSeconds = pauseTimeSeconds ?? duration;
    } else {
      final now = DateTime.now().millisecondsSinceEpoch;
      final elapsed = (now - startTime) ~/ 1000;
      _remainingSeconds = duration - elapsed;
      
      if (_remainingSeconds > 0) {
        _localTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (mounted) {
            setState(() {
              _remainingSeconds--;
              if (_remainingSeconds <= 0) {
                timer.cancel();
              }
            });
          }
        });
      }
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _localTimer?.cancel();
    super.dispose();
  }

  String _formatTime(int seconds) {
    if (seconds < 0) return "00:00";
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return "$m:$s";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isRunning = widget.data['startTime'] != null && !(widget.data['isPaused'] ?? false);
    final int totalDuration = widget.data['duration'] ?? 25 * 60;
    final double progress = (_remainingSeconds / totalDuration).clamp(0.0, 1.0);

    return Container(
      width: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.timer, color: theme.colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              const Text("Group Study Timer", style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 20),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 8,
                  backgroundColor: theme.colorScheme.surface,
                  color: _remainingSeconds < 60 ? Colors.red : theme.colorScheme.primary,
                ),
              ),
              Text(
                _formatTime(_remainingSeconds),
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (!isRunning)
                IconButton(
                  onPressed: _startTimer,
                  icon: const Icon(Icons.play_arrow),
                  color: Colors.green,
                  iconSize: 32,
                )
              else
                IconButton(
                  onPressed: _pauseTimer,
                  icon: const Icon(Icons.pause),
                  color: Colors.orange,
                  iconSize: 32,
                ),
              IconButton(
                onPressed: _resetTimer,
                icon: const Icon(Icons.refresh),
                color: Colors.grey,
                iconSize: 32,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _startTimer() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final int duration = widget.data['duration'] ?? 25 * 60;
    final int? pauseTimeSeconds = widget.data['pauseTimeSeconds'];
    
    // If resuming from pause, adjust startTime
    int startTime = now;
    if (pauseTimeSeconds != null) {
      startTime = now - (duration - pauseTimeSeconds) * 1000;
    }

    _updateData({
      'type': 'study_timer',
      'duration': duration,
      'startTime': startTime,
      'isPaused': false,
      'pauseTimeSeconds': null,
    });
  }

  void _pauseTimer() {
    _updateData({
      ...widget.data,
      'isPaused': true,
      'pauseTimeSeconds': _remainingSeconds,
    });
  }

  void _resetTimer() {
    _updateData({
      'type': 'study_timer',
      'duration': 25 * 60,
      'startTime': null,
      'isPaused': false,
      'pauseTimeSeconds': null,
    });
  }

  void _updateData(Map<String, dynamic> newData) {
    Provider.of<InnovationProvider>(context, listen: false).updatePluginData(
      chatId: widget.chatId,
      messageId: widget.messageId,
      newData: newData,
    );
  }
}
