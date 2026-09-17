import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quanlycongviecapp/navigation/app_session.dart';
import 'package:quanlycongviecapp/repositories/app_repository.dart';
import 'package:quanlycongviecapp/repositories/demo_repository.dart';
import 'package:quanlycongviecapp/services/auth_service.dart';

const alice = AppUser(uid: 'a', displayName: 'Alice', email: 'a@example.com');
const bob = AppUser(uid: 'b', displayName: 'Bob', email: 'b@example.com');

class TestAuth extends AuthService {
  final events = StreamController<AppUser?>.broadcast();
  @override
  AppUser? currentUser;
  @override
  bool isAvailable = true;
  @override
  String? initializationError;
  @override
  Future<void> ensureInitialized() async {}
  @override
  Future<AppUser?> restoreSession() async => currentUser;
  @override
  Stream<AppUser?> authStateChanges() => events.stream;
  @override
  Future<AppUser> signInWithGoogle() async => currentUser!;
  @override
  Future<void> signOut() async {
    currentUser = null;
    events.add(null);
  }

  @override
  void dispose() {
    events.close();
    super.dispose();
  }
}

class TrackedRepository extends DemoRepository {
  int disposals = 0;
  Completer<void>? gate;
  bool fail = false;
  @override
  Future<void> init() async {
    if (gate != null) await gate!.future;
    if (fail) throw const RepositoryException('Không có quyền truy cập');
  }

  @override
  void dispose() {
    disposals++;
    super.dispose();
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'restores session, switches UID and disposes before replacement',
    () async {
      final auth = TestAuth()..currentUser = alice;
      final repos = <TrackedRepository>[];
      final session = AppSession(
        authService: auth,
        repositoryFactory: (uid) {
          if (repos.isNotEmpty) expect(repos.last.disposals, 1);
          final repo = TrackedRepository();
          repos.add(repo);
          return repo;
        },
      );
      await session.bootstrap();
      expect(session.user?.uid, 'a');
      auth.currentUser = bob;
      auth.events.add(bob);
      await Future<void>.delayed(Duration.zero);
      expect(session.user?.uid, 'b');
      expect(repos.length, 2);
      auth.events.add(bob);
      await Future<void>.delayed(Duration.zero);
      expect(repos.length, 2);
      await session.signOut();
      expect(repos.last.disposals, 1);
      expect(session.repository, isNull);
      expect(session.user, isNull);
      session.dispose();
    },
  );

  test('repository failure does not report successful sign-in', () async {
    final auth = TestAuth()..currentUser = alice;
    final repo = TrackedRepository()..fail = true;
    final session = AppSession(
      authService: auth,
      repositoryFactory: (_) => repo,
    );
    expect(await session.signInWithGoogle(), false);
    expect(session.status, SessionStatus.needsAuth);
    expect(session.lastError, contains('quyền'));
    expect(repo.disposals, 1);
    session.dispose();
  });

  test('logout during load cannot restore old UID data', () async {
    final auth = TestAuth()..currentUser = alice;
    final repo = TrackedRepository()..gate = Completer<void>();
    final session = AppSession(
      authService: auth,
      repositoryFactory: (_) => repo,
    );
    final login = session.signInWithGoogle();
    await Future<void>.delayed(Duration.zero);
    await session.signOut();
    expect(repo.disposals, 1);
    repo.gate!.complete();
    expect(await login, false);
    expect(session.repository, isNull);
    expect(session.user, isNull);
    session.dispose();
  });

  test('Demo works without Firebase and clears previous repository', () async {
    final auth = TestAuth()..currentUser = alice;
    final repo = TrackedRepository();
    final session = AppSession(
      authService: auth,
      repositoryFactory: (_) => repo,
    );
    await session.bootstrap();
    await session.enterDemoMode();
    expect(repo.disposals, 1);
    expect(session.isDemoMode, true);
    expect(session.repository!.groups, isNotEmpty);
    expect(session.user, isNull);
    session.dispose();
  });
}
