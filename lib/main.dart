import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'firebase_options.dart';
import 'core/theme.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/chat_provider.dart';
import 'presentation/providers/ai_provider.dart';
import 'presentation/providers/status_provider.dart';
import 'presentation/providers/call_provider.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/providers/agora_provider.dart';
import 'presentation/providers/task_provider.dart';
import 'presentation/providers/innovation_provider.dart';
import 'presentation/providers/analytics_provider.dart';
import 'presentation/providers/reward_provider.dart';
import 'presentation/providers/secret_vault_provider.dart';
import 'presentation/providers/contact_provider.dart';
import 'presentation/pages/splash_page.dart';
import 'presentation/pages/chat_list_page.dart';
import 'presentation/pages/login_page.dart';
import 'data/services/notification_service.dart';
import 'data/services/voice_assistant_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await NotificationService.initialize();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint("---------------------------------------------------------");
    debugPrint("FIREBASE INITIALIZATION FAILED");
    debugPrint("Error: $e");
    debugPrint("---------------------------------------------------------");
  }
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        Provider(create: (_) {
          final voice = VoiceAssistantService();
          voice.init("AIzaSyDtx6A6AVfpaiyUYWuPZdrw1sMzORcgrN4");
          return voice;
        }),
        ChangeNotifierProvider(create: (_) {
          final ai = AiProvider();
          ai.init("AIzaSyDtx6A6AVfpaiyUYWuPZdrw1sMzORcgrN4"); 
          return ai;
        }),
        ChangeNotifierProvider(create: (_) => StatusProvider()),
        ChangeNotifierProvider(create: (_) => CallProvider()),
        ChangeNotifierProvider(create: (_) => AgoraProvider()),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => InnovationProvider()),
        ChangeNotifierProvider(create: (_) => AnalyticsProvider()),
        ChangeNotifierProvider(create: (_) => RewardProvider()),
        ChangeNotifierProvider(create: (_) => SecretVaultProvider()),
        ChangeNotifierProvider(create: (_) => ContactProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeMode = context.watch<ThemeProvider>().themeMode;
    return MaterialApp(
      title: 'WhatsApp AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'), 
        Locale('es'),
      ],
      home: const AuthWrapper(),
    );
  }
}

/// Listens to [AuthProvider] and routes to the correct page.
/// This ensures logout navigates back to [LoginPage] automatically.
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    // Still initializing — show splash
    if (!auth.isInitialized) return const SplashPage();

    // Authenticated → main app
    if (auth.isAuthenticated) return const ChatListPage();

    // Not authenticated → login
    return const LoginPage();
  }
}
