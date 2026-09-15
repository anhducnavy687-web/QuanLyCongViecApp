import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../models/models.dart';

/// Chip trạng thái hồ sơ — LUÔN có icon + chữ, không dựa duy nhất vào màu.
class StatusBadge extends StatelessWidget {
  final ProfileStatus status;
  final bool compact;

  const StatusBadge({super.key, required this.status, this.compact = false});

  (Color, IconData) get _style {
    switch (status) {
      case ProfileStatus.newProfile:
        return (AppColors.neutral, Icons.fiber_new_rounded);
      case ProfileStatus.inProgress:
        return (AppColors.inProgress, Icons.autorenew_rounded);
      case ProfileStatus.waiting:
        return (AppColors.waiting, Icons.hourglass_empty_rounded);
      case ProfileStatus.completed:
        return (AppColors.completed, Icons.check_circle_rounded);
      case ProfileStatus.cancelled:
        return (AppColors.cancelled, Icons.cancel_rounded);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (color, icon) = _style;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 10, vertical: compact ? 2 : 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 12 : 14, color: color),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: compact ? 11 : 12,
            ),
          ),
        ],
      ),
    );
  }
}

/// Chip cảnh báo hạn (quá hạn / hôm nay / sắp đến hạn / trì trệ).
class DeadlineChip extends StatelessWidget {
  final DeadlineCategory category;
  final String text;

  const DeadlineChip({super.key, required this.category, required this.text});

  (Color, IconData) get _style {
    switch (category) {
      case DeadlineCategory.overdue:
        return (AppColors.overdue, Icons.error_rounded);
      case DeadlineCategory.dueToday:
        return (AppColors.dueToday, Icons.today_rounded);
      case DeadlineCategory.upcoming:
        return (AppColors.upcoming, Icons.schedule_rounded);
      case DeadlineCategory.stalled:
        return (AppColors.stalled, Icons.hourglass_bottom_rounded);
      case DeadlineCategory.completed:
        return (AppColors.completed, Icons.check_circle_rounded);
      case DeadlineCategory.normal:
        return (AppColors.neutral, Icons.circle_outlined);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (color, icon) = _style;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12),
        ),
      ],
    );
  }
}
