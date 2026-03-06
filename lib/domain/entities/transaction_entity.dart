class TransactionEntity {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final String status; // 'pending', 'completed', 'failed'

  TransactionEntity({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.status,
  });
}
