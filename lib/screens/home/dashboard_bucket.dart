import '../../models/models.dart';

enum DashboardBucket {
  overdue('Quá hạn'),
  today('Hôm nay'),
  waiting('Đang chờ'),
  upcoming('Sắp tới'),
  noDeadline('Không có hạn');

  const DashboardBucket(this.label);

  final String label;

  String get emptyMessage => switch (this) {
    DashboardBucket.overdue => 'Không có hồ sơ quá hạn.',
    DashboardBucket.today => 'Không có hồ sơ đến hạn hôm nay.',
    DashboardBucket.waiting => 'Không có hồ sơ đang chờ.',
    DashboardBucket.upcoming => 'Không có hồ sơ sắp đến hạn.',
    DashboardBucket.noDeadline => 'Không có hồ sơ chưa đặt deadline.',
  };
}

/// Snapshot chỉ đọc dùng chung cho số đếm trên Dashboard và màn drill-down.
/// Các selector giữ nguyên định nghĩa production: năm stat card đều đếm hồ
/// sơ đang hoạt động, không cộng task.
class DashboardBuckets {
  DashboardBuckets._(this._items);

  factory DashboardBuckets.fromAggregates(
    Iterable<ProfileAggregate> aggregates,
  ) {
    final active = aggregates
        .where((item) => item.deadlineCategory != DeadlineCategory.completed)
        .toList();

    List<ProfileAggregate> sorted(
      Iterable<ProfileAggregate> source, {
      bool waiting = false,
    }) {
      final result = source.toList();
      result.sort((a, b) {
        if (waiting) {
          final aSince = a.profile.waitingSince;
          final bSince = b.profile.waitingSince;
          if (aSince != null && bSince != null) return aSince.compareTo(bSince);
          if (aSince != null) return -1;
          if (bSince != null) return 1;
        }
        final aDeadline = a.profile.deadline;
        final bDeadline = b.profile.deadline;
        if (aDeadline == null && bDeadline == null) {
          return a.profile.fullName.compareTo(b.profile.fullName);
        }
        if (aDeadline == null) return 1;
        if (bDeadline == null) return -1;
        return aDeadline.compareTo(bDeadline);
      });
      return List.unmodifiable(result);
    }

    return DashboardBuckets._({
      DashboardBucket.overdue: sorted(
        active.where(
          (item) => item.deadlineCategory == DeadlineCategory.overdue,
        ),
      ),
      DashboardBucket.today: sorted(
        active.where(
          (item) => item.deadlineCategory == DeadlineCategory.dueToday,
        ),
      ),
      DashboardBucket.waiting: sorted(
        active.where((item) => item.isWaiting),
        waiting: true,
      ),
      DashboardBucket.upcoming: sorted(
        active.where(
          (item) => item.deadlineCategory == DeadlineCategory.upcoming,
        ),
      ),
      DashboardBucket.noDeadline: sorted(
        active.where((item) => !item.profile.hasDeadline),
      ),
    });
  }

  final Map<DashboardBucket, List<ProfileAggregate>> _items;

  List<ProfileAggregate> items(DashboardBucket bucket) =>
      _items[bucket] ?? const [];

  int count(DashboardBucket bucket) => items(bucket).length;
}
