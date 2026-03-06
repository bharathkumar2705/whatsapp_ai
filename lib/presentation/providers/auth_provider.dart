import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../data/repositories/user_repository.dart';
import '../../domain/entities/user_entity.dart';
import '../../data/models/user_model.dart';
import '../../data/services/notification_service.dart';

class AuthProvider extends ChangeNotifier with WidgetsBindingObserver {
  FirebaseAuth get _auth => FirebaseAuth.instance;
  final UserRepository _userRepository = UserRepository();
  User? _user;
  UserEntity? _userModel;

  User? get user => _user;
  UserEntity? get userModel => _userModel;
  bool get isAuthenticated => _user != null;
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  AuthProvider() {
    WidgetsBinding.instance.addObserver(this);
    _initAuthListener();
  }

  void _initAuthListener() {
    if (Firebase.apps.isEmpty) {
      debugPrint("Firebase not initialized. AuthProvider forced to initialized state.");
      _isInitialized = true;
      notifyListeners();
      return;
    }
    
    _auth.authStateChanges().listen((User? user) async {
      try {
        _user = user;
        if (user != null) {
          _userModel = await _userRepository.getUser(user.uid);

          // Auto-create Firestore profile if missing (e.g. Google/Phone sign-in)
          if (_userModel == null) {
            final newUser = UserModel(
              uid: user.uid,
              displayName: user.displayName ??
                  user.email?.split('@').first ??
                  user.phoneNumber ??
                  'User',
              email: user.email ?? '',
              photoUrl: user.photoURL ?? '',
              phoneNumber: user.phoneNumber ?? '',
              about: 'Hey there! I am using WhatsApp.',
              lastSeen: DateTime.now(),
              isOnline: true,
            );
            await _userRepository.createUser(newUser);
            _userModel = newUser;
          } else if (_userModel!.phoneNumber.isEmpty && user.phoneNumber != null) {
            // Update phone number if missing from Firestore but exists in Firebase Auth
            await _userRepository.updateProfile(user.uid, {'phoneNumber': user.phoneNumber});
            _userModel = await _userRepository.getUser(user.uid);
          }

          _updatePresence(true);
          _updateFcmToken();
          _registerThisDevice(user.uid);
          cleanupOldDevices();
        } else {
          _userModel = null;
        }

        // Check for account expiration (Self-Destruct Profile)
        if (_userModel?.expiresAt != null) {
          if (_userModel!.expiresAt!.isBefore(DateTime.now())) {
            debugPrint("Account expired. Signing out...");
            // signOut(); // This would cause a recursive call if not handled carefully
            // Instead, we should trigger a sign out process that doesn't rely on context here.
            // For now, let's assume the UI will react to _user becoming null.
          }
        }
      } catch (e) {
        debugPrint("Error fetching user data: $e");
      } finally {
        _isInitialized = true;
        notifyListeners();
      }
    });
  }

  void _registerThisDevice(String uid) {
    final platform = kIsWeb ? 'Web' : 'Mobile';
    // Use a stable ID for "this device" to prevent duplicates on every restart
    final deviceId = '${platform}_${uid.substring(0, 6)}_primary';
    _userRepository.registerDevice(uid, {
      'deviceId': deviceId,
      'platform': platform,
      'name': kIsWeb ? 'WhatsApp Web / Desktop' : 'Mobile Device',
      'linkedAt': DateTime.now().millisecondsSinceEpoch,
      'lastActive': DateTime.now().millisecondsSinceEpoch,
      'isCurrent': true,
    });
  }

  Future<void> _updateFcmToken() async {
    if (_user == null || kIsWeb) return;
    try {
      final token = await NotificationService.getToken();
      if (token != null && token.isNotEmpty) {
        await _userRepository.updateProfile(_user!.uid, {'fcmToken': token});
        debugPrint('AuthProvider: FCM token saved to Firestore.');
      }
    } catch (e) {
      debugPrint('AuthProvider: Failed to save FCM token: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_user != null) {
      if (state == AppLifecycleState.resumed) {
        _updatePresence(true);
      } else {
        // Only mark offline if we've been in background for more than 30 seconds
        // This prevents "losing connection" when just briefly switching apps
        Future.delayed(const Duration(seconds: 30), () async {
          final currentState = WidgetsBinding.instance.lifecycleState;
          if (currentState != AppLifecycleState.resumed) {
            _updatePresence(false);
          }
        });
      }
    }
  }

  Future<void> _updatePresence(bool isOnline) async {
    if (_user == null) return;
    await _userRepository.updateProfile(_user!.uid, {
      'isOnline': isOnline,
      'lastSeen': DateTime.now().millisecondsSinceEpoch,
    });
  }


  Future<void> toggleBlockUser(String otherUserId) async {
    if (_userModel == null) return;
    List<String> blockedUsers = List.from(_userModel!.blockedUsers);
    if (blockedUsers.contains(otherUserId)) {
      blockedUsers.remove(otherUserId);
    } else {
      blockedUsers.add(otherUserId);
    }
    await _userRepository.updateProfile(_user!.uid, {'blockedUsers': blockedUsers});
    _userModel = await _userRepository.getUser(_user!.uid);
    notifyListeners();
  }

  /// Generic profile update — saves [data] to Firestore and refreshes userModel.
  Future<void> updateProfile(Map<String, dynamic> data) async {
    if (_user == null) return;
    await _userRepository.updateProfile(_user!.uid, data);
    _userModel = await _userRepository.getUser(_user!.uid);
    notifyListeners();
  }

  Future<void> updatePrivacySettings(Map<String, dynamic> settings) async {
    if (_user == null) return;
    Map<String, dynamic> currentSettings = Map.from(_userModel?.privacySettings ?? {});
    currentSettings.addAll(settings);
    await _userRepository.updateProfile(_user!.uid, {'privacySettings': currentSettings});
    _userModel = await _userRepository.getUser(_user!.uid);
    notifyListeners();
  }

  Future<void> signIn(String email, String password) async {
    debugPrint("AuthProvider: Attempting to sign in with $email");
    if (Firebase.apps.isEmpty) {
      debugPrint("AuthProvider Error: Firebase not initialized");
      throw FirebaseException(
        plugin: 'core',
        code: 'no-app',
        message: 'Firebase is not initialized. Please run "flutterfire configure" for your platform.',
      );
    }
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      debugPrint("AuthProvider: Sign in successful for $email");
    } catch (e) {
      debugPrint("AuthProvider Error: Sign in failed - $e");
      rethrow;
    }
  }

  Future<void> signUp(String email, String password, String displayName) async {
    if (Firebase.apps.isEmpty) {
      throw FirebaseException(
        plugin: 'core',
        code: 'no-app',
        message: 'Firebase is not initialized. Please run "flutterfire configure" for your platform.',
      );
    }
    try {
      final credential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      if (credential.user != null) {
        final newUser = UserModel(
          uid: credential.user!.uid,
          displayName: displayName,
          email: email,
          phoneNumber: '', // Will be updated if phone auth is used or added later
          lastSeen: DateTime.now(),
          isOnline: true,
        );
        await _userRepository.createUser(newUser);
        _userModel = newUser;
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    if (Firebase.apps.isEmpty) return;
    await _updatePresence(false);
    await _auth.signOut();
    // Also sign out from Google if it was used
    try { await GoogleSignIn().signOut(); } catch (_) {}
  }

  // ── Google Sign-In ────────────────────────────────────────────────────────
  Future<void> signInWithGoogle() async {
    if (Firebase.apps.isEmpty) {
      throw FirebaseException(
        plugin: 'core', code: 'no-app',
        message: 'Firebase is not initialized.',
      );
    }
    try {
      if (kIsWeb) {
        final provider = GoogleAuthProvider();
        await _auth.signInWithPopup(provider);
      } else {
        final googleUser = await GoogleSignIn().signIn();
        if (googleUser == null) throw Exception('Google sign-in cancelled');
        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        final result = await _auth.signInWithCredential(credential);
        // Always upsert Firestore profile for Google sign-in
        // (so returning users also appear in contacts/all-users list)
        if (result.user != null) {
          final u = result.user!;
          final existingUser = await _userRepository.getUser(u.uid);
          if (existingUser == null) {
            // New user — create fresh profile
            final newUser = UserModel(
              uid: u.uid,
              displayName: u.displayName ?? 'User',
              email: u.email ?? '',
              photoUrl: u.photoURL ?? '',
              phoneNumber: u.phoneNumber ?? '',
              lastSeen: DateTime.now(),
              isOnline: true,
            );
            await _userRepository.createUser(newUser);
          } else {
            // Returning user — update photo/name in case they changed
            await _userRepository.updateProfile(u.uid, {
              'displayName': u.displayName ?? existingUser.displayName,
              'photoUrl': u.photoURL ?? existingUser.photoUrl ?? '',
              'isOnline': true,
              'lastSeen': DateTime.now().millisecondsSinceEpoch,
            });
          }
        }
      }
    } catch (e) {
      debugPrint('AuthProvider Google Sign-In error: $e');
      rethrow;
    }
  }

  // ── Phone OTP ─────────────────────────────────────────────────────────────
  String? _verificationId;
  String? get verificationId => _verificationId;

  // Web-only: stores the ConfirmationResult from signInWithPhoneNumber
  ConfirmationResult? _confirmationResult;

  Future<void> verifyPhoneNumber(
    String phoneNumber, {
    required Function(String) onCodeSent,
    required Function(String) onError,
    required Function() onAutoVerified,
  }) async {
    if (Firebase.apps.isEmpty) {
      onError('Firebase is not initialized.');
      return;
    }
    try {
      if (kIsWeb) {
        // Web: use signInWithPhoneNumber — verifier is optional,
        // Firebase auto-creates an invisible reCAPTCHA when omitted.
        _confirmationResult = await _auth.signInWithPhoneNumber(phoneNumber);
        onCodeSent(_confirmationResult!.verificationId);
      } else {
        // Android / iOS: native OTP
        await _auth.verifyPhoneNumber(
          phoneNumber: phoneNumber,
          timeout: const Duration(seconds: 60),
          verificationCompleted: (PhoneAuthCredential credential) async {
            await _auth.signInWithCredential(credential);
            onAutoVerified();
          },
          verificationFailed: (FirebaseAuthException e) {
            debugPrint('Phone verification failed: ${e.message}');
            onError(e.message ?? 'Verification failed');
          },
          codeSent: (String verificationId, int? resendToken) {
            _verificationId = verificationId;
            onCodeSent(verificationId);
          },
          codeAutoRetrievalTimeout: (String verificationId) {
            _verificationId = verificationId;
          },
        );
      }
    } catch (e) {
      onError(e.toString());
    }
  }

  Future<void> confirmOtp(String smsCode) async {
    UserCredential result;
    if (kIsWeb) {
      // Web: use ConfirmationResult from signInWithPhoneNumber
      if (_confirmationResult == null) throw Exception('No verification in progress');
      result = await _confirmationResult!.confirm(smsCode);
    } else {
      // Android / iOS: use PhoneAuthCredential
      if (_verificationId == null) throw Exception('No verification in progress');
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: smsCode,
      );
      result = await _auth.signInWithCredential(credential);
    }
    // Create Firestore profile for first-time phone users
    if (result.additionalUserInfo?.isNewUser == true && result.user != null) {
      final u = result.user!;
      final newUser = UserModel(
        uid: u.uid,
        displayName: u.displayName ?? u.phoneNumber ?? 'User',
        email: u.email ?? '',
        phoneNumber: u.phoneNumber ?? '',
        lastSeen: DateTime.now(),
        isOnline: true,
      );
      await _userRepository.createUser(newUser);
    }
  }

  // Wave 8: Business
  Future<void> updateBusinessProfile(Map<String, dynamic> data) async {
    if (_user == null) return;
    await _userRepository.updateBusinessProfile(_user!.uid, data);
    _userModel = await _userRepository.getUser(_user!.uid);
    notifyListeners();
  }

  Stream<List<Map<String, dynamic>>> getCatalog() {
    if (_user == null) return Stream.value([]);
    return _userRepository.getCatalog(_user!.uid);
  }

  Future<void> addCatalogItem(Map<String, dynamic> item) async {
    if (_user == null) return;
    await _userRepository.addCatalogItem(_user!.uid, item);
  }

  Future<void> updateCatalogItem(String itemId, Map<String, dynamic> item) async {
    if (_user == null) return;
    await _userRepository.updateCatalogItem(_user!.uid, itemId, item);
  }

  Future<void> deleteCatalogItem(String itemId) async {
    if (_user == null) return;
    await _userRepository.deleteCatalogItem(_user!.uid, itemId);
  }

  Stream<List<Map<String, dynamic>>> getQuickReplies() {
    if (_user == null) return Stream.value([]);
    return _userRepository.getQuickReplies(_user!.uid);
  }

  Future<void> addQuickReply(Map<String, dynamic> reply) async {
    if (_user == null) return;
    await _userRepository.addQuickReply(_user!.uid, reply);
  }

  Future<void> updateQuickReply(String replyId, Map<String, dynamic> reply) async {
    if (_user == null) return;
    await _userRepository.updateQuickReply(_user!.uid, replyId, reply);
  }

  Future<void> deleteQuickReply(String replyId) async {
    if (_user == null) return;
    await _userRepository.deleteQuickReply(_user!.uid, replyId);
  }

  // Wave 9: Multi-Device
  Stream<List<Map<String, dynamic>>> getLinkedDevices() {
    if (_user == null) return Stream.value([]);
    return _userRepository.getLinkedDevices(_user!.uid);
  }

  Future<void> removeDevice(String deviceId) async {
    if (_user == null) return;
    await _userRepository.removeDevice(_user!.uid, deviceId);
  }

  Future<void> linkDevice(String platform, String name) async {
    if (_user == null) return;
    final deviceId = '${platform}_${_user!.uid.substring(0, 6)}_${DateTime.now().millisecondsSinceEpoch}';
    await _userRepository.registerDevice(_user!.uid, {
      'deviceId': deviceId,
      'platform': platform,
      'name': name,
      'linkedAt': DateTime.now().millisecondsSinceEpoch,
      'lastActive': DateTime.now().millisecondsSinceEpoch,
      'isCurrent': false,
    });
    notifyListeners();
  }

  Future<void> cleanupOldDevices() async {
    if (_user == null) return;
    final devices = await getLinkedDevices().first;
    final now = DateTime.now().millisecondsSinceEpoch;
    final oneDayAgo = now - (24 * 60 * 60 * 1000);

    for (final device in devices) {
      if (device['isCurrent'] == true) continue;
      
      // Cleanup logic:
      // 1. Remove if inactive for > 24h AND name matches 'Mobile Device' (likely duplicate primary logs)
      // 2. Remove if inactive for > 7 days regardless of name
      final lastActive = device['lastActive'] ?? 0;
      final name = device['name'] ?? '';
      
      if (lastActive < oneDayAgo && name == 'Mobile Device') {
        await removeDevice(device['id'] ?? device['deviceId']);
      } else if (lastActive < now - (7 * 24 * 60 * 60 * 1000)) {
        await removeDevice(device['id'] ?? device['deviceId']);
      }
    }
    notifyListeners();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
