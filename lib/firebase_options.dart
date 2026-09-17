import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Public client identifiers; native registration is outside Phase 1.4.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    throw UnsupportedError('Firebase production is configured for Web only.');
  }

  static const web = FirebaseOptions(
    apiKey: 'AIzaSyBquAgQghKPfCbpftjp9dBbDZuKrwmvUl8',
    authDomain: 'quanlycongviecapp-129de.firebaseapp.com',
    projectId: 'quanlycongviecapp-129de',
    storageBucket: 'quanlycongviecapp-129de.firebasestorage.app',
    messagingSenderId: '957843233910',
    appId: '1:957843233910:web:e23b136aff578073d09357',
    measurementId: 'G-HYL89T6JQT',
  );
}
