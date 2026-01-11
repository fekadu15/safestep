import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return web;
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBfdywkkb-4C5oVEu7vDUGq_udAajMzmP4',
    appId: '1:280130887058:web:970ad9fbcb45decc26b54b',
    messagingSenderId: '280130887058',
    projectId: 'safestep-47178',
    authDomain: 'safestep-47178.firebaseapp.com',
    storageBucket: 'safestep-47178.firebasestorage.app',
    measurementId: 'G-RZS73EQ2VS',
  );
}