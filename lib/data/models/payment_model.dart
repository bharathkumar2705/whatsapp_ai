class PaymentModel {
  final String id;
  final String senderId;
  final String receiverId;
  final double amount;
  final String currency;
  final String note;
  final DateTime timestamp;
  final String status; // 'pending', 'completed', 'failed'

  PaymentModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.amount,
    this.currency = 'USD',
    this.note = '',
    required this.timestamp,
    this.status = 'completed',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'amount': amount,
      'currency': currency,
      'note': note,
      'timestamp': timestamp.toIso8601String(),
      'status': status,
    };
  }

  factory PaymentModel.fromMap(Map<String, dynamic> map) {
    return PaymentModel(
      id: map['id'] ?? '',
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      currency: map['currency'] ?? 'USD',
      note: map['note'] ?? '',
      timestamp: DateTime.parse(map['timestamp']),
      status: map['status'] ?? 'completed',
    );
  }
}
