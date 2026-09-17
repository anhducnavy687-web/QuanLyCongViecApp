import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../firebase_options.dart';
import 'auth_service.dart';
import 'firebase_error_message.dart';

class FirebaseAuthService extends AuthService {
  FirebaseAuthService({
    bool? isWeb,
    this.initialize,
    fb_auth.FirebaseAuth Function()? authFactory,
    GoogleSignIn Function()? googleFactory,
  }) : _isWeb = isWeb ?? kIsWeb,
       _authFactory = authFactory ?? (() => fb_auth.FirebaseAuth.instance),
       _googleFactory = googleFactory ?? (() => GoogleSignIn());

  final bool _isWeb;
  final Future<void> Function()? initialize;
  final fb_auth.FirebaseAuth Function() _authFactory;
  final GoogleSignIn Function() _googleFactory;
  fb_auth.FirebaseAuth? _auth;
  GoogleSignIn? _googleSignIn;
  bool _available = false;
  String? _initializationError;
  Future<void>? _initializing;

  @override
  AppUser? get currentUser => _mapUser(_auth?.currentUser);
  @override
  bool get isAvailable => _available;
  @override
  String? get initializationError => _initializationError;

  @override
  Future<void> ensureInitialized() {
    if (_available) return Future.value();
    return _initializing ??= _initializeFirebase().whenComplete(() {
      _initializing = null;
    });
  }

  Future<void> _initializeFirebase() async {
    try {
      if (initialize != null) {
        await initialize!();
      } else if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: _isWeb ? DefaultFirebaseOptions.web : null,
        ).timeout(const Duration(seconds: 8));
      }
      _auth = _authFactory();
      // No GIS client or People API is needed by Firebase's Web popup.
      if (!_isWeb) _googleSignIn = _googleFactory();
      _available = true;
      _initializationError = null;
    } catch (e) {
      _available = false;
      _initializationError =
          'Không thể khởi tạo Firebase. ${firebaseErrorMessage(e)}';
    }
  }

  AppUser? _mapUser(fb_auth.User? user) => user == null
      ? null
      : AppUser(
          uid: user.uid,
          displayName: user.displayName ?? user.email ?? 'Người dùng',
          email: user.email ?? '',
          photoUrl: user.photoURL,
        );

  @override
  Stream<AppUser?> authStateChanges() =>
      _auth?.authStateChanges().map(_mapUser) ?? const Stream.empty();

  @override
  Future<AppUser?> restoreSession() async {
    if (!_available) return null;
    // First event arrives after persisted Firebase credentials restore.
    return await authStateChanges().first.timeout(const Duration(seconds: 8));
  }

  @override
  Future<AppUser> signInWithGoogle() async {
    if (!_available || _auth == null) {
      throw AuthException(
        _initializationError ??
            'Firebase chưa sẵn sàng. Vui lòng thử kết nối lại hoặc dùng Demo.',
      );
    }
    try {
      final fb_auth.UserCredential result;
      if (_isWeb) {
        // Called directly from the button gesture, before any other awaits.
        result = await _auth!
            .signInWithPopup(fb_auth.GoogleAuthProvider())
            .timeout(const Duration(seconds: 90));
      } else {
        final googleUser = await _googleSignIn!.signIn();
        if (googleUser == null) {
          throw const AuthException(
            'Bạn đã hủy đăng nhập. Bạn có thể thử lại.',
          );
        }
        final tokens = await googleUser.authentication;
        result = await _auth!.signInWithCredential(
          fb_auth.GoogleAuthProvider.credential(
            accessToken: tokens.accessToken,
            idToken: tokens.idToken,
          ),
        );
      }
      final user = _mapUser(result.user);
      if (user == null) {
        throw const AuthException('Đăng nhập chưa hoàn tất. Vui lòng thử lại.');
      }
      return user;
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException(firebaseErrorMessage(e));
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _googleSignIn?.signOut();
    } catch (_) {
      // A native Google failure must never prevent Firebase sign-out.
    }
    try {
      await _auth?.signOut();
    } catch (e) {
      throw AuthException(firebaseErrorMessage(e));
    }
  }
}
