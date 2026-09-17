// SDK sealed types are mocked only to inject stream failures, never subclassed in production.
// ignore_for_file: subtype_of_sealed_class

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quanlycongviecapp/models/models.dart';
import 'package:quanlycongviecapp/repositories/app_repository.dart';
import 'package:quanlycongviecapp/repositories/firebase_repository.dart';

class MockDb extends Mock implements FirebaseFirestore {}

class MockCollection extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

class MockDocument extends Mock
    implements DocumentReference<Map<String, dynamic>> {}

class MockSnapshot extends Mock
    implements QuerySnapshot<Map<String, dynamic>> {}

class MockMetadata extends Mock implements SnapshotMetadata {}

void main() {
  test('permission loss after readiness exposes error and cancels listeners on disposal', () async {
    final db = MockDb();
    final users = MockCollection();
    final root = MockDocument();
    final controllers =
        <StreamController<QuerySnapshot<Map<String, dynamic>>>>[];
    when(() => db.collection('users')).thenReturn(users);
    when(() => users.doc('a')).thenReturn(root);
    for (final name in ['groups', 'profiles', 'collaborators']) {
      final collection = MockCollection();
      final controller =
          StreamController<QuerySnapshot<Map<String, dynamic>>>();
      controllers.add(controller);
      when(() => root.collection(name)).thenReturn(collection);
      when(() => collection.path).thenReturn(name);
      when(() => collection.snapshots(includeMetadataChanges: true))
          .thenAnswer((_) => controller.stream);
    }
    final snapshot = MockSnapshot();
    final metadata = MockMetadata();
    when(() => snapshot.docs).thenReturn([]);
    when(() => snapshot.metadata).thenReturn(metadata);
    when(() => metadata.isFromCache).thenReturn(false);
    final repo = FirebaseRepository(uid: 'a', firestore: db);
    final initial = repo.init();
    for (final controller in controllers) {
      controller.add(snapshot);
    }
    await initial;
    expect(repo.isReady, true);
    controllers.last.addError(
      FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied'),
    );
    await Future<void>.delayed(Duration.zero);
    expect(repo.isReady, false);
    expect(repo.syncError, contains('quyền'));
    repo.dispose();
    expect(controllers.every((c) => !c.hasListener), true);
    for (final controller in controllers) {
      await controller.close();
    }
  });
  test(
    'waits for all initial snapshots, loads nested collections and disposes',
    () async {
      final db = FakeFirebaseFirestore();
      final now = DateTime.now();
      await db
          .doc('users/a/profiles/p')
          .set(
            Profile(
              id: 'p',
              groupId: 'g',
              fullName: 'Test',
              workTarget: '',
              startDate: now,
              createdAt: now,
              updatedAt: now,
            ).toJson(),
          );
      final repo = FirebaseRepository(uid: 'a', firestore: db);
      final initial = repo.init();
      expect(repo.isReady, false);
      await initial;
      expect(repo.isReady, true);
      expect(repo.profiles.single.id, 'p');
      expect(repo.tasksOf('p'), isEmpty);
      var notifications = 0;
      repo.addListener(() => notifications++);
      await repo.init();
      repo.dispose();
      final before = notifications;
      await db
          .doc('users/a/groups/g')
          .set(
            WorkGroup(
              id: 'g',
              name: 'After dispose',
              createdAt: now,
              updatedAt: now,
            ).toJson(),
          );
      await Future<void>.delayed(Duration.zero);
      expect(notifications, before);
    },
  );

  for (final code in ['permission-denied', 'unavailable']) {
    test('listener $code fails initialization with a friendly error', () async {
      final db = MockDb();
      final users = MockCollection();
      final root = MockDocument();
      final streams = <StreamController<QuerySnapshot<Map<String, dynamic>>>>[];
      when(() => db.collection('users')).thenReturn(users);
      when(() => users.doc('a')).thenReturn(root);
      for (final name in ['groups', 'profiles', 'collaborators']) {
        final collection = MockCollection();
        final stream = StreamController<QuerySnapshot<Map<String, dynamic>>>();
        streams.add(stream);
        when(() => root.collection(name)).thenReturn(collection);
        when(() => collection.path).thenReturn('users/a/$name');
        when(() => collection.snapshots(includeMetadataChanges: true))
            .thenAnswer((_) => stream.stream);
      }
      final repo = FirebaseRepository(uid: 'a', firestore: db);
      final initial = repo.init();
      final assertion = expectLater(
        initial,
        throwsA(isA<RepositoryException>()),
      );
      streams.first.addError(
        FirebaseException(plugin: 'cloud_firestore', code: code),
      );
      await assertion;
      expect(repo.isReady, false);
      expect(repo.syncError, isNotNull);
      expect(repo.syncError, isNot(contains(code)));
      repo.dispose();
      expect(streams.every((s) => !s.hasListener), true);
      for (final stream in streams) {
        await stream.close();
      }
    });
  }

  test('empty offline cache is not a successful empty database', () async {
    final db = MockDb();
    final users = MockCollection();
    final root = MockDocument();
    final controllers =
        <StreamController<QuerySnapshot<Map<String, dynamic>>>>[];
    when(() => db.collection('users')).thenReturn(users);
    when(() => users.doc('a')).thenReturn(root);
    for (final name in ['groups', 'profiles', 'collaborators']) {
      final collection = MockCollection();
      final controller =
          StreamController<QuerySnapshot<Map<String, dynamic>>>();
      controllers.add(controller);
      when(() => root.collection(name)).thenReturn(collection);
      when(() => collection.path).thenReturn(name);
      when(() => collection.snapshots(includeMetadataChanges: true))
          .thenAnswer((_) => controller.stream);
    }
    final cached = MockSnapshot();
    final metadata = MockMetadata();
    when(() => cached.docs).thenReturn([]);
    when(() => cached.metadata).thenReturn(metadata);
    when(() => metadata.isFromCache).thenReturn(true);
    final repo = FirebaseRepository(uid: 'a', firestore: db);
    final initial = repo.init();
    final assertion = expectLater(initial, throwsA(isA<RepositoryException>()));
    for (final controller in controllers) {
      controller.add(cached);
    }
    await Future<void>.delayed(Duration.zero);
    expect(repo.isReady, false);
    repo.dispose();
    await assertion;
    for (final controller in controllers) {
      await controller.close();
    }
  });

  test('two clients add payments without losing paidAmount; stale edit preserves it', () async {
    final db = FakeFirebaseFirestore();
    final now = DateTime.now();
    final root = db.doc('users/a/profiles/p');
    await root.set(
      Profile(
        id: 'p',
        groupId: 'g',
        fullName: 'Test',
        workTarget: '',
        startDate: now,
        createdAt: now,
        updatedAt: now,
      ).toJson(),
    );
    final original = CollaboratorAssignment(
      id: 'c',
      profileId: 'p',
      collaboratorId: 'person',
      createdAt: now,
      updatedAt: now,
    );
    await root
        .collection('collaboratorAssignments')
        .doc('c')
        .set(original.toJson());
    final pc = FirebaseRepository(uid: 'a', firestore: db);
    final phone = FirebaseRepository(uid: 'a', firestore: db);
    await Future.wait([pc.init(), phone.init()]);
    await Future.wait([
      pc.payCommission(assignmentId: 'c', amount: 100, date: now),
      phone.payCommission(assignmentId: 'c', amount: 200, date: now),
    ]);
    final assignmentRef = root.collection('collaboratorAssignments').doc('c');
    expect((await assignmentRef.get()).data()!['paidAmount'], 300);
    expect((await root.collection('transactions').get()).docs.length, 2);
    await pc.updateAssignment(
      original.copyWith(role: 'Edited from stale cache'),
    );
    expect((await assignmentRef.get()).data()!['paidAmount'], 300);
    await Future<void>.delayed(Duration.zero);
    final payment = pc.transactionsOf('p').first;
    await pc.deleteTransaction(payment.id);
    // The second client may still have this transaction in its cache.
    await phone.deleteTransaction(payment.id);
    expect(
      (await assignmentRef.get()).data()!['paidAmount'],
      300 - payment.amount,
    );
    pc.dispose();
    phone.dispose();
  });
}
