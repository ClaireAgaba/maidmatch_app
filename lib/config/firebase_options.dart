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
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAWRt4x7WDjygelY-gBY2150PYKiYs15dw',
    authDomain: 'maidmatch-c280f.firebaseapp.com',
    projectId: 'maidmatch-c280f',
    storageBucket: 'maidmatch-c280f.firebasestorage.app',
    messagingSenderId: '909909588571',
    appId: '1:909909588571:web:b8abf2e2f2f90838479d7e',
    measurementId: 'G-11CPNG5419',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAWRt4x7WDjygelY-gBY2150PYKiYs15dw',
    appId: '1:909909588571:android:YOUR_ANDROID_APP_ID',
    messagingSenderId: '909909588571',
    projectId: 'maidmatch-c280f',
    storageBucket: 'maidmatch-c280f.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAWRt4x7WDjygelY-gBY2150PYKiYs15dw',
    appId: '1:909909588571:ios:YOUR_IOS_APP_ID',
    messagingSenderId: '909909588571',
    projectId: 'maidmatch-c280f',
    storageBucket: 'maidmatch-c280f.firebasestorage.app',
    iosBundleId: 'com.example.maidmatch',
  );
}
