import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/datetime_extensions.dart';
import '../../../models/models.dart';
import '../../../widgets/status_badge.dart';

class ProfileDetailHeader extends StatelessWidget {
  const ProfileDetailHeader({
    super.key,
    required this.aggregate,
    required this.onEdit,
  });
  final ProfileAggregate aggregate;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final profile = aggregate.profile;
    return Material(
      color: context.colors.surfaceContainerLow,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1040),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.fullName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          StatusBadge(status: profile.status),
                          if (aggregate.group != null)
                            _MetaChip(
                              icon: Icons.folder_outlined,
                              label: aggregate.group!.name,
                            ),
                          _MetaChip(
                            icon: profile.hasDeadline
                                ? Icons.event_outlined
                                : Icons.play_circle_outline_rounded,
                            label:
                                profile.hasDeadline && profile.deadline != null
                                ? '${aggregate.deadlineCategory.label} · ${profile.deadline!.ddMMyyyy}'
                                : 'Bắt đầu ${profile.startDate.ddMMyyyy}',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  key: const Key('profileDetailEditButton'),
                  tooltip: 'Sửa hồ sơ',
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(maxWidth: 300),
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: context.colors.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15),
        const SizedBox(width: 5),
        Flexible(
          child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ],
    ),
  );
}
