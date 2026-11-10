import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        return android;
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA8a2kgWayfrPfjMcZoITr2MCvFaqmx8wM',
    appId: '1:313295007264:android:73f76ebe33bd9b7c17d645',
    messagingSenderId: '313295007264',
    projectId: 'kredi-e636c',
    storageBucket: 'kredi-e636c.firebasestorage.app',
  );
}

