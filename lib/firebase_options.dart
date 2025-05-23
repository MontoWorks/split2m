// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyB7K5NyUnomdJQhNScQ6ADj_gXBcjSoW3g',
    appId: '1:82962796305:web:6bda310b5089c6987646b0',
    messagingSenderId: '82962796305',
    projectId: 'split2-3c074',
    authDomain: 'split2-3c074.firebaseapp.com',
    storageBucket: 'split2-3c074.firebasestorage.app',
    measurementId: 'G-RW8SD8NT0Z',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA6l1qsyqVL1vfJp_s85X9upusYL6eEb1U',
    appId: '1:82962796305:android:644e55d8a5d668ad7646b0',
    messagingSenderId: '82962796305',
    projectId: 'split2-3c074',
    storageBucket: 'split2-3c074.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyA9bG4Tut9-E3ZjjVyRqmPPx5L2kUWX-LI',
    appId: '1:82962796305:ios:91bb6d823f563bbf7646b0',
    messagingSenderId: '82962796305',
    projectId: 'split2-3c074',
    storageBucket: 'split2-3c074.firebasestorage.app',
    iosBundleId: 'works.monto.split2',
  );
}
