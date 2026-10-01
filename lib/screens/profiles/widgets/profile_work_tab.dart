import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/datetime_extensions.dart';
import '../../../repositories/app_repository.dart';
import '../../../widgets/milestone_section.dart';
import '../../../widgets/section_card.dart';
import '../../../widgets/stage_step_list.dart';
import '../../../widgets/status_badge.dart';
import '../../../widgets/task_list_section.dart';

class ProfileWorkTab extends StatelessWidget {
  const ProfileWorkTab({super.key, required this.profileId});
  final String profileId;

  @override
  Widget build(BuildContext context) {
    final aggregate = context.watch<AppRepository>().aggregateOf(profileId);
    final profile = aggregate.profile;
    return _WorkScrollView(
      children: [
        SectionCard(
          title: 'Quy trình xử lý',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 14,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  StatusBadge(status: profile.status),
                  _WorkflowItem(
                    label: 'Bắt đầu',
                    value: profile.startDate.ddMMyyyy,
                  ),
                  _WorkflowItem(
                    label: 'Deadline',
                    value: profile.hasDeadline && profile.deadline != null
                        ? profile.deadline!.ddMMyyyy
                        : 'Không có',
                  ),
                  _WorkflowItem(
                    label: 'Bước hiện tại',
                    value: aggregate.currentStage?.name ?? 'Chưa có',
                  ),
                ],
              ),
              if (aggregate.isWaiting) ...[
                const Divider(height: 24),
                Text(
                  'Đang chờ phản hồi',
                  style: context.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (profile.waitingReason?.isNotEmpty == true)
                  Text(profile.waitingReason!),
                if (profile.waitingSince != null)
                  Text('Chờ từ ${profile.waitingSince!.ddMMyyyy}'),
                if (profile.expectedResponseDate != null)
                  Text(
                    'Dự kiến phản hồi ${profile.expectedResponseDate!.ddMMyyyy}',
                  ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        StageStepList(profileId: profileId),
        const SizedBox(height: 12),
        TaskListSection(profileId: profileId),
        const SizedBox(height: 12),
        MilestoneSection(profileId: profileId),
      ],
    );
  }
}

class _WorkflowItem extends StatelessWidget {
  const _WorkflowItem({required this.label, required this.value});
  final String label, value;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: context.textTheme.labelSmall),
      Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
    ],
  );
}

class _WorkScrollView extends StatelessWidget {
  const _WorkScrollView({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 840),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: children,
      ),
    ),
  );
}
