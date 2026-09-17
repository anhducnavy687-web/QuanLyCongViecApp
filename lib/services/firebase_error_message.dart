import 'dart:async';

import 'package:firebase_core/firebase_core.dart';

String firebaseErrorMessage(Object error) {
  if (error is TimeoutException) {
    return 'Kết nối quá lâu. Vui lòng kiểm tra mạng và thử lại.';
  }
  if (error is FirebaseException) {
    switch (error.code) {
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
  return 'Không thể hoàn tất thao tác. Vui lòng thử lại.';
}
