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
    apiKey: 'AIzaSyCVa0BWyY05ai3ieLWG8gCr9AunGk6ae7I',
    appId: '1:852813891064:web:c5ed136494957f81f8820d',
    messagingSenderId: '852813891064',
    projectId: 'namma-bingo-d007c',
    authDomain: 'namma-bingo-d007c.firebaseapp.com',
    storageBucket: 'namma-bingo-d007c.appspot.com',
    measurementId: 'G-C5ED136494',
    databaseURL: 'https://namma-bingo-d007c-default-rtdb.firebaseio.com/',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCVa0BWyY05ai3ieLWG8gCr9AunGk6ae7I',
    appId: '1:852813891064:android:bd095baf07758a29f8820d',
    messagingSenderId: '852813891064',
    projectId: 'namma-bingo-d007c',
    storageBucket: 'namma-bingo-d007c.appspot.com',
    databaseURL: 'https://namma-bingo-d007c-default-rtdb.firebaseio.com/',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCVa0BWyY05ai3ieLWG8gCr9AunGk6ae7I',
    appId: '1:852813891064:ios:1d54974a6bc5ecb7f8820d',
    messagingSenderId: '852813891064',
    projectId: 'namma-bingo-d007c',
    storageBucket: 'namma-bingo-d007c.appspot.com',
    iosBundleId: 'com.example.nammaBingo',
    databaseURL: 'https://namma-bingo-d007c-default-rtdb.firebaseio.com/',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCVa0BWyY05ai3ieLWG8gCr9AunGk6ae7I',
    appId: '1:852813891064:ios:1d54974a6bc5ecb7f8820d',
    messagingSenderId: '852813891064',
    projectId: 'namma-bingo-d007c',
    storageBucket: 'namma-bingo-d007c.appspot.com',
    iosBundleId: 'com.example.nammaBingo',
    databaseURL: 'https://namma-bingo-d007c-default-rtdb.firebaseio.com/',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCVa0BWyY05ai3ieLWG8gCr9AunGk6ae7I',
    appId: '1:852813891064:web:13895fca88c8c7cef8820d',
    messagingSenderId: '852813891064',
    projectId: 'namma-bingo-d007c',
    authDomain: 'namma-bingo-d007c.firebaseapp.com',
    storageBucket: 'namma-bingo-d007c.appspot.com',
    measurementId: 'G-13895FCA88',
    databaseURL: 'https://namma-bingo-d007c-default-rtdb.firebaseio.com/',
  );
}
