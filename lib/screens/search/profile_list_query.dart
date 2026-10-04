import '../../core/utils/vietnamese_utils.dart';
import '../../models/models.dart';

enum ProfileFilter {
  all,
  needsAction,
  overdue,
  today,
  upcoming,
  inProgress,
  waiting,
  noDeadline,
  completed,
}

extension ProfileFilterX on ProfileFilter {
  String get label => switch (this) {
    ProfileFilter.all => 'Tất cả',
    ProfileFilter.needsAction => 'Cần xử lý',
    ProfileFilter.overdue => 'Quá hạn',
    ProfileFilter.today => 'Hôm nay',
    ProfileFilter.upcoming => 'Sắp đến hạn',
    ProfileFilter.inProgress => 'Đang xử lý',
    ProfileFilter.waiting => 'Đang chờ',
    ProfileFilter.noDeadline => 'Không deadline',
    ProfileFilter.completed => 'Hoàn thành',
  };
}

enum ProfileSort {
  urgency('Ưu tiên deadline'),
  updatedNewest('Mới cập nhật'),
  nameAZ('Họ tên A–Z');

  const ProfileSort(this.label);
  final String label;
}

class ProfileListQuery {
  const ProfileListQuery._();

  static List<ProfileAggregate> apply({
    required Iterable<ProfileAggregate> source,
    String query = '',
    ProfileFilter filter = ProfileFilter.all,
    String? groupId,
    ProfileSort sort = ProfileSort.urgency,
  }) {
    final normalizedQuery = VietnameseUtils.removeDiacritics(query.trim());
    final results = source.where((item) {
      return _matchesQuery(item, normalizedQuery) &&
          _matchesFilter(item, filter) &&
          (groupId == null || item.profile.groupId == groupId);
    }).toList();

    results.sort(
      (a, b) => switch (sort) {
        ProfileSort.urgency => a.deadlineCategory.priority.compareTo(
          b.deadlineCategory.priority,
        ),
        ProfileSort.updatedNewest => b.profile.updatedAt.compareTo(
          a.profile.updatedAt,
        ),
        ProfileSort.nameAZ => VietnameseUtils.removeDiacritics(
          a.profile.fullName,
        ).compareTo(VietnameseUtils.removeDiacritics(b.profile.fullName)),
      },
    );
    return results;
  }

  static bool _matchesFilter(ProfileAggregate item, ProfileFilter filter) {
    return switch (filter) {
      ProfileFilter.all => true,
      ProfileFilter.needsAction =>
        item.deadlineCategory == DeadlineCategory.overdue ||
            item.deadlineCategory == DeadlineCategory.dueToday ||
            item.deadlineCategory == DeadlineCategory.upcoming ||
            item.deadlineCategory == DeadlineCategory.stalled ||
            item.isWaiting,
      ProfileFilter.overdue =>
        item.deadlineCategory == DeadlineCategory.overdue,
      ProfileFilter.today => item.deadlineCategory == DeadlineCategory.dueToday,
      ProfileFilter.upcoming =>
        item.deadlineCategory == DeadlineCategory.upcoming,
      ProfileFilter.inProgress =>
        item.profile.status == ProfileStatus.inProgress,
      ProfileFilter.waiting => item.profile.status == ProfileStatus.waiting,
      ProfileFilter.noDeadline => !item.profile.hasDeadline,
      ProfileFilter.completed => item.profile.status == ProfileStatus.completed,
    };
  }

  static bool _matchesQuery(ProfileAggregate item, String query) {
    if (query.isEmpty) return true;
    final profile = item.profile;
    bool has(Object? value) =>
        value != null &&
        VietnameseUtils.removeDiacritics(value.toString()).contains(query);
    final searchableValues = <Object?>[
      profile.fullName,
      profile.phone,
      profile.workTarget,
      profile.description,
      profile.citizenId,
      profile.rank,
      profile.position,
      profile.unit,
      profile.enlistment,
      profile.hometown,
      profile.currentResidence,
      profile.educationLevel,
      profile.specialty,
      profile.schoolHistory,
      profile.officerRating,
      profile.fatherFullName,
      profile.fatherBirthYear,
      profile.fatherOccupation,
      profile.fatherHometown,
      profile.fatherCurrentResidence,
      profile.motherFullName,
      profile.motherBirthYear,
      profile.motherOccupation,
      profile.motherHometown,
      profile.motherCurrentResidence,
      profile.aspiration1,
      profile.aspiration2,
      profile.aspiration3,
      profile.status.label,
      item.group?.name,
      ...profile.customFieldValues.values,
      for (final task in item.tasks) ...[
        task.title,
        task.description,
        task.status.label,
      ],
      if (item.group != null)
        for (final definition in item.group!.customFieldDefinitions)
          for (final option in definition.options)
            if (profile.customFieldValues[definition.id] == option.id)
              option.label,
    ];
    return searchableValues.any(has);
  }
}
