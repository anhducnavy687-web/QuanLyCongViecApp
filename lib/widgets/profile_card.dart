import 'package:flutter/material.dart';

import '../core/extensions/context_extensions.dart';
import '../core/utils/app_date_utils.dart';
import '../models/models.dart';
import '../screens/profiles/profile_detail_screen.dart';
import 'money_bar.dart';
import 'stage_progress_summary.dart';
import 'status_badge.dart';
import 'timeline_bar.dart';

/// Card hồ sơ dùng trên Dashboard, Danh sách nhóm, Kết quả tìm kiếm...
/// Thiết kế theo đúng mẫu trong spec: tên nổi bật -> đích công việc ->
/// trạng thái -> timeline -> tiền -> bước hiện tại.
class ProfileCard extends StatelessWidget {
  final ProfileAggregate aggregate;
  final bool showGroupLabel;

  const ProfileCard({super.key, required this.aggregate, this.showGroupLabel = false});

  @override
  Widget build(BuildContext context) {
    final profile = aggregate.profile;
    final finance = aggregate.finance;
    final category = aggregate.deadlineCategory;
    final colors = context.colors;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ProfileDetailScreen(profileId: profile.id)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.fullName.toUpperCase(),
                          style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.arrow_forward_rounded, size: 14, color: colors.onSurfaceVariant),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                profile.workTarget,
                                style: context.textTheme.bodyMedium?.copyWith(
                                  color: colors.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (showGroupLabel && aggregate.group != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        aggregate.group!.name,
                        style: context.textTheme.labelSmall,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  StatusBadge(status: profile.status),
                  if (category == DeadlineCategory.overdue ||
                      category == DeadlineCategory.dueToday ||
                      category == DeadlineCategory.upcoming)
                    DeadlineChip(
                      category: category,
                      text: AppDateUtils.describeDeadline(profile.deadline!),
                    ),
                  if (aggregate.overdueMilestoneCount > 0)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.notifications_active_rounded, size: 14, color: colors.error),
                        const SizedBox(width: 2),
                        Text(
                          '${aggregate.overdueMilestoneCount} mốc quá hạn',
                          style: TextStyle(fontSize: 11, color: colors.error, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 12),
              TimelineBar(
                startDate: profile.startDate,
                deadline: profile.deadline,
                hasDeadline: profile.hasDeadline,
              ),
              const SizedBox(height: 12),
              MoneyBar(received: finance.received, total: finance.totalAmount),
              const SizedBox(height: 10),
              StageProgressSummary(
                currentStage: aggregate.currentStage,
                completedCount: aggregate.completedStages.length,
                totalCount: aggregate.stages.length,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
