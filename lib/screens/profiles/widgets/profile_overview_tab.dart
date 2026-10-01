import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/utils/money_utils.dart';
import '../../../models/models.dart';
import '../../../repositories/app_repository.dart';
import '../../../widgets/section_card.dart';

class ProfileOverviewTab extends StatelessWidget {
  const ProfileOverviewTab({super.key, required this.profileId});
  final String profileId;

  @override
  Widget build(BuildContext context) {
    final aggregate = context.watch<AppRepository>().aggregateOf(profileId);
    final profile = aggregate.profile;
    final finance = aggregate.finance;
    final completedTasks = aggregate.tasks
        .where((task) => task.status == TaskStatus.completed)
        .length;
    final attention = <String>[
      if (aggregate.deadlineCategory == DeadlineCategory.overdue)
        'Hồ sơ đã quá hạn xử lý.',
      if (aggregate.overdueTaskCount > 0)
        '${aggregate.overdueTaskCount} việc cần làm đã quá hạn.',
      if (aggregate.todayTasks.isNotEmpty)
        '${aggregate.todayTasks.length} việc cần xử lý hôm nay.',
      if (aggregate.isWaiting)
        profile.waitingReason?.trim().isNotEmpty == true
            ? 'Đang chờ: ${profile.waitingReason}'
            : 'Hồ sơ đang chờ phản hồi.',
    ];

    return _DetailScrollView(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = constraints.maxWidth < 600
                ? constraints.maxWidth
                : (constraints.maxWidth - 12) / 2;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
            _SummaryCard(
              width: cardWidth,
              icon: Icons.route_outlined,
              title: 'TIẾN ĐỘ',
              primary: aggregate.currentStage?.name ?? 'Chưa có bước hiện tại',
              secondary:
                  '$completedTasks/${aggregate.tasks.length} việc đã hoàn thành',
            ),
            _SummaryCard(
              width: cardWidth,
              icon: Icons.schedule_outlined,
              title: 'THỜI GIAN',
              primary: aggregate.deadlineCategory.label,
              secondary: profile.hasDeadline && profile.deadline != null
                  ? 'Theo deadline của hồ sơ'
                  : 'Không đặt deadline',
            ),
            _SummaryCard(
              width: cardWidth,
              icon: Icons.account_balance_wallet_outlined,
              title: 'TÀI CHÍNH',
              primary: MoneyUtils.format(finance.totalAmount),
              secondary:
                  'Đã nhận ${MoneyUtils.format(finance.received)} · Còn ${MoneyUtils.format(finance.remainingToReceive)}',
            ),
            if (aggregate.assignments.isNotEmpty)
              _SummaryCard(
                width: cardWidth,
                icon: Icons.groups_outlined,
                title: 'CỘNG TÁC VIÊN',
                primary: '${aggregate.assignments.length} phân công',
                secondary:
                    'Còn trả ${MoneyUtils.format(finance.commissionRemaining)}',
              ),
              ],
            );
          },
        ),
        if (attention.isNotEmpty) ...[
          const SizedBox(height: 14),
          SectionCard(
            title: 'Cần chú ý',
            child: Column(
              children: [
                for (final message in attention)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      Icons.warning_amber_rounded,
                      color: context.colors.error,
                    ),
                    title: Text(message),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.width,
    required this.icon,
    required this.title,
    required this.primary,
    required this.secondary,
  });
  final double width;
  final IconData icon;
  final String title, primary, secondary;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: context.colors.primary),
                const SizedBox(width: 7),
                Text(title, style: context.textTheme.labelMedium),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              primary,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 3),
            Text(secondary, style: context.textTheme.bodySmall),
          ],
        ),
      ),
    ),
  );
}

class _DetailScrollView extends StatelessWidget {
  const _DetailScrollView({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1040),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: children,
      ),
    ),
  );
}
