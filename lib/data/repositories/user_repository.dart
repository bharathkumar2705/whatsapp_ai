import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/user_repository_interface.dart';
import '../models/user_model.dart';

class UserRepository implements IUserRepository {
  FirebaseFirestore get _firestore {
    if (Firebase.apps.isEmpty) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'no-app',
        message: 'Firebase is not initialized.',
      );
    }
    return FirebaseFirestore.instance;
  }

  @override
  Future<void> createUser(UserEntity user) async {
    final model = UserModel(
      uid: user.uid,
      displayName: user.displayName,
      email: user.email,
      photoUrl: user.photoUrl,
      about: user.about,
      lastSeen: user.lastSeen,
      isOnline: user.isOnline,
    );
    await _firestore.collection('users').doc(user.uid).set(model.toMap());
  }

  @override
  Future<UserEntity?> getUser(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      return UserModel.fromMap(doc.data()!);
    }
    return null;
  }

  @override
  Future<UserEntity?> getUserByPhone(String phone) async {
    final snapshot = await _firestore
        .collection('users')
        .where('phoneNumber', isEqualTo: phone)
        .limit(1)
        .get();
    if (snapshot.docs.isNotEmpty) {
      return UserModel.fromMap(snapshot.docs.first.data());
    }
    return null;
  }

  @override
  Future<void> updateProfile(String uid, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(uid).update(data);
  }

  @override
  Stream<UserEntity> getUserStream(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) => UserModel.fromMap(doc.data()!));
  }

  @override
  Future<List<UserEntity>> getAllUsers() async {
    final snapshot = await _firestore.collection('users').get();
    return snapshot.docs.map((doc) => UserModel.fromMap(doc.data())).toList();
  }

  @override
  Future<void> updateBusinessProfile(String uid, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(uid).update(data);
  }

  @override
  Future<void> addCatalogItem(String uid, Map<String, dynamic> item) async {
    await _firestore.collection('users').doc(uid).collection('catalog').add(item);
  }

  @override
  Future<void> updateCatalogItem(String uid, String itemId, Map<String, dynamic> item) async {
    await _firestore.collection('users').doc(uid).collection('catalog').doc(itemId).update(item);
  }

  @override
  Future<void> deleteCatalogItem(String uid, String itemId) async {
    await _firestore.collection('users').doc(uid).collection('catalog').doc(itemId).delete();
  }

  @override
  Stream<List<Map<String, dynamic>>> getCatalog(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('catalog')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList());
  }

  @override
  Future<void> addQuickReply(String uid, Map<String, dynamic> reply) async {
    await _firestore.collection('users').doc(uid).collection('quick_replies').add(reply);
  }

  @override
  Future<void> updateQuickReply(String uid, String replyId, Map<String, dynamic> reply) async {
    await _firestore.collection('users').doc(uid).collection('quick_replies').doc(replyId).update(reply);
  }

  @override
  Future<void> deleteQuickReply(String uid, String replyId) async {
    await _firestore.collection('users').doc(uid).collection('quick_replies').doc(replyId).delete();
  }

  @override
  Stream<List<Map<String, dynamic>>> getQuickReplies(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('quick_replies')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList());
  }

  // Wave 9: Multi-Device
  @override
  Future<void> registerDevice(String uid, Map<String, dynamic> deviceInfo) async {
    final deviceId = deviceInfo['deviceId'] as String;
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('devices')
        .doc(deviceId)
        .set(deviceInfo, SetOptions(merge: true));
  }

  @override
  Stream<List<Map<String, dynamic>>> getLinkedDevices(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('devices')
        .orderBy('linkedAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList());
  }

  @override
  Future<void> removeDevice(String uid, String deviceId) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('devices')
        .doc(deviceId)
        .delete();
  }
}
