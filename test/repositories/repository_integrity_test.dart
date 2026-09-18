import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quanlycongviecapp/models/models.dart';
import 'package:quanlycongviecapp/repositories/app_repository.dart';
import 'package:quanlycongviecapp/repositories/demo_repository.dart';
import 'package:quanlycongviecapp/repositories/firebase_repository.dart';

Profile profileAt(
  DateTime now, {
  String id = '',
  ProfileStatus status = ProfileStatus.inProgress,
  DateTime? completedAt,
  bool hasDeadline = false,
  DateTime? deadline,
  DateTime? waitingSince,
  DateTime? expectedResponseDate,
}) => Profile(
  id: id,
  groupId: 'group',
  fullName: 'Nguyễn Văn A',
  workTarget: 'Xử lý hồ sơ',
  startDate: now,
  status: status,
  completedAt: completedAt,
  hasDeadline: hasDeadline,
  deadline: deadline,
  waitingSince: waitingSince,
  expectedResponseDate: expectedResponseDate,
  createdAt: now,
  updatedAt: now,
);

void main() {
  group('Demo and Firebase business invariants', () {
    test(
      'deadline enabled without date and invalid waiting dates are rejected',
      () async {
        final repo = DemoRepository();
        await repo.init();
        final now = DateTime(2026, 9, 18);
        await expectLater(
          repo.addProfile(profileAt(now, hasDeadline: true)),
          throwsA(isA<RepositoryException>()),
        );
        await expectLater(
          repo.addProfile(
            profileAt(
              now,
              status: ProfileStatus.waiting,
              waitingSince: now.add(const Duration(days: 2)),
              expectedResponseDate: now.add(const Duration(days: 1)),
            ),
          ),
          throwsA(isA<RepositoryException>()),
        );
        repo.dispose();
      },
    );

    test('editing completed profile and task preserves completedAt', () async {
      final repo = DemoRepository();
      await repo.init();
      final now = DateTime(2026, 9, 18);
      final completedAt = now.subtract(const Duration(days: 3));
      final profile = await repo.addProfile(
        profileAt(
          now,
          status: ProfileStatus.completed,
          completedAt: completedAt,
        ),
        withDefaultStages: false,
      );
      await repo.updateProfile(profile.copyWith(note: 'Nội dung mới'));
      expect(repo.profileById(profile.id)!.completedAt, completedAt);

      final task = await repo.addTask(
        TaskItem(
          id: '',
          profileId: profile.id,
          title: 'Việc đã xong',
          status: TaskStatus.completed,
          completedAt: completedAt,
          createdAt: now,
          updatedAt: now,
        ),
      );
      await repo.updateTask(task.copyWith(note: 'Nội dung mới'));
      expect(repo.tasksOf(profile.id).single.completedAt, completedAt);
      repo.dispose();
    });

    test(
      'Demo archives paid assignment and preserves payment history',
      () async {
        final repo = DemoRepository();
        await repo.init();
        final now = DateTime.now();
        final profile = await repo.addProfile(
          profileAt(now),
          withDefaultStages: false,
        );
        final collaborator = await repo.addCollaborator(name: 'CTV kiểm thử');
        final assignment = await repo.addAssignment(
          CollaboratorAssignment(
            id: '',
            profileId: profile.id,
            collaboratorId: collaborator.id,
            commissionAmount: 100,
            createdAt: now,
            updatedAt: now,
          ),
        );
        await repo.payCommission(
          assignmentId: assignment.id,
          amount: 50,
          date: now,
        );
        await repo.deleteAssignment(assignment.id);
        expect(repo.assignmentsOf(profile.id).single.isArchived, true);
        expect(repo.transactionsOf(profile.id), hasLength(1));
        await repo.deleteCollaborator(collaborator.id);
        expect(repo.collaboratorById(collaborator.id)!.active, false);
        repo.dispose();
      },
    );

    test('unused collaborator and unpaid assignment are hard-deleted in both repositories', () async {
      final now = DateTime.now();
      final demo = DemoRepository();
      await demo.init();
      final unused = await demo.addCollaborator(name: 'Chưa dùng');
      await demo.deleteCollaborator(unused.id);
      expect(demo.collaboratorById(unused.id), isNull);

      final profile = await demo.addProfile(
        profileAt(now),
        withDefaultStages: false,
      );
      final used = await demo.addCollaborator(name: 'Có phân công');
      final assignment = await demo.addAssignment(
        CollaboratorAssignment(
          id: '',
          profileId: profile.id,
          collaboratorId: used.id,
          commissionAmount: 100,
          createdAt: now,
          updatedAt: now,
        ),
      );
      await demo.deleteAssignment(assignment.id);
      expect(demo.assignmentsOf(profile.id), isEmpty);
      demo.dispose();

      final db = FakeFirebaseFirestore();
      final root = db.doc('users/u');
      await root
          .collection('collaborators')
          .doc('unused')
          .set(
            Collaborator(
              id: 'unused',
              name: 'Chưa dùng',
              createdAt: now,
              updatedAt: now,
            ).toJson(),
          );
      await root
          .collection('collaborators')
          .doc('used')
          .set(
            Collaborator(
              id: 'used',
              name: 'Đã dùng',
              createdAt: now,
              updatedAt: now,
            ).toJson(),
          );
      await root
          .collection('profiles')
          .doc('p')
          .set(profileAt(now, id: 'p').toJson());
      await root
          .collection('profiles')
          .doc('p')
          .collection('collaboratorAssignments')
          .doc('a')
          .set(
            CollaboratorAssignment(
              id: 'a',
              profileId: 'p',
              collaboratorId: 'used',
              commissionAmount: 100,
              createdAt: now,
              updatedAt: now,
            ).toJson(),
          );
      final firebase = FirebaseRepository(uid: 'u', firestore: db);
      await firebase.init();
      await firebase.deleteCollaborator('unused');
      await firebase.deleteCollaborator('used');
      expect(
        (await root.collection('collaborators').doc('unused').get()).exists,
        false,
      );
      expect(
        (await root.collection('collaborators').doc('used').get())
            .data()!['active'],
        false,
      );
      firebase.dispose();
    });

    test(
      'Demo rejects zero/negative money and commission below paid amount',
      () async {
        final repo = DemoRepository();
        await repo.init();
        final now = DateTime.now();
        final profile = await repo.addProfile(
          profileAt(now),
          withDefaultStages: false,
        );
        final collaborator = await repo.addCollaborator(name: 'CTV');
        final assignment = await repo.addAssignment(
          CollaboratorAssignment(
            id: '',
            profileId: profile.id,
            collaboratorId: collaborator.id,
            commissionAmount: 100,
            paidAmount: 50,
            createdAt: now,
            updatedAt: now,
          ),
        );
        for (final amount in [0, -1]) {
          await expectLater(
            repo.addTransaction(
              MoneyTransaction(
                id: '',
                profileId: profile.id,
                type: TransactionType.received,
                amount: amount,
                date: now,
                createdAt: now,
              ),
            ),
            throwsA(isA<RepositoryException>()),
          );
          await expectLater(
            repo.payCommission(
              assignmentId: assignment.id,
              amount: amount,
              date: now,
            ),
            throwsA(isA<RepositoryException>()),
          );
        }
        await expectLater(
          repo.updateAssignment(assignment.copyWith(commissionAmount: 49)),
          throwsA(isA<RepositoryException>()),
        );
        repo.dispose();
      },
    );
  });
}
