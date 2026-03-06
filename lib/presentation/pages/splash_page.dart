import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'chat_list_page.dart';
import 'login_page.dart';
import '../../data/services/security_service.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  late AnimationController _controller;
  final SecurityService _securityService = SecurityService();
  Timer? _fallbackTimer;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    
    // Fallback timer: 5 seconds max on splash
    _fallbackTimer = Timer(const Duration(seconds: 5), () {
      _checkAuthAndNavigate();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _fallbackTimer?.cancel();
    super.dispose();
  }

  void _checkAuthAndNavigate() {
    if (_navigated) return;
    
    _navigated = true;
    _fallbackTimer?.cancel();
    _performNavigation();
  }

  Future<void> _performNavigation() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    if (authProvider.isAuthenticated) {
      bool isLockEnabled = authProvider.userModel?.privacySettings['appLock'] ?? false;
      if (isLockEnabled) {
        bool authenticated = await _securityService.authenticate();
        if (!authenticated) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Authentication failed.")));
          }
          // Reset navigated flag so user can try again or the timer can trigger? 
          // Actually, if they fail biometric, we should probably allow them to try again.
          _navigated = false;
          return;
        }
      }
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const ChatListPage()),
        );
      }
    } else {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to AuthProvider initialization
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        // If auth becomes initialized and we haven't navigated yet, check if we should
        if (auth.isInitialized && !_navigated) {
          // We wait for either the animation to finish OR the timer, 
          // but if it's already initialized and we haven't navigated, 
          // let's wait a bit for some "splash feel" unless animation is already done.
        }

        return Scaffold(
          body: Center(
            child: Lottie.asset(
              'assets/animations/splash_loader.json',
              controller: _controller,
              onLoaded: (composition) {
                _controller
                  ..duration = composition.duration
                  ..forward().whenComplete(() {
                    _checkAuthAndNavigate();
                  });
              },
            ),
          ),
        );
      },
    );
  }
}
