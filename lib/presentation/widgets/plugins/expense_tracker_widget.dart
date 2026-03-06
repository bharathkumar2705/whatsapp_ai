import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/innovation_provider.dart';
import '../../providers/auth_provider.dart';
import 'package:intl/intl.dart';

class ExpenseTrackerWidget extends StatelessWidget {
  final String chatId;
  final String messageId;
  final Map<String, dynamic> data;

  const ExpenseTrackerWidget({
    super.key,
    required this.chatId,
    required this.messageId,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final List<dynamic> expenses = data['expenses'] ?? [];
    final double total = expenses.fold(0.0, (sum, item) => sum + (item['amount'] ?? 0.0));
    final theme = Theme.of(context);
    final myUid = Provider.of<AuthProvider>(context, listen: false).user?.uid;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_balance_wallet, color: theme.colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                "Shared Expense Tracker",
                style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
              ),
            ],
          ),
          const Divider(),
          if (expenses.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text("No expenses added yet.", style: TextStyle(fontStyle: FontStyle.italic, fontSize: 13)),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: expenses.length,
              itemBuilder: (context, index) {
                final item = expenses[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          item['description'] ?? 'Expense',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      Text(
                        "\$${(item['amount'] ?? 0.0).toStringAsFixed(2)}",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                );
              },
            ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Total:", style: TextStyle(fontWeight: FontWeight.bold)),
              Text(
                "\$${total.toStringAsFixed(2)}",
                style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showAddExpenseDialog(context, expenses),
              icon: const Icon(Icons.add, size: 18),
              label: const Text("Add Expense"),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddExpenseDialog(BuildContext context, List<dynamic> currentExpenses) {
    final descController = TextEditingController();
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Add New Expense"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: "Description (e.g. Pizza)"),
            ),
            TextField(
              controller: amountController,
              decoration: const InputDecoration(labelText: "Amount"),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL")),
          ElevatedButton(
            onPressed: () {
              final double? amount = double.tryParse(amountController.text);
              if (descController.text.isNotEmpty && amount != null) {
                Provider.of<InnovationProvider>(context, listen: false).addExpense(
                  chatId: chatId,
                  messageId: messageId,
                  currentExpenses: currentExpenses,
                  description: descController.text,
                  amount: amount,
                  addedByUid: Provider.of<AuthProvider>(context, listen: false).user?.uid ?? '',
                );
                Navigator.pop(ctx);
              }
            },
            child: const Text("ADD"),
          ),
        ],
      ),
    );
  }
}
