import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:quanlycongviecapp/services/firebase_error_message.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quanlycongviecapp/firebase_options.dart';
import 'package:quanlycongviecapp/services/auth_service.dart';
import 'package:quanlycongviecapp/services/firebase_auth_service.dart';

class MockAuth extends Mock implements FirebaseAuth {}

class MockCredential extends Mock implements UserCredential {}

class MockUser extends Mock implements User {}

class MockGoogle extends Mock implements GoogleSignIn {}

class ColdWebCore extends FirebasePlatform {
  int calls = 0;
  int creations = 0;
  FirebaseAppPlatform? existing;

  @override
  List<FirebaseAppPlatform> get apps => throw StateError(
    "undefined is not an object (evaluating 'firebase_core.getApps')",
  );

  @override
  Future<FirebaseAppPlatform> initializeApp({
    String? name,
    FirebaseOptions? options,
  }) async {
    calls++;
    if (existing == null) {
      creations++;
      existing = FirebaseAppPlatform('[DEFAULT]', options!);
    }
    return existing!;
  }
}

void main() {
  test(
    'cold Web starts without querying apps; retry reuses default app',
    () async {
      final previous = FirebasePlatform.instance;
      final core = ColdWebCore();
      FirebasePlatform.instance = core;
      addTearDown(() => FirebasePlatform.instance = previous);
      var authAttempts = 0;
      final service = FirebaseAuthService(
        isWeb: true,
        authFactory: () {
          if (authAttempts++ == 0) {
            throw StateError('auth initialization failed');
          }
          return MockAuth();
        },
      );
      await service.ensureInitialized();
      expect(service.isAvailable, false);
      expect(core.calls, 1);
      await service.ensureInitialized();
      expect(service.isAvailable, true);
      expect(core.calls, 2);
      expect(core.creations, 1);
      await service.ensureInitialized();
      expect(core.calls, 2);
    },
  );

  testWidgets('slow initialization survives UI timeout and retry joins it', (
    tester,
  ) async {
    final pending = Completer<void>();
    var calls = 0;
    final service = FirebaseAuthService(
      isWeb: true,
      initialize: () {
        calls++;
        return pending.future;
      },
      authFactory: MockAuth.new,
    );
    final first = service.ensureInitialized();
    await tester.pump(const Duration(seconds: 9));
    await first;
    expect(service.isAvailable, false);
    expect(service.initializationError, contains('vẫn đang khởi tạo'));
    final retry = service.ensureInitialized();
    expect(calls, 1);
    pending.complete();
    await tester.pump();
    await retry;
    expect(service.isAvailable, true);
    expect(service.initializationError, isNull);
    await service.ensureInitialized();
    expect(calls, 1);
  });

  testWidgets(
    'late failure after UI timeout permits a fresh successful retry',
    (tester) async {
      final pending = Completer<void>();
      var calls = 0;
      final service = FirebaseAuthService(
        isWeb: true,
        initialize: () => ++calls == 1 ? pending.future : Future.value(),
        authFactory: MockAuth.new,
      );
      final first = service.ensureInitialized();
      await tester.pump(const Duration(seconds: 9));
      await first;
      pending.completeError(
        FirebaseException(plugin: 'core', code: 'network-request-failed'),
      );
      await tester.pump();
      expect(service.isAvailable, false);
      expect(service.initializationError, contains('kiểm tra mạng'));
      await service.ensureInitialized();
      expect(service.isAvailable, true);
      expect(calls, 2);
    },
  );

  testWidgets('session restore timeout is distinct and can be retried', (
    tester,
  ) async {
    final auth = MockAuth();
    final events = StreamController<User?>.broadcast();
    when(() => auth.authStateChanges()).thenAnswer((_) => events.stream);
    final service = FirebaseAuthService(
      isWeb: true,
      initialize: () async {},
      authFactory: () => auth,
    );
    await service.ensureInitialized();
    final timedOut = expectLater(
      service.restoreSession(),
      throwsA(isA<TimeoutException>()),
    );
    await tester.pump(const Duration(seconds: 9));
    await timedOut;
    expect(service.isAvailable, true);
    final retry = service.restoreSession();
    events.add(null);
    await tester.pump();
    expect(await retry, isNull);
    await events.close();
  });

  test('error categories stay friendly and never expose raw details', () {
    final cases = <Object, String>{
      TimeoutException('private detail'): 'quá lâu',
      FirebaseException(
        plugin: 'core',
        code: 'invalid-api-key',
        message: 'private detail',
      ): 'Cấu hình',
      FirebaseException(
        plugin: 'auth',
        code: 'unauthorized-domain',
        message: 'private detail',
      ): 'Tên miền',
      FirebaseException(
        plugin: 'auth',
        code: 'web-storage-unsupported',
        message: 'private detail',
      ): 'Trình duyệt',
      FirebaseException(
        plugin: 'auth',
        code: 'network-request-failed',
        message: 'private detail',
      ): 'kiểm tra mạng',
      Exception('TypeError: Load failed private detail'): 'Kiểm tra mạng',
      UnsupportedError('private detail'): 'chưa được hỗ trợ',
      StateError('private detail'): 'Không thể hoàn tất',
    };
    for (final entry in cases.entries) {
      final message = firebaseErrorMessage(entry.key);
      expect(message, contains(entry.value));
      expect(message, isNot(contains('private detail')));
    }
  });

  test('diagnostics redact credentials, identifiers and request URLs', () {
    final result = redactFirebaseDiagnostic(
      'code=invalid-api-key token=SECRET credential=PRIVATE '
      'a@example.com https://example.com/?key=SECRET AIzaAbc123 eyJabc.def.ghi Authorization: Bearer HIDDEN',
    );
    expect(result, contains('code=invalid-api-key'));
    for (final secret in [
      'SECRET',
      'PRIVATE',
      'a@example.com',
      'AIzaAbc123',
      'eyJabc',
      'HIDDEN',
    ]) {
      expect(result, isNot(contains(secret)));
    }
  });

  setUpAll(() => registerFallbackValue(GoogleAuthProvider()));

  test('Web options identify the existing production app', () {
    final options = DefaultFirebaseOptions.web;
    expect(options.projectId, 'quanlycongviecapp-129de');
    expect(options.appId, '1:957843233910:web:e23b136aff578073d09357');
    expect(options.authDomain, 'quanlycongviecapp-129de.firebaseapp.com');
    expect(options.messagingSenderId, '957843233910');
  });

  test(
    'Web initializes once and signs in through Firebase popup only',
    () async {
      final auth = MockAuth();
      final result = MockCredential();
      final user = MockUser();
      var initialized = 0;
      when(() => user.uid).thenReturn('uid-a');
      when(() => user.email).thenReturn('a@example.com');
      when(() => result.user).thenReturn(user);
      when(() => auth.signInWithPopup(any())).thenAnswer((_) async => result);
      final service = FirebaseAuthService(
        isWeb: true,
        initialize: () async {
          initialized++;
        },
        authFactory: () => auth,
        googleFactory: () =>
            throw StateError('Web must not create GoogleSignIn'),
      );
      await Future.wait([
        service.ensureInitialized(),
        service.ensureInitialized(),
      ]);
      await service.ensureInitialized();
      expect(initialized, 1);
      expect((await service.signInWithGoogle()).uid, 'uid-a');
      final provider =
          verify(() => auth.signInWithPopup(captureAny())).captured.single
              as GoogleAuthProvider;
      expect(provider.providerId, 'google.com');
    },
  );

  test(
    'restore waits for persisted auth state instead of stale currentUser',
    () async {
      final auth = MockAuth();
      final events = StreamController<User?>();
      when(() => auth.authStateChanges()).thenAnswer((_) => events.stream);
      final service = FirebaseAuthService(
        isWeb: true,
        initialize: () async {},
        authFactory: () => auth,
      );
      await service.ensureInitialized();
      var finished = false;
      final restored = service.restoreSession().then((user) {
        finished = true;
        return user;
      });
      await Future<void>.delayed(Duration.zero);
      expect(finished, false);
      final user = MockUser();
      when(() => user.uid).thenReturn('restored');
      events.add(user);
      expect((await restored)?.uid, 'restored');
      await events.close();
    },
  );

  for (final code in [
    'popup-closed-by-user',
    'popup-blocked',
    'unauthorized-domain',
    'network-request-failed',
  ]) {
    test('friendly error for $code', () async {
      final auth = MockAuth();
      when(() => auth.signInWithPopup(any())).thenThrow(
        FirebaseAuthException(code: code, message: 'raw secret detail'),
      );
      final service = FirebaseAuthService(
        isWeb: true,
        initialize: () async {},
        authFactory: () => auth,
      );
      await service.ensureInitialized();
      await expectLater(
        service.signInWithGoogle(),
        throwsA(
          isA<AuthException>().having(
            (e) => e.message,
            'safe message',
            allOf(isNot(contains(code)), isNot(contains('raw secret'))),
          ),
        ),
      );
    });
  }

  test('initialization failure remains retryable', () async {
    var attempts = 0;
    final service = FirebaseAuthService(
      isWeb: true,
      initialize: () async {
        if (attempts++ == 0) throw TimeoutException('raw');
      },
      authFactory: MockAuth.new,
    );
    await service.ensureInitialized();
    expect(service.isAvailable, false);
    expect(service.initializationError, contains('khởi tạo'));
    await service.ensureInitialized();
    expect(service.isAvailable, true);
    expect(service.initializationError, isNull);
  });

  test('native Google sign-out failure still signs out Firebase', () async {
    final auth = MockAuth();
    final google = MockGoogle();
    when(() => google.signOut()).thenThrow(StateError('native failure'));
    when(() => auth.signOut()).thenAnswer((_) async {});
    final service = FirebaseAuthService(
      isWeb: false,
      initialize: () async {},
      authFactory: () => auth,
      googleFactory: () => google,
    );
    await service.ensureInitialized();
    await service.signOut();
    verify(() => auth.signOut()).called(1);
  });

  testWidgets('unresponsive popup times out instead of locking Login forever', (
    tester,
  ) async {
    final auth = MockAuth();
    when(() => auth.signInWithPopup(any()))
        .thenAnswer((_) => Completer<UserCredential>().future);
    final service = FirebaseAuthService(
      isWeb: true,
      initialize: () async {},
      authFactory: () => auth,
    );
    await service.ensureInitialized();
    final assertion = expectLater(
      service.signInWithGoogle(),
      throwsA(isA<AuthException>()),
    );
    await tester.pump(const Duration(seconds: 91));
    await assertion;
  });
}
