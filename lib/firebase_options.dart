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
        return macos;
      case TargetPlatform.windows:
        return windows;
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
    apiKey: 'AIzaSyDLWpVDLtiULzj-9_QnGWjW8_bnVOfKkZI',
    appId: '1:491814430851:web:1e66f4fd306bf61d1a93b6',
    messagingSenderId: '491814430851',
    projectId: 'shpalman-app',
    authDomain: 'shpalman-app.firebaseapp.com',
    storageBucket: 'shpalman-app.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyApTaFOTSj1PbpjLiN_Col3_NNi34fM6t4',
    appId: '1:491814430851:android:be3220ae088018021a93b6',
    messagingSenderId: '491814430851',
    projectId: 'shpalman-app',
    storageBucket: 'shpalman-app.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDoTZBBeL9su_RjX9otI3LdRiNYr8umCu4',
    appId: '1:491814430851:ios:605db9907a466b181a93b6',
    messagingSenderId: '491814430851',
    projectId: 'shpalman-app',
    storageBucket: 'shpalman-app.firebasestorage.app',
    iosBundleId: 'com.example.shpalmanApp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDoTZBBeL9su_RjX9otI3LdRiNYr8umCu4',
    appId: '1:491814430851:ios:605db9907a466b181a93b6',
    messagingSenderId: '491814430851',
    projectId: 'shpalman-app',
    storageBucket: 'shpalman-app.firebasestorage.app',
    iosBundleId: 'com.example.shpalmanApp',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDLWpVDLtiULzj-9_QnGWjW8_bnVOfKkZI',
    appId: '1:491814430851:web:a7a127aa3f6115141a93b6',
    messagingSenderId: '491814430851',
    projectId: 'shpalman-app',
    authDomain: 'shpalman-app.firebaseapp.com',
    storageBucket: 'shpalman-app.firebasestorage.app',
  );
}
