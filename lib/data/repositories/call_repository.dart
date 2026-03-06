import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/call_entity.dart';
import '../models/call_model.dart';

class CallRepository {
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

  Future<void> saveCall(CallEntity call) async {
    final model = CallModel(
      id: call.id,
      callerId: call.callerId,
      callerName: call.callerName,
      callerImage: call.callerImage,
      receiverId: call.receiverId,
      receiverName: call.receiverName,
      receiverImage: call.receiverImage,
      timestamp: call.timestamp,
      type: call.type,
      status: call.status,
    );
    await _firestore.collection('calls').add(model.toMap());
  }

  Stream<List<CallEntity>> getCallHistory(String uid) {
    return _firestore
        .collection('calls')
        .where(Filter.or(
          Filter('callerId', isEqualTo: uid),
          Filter('receiverId', isEqualTo: uid),
        ))
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CallModel.fromMap(doc.data(), doc.id))
            .toList());
  }
}
