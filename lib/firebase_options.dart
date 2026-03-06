import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for ios - '
          'you can reconfigure this by running the Flutterfire CLI again.',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the Flutterfire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the Flutterfire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the Flutterfire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCxNaiwSqZ3sjW7fCTuDT-0fSG8AufMUAM',
    appId: '1:693917534702:android:31a9c10940b2ea3f0466ff',
    messagingSenderId: '693917534702',
    projectId: 'whatsapp-ai-ebb0a',
    storageBucket: 'whatsapp-ai-ebb0a.firebasestorage.app',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyACFFhzljj7GtEqVIQ5QCMriFm922LNotU',
    appId: '1:693917534702:web:829d6ae854ca599f0466ff',
    messagingSenderId: '693917534702',
    projectId: 'whatsapp-ai-ebb0a',
    authDomain: 'whatsapp-ai-ebb0a.firebaseapp.com',
    storageBucket: 'whatsapp-ai-ebb0a.firebasestorage.app',
    measurementId: 'G-7CGF4TM7MK',
  );
}
