import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class DriveAuthorizationException implements Exception {
  const DriveAuthorizationException(this.message);
  final String message;
  @override
  String toString() => message;
}

class DriveAuthorizationService {
  DriveAuthorizationService({FirebaseAuth Function()? authFactory})
    : _authFactory = authFactory ?? (() => FirebaseAuth.instance);

  static const scope = 'https://www.googleapis.com/auth/drive.file';
  final FirebaseAuth Function() _authFactory;
  String? _accessToken;

  bool get isConnected => _accessToken != null;
  String? get accessToken => _accessToken;

  Future<String> connect() async {
    if (!kIsWeb) {
      throw const DriveAuthorizationException(
        'Google Drive hiện chỉ được hỗ trợ trên bản Web.',
      );
    }
    final auth = _authFactory();
    final user = auth.currentUser;
    if (user == null) {
      throw const DriveAuthorizationException(
        'Vui lòng đăng nhập Google trước.',
      );
    }
    final provider = GoogleAuthProvider()
      ..addScope(scope)
      ..setCustomParameters({'login_hint': user.email ?? ''});
    try {
      final result = await user.reauthenticateWithPopup(provider);
      if (result.user?.email?.toLowerCase() != user.email?.toLowerCase()) {
        throw const DriveAuthorizationException(
          'Tài khoản Google Drive không khớp tài khoản đang đăng nhập.',
        );
      }
      final token = result.credential?.accessToken;
      if (token == null || token.isEmpty) {
        throw const DriveAuthorizationException(
          'Google chưa cấp quyền truy cập Drive. Vui lòng thử lại.',
        );
      }
      _accessToken = token;
      return token;
    } on DriveAuthorizationException {
      rethrow;
    } on FirebaseAuthException catch (error) {
      throw DriveAuthorizationException(switch (error.code) {
        'popup-closed-by-user' => 'Bạn đã đóng cửa sổ kết nối Google Drive.',
        'popup-blocked' =>
          'Trình duyệt đã chặn cửa sổ kết nối Google Drive '
              '(popup-blocked). Vui lòng thử lại.',
        _ =>
          'Không thể kết nối Google Drive '
              '(${error.code}: ${error.message ?? 'không có mô tả'}).',
      });
    } catch (error) {
      throw DriveAuthorizationException(
        'Không thể kết nối Google Drive '
        '(${error.runtimeType}: $error).',
      );
    }
  }

  void disconnect() => _accessToken = null;
}
