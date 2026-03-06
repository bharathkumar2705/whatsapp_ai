import 'package:flutter/foundation.dart';

// STUB: agora_rtc_engine removed to avoid NDK dependency.
// Video calling is disabled. Re-enable by restoring agora_rtc_engine.

const String kAgoraAppId = 'e45409b6ea5d43378ae1cde7cbe33ca2';

class AgoraService {
  bool _isInitialized = false;

  void Function(int uid, int elapsed)? onUserJoined;
  void Function(int uid, dynamic reason)? onUserOffline;
  void Function()? onJoinSuccess;
  void Function(dynamic code, String message)? onError;

  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    _isInitialized = true;
    debugPrint('AgoraService: STUB mode — video calls disabled.');
  }

  Future<void> joinChannel({
    required String channelName,
    String token = '',
    int uid = 0,
    bool videoEnabled = true,
  }) async {
    debugPrint('AgoraService STUB: joinChannel called (no-op)');
  }

  Future<void> leaveChannel() async {}
  Future<void> setMuted(bool muted) async {}
  Future<void> setCameraEnabled(bool enabled) async {}
  Future<void> switchCamera() async {}
  Future<void> setSpeakerEnabled(bool enabled) async {}
  Future<void> initializeSpatialAudio() async {}
  Future<void> dispose() async { _isInitialized = false; }
}
