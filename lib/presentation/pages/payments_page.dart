import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/chat_provider.dart';
import '../providers/auth_provider.dart';
import '../../domain/entities/transaction_entity.dart';

class PaymentsPage extends StatelessWidget {
  const PaymentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Payments"),
        actions: [
          IconButton(icon: const Icon(Icons.help_outline), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              color: Colors.grey.withOpacity(0.05),
              child: Column(
                children: [
                  const Icon(Icons.payment, size: 60, color: Color(0xFF00A884)),
                  const SizedBox(height: 16),
                  const Text(
                    "Send and receive money securely",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "WhatsApp Pay is a simple and secure way to transfer money in our demo environment.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 20),
                   ElevatedButton(
                    onPressed: () => _showSetupDialog(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00A884),
                      minimumSize: const Size(double.infinity, 45),
                    ),
                    child: const Text("Finish Setup", style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                "Payment methods",
                style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00A884)),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.add_circle_outline, color: Colors.blue),
              title: const Text("Add payment method"),
              onTap: () => _showAddPaymentMethodDialog(context),
            ),
            const Divider(),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                "History",
                style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00A884)),
              ),
            ),
            StreamBuilder<List<TransactionEntity>>(
              stream: context.read<ChatProvider>().getTransactions(context.read<AuthProvider>().user?.uid ?? ''),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
                }
                final transactions = snapshot.data ?? [];
                if (transactions.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Text(
                        "No transaction history",
                        style: TextStyle(color: Colors.black38),
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    final tx = transactions[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: tx.status == 'completed' ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                        child: Icon(
                          tx.status == 'completed' ? Icons.check : Icons.error_outline,
                          color: tx.status == 'completed' ? Colors.green : Colors.red,
                        ),
                      ),
                      title: Text(tx.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(DateFormat('MMM d, HH:mm').format(tx.date)),
                      trailing: Text(
                        "₹${tx.amount.toStringAsFixed(2)}",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showSetupDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Finish Setup"),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Complete these steps to start using WhatsApp Pay:"),
            SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.check_circle, color: Colors.green),
              title: Text("Verify Phone Number"),
            ),
            ListTile(
              leading: Icon(Icons.radio_button_unchecked, color: Colors.grey),
              title: Text("Add Bank Account or Card"),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showAddPaymentMethodDialog(context);
            },
            child: const Text("CONTINUE", style: TextStyle(color: Color(0xFF00A884))),
          ),
        ],
      ),
    );
  }

  void _showAddPaymentMethodDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Add Payment Method", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 20),
            TextField(
              decoration: const InputDecoration(labelText: "Card Number", hintText: "0000 0000 0000 0000"),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: TextField(decoration: const InputDecoration(labelText: "Expiry", hintText: "MM/YY"))),
                const SizedBox(width: 16),
                Expanded(child: TextField(decoration: const InputDecoration(labelText: "CVV", hintText: "123"))),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Payment method added successfully!")));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00A884),
                minimumSize: const Size(double.infinity, 45),
              ),
              child: const Text("ADD CARD", style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
