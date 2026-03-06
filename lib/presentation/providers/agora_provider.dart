import 'package:flutter/material.dart';
import '../../data/services/agora_service.dart';

class AgoraProvider extends ChangeNotifier {
  final AgoraService _service = AgoraService();

  bool _isCallActive = false;
  bool _isMuted = false;
  bool _isCameraOff = false;
  bool _isSpeakerOn = true;
  int? _remoteUid;
  bool _isRemoteJoined = false;
  String? _activeChannel;
  String? _selectedAvatarUrl;
  bool _isAvatarMode = false;

  bool get isCallActive => _isCallActive;
  bool get isMuted => _isMuted;
  bool get isCameraOff => _isCameraOff;
  bool get isSpeakerOn => _isSpeakerOn;
  int? get remoteUid => _remoteUid;
  bool get isRemoteJoined => _isRemoteJoined;
  String? get activeChannel => _activeChannel;
  String? get selectedAvatarUrl => _selectedAvatarUrl;
  bool get isAvatarMode => _isAvatarMode;
  AgoraService get service => _service;

  AgoraProvider() {
    _service.onUserJoined = (uid, elapsed) {
      _remoteUid = uid;
      _isRemoteJoined = true;
      notifyListeners();
    };
    _service.onUserOffline = (uid, reason) {
      _remoteUid = null;
      _isRemoteJoined = false;
      notifyListeners();
    };
    _service.onJoinSuccess = () {
      _isCallActive = true;
      notifyListeners();
    };
  }

  /// Start a call — joins an Agora channel named after the chat ID.
  Future<void> startCall({
    required String channelName,
    String token = '',
    bool videoEnabled = true,
  }) async {
    await _service.initialize();
    _activeChannel = channelName;
    _isCameraOff = !videoEnabled;
    _isMuted = false;
    _isSpeakerOn = true;
    _isRemoteJoined = false;
    _remoteUid = null;
    await _service.joinChannel(
      channelName: channelName,
      token: token,
      videoEnabled: videoEnabled,
    );
    notifyListeners();
  }

  /// End the call cleanly.
  Future<void> endCall() async {
    await _service.leaveChannel();
    _isCallActive = false;
    _isRemoteJoined = false;
    _remoteUid = null;
    _activeChannel = null;
    notifyListeners();
  }

  Future<void> toggleMute() async {
    _isMuted = !_isMuted;
    await _service.setMuted(_isMuted);
    notifyListeners();
  }

  Future<void> toggleCamera() async {
    _isCameraOff = !_isCameraOff;
    await _service.setCameraEnabled(!_isCameraOff);
    notifyListeners();
  }

  Future<void> switchCamera() async {
    await _service.switchCamera();
  }

  Future<void> toggleSpeaker() async {
    _isSpeakerOn = !_isSpeakerOn;
    await _service.setSpeakerEnabled(_isSpeakerOn);
    notifyListeners();
  }

  void setSelectedAvatar(String url) {
    _selectedAvatarUrl = url;
    notifyListeners();
  }

  void toggleAvatarMode() {
    _isAvatarMode = !_isAvatarMode;
    // When avatar mode is ON, we should ideally mute the camera stream for others
    // but keep our local preview as the avatar.
    // Agora allows and encourages "Virtual Background" or custom video source,
    // but for our MVP, we'll just swap the UI and turn off camera if needed.
    if (_isAvatarMode) {
      _service.setCameraEnabled(false);
      _isCameraOff = true;
    } else {
      _service.setCameraEnabled(true);
      _isCameraOff = false;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }
}
