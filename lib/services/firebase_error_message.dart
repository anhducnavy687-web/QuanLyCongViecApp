import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

String firebaseErrorMessage(Object error) {
  if (error is TimeoutException) {
    return 'Kết nối quá lâu. Vui lòng kiểm tra mạng và thử lại.';
  }
  if (error is FirebaseException) {
    switch (error.code) {
      case 'invalid-api-key':
      case 'app-not-authorized':
      case 'invalid-app-argument':
      case 'invalid-options':
      case 'duplicate-app':
      case 'no-options':
        return 'Cấu hình Firebase chưa hợp lệ. Vui lòng liên hệ quản trị viên.';
      case 'operation-not-supported-in-this-environment':
      case 'web-storage-unsupported':
      case 'unsupported-browser':
        return 'Trình duyệt hoặc chế độ duyệt web chưa hỗ trợ kết nối này. Hãy thử trình duyệt được cập nhật và cho phép lưu dữ liệu trang web.';
      case 'popup-closed-by-user':
      case 'cancelled-popup-request':
      case 'web-context-canceled':
        return 'Bạn đã hủy đăng nhập. Bạn có thể thử lại.';
      case 'popup-blocked':
        return 'Trình duyệt đã chặn cửa sổ đăng nhập. Hãy cho phép popup rồi thử lại.';
      case 'unauthorized-domain':
        return 'Tên miền này chưa được phép đăng nhập. Vui lòng liên hệ quản trị viên.';
      case 'network-request-failed':
      case 'unavailable':
      case 'deadline-exceeded':
        return 'Không thể kết nối máy chủ. Vui lòng kiểm tra mạng và thử lại.';
      case 'permission-denied':
        return 'Bạn chưa có quyền truy cập dữ liệu. Vui lòng kiểm tra tài khoản hoặc liên hệ quản trị viên.';
      case 'unauthenticated':
      case 'user-token-expired':
      case 'invalid-user-token':
        return 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';
      case 'operation-not-allowed':
        return 'Đăng nhập Google chưa được bật cho ứng dụng này.';
      case 'user-disabled':
        return 'Tài khoản đã bị vô hiệu hóa. Vui lòng liên hệ quản trị viên.';
      case 'account-exists-with-different-credential':
        return 'Email này đang dùng phương thức đăng nhập khác. Vui lòng liên hệ quản trị viên.';
    }
  }
  if (error is UnsupportedError) {
    return 'Nền tảng hoặc trình duyệt này chưa được hỗ trợ.';
  }
  final detail = error.toString().toLowerCase();
  if (detail.contains('failed to fetch') ||
      detail.contains('networkerror') ||
      detail.contains('load failed') ||
      detail.contains('socketexception')) {
    return 'Không thể tải kết nối Firebase. Kiểm tra mạng hoặc trình chặn nội dung rồi thử lại.';
  }
  return 'Không thể hoàn tất thao tác. Vui lòng thử lại.';
}

/// Debug-only diagnostics. Never print options, users, credentials or tokens.
void logFirebaseFailure(String stage, Object error) {
  if (!kDebugMode) return;
  final detail = error is FirebaseException
      ? 'plugin=${error.plugin} code=${error.code} message=${error.message}'
      : '${error.runtimeType}: $error';
  debugPrint('[Firebase/$stage] ${redactFirebaseDiagnostic(detail)}');
}

@visibleForTesting
String redactFirebaseDiagnostic(String text) => text
    .replaceAll(
      RegExp(r'Bearer\s+[^\s,;]+', caseSensitive: false),
      '[REDACTED]',
    )
    .replaceAll(RegExp(r'AIza[0-9A-Za-z_-]+'), '[REDACTED]')
    .replaceAll(RegExp(r'eyJ[0-9A-Za-z_.-]+'), '[REDACTED]')
    .replaceAll(RegExp(r'[\w.+-]+@[\w.-]+\.[A-Za-z]{2,}'), '[REDACTED]')
    .replaceAll(RegExp(r'https?://[^\s]+'), '[URL]')
    .replaceAll(
      RegExp(
        r'(token|credential|password|secret|api[_-]?key|authorization)\s*[:=]\s*[^\s,;]+',
        caseSensitive: false,
      ),
      '[REDACTED]',
    );
