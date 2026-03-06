import '../entities/user_entity.dart';

abstract class IUserRepository {
  Future<void> createUser(UserEntity user);
  Future<UserEntity?> getUser(String uid);
  Future<UserEntity?> getUserByPhone(String phone);
  Future<void> updateProfile(String uid, Map<String, dynamic> data);
  Stream<UserEntity> getUserStream(String uid);
  Future<List<UserEntity>> getAllUsers();
  
  // Wave 8: Business
  Future<void> updateBusinessProfile(String uid, Map<String, dynamic> data);
  Future<void> addCatalogItem(String uid, Map<String, dynamic> item);
  Future<void> updateCatalogItem(String uid, String itemId, Map<String, dynamic> item);
  Future<void> deleteCatalogItem(String uid, String itemId);
  Stream<List<Map<String, dynamic>>> getCatalog(String uid);
  
  Future<void> addQuickReply(String uid, Map<String, dynamic> reply);
  Future<void> updateQuickReply(String uid, String replyId, Map<String, dynamic> reply);
  Future<void> deleteQuickReply(String uid, String replyId);
  Stream<List<Map<String, dynamic>>> getQuickReplies(String uid);

  // Wave 9: Multi-Device
  Future<void> registerDevice(String uid, Map<String, dynamic> deviceInfo);
  Stream<List<Map<String, dynamic>>> getLinkedDevices(String uid);
  Future<void> removeDevice(String uid, String deviceId);
}
