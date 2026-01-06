// File generated manually - Replace with your Firebase project configuration
// To get these values:
// 1. Go to Firebase Console (https://console.firebase.google.com/)
// 2. Select your project (or create one)
// 3. Go to Project Settings > General
// 4. Scroll down to "Your apps" and add a Flutter app if you haven't
// 5. Copy the configuration values below

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'you can reconfigure this by running the FlutterFire CLI again.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for ios - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAUF0d9d6krp9Fge-yFEp37wbT-wdJedlo',
    appId: '1:550085522202:android:b020a6ef24dd19cbacf2a3',
    messagingSenderId: '550085522202',
    projectId: 'akalt-27d06',
    authDomain: 'akalt-27d06.firebaseapp.com',
    storageBucket: 'akalt-27d06.firebasestorage.app',
  );
}
