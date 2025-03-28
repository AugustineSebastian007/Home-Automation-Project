import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.

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
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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
    apiKey: 'AIzaSyBTmNo1La3_ZKebznH0pXtRb90HlHb2BBo',
    appId: '1:192863908370:web:d891a60c0e3fe9f68edecb',
    messagingSenderId: '192863908370',
    projectId: 'testing-2de70',
    authDomain: 'testing-2de70.firebaseapp.com',
    storageBucket: 'testing-2de70.appspot.com',
    measurementId: 'G-MTHZP7PWWX',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCgrkvY-A7KuzP7_534uegjodm4vyZkhAY',
    appId: '1:283384641162:android:5c407538086f3a5ea9df73',
    messagingSenderId: '283384641162',
    projectId: 'home-automation-78d43',
    storageBucket: 'home-automation-78d43.appspot.com',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBTmNo1La3_ZKebznH0pXtRb90HlHb2BBo',
    appId: '1:192863908370:web:62a5a273db8284ef8edecb',
    messagingSenderId: '192863908370',
    projectId: 'testing-2de70',
    authDomain: 'testing-2de70.firebaseapp.com',
    storageBucket: 'testing-2de70.appspot.com',
    measurementId: 'G-8BWZT7JZLG',
  );

}