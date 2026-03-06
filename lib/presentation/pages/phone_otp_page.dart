import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'chat_list_page.dart';

/// Two-step screen: (1) enter phone number → (2) enter 6-digit OTP
class PhoneOtpPage extends StatefulWidget {
  const PhoneOtpPage({super.key});

  @override
  State<PhoneOtpPage> createState() => _PhoneOtpPageState();
}

class _PhoneOtpPageState extends State<PhoneOtpPage> {
  // Step 0 = enter phone, Step 1 = enter OTP
  int _step = 0;
  bool _isLoading = false;

  final _phoneController = TextEditingController();
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocus = List.generate(6, (_) => FocusNode());

  static const _green = Color(0xFF00A884);
  static const _darkGreen = Color(0xFF075E54);

  @override
  void dispose() {
    _phoneController.dispose();
    for (final c in _otpControllers) { c.dispose(); }
    for (final f in _otpFocus) { f.dispose(); }
    super.dispose();
  }

  // ── Step 1: send OTP ──────────────────────────────────────────────────────
  Future<void> _sendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.length < 8) {
      _snack("Enter a valid phone number with country code (e.g. +91XXXXXXXXXX)");
      return;
    }
    setState(() => _isLoading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    await auth.verifyPhoneNumber(
      phone,
      onCodeSent: (_) {
        setState(() { _isLoading = false; _step = 1; });
        _snack("OTP sent! Check your SMS.");
      },
      onError: (msg) {
        setState(() => _isLoading = false);
        _snack("Error: $msg");
      },
      onAutoVerified: () {
        // Auto-verified on Android — go straight to home
        if (mounted) _goHome();
      },
    );
  }

  // ── Step 2: verify OTP ────────────────────────────────────────────────────
  Future<void> _verifyOtp() async {
    final code = _otpControllers.map((c) => c.text).join();
    if (code.length != 6) {
      _snack("Enter the complete 6-digit OTP");
      return;
    }
    setState(() => _isLoading = true);
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      await auth.confirmOtp(code);
      if (mounted) _goHome();
    } catch (e) {
      setState(() => _isLoading = false);
      _snack("Invalid OTP. Please try again.");
    }
  }

  void _goHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const ChatListPage()),
      (route) => false,
    );
  }

  void _snack(String msg) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ── UI ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: _darkGreen,
        foregroundColor: Colors.white,
        title: const Text("Phone Verification"),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            const SizedBox(height: 32),

            // Icon
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: _green.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.phone_android, size: 48, color: _green),
            ),
            const SizedBox(height: 24),

            Text(
              _step == 0 ? "Enter your phone number" : "Enter the OTP",
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold, color: _darkGreen),
            ),
            const SizedBox(height: 8),
            Text(
              _step == 0
                  ? "We will send a 6-digit verification code to your number."
                  : "A code was sent to ${_phoneController.text.trim()}",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 40),

            // ── Step 0: phone field ──────────────────────────────────────
            if (_step == 0) ...[
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: "Phone number",
                  hintText: "+91 9876543210",
                  prefixIcon: const Icon(Icons.phone, color: _green),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _green, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _sendOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _green,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                      : const Text("SEND OTP",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15)),
                ),
              ),
            ],

            // ── Step 1: OTP boxes ────────────────────────────────────────
            if (_step == 1) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, (i) => _OtpBox(
                  controller: _otpControllers[i],
                  focusNode: _otpFocus[i],
                  onChanged: (v) {
                    if (v.length == 1 && i < 5) {
                      _otpFocus[i + 1].requestFocus();
                    } else if (v.isEmpty && i > 0) {
                      _otpFocus[i - 1].requestFocus();
                    }
                    if (i == 5 && v.length == 1) _verifyOtp(); // auto-submit
                  },
                )),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _verifyOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _green,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                      : const Text("VERIFY OTP",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15)),
                ),
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text("Resend OTP"),
                onPressed: () {
                  setState(() {
                    _step = 0;
                    for (final c in _otpControllers) { c.clear(); }
                  });
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Single OTP character box
class _OtpBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 55,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: onChanged,
        decoration: InputDecoration(
          counterText: '',
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF00A884), width: 2),
          ),
        ),
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      ),
    );
  }
}
