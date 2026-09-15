import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_constants.dart';
import '../repositories/app_repository.dart';
import '../repositories/demo_repository.dart';
import '../repositories/firebase_repository.dart';
import '../services/auth_service.dart';
import '../services/firebase_auth_service.dart';

enum SessionStatus { loading, needsAuth, demo, authenticated }

/// Điều phối trung tâm cho vòng đời phiên làm việc: Splash -> kiểm tra
/// session -> Login/Demo -> Home. Đây là nơi DUY NHẤT quyết định app đang
/// dùng [DemoRepository] hay [FirebaseRepository] — toàn bộ UI phía dưới
/// chỉ đọc [AppSession.repository] thông qua Provider mà không cần biết
/// đang chạy ở chế độ nào.
class AppSession extends ChangeNotifier {
  AppSession({FirebaseAuthService? authService})
      : authService = authService ?? FirebaseAuthService();

  final FirebaseAuthService authService;

  SessionStatus status = SessionStatus.loading;
  AppRepository? repository;
  AppUser? user;
  String? lastError;

  bool get isDemoMode => status == SessionStatus.demo;

  Future<void> bootstrap() async {
    await authService.ensureInitialized();
    final prefs = await SharedPreferences.getInstance();
    final wasDemo = prefs.getBool(AppConstants.prefsKeyDemoMode) ?? false;

    if (authService.isAvailable) {
      final restoredUser = await authService.restoreSession();
      if (restoredUser != null) {
        await _enterFirebaseMode(restoredUser);
        return;
      }
    }

    if (wasDemo) {
      await enterDemoMode();
      return;
    }

    status = SessionStatus.needsAuth;
    notifyListeners();
  }

  Future<void> enterDemoMode() async {
    final repo = DemoRepository();
    await repo.init();
    repository = repo;
    status = SessionStatus.demo;
    lastError = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.prefsKeyDemoMode, true);
    notifyListeners();
  }

  Future<bool> signInWithGoogle() async {
    try {
      final signedInUser = await authService.signInWithGoogle();
      await _enterFirebaseMode(signedInUser);
      return true;
    } on AuthException catch (e) {
      lastError = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      lastError = 'Đăng nhập thất bại: $e';
      notifyListeners();
      return false;
    }
  }

  Future<void> _enterFirebaseMode(AppUser signedInUser) async {
    user = signedInUser;
    final repo = FirebaseRepository(uid: signedInUser.uid);
    try {
      await repo.init();
      repository = repo;
      status = SessionStatus.authenticated;
      lastError = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.prefsKeyDemoMode, false);
      notifyListeners();
    } catch (e) {
      lastError = 'Không thể tải dữ liệu từ máy chủ: $e';
      status = SessionStatus.needsAuth;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    if (status == SessionStatus.authenticated) {
      await authService.signOut();
    }
    repository = null;
    user = null;
    status = SessionStatus.needsAuth;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.prefsKeyDemoMode, false);
    notifyListeners();
  }
}
