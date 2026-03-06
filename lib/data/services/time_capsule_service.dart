import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class TimeCapsuleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> scheduleMessage({
    required String chatId,
    required String senderId,
    required String receiverId,
    required String text,
    required DateTime deliverAt,
  }) async {
    final messageId = const Uuid().v4();
    
    await _firestore.collection('time_capsules').doc(messageId).set({
      'id': messageId,
      'chatId': chatId,
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'deliverAt': deliverAt.millisecondsSinceEpoch,
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'pending',
    });
  }

  Stream<List<Map<String, dynamic>>> getPendingCapsules(String userId) {
    return _firestore
        .collection('time_capsules')
        .where('senderId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snap) => snap.docs.map((doc) => doc.data()).toList());
  }
}
