import 'package:flutter/foundation.dart';

/// Thông tin người dùng tối giản, độc lập với Firebase, để UI không phải
/// phụ thuộc trực tiếp vào `firebase_auth`.
class AppUser {
  final String uid;
  final String displayName;
  final String email;
  final String? photoUrl;

  const AppUser({
    required this.uid,
    required this.displayName,
    required this.email,
    this.photoUrl,
  });
}

/// Lỗi xác thực có thông điệp tiếng Việt sẵn sàng hiển thị cho người dùng.
class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => message;
}

/// Interface xác thực dùng chung. UI chỉ biết tới [AuthService], không biết
/// tới Firebase hay Google Sign-In cụ thể — nhờ vậy Demo Mode và Firebase
/// Mode dùng chung một luồng màn hình Splash/Login.
abstract class AuthService extends ChangeNotifier {
  AppUser? get currentUser;

  bool get isAvailable;

  String? get initializationError;
  Future<void> ensureInitialized();
  Stream<AppUser?> authStateChanges();

  /// Thử khôi phục phiên đăng nhập đã lưu trước đó (nếu có).
  Future<AppUser?> restoreSession();

  Future<AppUser> signInWithGoogle();

  Future<void> signOut();
}
