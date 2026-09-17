import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_constants.dart';
import '../repositories/app_repository.dart';
import '../repositories/demo_repository.dart';
import '../repositories/firebase_repository.dart';
import '../services/auth_service.dart';
import '../services/firebase_auth_service.dart';
import '../services/firebase_error_message.dart';

enum SessionStatus { loading, needsAuth, demo, authenticated }

class AppSession extends ChangeNotifier {
  AppSession({
    AuthService? authService,
    AppRepository Function(String)? repositoryFactory,
  }) : authService = authService ?? FirebaseAuthService(),
       _repositoryFactory =
           repositoryFactory ?? ((uid) => FirebaseRepository(uid: uid));

  final AuthService authService;
  final AppRepository Function(String) _repositoryFactory;
  SessionStatus status = SessionStatus.loading;
  AppRepository? repository;
  AppRepository? _pendingRepository;
  AppUser? user;
  String? lastError;
  StreamSubscription<AppUser?>? _authSubscription;
  int _generation = 0;
  int viewRevision = 0;
  bool _disposed = false;
  bool _manualAuth = false;
  bool get isDemoMode => status == SessionStatus.demo;

  void _releaseRepositories() {
    final old = repository;
    repository = null;
    old?.dispose();
    _pendingRepository?.dispose();
    _pendingRepository = null;
    user = null;
    viewRevision++;
  }

  Future<void> _rememberDemo(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.prefsKeyDemoMode, value);
    } catch (_) {
      // Browser preference storage must not invalidate an authenticated session.
    }
  }

  Future<void> bootstrap() async {
    final generation = ++_generation;
    _manualAuth = true;
    await _authSubscription?.cancel();
    _authSubscription = null;
    _releaseRepositories();
    status = SessionStatus.loading;
    lastError = null;
    notifyListeners();
    try {
      await authService.ensureInitialized();
      if (_disposed || generation != _generation) return;
      final prefs = await SharedPreferences.getInstance();
      final restored = authService.isAvailable
          ? await authService.restoreSession()
          : null;
      if (_disposed || generation != _generation) return;
      if (restored != null) {
        await _enterFirebaseMode(restored);
      } else if (prefs.getBool(AppConstants.prefsKeyDemoMode) ?? false) {
        await enterDemoMode();
      } else {
        status = SessionStatus.needsAuth;
        lastError = authService.initializationError;
        notifyListeners();
      }
    } catch (e) {
      if (!_disposed && generation == _generation) {
        status = SessionStatus.needsAuth;
        lastError = firebaseErrorMessage(e);
        notifyListeners();
      }
    } finally {
      _manualAuth = false;
      if (!_disposed) _listenToAuth();
    }
  }

  void _listenToAuth() {
    if (!authService.isAvailable || _authSubscription != null) return;
    _authSubscription = authService.authStateChanges().listen(
      (next) {
        if (_disposed || _manualAuth || isDemoMode) return;
        if (next?.uid == user?.uid) return;
        if (next == null) {
          ++_generation;
          _releaseRepositories();
          status = SessionStatus.needsAuth;
          lastError = 'Phiên đăng nhập đã kết thúc. Vui lòng đăng nhập lại.';
          notifyListeners();
        } else {
          unawaited(_enterFirebaseMode(next));
        }
      },
      onError: (Object error) {
        if (_disposed) return;
        ++_generation;
        _releaseRepositories();
        status = SessionStatus.needsAuth;
        lastError = firebaseErrorMessage(error);
        notifyListeners();
      },
    );
  }

  Future<void> enterDemoMode() async {
    final generation = ++_generation;
    _releaseRepositories();
    final repo = DemoRepository();
    _pendingRepository = repo;
    await repo.init();
    if (_disposed || generation != _generation) return;
    _pendingRepository = null;
    repository = repo;
    status = SessionStatus.demo;
    lastError = null;
    notifyListeners();
    await _rememberDemo(true);
  }

  Future<bool> signInWithGoogle() async {
    if (_manualAuth || _disposed) return false;
    _manualAuth = true;
    final generation = _generation;
    try {
      final signedInUser = await authService.signInWithGoogle();
      if (_disposed || generation != _generation) return false;
      return await _enterFirebaseMode(signedInUser);
    } catch (e) {
      if (!_disposed && generation == _generation) {
        lastError = e is AuthException ? e.message : firebaseErrorMessage(e);
        notifyListeners();
      }
      return false;
    } finally {
      _manualAuth = false;
      if (!_disposed) _listenToAuth();
    }
  }

  Future<bool> _enterFirebaseMode(AppUser signedInUser) async {
    final generation = ++_generation;
    _releaseRepositories();
    user = signedInUser;
    status = SessionStatus.loading;
    lastError = null;
    notifyListeners();
    AppRepository? repo;
    try {
      repo = _repositoryFactory(signedInUser.uid);
      _pendingRepository = repo;
      await repo.init();
      if (_disposed || generation != _generation) return false;
      _pendingRepository = null;
      repository = repo;
      status = SessionStatus.authenticated;
      notifyListeners();
      await _rememberDemo(false);
      return !_disposed && generation == _generation;
    } catch (e) {
      if (_disposed || generation != _generation) return false;
      _pendingRepository = null;
      repo?.dispose();
      // Keep the UID to avoid retry loops from the initial auth event.
      status = SessionStatus.needsAuth;
      lastError = e is RepositoryException
          ? e.message
          : firebaseErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  Future<void> retryRepository() async {
    final current = authService.currentUser;
    if (current != null) await _enterFirebaseMode(current);
  }

  Future<void> signOut() async {
    ++_generation;
    _manualAuth = true;
    _releaseRepositories();
    status = SessionStatus.needsAuth;
    lastError = null;
    notifyListeners();
    try {
      // Also signs out a restored Firebase session while currently in Demo.
      await authService.signOut();
    } catch (e) {
      lastError = e is AuthException ? e.message : firebaseErrorMessage(e);
    } finally {
      _manualAuth = false;
      await _rememberDemo(false);
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    ++_generation;
    _authSubscription?.cancel();
    _releaseRepositories();
    authService.dispose();
    super.dispose();
  }
}
