import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../models/models.dart';

/// Chip trạng thái việc cần làm — LUÔN có icon + chữ, không dựa duy nhất vào màu.
class TaskStatusBadge extends StatelessWidget {
  final TaskStatus status;
  final bool compact;

  const TaskStatusBadge({super.key, required this.status, this.compact = false});

  (Color, IconData) get _style {
    switch (status) {
      case TaskStatus.todo:
        return (AppColors.neutral, Icons.radio_button_unchecked_rounded);
      case TaskStatus.inProgress:
        return (AppColors.inProgress, Icons.autorenew_rounded);
      case TaskStatus.waiting:
        return (AppColors.waiting, Icons.hourglass_empty_rounded);
      case TaskStatus.completed:
        return (AppColors.completed, Icons.check_circle_rounded);
      case TaskStatus.cancelled:
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

/// Chip ưu tiên việc cần làm.
class TaskPriorityChip extends StatelessWidget {
  final TaskPriority priority;

  const TaskPriorityChip({super.key, required this.priority});

  Color get _color {
    switch (priority) {
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        priority.label,
        style: TextStyle(fontSize: 11, color: _color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
