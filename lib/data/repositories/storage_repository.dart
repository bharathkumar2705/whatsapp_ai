import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class StorageRepository {
  FirebaseStorage get _storage {
    if (Firebase.apps.isEmpty) {
      throw FirebaseException(
        plugin: 'firebase_storage',
        code: 'no-app',
        message: 'Firebase is not initialized.',
      );
    }
    return FirebaseStorage.instance;
  }

  /// Upload any XFile (works on both Web and Mobile via bytes)
  Future<String> uploadXFile(XFile xFile, String storagePath) async {
    debugPrint("StorageRepository: Starting upload to $storagePath");
    try {
      final bytes = await xFile.readAsBytes();
      debugPrint("StorageRepository: Bytes read (${bytes.length} bytes)");
      
      // Determine content type based on extension
      String contentType = 'application/octet-stream';
      final ext = storagePath.split('.').last.toLowerCase();
      if (['jpg', 'jpeg', 'png', 'gif'].contains(ext)) {
        contentType = 'image/$ext';
        if (ext == 'jpg') contentType = 'image/jpeg';
      } else if (ext == 'pdf') {
        contentType = 'application/pdf';
      } else if (['mp3', 'wav', 'm4a', 'aac'].contains(ext)) {
        contentType = 'audio/$ext';
      } else if (['mp4', 'mov'].contains(ext)) {
        contentType = 'video/mp4';
      }

      final metadata = SettableMetadata(contentType: contentType);
      final ref = _storage.ref().child(storagePath);
      
      debugPrint("StorageRepository: Calling putData with type: $contentType");
      UploadTask uploadTask = ref.putData(bytes, metadata);

      // Listen to progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        double progress = 100 * (snapshot.bytesTransferred / snapshot.totalBytes);
        debugPrint("Upload progress: ${progress.toStringAsFixed(2)}% (${snapshot.state})");
      }, onError: (e) {
        debugPrint("StorageRepository: Snapshot Stream Error: $e");
      });

      // Wait for completion with a timeout
      final snapshot = await uploadTask.timeout(const Duration(seconds: 45));
      debugPrint("StorageRepository: Upload complete, state: ${snapshot.state}");
      
      final url = await ref.getDownloadURL();
      debugPrint("StorageRepository: URL generated: $url");
      return url;
    } catch (e) {
      debugPrint("StorageRepository ERROR in uploadXFile: $e");
      if (e.toString().contains("timeout")) {
        throw "Upload timed out. This is likely a Firebase CORS issue. You MUST configure CORS in your Firebase console.";
      }
      rethrow;
    }
  }

  Future<String> uploadMessageMedia(XFile file, String chatId) async {
    final fileName = const Uuid().v4();
    final extension = file.name.split('.').last;
    return uploadXFile(file, 'chats/$chatId/media/$fileName.$extension');
  }

  Future<String> uploadProfileImage(XFile file, String uid) async {
    return uploadXFile(file, 'users/$uid/profile.jpg');
  }

  Future<String> uploadStatusMedia(XFile file, String uid) async {
    final fileName = const Uuid().v4();
    final extension = file.name.split('.').last;
    return uploadXFile(file, 'statuses/$uid/$fileName.$extension');
  }

  /// Legacy helper — upload raw bytes directly
  Future<String> uploadBytes(List<int> bytes, String path, {String? contentType}) async {
    final ref = _storage.ref().child(path);
    final metadata = contentType != null ? SettableMetadata(contentType: contentType) : null;
    await ref.putData(Uint8List.fromList(bytes), metadata);
    return await ref.getDownloadURL();
  }
}
