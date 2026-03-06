import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import '../providers/innovation_provider.dart';
import '../providers/auth_provider.dart';

class ReceiptScannerPage extends StatefulWidget {
  final String chatId;

  const ReceiptScannerPage({super.key, required this.chatId});

  @override
  State<ReceiptScannerPage> createState() => _ReceiptScannerPageState();
}

class _ReceiptScannerPageState extends State<ReceiptScannerPage> {
  File? _image;
  bool _isProcessing = false;
  final TextRecognizer _textRecognizer = TextRecognizer();
  double? _extractedTotal;

  @override
  void dispose() {
    _textRecognizer.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Smart Receipt Scanner", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_image != null)
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Image.file(_image!),
                    if (_isProcessing)
                      const CircularProgressIndicator(color: Colors.green),
                  ],
                ),
              )
            else
              const Icon(Icons.receipt_long, size: 100, color: Colors.white24),
            const SizedBox(height: 20),
            if (_extractedTotal != null)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.green),
                ),
                child: Column(
                  children: [
                    const Text("Extracted Total", style: TextStyle(color: Colors.white70)),
                    Text("\$${_extractedTotal!.toStringAsFixed(2)}", 
                         style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _sendToSplit,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      child: const Text("AUTO-SPLIT NOW"),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _actionButton(Icons.camera_alt, "Take Photo", _takePhoto),
                const SizedBox(width: 20),
                _actionButton(Icons.photo_library, "Gallery", _fromGallery),
              ],
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _actionButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(radius: 30, backgroundColor: Colors.white10, child: Icon(icon, color: Colors.white)),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }

  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.camera);
    if (image != null) _processImage(File(image.path));
  }

  Future<void> _fromGallery() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) _processImage(File(image.path));
  }

  Future<void> _processImage(File image) async {
    setState(() {
      _image = image;
      _isProcessing = true;
      _extractedTotal = null;
    });

    final inputImage = InputImage.fromFile(image);
    final recognizedText = await _textRecognizer.processImage(inputImage);
    
    // Simple logic to find the largest currency-formatted number near keywords like "Total"
    double? total;
    final lines = recognizedText.blocks.expand((b) => b.lines).map((l) => l.text.toLowerCase()).toList();
    
    for (var line in lines) {
      if (line.contains('total') || line.contains('amount') || line.contains('sum')) {
        final matches = RegExp(r'\d+\.\d{2}').allMatches(line);
        if (matches.isNotEmpty) {
          total = double.tryParse(matches.last.group(0)!);
          break;
        }
      }
    }

    // Backup: find any price looking thing if 'total' keyword isn me
    if (total == null) {
      final allMatches = RegExp(r'\d+\.\d{2}').allMatches(recognizedText.text);
      if (allMatches.isNotEmpty) {
        total = allMatches.map((m) => double.tryParse(m.group(0)!) ?? 0.0).reduce((a, b) => a > b ? a : b);
      }
    }

    setState(() {
      _isProcessing = false;
      _extractedTotal = total;
    });

    if (total == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Couldn't extract total. Please try again or enter manually.")));
    }
  }

  void _sendToSplit() {
    if (_extractedTotal == null) return;
    
    final innovation = Provider.of<InnovationProvider>(context, listen: false);
    final myUid = Provider.of<AuthProvider>(context, listen: false).user?.uid ?? '';
    
    // We start an expense tracker with the extracted total
    innovation.startExpenseTracker(
      chatId: widget.chatId,
      myUid: myUid,
      initialDescription: "Scanned Receipt",
      initialAmount: _extractedTotal!,
    );
    
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text("Shared expense created from receipt! ✅"),
      backgroundColor: Colors.green,
    ));
  }
}
