import 'dart:async';

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
    this.initializationWait = const Duration(seconds: 8),
    fb_auth.FirebaseAuth Function()? authFactory,
    GoogleSignIn Function()? googleFactory,
  }) : _isWeb = isWeb ?? kIsWeb,
       _authFactory = authFactory ?? (() => fb_auth.FirebaseAuth.instance),
       _googleFactory = googleFactory ?? (() => GoogleSignIn());

  // UI wait budget only: the SDK operation continues and retries join it.
  final Duration initializationWait;
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
  Future<void> ensureInitialized() async {
    if (_available) return;
    final pending = _initializing ??= _initializeFirebase().whenComplete(() {
      _initializing = null;
    });
    try {
      await pending.timeout(initializationWait);
    } on TimeoutException catch (error) {
      // Future.timeout does not cancel Firebase. Keep the original future so
      // a retry cannot start a second initialization while this one is pending.
      logFirebaseFailure('initialization-wait', error);
      _initializationError =
          'Kết nối đang chậm hoặc bị chặn. Firebase vẫn đang khởi tạo. '
          'Kiểm tra mạng rồi nhấn Thử lại; nếu vẫn không được, hãy tải lại trang.';
    }
  }

  Future<void> _initializeFirebase() async {
    var stage = 'core-initialization';
    try {
      if (initialize != null) {
        await initialize!();
      } else {
        // Do not read Firebase.apps before the Web SDK is loaded: the legacy
        // plugin's undefined-object guard only recognizes Chromium wording.
        // initializeApp itself reuses an existing default app with these options.
        await Firebase.initializeApp(
          options: _isWeb ? DefaultFirebaseOptions.web : null,
        );
      }
      stage = 'auth-initialization';
      _auth = _authFactory();
      // No GIS client or People API is needed by Firebase's Web popup.
      if (!_isWeb) _googleSignIn = _googleFactory();
      _available = true;
      _initializationError = null;
    } catch (e) {
      logFirebaseFailure(stage, e);
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
    try {
      return await authStateChanges().first.timeout(initializationWait);
    } catch (error) {
      logFirebaseFailure('session-restore', error);
      rethrow;
    }
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
