import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/extensions/context_extensions.dart';
import '../../core/theme/app_colors.dart';
import '../../models/models.dart';
import '../../repositories/app_repository.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/offline_banner.dart';
import '../../widgets/profile_card.dart';
import '../../widgets/stat_pill.dart';
import '../search/search_screen.dart';

/// Màn hình quan trọng nhất của ứng dụng: cho người dùng biết NGAY công
/// việc nào cần xử lý trước, theo đúng thứ tự ưu tiên trong spec:
/// Quá hạn > Hôm nay > Sắp đến hạn > Trì trệ/Không có deadline > Bình thường.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<AppRepository>();
    final all = repo.allAggregates;

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

    num remainingToReceive = 0;
    for (final a in all) {
      remainingToReceive += a.finance.remainingToReceive;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trang chủ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
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
                      const SizedBox(height: 12),
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
                            ),
                            const SizedBox(width: 10),
                            StatPill(
                              label: 'Hôm nay',
                              value: '${byCategory[DeadlineCategory.dueToday]?.length ?? 0}',
                              icon: Icons.today_rounded,
                              color: AppColors.dueToday,
                            ),
                            const SizedBox(width: 10),
                            StatPill(
                              label: 'Sắp đến hạn',
                              value: '${byCategory[DeadlineCategory.upcoming]?.length ?? 0}',
                              icon: Icons.schedule_rounded,
                              color: AppColors.upcoming,
                            ),
                            const SizedBox(width: 10),
                            StatPill(
                              label: 'Trì trệ',
                              value: '${byCategory[DeadlineCategory.stalled]?.length ?? 0}',
                              icon: Icons.hourglass_bottom_rounded,
                              color: AppColors.stalled,
                            ),
                            const SizedBox(width: 10),
                            StatPill(
                              label: 'Còn phải nhận',
                              value: _compactMoney(remainingToReceive),
                              icon: Icons.account_balance_wallet_rounded,
                              color: AppColors.inProgress,
                            ),
                          ],
                        ),
                      ),
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

  String _compactMoney(num v) {
    if (v >= 1000000000) return '${(v / 1000000000).toStringAsFixed(1)}tỷ';
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(0)}tr';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}k';
    return v.toStringAsFixed(0);
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
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
          child: Row(
            children: [
              Container(width: 4, height: 16, color: _color),
              const SizedBox(width: 8),
              Text(
                '${category.label} (${items.length})',
                style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
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
