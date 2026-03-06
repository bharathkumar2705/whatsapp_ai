import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Generic methods to handle Firestore CRUD
  Future<void> setData(String collection, String docId, Map<String, dynamic> data) async {
    await _firestore.collection(collection).doc(docId).set(data);
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getDoc(String collection, String docId) async {
    return await _firestore.collection(collection).doc(docId).get();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchDoc(String collection, String docId) {
    return _firestore.collection(collection).doc(docId).snapshots();
  }

  Future<QuerySnapshot<Map<String, dynamic>>> getCollection(String collection) async {
    return await _firestore.collection(collection).get();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchCollection(String collection) {
    return _firestore.collection(collection).snapshots();
  }
}
