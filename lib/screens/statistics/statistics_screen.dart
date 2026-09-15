import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/extensions/context_extensions.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/money_utils.dart';
import '../../models/models.dart';
import '../../repositories/app_repository.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<AppRepository>();
    final aggregates = repo.allAggregates;

    final total = aggregates.length;
    final inProgress = aggregates.where((a) => a.profile.status == ProfileStatus.inProgress).length;
    final waiting = aggregates.where((a) => a.profile.status == ProfileStatus.waiting).length;
    final overdue = aggregates.where((a) => a.deadlineCategory == DeadlineCategory.overdue).length;
    final completed = aggregates.where((a) => a.profile.status == ProfileStatus.completed).length;

    num totalAmount = 0, received = 0, expense = 0, commissionTotal = 0, commissionPaid = 0;
    for (final a in aggregates) {
      final f = a.finance;
      totalAmount += f.totalAmount;
      received += f.received;
      expense += f.expense;
      commissionTotal += f.commissionTotal;
      commissionPaid += f.commissionPaid;
    }
    final remainingToReceive = totalAmount - received < 0 ? 0 : totalAmount - received;
    final commissionRemaining = commissionTotal - commissionPaid < 0 ? 0 : commissionTotal - commissionPaid;

    return Scaffold(
      appBar: AppBar(title: const Text('Thống kê')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: [
          Text('Hồ sơ', style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.15,
            children: [
              _StatCard(label: 'Tổng hồ sơ', value: '$total', color: AppColors.neutral, icon: Icons.folder_copy_outlined),
              _StatCard(label: 'Đang xử lý', value: '$inProgress', color: AppColors.inProgress, icon: Icons.autorenew_rounded),
              _StatCard(label: 'Đang chờ', value: '$waiting', color: AppColors.waiting, icon: Icons.hourglass_empty_rounded),
              _StatCard(label: 'Quá hạn', value: '$overdue', color: AppColors.overdue, icon: Icons.error_outline_rounded),
              _StatCard(label: 'Hoàn thành', value: '$completed', color: AppColors.completed, icon: Icons.check_circle_outline_rounded),
            ],
          ),
          const SizedBox(height: 24),
          Text('Tài chính', style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _moneyRow(context, 'Tổng tiền', totalAmount, AppColors.neutral),
                  _moneyRow(context, 'Đã nhận', received, AppColors.completed),
                  _moneyRow(context, 'Còn phải nhận', remainingToReceive, AppColors.overdue),
                  const Divider(height: 24),
                  _moneyRow(context, 'Chi phí', expense, AppColors.stalled),
                  const Divider(height: 24),
                  _moneyRow(context, 'Hoa hồng cộng tác viên', commissionTotal, AppColors.waiting),
                  _moneyRow(context, 'Hoa hồng đã trả', commissionPaid, AppColors.inProgress),
                  _moneyRow(context, 'Hoa hồng còn lại', commissionRemaining, AppColors.overdue),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Theo nhóm', style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ...repo.groups.map((g) {
            final inGroup = aggregates.where((a) => a.profile.groupId == g.id).toList();
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(g.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('${inGroup.length} hồ sơ'),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _moneyRow(BuildContext context, String label, num value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(MoneyUtils.format(value), style: TextStyle(fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  const _StatCard({required this.label, required this.value, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
              Text(label, style: TextStyle(fontSize: 11.5, color: color.withValues(alpha: 0.85))),
            ],
          ),
        ],
      ),
    );
  }
}
