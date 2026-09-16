import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/extensions/context_extensions.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/app_date_utils.dart';
import '../../models/models.dart';
import '../../repositories/app_repository.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/offline_banner.dart';
import '../../widgets/profile_card.dart';
import '../../widgets/stat_pill.dart';
import '../profiles/profile_detail_screen.dart';
import '../search/search_screen.dart' show ProfileFilter, SearchScreen;
import '../tasks/tasks_screen.dart';

const List<String> _weekdayNames = [
  'Thứ Hai',
  'Thứ Ba',
  'Thứ Tư',
  'Thứ Năm',
  'Thứ Sáu',
  'Thứ Bảy',
  'Chủ Nhật',
];

String _greeting(DateTime now) {
  if (now.hour < 11) return 'Chào buổi sáng';
  if (now.hour < 13) return 'Chào buổi trưa';
  if (now.hour < 18) return 'Chào buổi chiều';
  return 'Chào buổi tối';
}

String _headerDate(DateTime now) {
  final weekday = _weekdayNames[now.weekday - 1];
  return '$weekday, ${AppDateUtils.formatDate(now)}';
}

/// Việc/hồ sơ đang "Đang chờ" — gộp chung cả hồ sơ lẫn task đang chờ để
/// hiển thị trên Dashboard theo đúng câu hỏi "chờ ai/cái gì, chờ bao lâu".
class _WaitingPreviewItem {
  final String title;
  final String? profileName;
  final String reason;
  final int daysWaiting;
  final DateTime? expectedResponseDate;
  final VoidCallback onTap;

  const _WaitingPreviewItem({
    required this.title,
    this.profileName,
    required this.reason,
    required this.daysWaiting,
    this.expectedResponseDate,
    required this.onTap,
  });
}

/// Màn hình quan trọng nhất của ứng dụng: cho người dùng biết NGAY công
/// việc nào cần xử lý trước, theo đúng thứ tự ưu tiên trong spec:
/// Quá hạn > Hôm nay > Đang chờ > Sắp tới > Không có hạn.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<AppRepository>();
    final all = repo.allAggregates;
    final now = DateTime.now();

    final active = all.where((a) => a.deadlineCategory != DeadlineCategory.completed).toList();
    final byCategory = <DeadlineCategory, List<ProfileAggregate>>{};
    for (final a in active) {
      byCategory.putIfAbsent(a.deadlineCategory, () => []).add(a);
    }
    for (final list in byCategory.values) {
      list.sort((a, b) {
        final da = a.profile.deadline;
        final db = b.profile.deadline;
        if (da == null && db == null) return 0;
        if (da == null) return 1;
        if (db == null) return -1;
        return da.compareTo(db);
      });
    }
    final doneList = all.where((a) => a.deadlineCategory == DeadlineCategory.completed).toList();

    final waitingCount = active.where((a) => a.isWaiting).length;
    final noDeadlineCount = active.where((a) => !a.profile.hasDeadline).length;

    final todayTasks = repo.allOpenTasks
        .where((t) => t.dueDate != null && AppDateUtils.isToday(t.dueDate!))
        .toList()
      ..sort((a, b) => b.priority.index.compareTo(a.priority.index));

    final overdueTasks = repo.allOpenTasks
        .where((t) => t.dueDate != null && AppDateUtils.isOverdue(t.dueDate!))
        .toList()
      ..sort((a, b) => b.dueDate!.compareTo(a.dueDate!));

    // "Đang chờ": gộp hồ sơ đang chờ + task đang chờ, ưu tiên chờ lâu nhất.
    final waitingItems = <_WaitingPreviewItem>[
      for (final a in active.where((a) => a.isWaiting))
        _WaitingPreviewItem(
          title: a.profile.fullName,
          reason: (a.profile.waitingReason?.isNotEmpty ?? false) ? a.profile.waitingReason! : 'Chưa rõ lý do',
          daysWaiting: a.profile.waitingSince != null
              ? AppDateUtils.daysSince(a.profile.waitingSince!, until: now)
              : 0,
          expectedResponseDate: a.profile.expectedResponseDate,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => ProfileDetailScreen(profileId: a.profile.id)),
          ),
        ),
      for (final t in repo.allOpenTasks.where((t) => t.status == TaskStatus.waiting))
        _WaitingPreviewItem(
          title: t.title,
          profileName: repo.profileById(t.profileId)?.fullName,
          reason: (t.waitingReason?.isNotEmpty ?? false) ? t.waitingReason! : 'Chưa rõ lý do',
          daysWaiting: t.waitingSince != null ? AppDateUtils.daysSince(t.waitingSince!, until: now) : 0,
          expectedResponseDate: t.expectedResponseDate,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => ProfileDetailScreen(profileId: t.profileId, initialTabIndex: 2)),
          ),
        ),
    ]..sort((a, b) => b.daysWaiting.compareTo(a.daysWaiting));

    // "Sắp tới": chia 2 nhóm 1-3 ngày / 4-7 ngày, chỉ để xem lướt — bấm
    // "Xem tất cả" để mở danh sách đầy đủ (SearchScreen với filter Sắp tới).
    final upcomingNear = byCategory[DeadlineCategory.upcoming] ?? const <ProfileAggregate>[];
    final upcomingFar = active.where((a) {
      final deadline = a.profile.deadline;
      if (!a.profile.hasDeadline || deadline == null) return false;
      final d = AppDateUtils.daysUntil(deadline, from: now);
      return d > 3 && d <= 7;
    }).toList()
      ..sort((a, b) => a.profile.deadline!.compareTo(b.profile.deadline!));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trang chủ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.checklist_rounded),
            tooltip: 'Việc cần làm',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const TasksScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.search_rounded),
            tooltip: 'Tìm kiếm',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SearchScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: repo.profiles.isEmpty
                ? EmptyState(
                    icon: Icons.inbox_rounded,
                    title: 'Chưa có hồ sơ nào',
                    message: 'Nhấn nút "Thêm hồ sơ" để bắt đầu quản lý công việc.',
                  )
                : ListView(
                    padding: const EdgeInsets.only(bottom: 100),
                    children: [
                      _DashboardHeader(now: now),
                      const SizedBox(height: 4),
                      SizedBox(
                        height: 100,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          children: [
                            StatPill(
                              label: 'Quá hạn',
                              value: '${byCategory[DeadlineCategory.overdue]?.length ?? 0}',
                              icon: Icons.error_rounded,
                              color: AppColors.overdue,
                              onTap: () => _openFilter(context, ProfileFilter.overdue),
                            ),
                            const SizedBox(width: 10),
                            StatPill(
                              label: 'Hôm nay',
                              value: '${byCategory[DeadlineCategory.dueToday]?.length ?? 0}',
                              icon: Icons.today_rounded,
                              color: AppColors.dueToday,
                              onTap: () => _openFilter(context, ProfileFilter.today),
                            ),
                            const SizedBox(width: 10),
                            StatPill(
                              label: 'Đang chờ',
                              value: '$waitingCount',
                              icon: Icons.hourglass_top_rounded,
                              color: AppColors.waiting,
                              onTap: () => _openFilter(context, ProfileFilter.waiting),
                            ),
                            const SizedBox(width: 10),
                            StatPill(
                              label: 'Sắp tới',
                              value: '${byCategory[DeadlineCategory.upcoming]?.length ?? 0}',
                              icon: Icons.schedule_rounded,
                              color: AppColors.upcoming,
                              onTap: () => _openFilter(context, ProfileFilter.upcoming),
                            ),
                            const SizedBox(width: 10),
                            StatPill(
                              label: 'Không có hạn',
                              value: '$noDeadlineCount',
                              icon: Icons.event_busy_rounded,
                              color: AppColors.neutral,
                              onTap: () => _openFilter(context, ProfileFilter.noDeadline),
                            ),
                          ],
                        ),
                      ),
                      if (todayTasks.isNotEmpty) ...[
                        const SizedBox(height: 18),
                        _TaskMiniListSection(
                          icon: Icons.checklist_rounded,
                          title: 'Việc hôm nay',
                          repo: repo,
                          tasks: todayTasks,
                        ),
                      ],
                      if (overdueTasks.isNotEmpty) ...[
                        const SizedBox(height: 18),
                        _TaskMiniListSection(
                          icon: Icons.error_rounded,
                          iconColor: AppColors.overdue,
                          title: 'Việc quá hạn',
                          repo: repo,
                          tasks: overdueTasks,
                          extraSubtitle: (t) =>
                              'Quá hạn ${-AppDateUtils.daysUntil(t.dueDate!)} ngày',
                        ),
                      ],
                      if (waitingItems.isNotEmpty) ...[
                        const SizedBox(height: 18),
                        _WaitingPreviewSection(
                          items: waitingItems.take(5).toList(),
                          onViewAll: () => _openFilter(context, ProfileFilter.waiting),
                        ),
                      ],
                      if (upcomingNear.isNotEmpty || upcomingFar.isNotEmpty) ...[
                        const SizedBox(height: 18),
                        _UpcomingPreviewSection(
                          near: upcomingNear.take(3).toList(),
                          far: upcomingFar.take(3).toList(),
                          onViewAll: () => _openFilter(context, ProfileFilter.upcoming),
                        ),
                      ],
                      const SizedBox(height: 8),
                      _Section(
                        category: DeadlineCategory.overdue,
                        items: byCategory[DeadlineCategory.overdue] ?? const [],
                      ),
                      _Section(
                        category: DeadlineCategory.dueToday,
                        items: byCategory[DeadlineCategory.dueToday] ?? const [],
                      ),
                      _Section(
                        category: DeadlineCategory.upcoming,
                        items: byCategory[DeadlineCategory.upcoming] ?? const [],
                      ),
                      _Section(
                        category: DeadlineCategory.stalled,
                        items: byCategory[DeadlineCategory.stalled] ?? const [],
                      ),
                      _Section(
                        category: DeadlineCategory.normal,
                        items: byCategory[DeadlineCategory.normal] ?? const [],
                      ),
                      if (doneList.isNotEmpty)
                        _CollapsedSection(title: 'Đã hoàn thành / Đã hủy', items: doneList),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

void _openFilter(BuildContext context, ProfileFilter filter) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => SearchScreen(initialFilter: filter, autofocusSearch: false),
    ),
  );
}

ProfileFilter _filterForCategory(DeadlineCategory category) {
  switch (category) {
    case DeadlineCategory.overdue:
      return ProfileFilter.overdue;
    case DeadlineCategory.dueToday:
      return ProfileFilter.today;
    case DeadlineCategory.upcoming:
      return ProfileFilter.upcoming;
    case DeadlineCategory.stalled:
      return ProfileFilter.noDeadline;
    case DeadlineCategory.normal:
      return ProfileFilter.inProgress;
    case DeadlineCategory.completed:
      return ProfileFilter.completed;
  }
}

class _DashboardHeader extends StatelessWidget {
  final DateTime now;

  const _DashboardHeader({required this.now});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _greeting(now),
            style: context.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            _headerDate(now),
            style: context.textTheme.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

/// Danh sách rút gọn các task (dùng chung cho "Việc hôm nay" và "Việc quá
/// hạn") — mỗi dòng có checkbox hoàn thành nhanh, tên việc, tên hồ sơ, mức
/// ưu tiên. [extraSubtitle] cho phép chèn thêm thông tin (VD: số ngày quá
/// hạn) vào dòng phụ.
class _TaskMiniListSection extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final AppRepository repo;
  final List<TaskItem> tasks;
  final String Function(TaskItem task)? extraSubtitle;

  const _TaskMiniListSection({
    required this.icon,
    this.iconColor,
    required this.title,
    required this.repo,
    required this.tasks,
    this.extraSubtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Row(
            children: [
              Icon(icon, size: 18, color: iconColor ?? context.colors.primary),
              const SizedBox(width: 8),
              Text(
                '$title (${tasks.length})',
                style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        ...tasks.map((t) => _TaskMiniTile(
              repo: repo,
              task: t,
              extraSubtitle: extraSubtitle?.call(t),
            )),
      ],
    );
  }
}

class _TaskMiniTile extends StatelessWidget {
  final AppRepository repo;
  final TaskItem task;
  final String? extraSubtitle;

  const _TaskMiniTile({required this.repo, required this.task, this.extraSubtitle});

  Color _priorityColor() {
    switch (task.priority) {
      case TaskPriority.urgent:
        return AppColors.overdue;
      case TaskPriority.high:
        return AppColors.upcoming;
      case TaskPriority.normal:
        return AppColors.inProgress;
      case TaskPriority.low:
        return AppColors.neutral;
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = repo.profileById(task.profileId);
    final subtitleParts = [
      if (profile != null) profile.fullName,
      ?extraSubtitle,
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Card(
        child: ListTile(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => ProfileDetailScreen(profileId: task.profileId, initialTabIndex: 2)),
          ),
          leading: Checkbox(
            value: false,
            onChanged: (_) => repo.markTaskCompleted(task.id),
          ),
          title: Text(task.title, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(
            subtitleParts.join(' • '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _priorityColor().withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              task.priority.label,
              style: TextStyle(fontSize: 11, color: _priorityColor(), fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }
}

/// "Đang chờ": chờ ai/cái gì, chờ từ bao lâu, ngày dự kiến phản hồi nếu có.
class _WaitingPreviewSection extends StatelessWidget {
  final List<_WaitingPreviewItem> items;
  final VoidCallback onViewAll;

  const _WaitingPreviewSection({required this.items, required this.onViewAll});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Row(
            children: [
              Icon(Icons.hourglass_top_rounded, size: 18, color: AppColors.waiting),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Đang chờ (${items.length})',
                  style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              TextButton(onPressed: onViewAll, child: const Text('Xem tất cả')),
            ],
          ),
        ),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Card(
                child: ListTile(
                  onTap: item.onTap,
                  leading: Icon(Icons.hourglass_top_rounded, color: AppColors.waiting),
                  title: Text(
                    item.profileName != null ? '${item.title} — ${item.profileName}' : item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${item.reason} — ${item.daysWaiting} ngày'
                    '${item.expectedResponseDate != null ? ' • Dự kiến ${AppDateUtils.formatDate(item.expectedResponseDate)}' : ''}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            )),
      ],
    );
  }
}

/// "Sắp tới": deadline gần nhất, chia 2 nhóm 1-3 ngày / 4-7 ngày để dễ quét.
class _UpcomingPreviewSection extends StatelessWidget {
  final List<ProfileAggregate> near;
  final List<ProfileAggregate> far;
  final VoidCallback onViewAll;

  const _UpcomingPreviewSection({required this.near, required this.far, required this.onViewAll});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
          child: Row(
            children: [
              Icon(Icons.schedule_rounded, size: 18, color: AppColors.upcoming),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Sắp tới',
                  style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              TextButton(onPressed: onViewAll, child: const Text('Xem tất cả')),
            ],
          ),
        ),
        if (near.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: Text('1–3 ngày', style: context.textTheme.labelMedium?.copyWith(color: context.colors.onSurfaceVariant)),
          ),
          ...near.map((a) => _UpcomingPreviewTile(aggregate: a)),
        ],
        if (far.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: Text('4–7 ngày', style: context.textTheme.labelMedium?.copyWith(color: context.colors.onSurfaceVariant)),
          ),
          ...far.map((a) => _UpcomingPreviewTile(aggregate: a)),
        ],
      ],
    );
  }
}

class _UpcomingPreviewTile extends StatelessWidget {
  final ProfileAggregate aggregate;

  const _UpcomingPreviewTile({required this.aggregate});

  @override
  Widget build(BuildContext context) {
    final profile = aggregate.profile;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Card(
        child: ListTile(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => ProfileDetailScreen(profileId: profile.id)),
          ),
          title: Text(profile.fullName, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(profile.workTarget, maxLines: 1, overflow: TextOverflow.ellipsis),
          trailing: Text(
            AppDateUtils.describeDeadline(profile.deadline!),
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.upcoming),
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final DeadlineCategory category;
  final List<ProfileAggregate> items;

  const _Section({required this.category, required this.items});

  Color get _color {
    switch (category) {
      case DeadlineCategory.overdue:
        return AppColors.overdue;
      case DeadlineCategory.dueToday:
        return AppColors.dueToday;
      case DeadlineCategory.upcoming:
        return AppColors.upcoming;
      case DeadlineCategory.stalled:
        return AppColors.stalled;
      case DeadlineCategory.normal:
        return AppColors.inProgress;
      case DeadlineCategory.completed:
        return AppColors.completed;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => _openFilter(context, _filterForCategory(category)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
            child: Row(
              children: [
                Container(width: 4, height: 16, color: _color),
                const SizedBox(width: 8),
                Text(
                  '${category.label} (${items.length})',
                  style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right_rounded, size: 18, color: context.colors.onSurfaceVariant),
              ],
            ),
          ),
        ),
        ...items.map((a) => Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: ProfileCard(aggregate: a, showGroupLabel: true),
            )),
      ],
    );
  }
}

class _CollapsedSection extends StatelessWidget {
  final String title;
  final List<ProfileAggregate> items;

  const _CollapsedSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        title: Text('$title (${items.length})', style: const TextStyle(fontWeight: FontWeight.bold)),
        childrenPadding: const EdgeInsets.only(bottom: 8),
        children: items
            .map((a) => Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: ProfileCard(aggregate: a, showGroupLabel: true),
                ))
            .toList(),
      ),
    );
  }
}
