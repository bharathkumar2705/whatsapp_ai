import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/payment_model.dart';
import 'package:uuid/uuid.dart';

class PaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  Future<PaymentModel> sendPayment({
    required String senderId,
    required String receiverId,
    required double amount,
    String note = '',
  }) async {
    final payment = PaymentModel(
      id: _uuid.v4(),
      senderId: senderId,
      receiverId: receiverId,
      amount: amount,
      note: note,
      timestamp: DateTime.now(),
      status: 'completed', // Simulated auto-completion for MVP
    );

    // Record in global payments collection
    await _firestore.collection('payments').doc(payment.id).set(payment.toMap());
    
    // Update sender & receiver balances (Simulation)
    // In a real app, this would integrate with a payment gateway (Stripe/PayPal)
    
    return payment;
  }

  Stream<List<PaymentModel>> getTransactionHistory(String userId) {
    return _firestore
        .collection('payments')
        .where('senderId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => PaymentModel.fromMap(doc.data())).toList());
  }
}
