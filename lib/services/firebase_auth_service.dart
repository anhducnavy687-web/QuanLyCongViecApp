import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'auth_service.dart';

/// Triển khai [AuthService] thật, dùng Firebase Authentication + Google
/// Sign-In. Được GUARD kỹ để KHÔNG BAO GIỜ làm crash app nếu Firebase chưa
/// được cấu hình (chưa chạy `flutterfire configure`, thiếu
/// google-services.json/GoogleService-Info.plist...).
class FirebaseAuthService extends AuthService {
  fb_auth.FirebaseAuth? _auth;
  GoogleSignIn? _googleSignIn;
  AppUser? _currentUser;
  bool _available = false;

  @override
  AppUser? get currentUser => _currentUser;

  @override
  bool get isAvailable => _available;

  /// Gọi một lần khi khởi động app. Nếu Firebase chưa cấu hình, [isAvailable]
  /// sẽ là false và mọi thao tác đăng nhập sẽ báo lỗi tiếng Việt thân thiện
  /// thay vì làm crash ứng dụng.
  Future<void> ensureInitialized() async {
    try {
      if (Firebase.apps.isEmpty) {
        // Nếu dự án chưa có firebase_options.dart / file cấu hình native,
        // lệnh này sẽ ném lỗi và bị bắt bên dưới — app vẫn chạy bình
        // thường ở Demo Mode.
        await Firebase.initializeApp();
      }
      _auth = fb_auth.FirebaseAuth.instance;
      _googleSignIn = GoogleSignIn();
      _available = true;
    } catch (_) {
      _available = false;
    }
  }

  AppUser _mapUser(fb_auth.User user) {
    return AppUser(
      uid: user.uid,
      displayName: user.displayName ?? user.email ?? 'Người dùng',
      email: user.email ?? '',
      photoUrl: user.photoURL,
    );
  }

  @override
  Future<AppUser?> restoreSession() async {
    if (!_available || _auth == null) return null;
    final user = _auth!.currentUser;
    if (user == null) return null;
    _currentUser = _mapUser(user);
    notifyListeners();
    return _currentUser;
  }

  @override
  Future<AppUser> signInWithGoogle() async {
    if (!_available || _auth == null || _googleSignIn == null) {
      throw const AuthException(
        'Firebase chưa được cấu hình cho ứng dụng này. '
        'Vui lòng dùng Chế độ Demo, hoặc xem hướng dẫn tại '
        'docs/firebase-setup.md để bật đăng nhập Google.',
      );
    }
    try {
      final googleUser = await _googleSignIn!.signIn();
      if (googleUser == null) {
        throw const AuthException('Bạn đã hủy đăng nhập.');
      }
      final googleAuth = await googleUser.authentication;
      final credential = fb_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final result = await _auth!.signInWithCredential(credential);
      final user = result.user;
      if (user == null) {
        throw const AuthException('Đăng nhập thất bại, vui lòng thử lại.');
      }
      _currentUser = _mapUser(user);
      notifyListeners();
      return _currentUser!;
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException('Đăng nhập thất bại: $e');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _googleSignIn?.signOut();
      await _auth?.signOut();
    } catch (_) {
      // Bỏ qua lỗi đăng xuất — vẫn xóa session cục bộ để tránh kẹt UI.
    }
    _currentUser = null;
    notifyListeners();
  }
}
