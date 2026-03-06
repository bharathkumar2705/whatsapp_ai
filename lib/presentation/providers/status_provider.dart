import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../domain/entities/status_entity.dart';
import '../../data/repositories/status_repository.dart';
import '../../data/repositories/storage_repository.dart';

class StatusProvider extends ChangeNotifier {
  final StatusRepository _statusRepository = StatusRepository();
  final StorageRepository _storageRepository = StorageRepository();
  
  List<StatusEntity> _statuses = [];
  bool _isLoading = false;

  List<StatusEntity> get statuses => _statuses;
  bool get isLoading => _isLoading;

  void listenToStatuses() {
    _statusRepository.getRecentStatuses().listen((statuses) {
      _statuses = statuses;
      notifyListeners();
    });
  }

  Future<void> postImageStatus(String userId, String userName, String? userImage, XFile file, {String privacyType = 'contacts', List<String> privacyList = const []}) async {
    debugPrint("StatusProvider: postImageStatus called, privacy: $privacyType");
    _isLoading = true;
    notifyListeners();
    
    try {
      final contentUrl = await _storageRepository.uploadStatusMedia(file, userId);
      debugPrint("StatusProvider: Image uploaded, URL: $contentUrl");
      final status = StatusEntity(
        id: '',
        userId: userId,
        userName: userName,
        userImageUrl: userImage,
        contentUrl: contentUrl,
        type: 'image',
        timestamp: DateTime.now(),
        privacyType: privacyType,
        privacyUidList: privacyList,
      );
      await _statusRepository.postStatus(status);
      debugPrint("StatusProvider: Image status posted");
    } catch (e) {
      debugPrint("StatusProvider Error in postImageStatus: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> postTextStatus(String userId, String userName, String? userImage, String text, {String privacyType = 'contacts', List<String> privacyList = const []}) async {
    debugPrint("StatusProvider: postTextStatus called, privacy: $privacyType");
     final status = StatusEntity(
        id: '',
        userId: userId,
        userName: userName,
        userImageUrl: userImage,
        contentUrl: text,
        type: 'text',
        timestamp: DateTime.now(),
        privacyType: privacyType,
        privacyUidList: privacyList,
      );
      try {
        await _statusRepository.postStatus(status);
        debugPrint("StatusProvider: Text status posted");
      } catch (e) {
        debugPrint("StatusProvider Error in postTextStatus: $e");
      }
  }

  Future<void> markSeen(String statusId, String uid) async {
    await _statusRepository.markStatusSeen(statusId, uid);
  }

  Future<void> postVideoStatus(String userId, String userName, String? userImage, XFile file, {String privacyType = 'contacts', List<String> privacyList = const []}) async {
    debugPrint("StatusProvider: postVideoStatus called");
    _isLoading = true;
    notifyListeners();
    try {
      final contentUrl = await _storageRepository.uploadStatusMedia(file, userId);
      final status = StatusEntity(
        id: '',
        userId: userId,
        userName: userName,
        userImageUrl: userImage,
        contentUrl: contentUrl,
        type: 'video',
        timestamp: DateTime.now(),
        privacyType: privacyType,
        privacyUidList: privacyList,
      );
      await _statusRepository.postStatus(status);
    } catch (e) {
      debugPrint("StatusProvider Error in postVideoStatus: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> postVoiceStatus(String userId, String userName, String? userImage, XFile file, {String privacyType = 'contacts', List<String> privacyList = const []}) async {
    debugPrint("StatusProvider: postVoiceStatus called");
    _isLoading = true;
    notifyListeners();
    try {
      final contentUrl = await _storageRepository.uploadStatusMedia(file, userId);
      final status = StatusEntity(
        id: '',
        userId: userId,
        userName: userName,
        userImageUrl: userImage,
        contentUrl: contentUrl,
        type: 'voice',
        timestamp: DateTime.now(),
        privacyType: privacyType,
        privacyUidList: privacyList,
      );
      await _statusRepository.postStatus(status);
    } catch (e) {
      debugPrint("StatusProvider Error in postVoiceStatus: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
