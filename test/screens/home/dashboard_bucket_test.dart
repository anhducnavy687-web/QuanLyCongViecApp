import 'package:flutter_test/flutter_test.dart';
import 'package:quanlycongviecapp/models/models.dart';
import 'package:quanlycongviecapp/screens/home/dashboard_bucket.dart';

ProfileAggregate _aggregate({
  required String id,
  required DateTime now,
  DateTime? deadline,
  bool hasDeadline = true,
  ProfileStatus status = ProfileStatus.inProgress,
  DateTime? waitingSince,
  List<TaskItem> tasks = const [],
}) {
  return ProfileAggregate(
    profile: Profile(
      id: id,
      groupId: 'group',
      fullName: 'Hồ sơ $id',
      workTarget: 'Mục tiêu $id',
      startDate: now.subtract(const Duration(days: 10)),
      deadline: deadline,
      hasDeadline: hasDeadline,
      status: status,
      waitingSince: waitingSince,
      createdAt: now,
      updatedAt: now,
    ),
    tasks: tasks,
  );
}

void main() {
  test('năm bucket giữ đúng định nghĩa hồ sơ production', () {
    final now = DateTime.now();
    final openTask = TaskItem(
      id: 'task-overdue',
      profileId: 'normal',
      title: 'Task quá hạn không được cộng vào stat hồ sơ',
      dueDate: now.subtract(const Duration(days: 2)),
      createdAt: now,
      updatedAt: now,
    );
    final aggregates = [
      _aggregate(
        id: 'overdue',
        now: now,
        deadline: now.subtract(const Duration(days: 1)),
      ),
      _aggregate(id: 'today', now: now, deadline: now),
      _aggregate(
        id: 'waiting',
        now: now,
        deadline: now.add(const Duration(days: 20)),
        status: ProfileStatus.waiting,
        waitingSince: now.subtract(const Duration(days: 4)),
      ),
      _aggregate(
        id: 'upcoming',
        now: now,
        deadline: now.add(const Duration(days: 2)),
      ),
      _aggregate(
        id: 'no-deadline',
        now: now,
        hasDeadline: false,
      ),
      _aggregate(
        id: 'normal',
        now: now,
        deadline: now.add(const Duration(days: 20)),
        tasks: [openTask],
      ),
      _aggregate(
        id: 'completed',
        now: now,
        deadline: now.subtract(const Duration(days: 2)),
        status: ProfileStatus.completed,
      ),
      _aggregate(
        id: 'cancelled-no-deadline',
        now: now,
        hasDeadline: false,
        status: ProfileStatus.cancelled,
      ),
    ];

    final buckets = DashboardBuckets.fromAggregates(aggregates);

    expect(buckets.items(DashboardBucket.overdue).single.profile.id, 'overdue');
    expect(buckets.items(DashboardBucket.today).single.profile.id, 'today');
    expect(buckets.items(DashboardBucket.waiting).single.profile.id, 'waiting');
    expect(buckets.items(DashboardBucket.upcoming).single.profile.id, 'upcoming');
    expect(
      buckets.items(DashboardBucket.noDeadline).single.profile.id,
      'no-deadline',
    );
    for (final bucket in DashboardBucket.values) {
      expect(buckets.count(bucket), buckets.items(bucket).length);
    }
  });

  test('bucket rỗng trả danh sách rỗng và empty message cụ thể', () {
    final buckets = DashboardBuckets.fromAggregates(const []);

    for (final bucket in DashboardBucket.values) {
      expect(buckets.count(bucket), 0);
      expect(buckets.items(bucket), isEmpty);
      expect(bucket.emptyMessage, isNotEmpty);
    }
  });
}
