// File generated manually from google-services.json.
// To regenerate, run `flutterfire configure`.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions is not configured for ${defaultTargetPlatform.name} — '
          'iOS uses native APNs, not Firebase.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD2Iq3g2Yyh2k8iaixwtSB-kIHOufK-WP4',
    appId: '1:1017670689867:android:80ba6bfb5de9365bd0d9ce',
    messagingSenderId: '1017670689867',
    projectId: 'flutter-project-82bd9',
    storageBucket: 'flutter-project-82bd9.firebasestorage.app',
  );
}
