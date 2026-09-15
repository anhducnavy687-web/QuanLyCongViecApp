import 'package:flutter_test/flutter_test.dart';
import 'package:quanlycongviecapp/models/models.dart';

Profile _profile({ProfileStatus status = ProfileStatus.inProgress}) {
  final now = DateTime.now();
  return Profile(
    id: 'p1',
    groupId: 'g1',
    fullName: 'Nguyễn Văn A',
    workTarget: 'Test',
    startDate: now,
    status: status,
    createdAt: now,
    updatedAt: now,
  );
}

TaskItem _task({
  String id = 't1',
  TaskStatus status = TaskStatus.todo,
  DateTime? dueDate,
}) {
  final now = DateTime.now();
  return TaskItem(
    id: id,
    profileId: 'p1',
    title: 'Việc $id',
    status: status,
    dueDate: dueDate,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('ProfileAggregate.isWaiting', () {
    test('true khi profile.status == waiting', () {
      final agg = ProfileAggregate(profile: _profile(status: ProfileStatus.waiting));
      expect(agg.isWaiting, isTrue);
    });

    test('false với các trạng thái khác', () {
      final agg = ProfileAggregate(profile: _profile(status: ProfileStatus.inProgress));
      expect(agg.isWaiting, isFalse);
    });

    test('task ở trạng thái waiting KHÔNG tự làm hồ sơ thành waiting', () {
      final agg = ProfileAggregate(
        profile: _profile(status: ProfileStatus.inProgress),
        tasks: [_task(status: TaskStatus.waiting)],
      );
      expect(agg.isWaiting, isFalse);
    });
  });

  group('ProfileAggregate — task-derived getters', () {
    test('openTasks loại bỏ completed/cancelled và sắp theo dueDate (null cuối)', () {
      final now = DateTime.now();
      final agg = ProfileAggregate(
        profile: _profile(),
        tasks: [
          _task(id: 'a', dueDate: now.add(const Duration(days: 5))),
          _task(id: 'b', dueDate: null),
          _task(id: 'c', dueDate: now.add(const Duration(days: 1))),
          _task(id: 'd', status: TaskStatus.completed, dueDate: now),
          _task(id: 'e', status: TaskStatus.cancelled, dueDate: now),
        ],
      );
      expect(agg.openTasks.map((t) => t.id), ['c', 'a', 'b']);
    });

    test('overdueTasks chỉ chứa task mở đã quá hạn', () {
      final now = DateTime.now();
      final agg = ProfileAggregate(
        profile: _profile(),
        tasks: [
          _task(id: 'overdue', dueDate: now.subtract(const Duration(days: 2))),
          _task(id: 'future', dueDate: now.add(const Duration(days: 2))),
          _task(id: 'done-overdue', status: TaskStatus.completed, dueDate: now.subtract(const Duration(days: 5))),
        ],
      );
      expect(agg.overdueTasks.map((t) => t.id), ['overdue']);
      expect(agg.overdueTaskCount, 1);
    });

    test('todayTasks chỉ chứa task mở có hạn hôm nay', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day, 18);
      final agg = ProfileAggregate(
        profile: _profile(),
        tasks: [
          _task(id: 'today', dueDate: today),
          _task(id: 'tomorrow', dueDate: now.add(const Duration(days: 1))),
        ],
      );
      expect(agg.todayTasks.map((t) => t.id), ['today']);
    });
  });

  group('TaskItem.copyWith — clear flags', () {
    test('clearDueDate/clearWaitingReason/... xóa field về null', () {
      final now = DateTime.now();
      final t = _task().copyWith(
        dueDate: now,
        waitingReason: 'lý do',
        waitingSince: now,
        expectedResponseDate: now,
        completedAt: now,
      );
      expect(t.dueDate, isNotNull);
      expect(t.waitingReason, isNotNull);

      final cleared = t.copyWith(
        clearDueDate: true,
        clearWaitingReason: true,
        clearWaitingSince: true,
        clearExpectedResponseDate: true,
        clearCompletedAt: true,
      );
      expect(cleared.dueDate, isNull);
      expect(cleared.waitingReason, isNull);
      expect(cleared.waitingSince, isNull);
      expect(cleared.expectedResponseDate, isNull);
      expect(cleared.completedAt, isNull);
      // id/createdAt luôn giữ nguyên, không settable qua copyWith.
      expect(cleared.id, t.id);
      expect(cleared.createdAt, t.createdAt);
    });
  });

  group('Profile.copyWith — clear flags cho waiting', () {
    test('clearWaitingReason/clearWaitingSince/clearExpectedResponseDate', () {
      final now = DateTime.now();
      final p = _profile(status: ProfileStatus.waiting).copyWith(
        waitingReason: 'lý do',
        waitingSince: now,
        expectedResponseDate: now,
      );
      final cleared = p.copyWith(
        status: ProfileStatus.inProgress,
        clearWaitingReason: true,
        clearWaitingSince: true,
        clearExpectedResponseDate: true,
      );
      expect(cleared.status, ProfileStatus.inProgress);
      expect(cleared.waitingReason, isNull);
      expect(cleared.waitingSince, isNull);
      expect(cleared.expectedResponseDate, isNull);
    });
  });

  group('TimelineEvent.fromValue', () {
    test('map đúng toàn bộ value sang enum type', () {
      expect(TimelineEventType.fromValue('profile_created'), TimelineEventType.profileCreated);
      expect(TimelineEventType.fromValue('task_completed'), TimelineEventType.taskCompleted);
      expect(TimelineEventType.fromValue('waiting_started'), TimelineEventType.waitingStarted);
      // Giá trị lạ mặc định về note thay vì ném lỗi.
      expect(TimelineEventType.fromValue('unknown'), TimelineEventType.note);
    });
  });
}
