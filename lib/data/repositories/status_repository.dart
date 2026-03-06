import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/status_entity.dart';
import '../../domain/repositories/status_repository_interface.dart';
import '../models/status_model.dart';

class StatusRepository implements IStatusRepository {
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
  Future<void> postStatus(StatusEntity status) async {
    final model = StatusModel(
      id: status.id,
      userId: status.userId,
      userName: status.userName,
      userImageUrl: status.userImageUrl,
      contentUrl: status.contentUrl,
      type: status.type,
      timestamp: status.timestamp,
      viewers: status.viewers,
    );
    
    await _firestore.collection('statuses').add(model.toMap());
  }

  @override
  Stream<List<StatusEntity>> getRecentStatuses() {
    // Note: Privacy filtering is done on the client side for this demo to avoid complex Firestore rules/queries.
    // In a production app, we would use complex queries or Cloud Functions.
    final oneDayAgo = DateTime.now().subtract(const Duration(hours: 24));
    return _firestore
        .collection('statuses')
        .where('timestamp', isGreaterThan: oneDayAgo.millisecondsSinceEpoch)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => StatusModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  @override
  Future<void> markStatusSeen(String statusId, String uid) async {
    await _firestore.collection('statuses').doc(statusId).update({
      'viewers': FieldValue.arrayUnion([uid]),
    });
  }
}
