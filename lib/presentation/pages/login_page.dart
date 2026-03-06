import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'registration_page.dart';
import 'forgot_password_page.dart';
import 'phone_otp_page.dart';
import 'chat_list_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading     = false;
  bool _googleLoading = false;
  bool _obscure       = true;

  static const _green     = Color(0xFF00A884);
  static const _darkGreen = Color(0xFF075E54);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ── Email/password login ──────────────────────────────────────────────────
  Future<void> _login() async {
    setState(() => _isLoading = true);
    try {
      await Provider.of<AuthProvider>(context, listen: false).signIn(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const ChatListPage()),
          (route) => false,
        );
      }
    } catch (e) {
      _snack("Login failed: ${e.toString()}");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Google Sign-In ────────────────────────────────────────────────────────
  Future<void> _googleSignIn() async {
    setState(() => _googleLoading = true);
    try {
      await Provider.of<AuthProvider>(context, listen: false).signInWithGoogle();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const ChatListPage()),
          (route) => false,
        );
      }
    } catch (e) {
      _snack("Google sign-in failed: ${e.toString()}");
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  // ── UI ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 60),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Logo
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Image.asset(
                  'assets/app_icon.png',
                  width: 84,
                  height: 84,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Center(
              child: Text(
                "WhatsApp AI",
                style: TextStyle(
                    fontSize: 26, fontWeight: FontWeight.bold, color: _darkGreen),
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(
                "Sign in to your account",
                style: TextStyle(color: Colors.grey[500], fontSize: 14),
              ),
            ),
            const SizedBox(height: 40),

            // Email field
            _buildField(
              controller: _emailController,
              label: "Email",
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 14),

            // Password field
            TextField(
              controller: _passwordController,
              obscureText: _obscure,
              decoration: _inputDeco(
                label: "Password",
                icon: Icons.lock_outline,
                suffix: IconButton(
                  icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
            ),

            // Forgot password
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ForgotPasswordPage())),
                child: const Text("Forgot Password?",
                    style: TextStyle(color: _green)),
              ),
            ),

            // Login button
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _green,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    : const Text("LOGIN",
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15)),
              ),
            ),
            const SizedBox(height: 24),

            // Divider
            Row(children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text("OR", style: TextStyle(color: Colors.grey[400])),
              ),
              const Expanded(child: Divider()),
            ]),
            const SizedBox(height: 20),

            // Google Sign-In
            SizedBox(
              height: 52,
              child: OutlinedButton.icon(
                icon: _googleLoading
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2,
                            color: Color(0xFF4285F4)))
                    : const _GoogleLogo(),
                label: const Text("Continue with Google",
                    style: TextStyle(fontWeight: FontWeight.w600)),
                onPressed: _googleLoading ? null : _googleSignIn,
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26)),
                  side: BorderSide(color: Colors.grey[300]!),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Phone OTP
            SizedBox(
              height: 52,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.phone_outlined, color: _green),
                label: const Text("Continue with Phone (OTP)",
                    style: TextStyle(
                        fontWeight: FontWeight.w600, color: _darkGreen)),
                onPressed: () => Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => const PhoneOtpPage())),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26)),
                  side: const BorderSide(color: _green),
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Sign up
            Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const RegistrationPage())),
                child: const Text.rich(
                  TextSpan(children: [
                    TextSpan(text: "Don't have an account? ",
                        style: TextStyle(color: Colors.grey)),
                    TextSpan(text: "Sign Up",
                        style: TextStyle(
                            color: _green, fontWeight: FontWeight.bold)),
                  ]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: _inputDeco(label: label, icon: icon),
    );
  }

  InputDecoration _inputDeco({
    required String label,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: _green),
      suffixIcon: suffix,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _green, width: 2),
      ),
      labelStyle: const TextStyle(color: Colors.grey),
    );
  }
}

/// Colourful G logo drawn in pure Flutter
class _GoogleLogo extends StatelessWidget {
  const _GoogleLogo();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  const _GoogleLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;

    // Coloured arc segments (simplified solid circle for compatibility)
    final colors = [
      (0.0, 0.5, const Color(0xFF4285F4)),    // blue top-right
      (0.5, 0.75, const Color(0xFF34A853)),   // green bottom-right
      (0.75, 0.875, const Color(0xFFFBBC05)), // yellow bottom-left
      (0.875, 1.0, const Color(0xFFEA4335)),  // red top-left
    ];
    for (final seg in colors) {
      final paint = Paint()..color = seg.$3..style = PaintingStyle.fill;
      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..arcTo(
          Rect.fromCircle(center: center, radius: r),
          seg.$1 * 2 * 3.1416 - 1.5708,
          (seg.$2 - seg.$1) * 2 * 3.1416,
          false,
        )
        ..close();
      canvas.drawPath(path, paint);
    }
    // White inner circle (donut effect)
    canvas.drawCircle(center, r * 0.55, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_) => false;
}
