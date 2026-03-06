import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../../data/services/time_capsule_service.dart';

class TimeCapsulePage extends StatefulWidget {
  final String chatId;
  final String otherUserId;

  const TimeCapsulePage({
    super.key,
    required this.chatId,
    required this.otherUserId,
  });

  @override
  State<TimeCapsulePage> createState() => _TimeCapsulePageState();
}

class _TimeCapsulePageState extends State<TimeCapsulePage> {
  final TextEditingController _textController = TextEditingController();
  DateTime _deliveryDate = DateTime.now().add(const Duration(days: 365));
  final TimeCapsuleService _capsuleService = TimeCapsuleService();
  bool _isSending = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Time Capsule"),
        backgroundColor: const Color(0xFF075E54),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Icon(Icons.hourglass_bottom, size: 64, color: Colors.amber),
            const SizedBox(height: 16),
            const Text(
              "Send a message to the future.\nIt will be delivered on the date you choose.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _textController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: "Your future message...",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              title: const Text("Delivery Date"),
              subtitle: Text(DateFormat('MMMM dd, yyyy').format(_deliveryDate)),
              trailing: const Icon(Icons.calendar_month),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _deliveryDate,
                  firstDate: DateTime.now().add(const Duration(days: 1)),
                  lastDate: DateTime.now().add(const Duration(days: 3650)),
                );
                if (picked != null) setState(() => _deliveryDate = picked);
              },
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSending ? null : _schedule,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                ),
                child: _isSending 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("SEAL CAPSULE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _schedule() async {
    if (_textController.text.trim().isEmpty) return;

    setState(() => _isSending = true);
    try {
      final myUid = Provider.of<AuthProvider>(context, listen: false).user!.uid;
      await _capsuleService.scheduleMessage(
        chatId: widget.chatId,
        senderId: myUid,
        receiverId: widget.otherUserId,
        text: _textController.text.trim(),
        deliverAt: _deliveryDate,
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Time Capsule sealed! See you in the future. 🕒")),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }
}
