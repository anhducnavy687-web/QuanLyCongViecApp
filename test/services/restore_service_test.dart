import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quanlycongviecapp/models/models.dart';
import 'package:quanlycongviecapp/repositories/app_repository.dart';
import 'package:quanlycongviecapp/repositories/demo_repository.dart';
import 'package:quanlycongviecapp/repositories/firebase_repository.dart';
import 'package:quanlycongviecapp/services/backup_file_picker.dart';
import 'package:quanlycongviecapp/services/backup_import_service.dart';
import 'package:quanlycongviecapp/services/backup_service.dart';
import 'package:quanlycongviecapp/services/restore_service.dart';

void main() {
  late DemoRepository demo;
  late RestorePreview preview;

  setUpAll(() async {
    demo = DemoRepository();
    await demo.init();
    final backup = const BackupService().createJsonBackup(
      await demo.createExportSnapshot(),
    );
    preview = const BackupImportService().inspect(
      PickedBackupFile(
        name: backup.fileName,
        size: backup.bytes.length,
        bytes: backup.bytes,
      ),
    );
  });

  tearDownAll(() => demo.dispose());

  test(
    'plan creates incoming, overwrites same IDs and deletes stale paths',
    () {
      const service = RestoreService();
      final first = preview.snapshot.profiles.first;
      final current = {
        'users/u/profiles/${first.id}',
        'users/u/profiles/stale',
        'users/u/profiles/${first.id}/tasks/stale-task',
      };
      final plan = service.plan(
        uid: 'u',
        preview: preview,
        currentDocumentPaths: current,
      );
      expect(
        plan.incomingDocumentPaths,
        contains('users/u/profiles/${first.id}'),
      );
      expect(plan.documentsToDelete, contains('users/u/profiles/stale'));
      expect(
        plan.documentsToDelete.any((path) => path.contains('stale-task')),
        true,
      );
      expect(
        plan.totalWrites,
        plan.totalSetOperations + plan.totalDeleteOperations,
      );
      expect(plan.expectedFinalCounts, preview.recordCounts);
    },
  );

  test('empty current graph creates every incoming document and preserves IDs/data', () {
    final plan = const RestoreService().plan(
      uid: 'u',
      preview: preview,
      currentDocumentPaths: {},
    );
    expect(plan.documentsToDelete, isEmpty);
    expect(
      plan.totalSetOperations,
      preview.recordCounts.values.fold(0, (a, b) => a + b),
    );
    final profile = preview.snapshot.profiles.first;
    final written = plan.documentsToSet.singleWhere(
      (d) => d.path.endsWith('/profiles/${profile.id}'),
    );
    expect(written.data['id'], profile.id);
    expect(written.data['createdAt'], profile.createdAt.toIso8601String());
    expect(written.data['completedAt'], profile.completedAt?.toIso8601String());
  });

  test('safe limit rejects the whole plan', () {
    expect(
      () =>
          const RestoreService(safeWriteLimit: 1)
              .plan(uid: 'u', preview: preview, currentDocumentPaths: {}),
      throwsA(
        isA<RestoreException>().having(
          (e) => e.message,
          'message',
          contains('quá lớn'),
        ),
      ),
    );
  });

  for (final unsafe in ['', '.', '..', 'a/b', r'a\b']) {
    test('unsafe ID "$unsafe" is rejected before planning', () {
      final original = preview.snapshot;
      final group = original.groups.first;
      final replacedGroup = WorkGroup(
        id: unsafe,
        name: group.name,
        description: group.description,
        createdAt: group.createdAt,
        updatedAt: group.updatedAt,
      );
      final changed = ExportSnapshot(
        exportedAt: original.exportedAt,
        appVersion: original.appVersion,
        sourceMode: original.sourceMode,
        repositoryRevision: 0,
        groups: [replacedGroup, ...original.groups.skip(1)],
        profiles: [
          for (final profile in original.profiles)
            profile.groupId == group.id
                ? profile.copyWith(groupId: unsafe)
                : profile,
        ],
        stages: original.stages,
        milestones: original.milestones,
        tasks: original.tasks,
        timelineEvents: original.timelineEvents,
        transactions: original.transactions,
        collaborators: original.collaborators,
        collaboratorAssignments: original.collaboratorAssignments,
        attachments: original.attachments,
      );
      final changedPreview = RestorePreview(
        fileName: preview.fileName,
        fileSize: preview.fileSize,
        snapshot: changed,
        warnings: const [],
        totalReceived: preview.totalReceived,
        totalExpense: preview.totalExpense,
        totalCollaboratorPayment: preview.totalCollaboratorPayment,
        rebuiltPaidAmounts: preview.rebuiltPaidAmounts,
      );
      expect(
        () => const RestoreService().plan(
          uid: 'u',
          preview: changedPreview,
          currentDocumentPaths: {},
        ),
        throwsA(anyOf(isA<RestoreException>(), isA<Exception>())),
      );
    });
  }

  test('one batch replaces graph, rebuilds paidAmount and removes stale docs', () async {
    final db = FakeFirebaseFirestore();
    await db.doc('users/u/groups/stale').set({'id': 'stale'});
    await db.doc('users/u/profiles/stale').set({'id': 'stale'});
    final repository = FirebaseRepository(uid: 'u', firestore: db);
    const service = RestoreService();
    final plan = service.plan(
      uid: 'u',
      preview: preview,
      currentDocumentPaths: {'users/u/groups/stale', 'users/u/profiles/stale'},
    );
    await service.commit(
      repository: repository,
      preview: preview,
      plan: plan,
      currentUid: () => 'u',
    );
    expect((await db.doc('users/u/groups/stale').get()).exists, false);
    expect((await db.doc('users/u/profiles/stale').get()).exists, false);
    for (final assignment in preview.snapshot.collaboratorAssignments) {
      final doc = await db
          .doc(
            'users/u/profiles/${assignment.profileId}/collaboratorAssignments/${assignment.id}',
          )
          .get();
      expect(
        doc.data()!['paidAmount'],
        preview.rebuiltPaidAmounts[assignment.id] ?? 0,
      );
      expect(
        doc.data()!['archivedAt'],
        assignment.archivedAt?.toIso8601String(),
      );
    }
    final attachment = preview.snapshot.attachments.first;
    final attachmentData =
        (await db
                .doc(
                  'users/u/profiles/${attachment.profileId}/attachments/${attachment.id}',
                )
                .get())
            .data()!;
    expect(attachmentData['localPathOrUrl'], attachment.localPathOrUrl);
    expect(attachmentData, isNot(contains('bytes')));
    repository.dispose();
  });

  test(
    'server discovery includes top-level and every nested collection',
    () async {
      final db = FakeFirebaseFirestore();
      await db.doc('users/u/groups/g').set({'id': 'g'});
      await db.doc('users/u/collaborators/c').set({'id': 'c'});
      await db.doc('users/u/profiles/p').set({'id': 'p'});
      for (final collection in [
        'stages',
        'milestones',
        'tasks',
        'timelineEvents',
        'transactions',
        'collaboratorAssignments',
        'attachments',
      ]) {
        await db.doc('users/u/profiles/p/$collection/x').set({'id': 'x'});
      }
      final repository = FirebaseRepository(uid: 'u', firestore: db);
      final plan = await const RestoreService().createPlan(
        repository: repository,
        preview: preview,
      );
      expect(plan.currentDocumentPaths, hasLength(10));
      expect(plan.currentDocumentPaths, contains('users/u/profiles/p/tasks/x'));
      repository.dispose();
    },
  );

  test('account change makes zero writes and releases write lock', () async {
    final db = FakeFirebaseFirestore();
    final repository = FirebaseRepository(uid: 'u', firestore: db);
    final plan = const RestoreService().plan(
      uid: 'u',
      preview: preview,
      currentDocumentPaths: {},
    );
    await expectLater(
      const RestoreService().commit(
        repository: repository,
        preview: preview,
        plan: plan,
        currentUid: () => 'other',
      ),
      throwsA(isA<RestoreException>()),
    );
    expect((await db.collection('users/u/groups').get()).docs, isEmpty);
    expect(repository.isRestoreInProgress, false);
    repository.dispose();
  });

  test('rejected atomic batch leaves existing server data unchanged', () async {
    const rules = '''
      service cloud.firestore {
        match /databases/{database}/documents {
          match /users/{uid}/{document=**} {
            allow read: if true;
            allow write: if request.auth != null && request.auth.uid == 'seed';
          }
        }
      }
    ''';
    final db = FakeFirebaseFirestore(securityRules: rules);
    db.authObject.add({'uid': 'seed'});
    await db.doc('users/u/groups/original').set({
      'id': 'original',
      'name': 'Original',
    });
    db.authObject.add({'uid': 'u'});
    final repository = FirebaseRepository(uid: 'u', firestore: db);
    final plan = const RestoreService().plan(
      uid: 'u',
      preview: preview,
      currentDocumentPaths: {'users/u/groups/original'},
    );
    await expectLater(
      const RestoreService().commit(
        repository: repository,
        preview: preview,
        plan: plan,
        currentUid: () => 'u',
      ),
      throwsA(isA<RestoreException>()),
    );
    final original = await db.doc('users/u/groups/original').get();
    expect(original.exists, true);
    expect(original.data()!['name'], 'Original');
    expect((await db.collection('users/u/profiles').get()).docs, isEmpty);
    repository.dispose();
  });

  test('repository lock blocks a concurrent mutation', () async {
    final repository = FirebaseRepository(
      uid: 'u',
      firestore: FakeFirebaseFirestore(),
    );
    final token = repository.beginRestore();
    await expectLater(
      repository.addGroup(name: 'blocked'),
      throwsA(isA<RepositoryException>()),
    );
    repository.endRestore(token);
    repository.dispose();
  });
}
