// File generated normally by the FlutterFire CLI (`flutterfire configure`).
// This is a placeholder so the project compiles out of the box; replace it
// by running `flutterfire configure` from the project root, which will
// overwrite this file with your real Firebase project credentials.
//
// ignore_for_file: type=lint
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
          'DefaultFirebaseOptions are not supported for this platform. '
          'Run `flutterfire configure` to generate real options.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyB--lModv5lOwvI_Rqnxg2xP01j4PZoF28',
    appId: '1:201233177226:web:8131f2e532f8d4aab5ab73',
    messagingSenderId: '201233177226',
    projectId: 'campustrack-eca81',
    authDomain: 'campustrack-eca81.firebaseapp.com',
    storageBucket: 'campustrack-eca81.firebasestorage.app',
    measurementId: 'G-C8GBKVWW63',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAX6l-7L2bjCNOWga4UPBTEHVyG1Yl81c0',
    appId: '1:201233177226:android:1782bd452649e44db5ab73',
    messagingSenderId: '201233177226',
    projectId: 'campustrack-eca81',
    storageBucket: 'campustrack-eca81.firebasestorage.app',
  );
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCmvkV-B8rNRiwms6td2X2wF8bk9qoA4EQ',
    appId: '1:201233177226:ios:11a5e05e247d1166b5ab73',
    messagingSenderId: '201233177226',
    projectId: 'campustrack-eca81',
    storageBucket: 'campustrack-eca81.firebasestorage.app',
    iosClientId: '201233177226-8j9htcbjq2hk162i9sia8urlbihs0krr.apps.googleusercontent.com',
    iosBundleId: 'com.campustrack.campustrack',
  );
}
