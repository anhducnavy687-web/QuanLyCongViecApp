import 'package:flutter_test/flutter_test.dart';
import 'package:quanlycongviecapp/models/models.dart';
import 'package:quanlycongviecapp/repositories/demo_repository.dart';

Future<String> _seedProfile(DemoRepository repo) async {
  final group = await repo.addGroup(name: 'Nhóm test');
  final profile = await repo.addProfile(
    Profile(
      id: '',
      groupId: group.id,
      fullName: 'Khách hàng test',
      workTarget: 'Mục tiêu test',
      startDate: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  );
  return profile.id;
}

void main() {
  group('DemoRepository — Task & Timeline', () {
    test('addTask ghi timeline taskCreated và xuất hiện trong tasksOf/allOpenTasks', () async {
      final repo = DemoRepository();
      await repo.init();
      final profileId = await _seedProfile(repo);

      final task = await repo.addTask(TaskItem(
        id: '',
        profileId: profileId,
        title: 'Gọi điện khách hàng',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      expect(task.id, isNotEmpty);
      expect(repo.tasksOf(profileId).map((t) => t.id), contains(task.id));
      expect(repo.allOpenTasks.map((t) => t.id), contains(task.id));

      final events = repo.timelineOf(profileId);
      expect(
        events.any((e) => e.type == TimelineEventType.taskCreated && e.message.contains(task.title)),
        isTrue,
      );
    });

    test('markTaskCompleted cập nhật status/completedAt, ghi timeline và biến mất khỏi allOpenTasks', () async {
      final repo = DemoRepository();
      await repo.init();
      final profileId = await _seedProfile(repo);
      final task = await repo.addTask(TaskItem(
        id: '',
        profileId: profileId,
        title: 'Nộp hồ sơ',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      await repo.markTaskCompleted(task.id);

      final updated = repo.tasksOf(profileId).firstWhere((t) => t.id == task.id);
      expect(updated.status, TaskStatus.completed);
      expect(updated.completedAt, isNotNull);
      expect(repo.allOpenTasks.map((t) => t.id), isNot(contains(task.id)));

      final events = repo.timelineOf(profileId);
      expect(events.any((e) => e.type == TimelineEventType.taskCompleted), isTrue);
    });

    test('deleteTask xóa khỏi tasksOf', () async {
      final repo = DemoRepository();
      await repo.init();
      final profileId = await _seedProfile(repo);
      final task = await repo.addTask(TaskItem(
        id: '',
        profileId: profileId,
        title: 'Việc sẽ bị xóa',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      await repo.deleteTask(task.id);
      expect(repo.tasksOf(profileId).map((t) => t.id), isNot(contains(task.id)));
    });

    test('addTimelineNote ghi một sự kiện loại note', () async {
      final repo = DemoRepository();
      await repo.init();
      final profileId = await _seedProfile(repo);

      await repo.addTimelineNote(profileId, 'Đã gọi điện, khách hẹn lại tuần sau');

      final events = repo.timelineOf(profileId);
      expect(
        events.any((e) => e.type == TimelineEventType.note && e.message == 'Đã gọi điện, khách hẹn lại tuần sau'),
        isTrue,
      );
    });

    test('cập nhật profile sang waiting ghi timeline waitingStarted, thoát waiting ghi waitingResolved', () async {
      final repo = DemoRepository();
      await repo.init();
      final profileId = await _seedProfile(repo);
      final profile = repo.profileById(profileId)!;

      await repo.updateProfile(profile.copyWith(
        status: ProfileStatus.waiting,
        waitingReason: 'Chờ công chứng',
      ));
      expect(
        repo.timelineOf(profileId).any((e) => e.type == TimelineEventType.waitingStarted),
        isTrue,
      );
      expect(repo.aggregateOf(profileId).isWaiting, isTrue);

      final waitingProfile = repo.profileById(profileId)!;
      await repo.updateProfile(waitingProfile.copyWith(status: ProfileStatus.inProgress));
      expect(
        repo.timelineOf(profileId).any((e) => e.type == TimelineEventType.waitingResolved),
        isTrue,
      );
      expect(repo.aggregateOf(profileId).isWaiting, isFalse);
    });

    test('đổi deadline ghi timeline profileUpdated, không đổi thì không ghi thêm', () async {
      final repo = DemoRepository();
      await repo.init();
      final profileId = await _seedProfile(repo);
      final profile = repo.profileById(profileId)!;
      final countBefore = repo.timelineOf(profileId).length;

      final newDeadline = DateTime.now().add(const Duration(days: 10));
      await repo.updateProfile(profile.copyWith(deadline: newDeadline, hasDeadline: true));
      final eventsAfterSet = repo.timelineOf(profileId);
      expect(eventsAfterSet.length, countBefore + 1);
      expect(
        eventsAfterSet.any((e) => e.type == TimelineEventType.profileUpdated && e.message.contains('Đặt hạn hoàn thành')),
        isTrue,
      );

      // Cập nhật hồ sơ mà KHÔNG đổi deadline — không được ghi thêm sự kiện.
      final updated = repo.profileById(profileId)!;
      await repo.updateProfile(updated.copyWith(note: 'Ghi chú mới'));
      expect(repo.timelineOf(profileId).length, countBefore + 1);

      // Đổi sang deadline khác — ghi thêm đúng 1 sự kiện "Đổi hạn hoàn thành".
      final withDeadline = repo.profileById(profileId)!;
      await repo.updateProfile(withDeadline.copyWith(deadline: newDeadline.add(const Duration(days: 5))));
      final eventsAfterChange = repo.timelineOf(profileId);
      expect(eventsAfterChange.length, countBefore + 2);
      expect(eventsAfterChange.any((e) => e.message.contains('Đổi hạn hoàn thành')), isTrue);

      // Bỏ deadline — ghi "Bỏ hạn hoàn thành".
      final withDeadline2 = repo.profileById(profileId)!;
      await repo.updateProfile(withDeadline2.copyWith(hasDeadline: false, clearDeadline: true));
      final eventsAfterClear = repo.timelineOf(profileId);
      expect(eventsAfterClear.length, countBefore + 3);
      expect(eventsAfterClear.any((e) => e.message == 'Bỏ hạn hoàn thành'), isTrue);
    });
  });
}
