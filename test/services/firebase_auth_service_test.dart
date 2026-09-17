import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quanlycongviecapp/firebase_options.dart';
import 'package:quanlycongviecapp/services/auth_service.dart';
import 'package:quanlycongviecapp/services/firebase_auth_service.dart';

class MockAuth extends Mock implements FirebaseAuth {}

class MockCredential extends Mock implements UserCredential {}

class MockUser extends Mock implements User {}

class MockGoogle extends Mock implements GoogleSignIn {}

void main() {
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
