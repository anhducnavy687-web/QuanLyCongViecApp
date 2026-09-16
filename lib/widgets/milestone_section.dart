import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/extensions/context_extensions.dart';
import '../core/extensions/datetime_extensions.dart';
import '../core/theme/app_colors.dart';
import '../models/models.dart';
import '../repositories/app_repository.dart';
import 'section_card.dart';

class MilestoneSection extends StatelessWidget {
  final String profileId;
  const MilestoneSection({super.key, required this.profileId});

  (Color, IconData) _style(MilestoneTiming timing) {
    switch (timing) {
      case MilestoneTiming.overdue:
        return (AppColors.overdue, Icons.error_rounded);
      case MilestoneTiming.today:
        return (AppColors.dueToday, Icons.today_rounded);
      case MilestoneTiming.upcoming:
        return (AppColors.upcoming, Icons.schedule_rounded);
      case MilestoneTiming.completed:
        return (AppColors.completed, Icons.check_circle_rounded);
      case MilestoneTiming.normal:
        return (Colors.grey, Icons.circle_outlined);
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<AppRepository>();
    final milestones = repo.milestonesOf(profileId);

    return SectionCard(
      title: 'Mốc thời gian',
      trailing: IconButton(
        icon: const Icon(Icons.add_rounded),
        tooltip: 'Thêm mốc thời gian',
        onPressed: () => _showEditDialog(context, repo, null),
      ),
      child: milestones.isEmpty
          ? Text('Chưa có mốc thời gian nào', style: context.textTheme.bodySmall)
          : Column(
              children: milestones.map((m) {
                final timing = m.timing();
                final (color, icon) = _style(timing);
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(icon, color: color),
                  title: Text(
                    m.title,
                    style: TextStyle(
                      decoration: m.status == MilestoneStatus.completed
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  subtitle: Text(
                    m.dueDate.ddMMyyyy,
                    style: TextStyle(color: color, fontWeight: FontWeight.w600),
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (v) {
                      if (v == 'toggle') {
                        repo.updateMilestone(m.copyWith(
                          status: m.status == MilestoneStatus.completed
                              ? MilestoneStatus.pending
                              : MilestoneStatus.completed,
                          completedAt: m.status == MilestoneStatus.completed ? null : DateTime.now(),
                          clearCompletedAt: m.status != MilestoneStatus.completed ? false : true,
                        ));
                      } else if (v == 'edit') {
                        _showEditDialog(context, repo, m);
                      } else if (v == 'delete') {
                        repo.deleteMilestone(m.id);
                      }
                    },
                    itemBuilder: (ctx) => [
                      PopupMenuItem(
                        value: 'toggle',
                        child: Text(m.status == MilestoneStatus.completed
                            ? 'Bỏ đánh dấu hoàn thành'
                            : 'Đánh dấu hoàn thành'),
                      ),
                      const PopupMenuItem(value: 'edit', child: Text('Sửa')),
                      const PopupMenuItem(value: 'delete', child: Text('Xóa')),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  void _showEditDialog(BuildContext context, AppRepository repo, Milestone? milestone) {
    final ctrl = TextEditingController(text: milestone?.title ?? '');
    DateTime dueDate = milestone?.dueDate ?? DateTime.now();
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(milestone == null ? 'Thêm mốc thời gian' : 'Sửa mốc thời gian'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: ctrl,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Tên mốc'),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: dueDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setState(() => dueDate = picked);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Ngày đến hạn'),
                  child: Text(dueDate.ddMMyyyy),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
            FilledButton(
              onPressed: () {
                final title = ctrl.text.trim();
                if (title.isEmpty) return;
                if (milestone == null) {
                  repo.addMilestone(Milestone(
                    id: '',
                    profileId: profileId,
                    title: title,
                    dueDate: dueDate,
                  ));
                } else {
                  repo.updateMilestone(milestone.copyWith(title: title, dueDate: dueDate));
                }
                Navigator.pop(ctx);
              },
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
  }
}
