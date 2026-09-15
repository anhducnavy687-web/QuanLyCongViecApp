import 'package:flutter/material.dart';

import '../core/extensions/datetime_extensions.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/app_date_utils.dart';

/// Dải thời gian "Ngày bắt đầu -> Hôm nay -> Deadline" dùng trên card hồ sơ.
/// Nếu KHÔNG có deadline, hiển thị "Đã bắt đầu N ngày" thay vì im lặng bỏ
/// qua, để người dùng nhận biết công việc có thể đang bị kéo dài.
class TimelineBar extends StatelessWidget {
  final DateTime startDate;
  final DateTime? deadline;
  final bool hasDeadline;

  const TimelineBar({
    super.key,
    required this.startDate,
    required this.deadline,
    required this.hasDeadline,
  });

  @override
  Widget build(BuildContext context) {
    if (!hasDeadline || deadline == null) {
      return Row(
        children: [
          Icon(Icons.timelapse_rounded, size: 16, color: AppColors.stalled),
          const SizedBox(width: 6),
          Text(
            AppDateUtils.describeStartedWithoutDeadline(startDate),
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppColors.stalled,
            ),
          ),
        ],
      );
    }

    final today = DateTime.now();
    final totalSpan = deadline!.difference(startDate).inHours;
    double progress;
    if (totalSpan <= 0) {
      progress = 1;
    } else {
      final elapsed = today.difference(startDate).inHours;
      progress = (elapsed / totalSpan).clamp(0.0, 1.0);
    }

    final isOverdue = AppDateUtils.isOverdue(deadline!);
    final barColor = isOverdue ? AppColors.overdue : AppColors.inProgress;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(startDate.ddMM, style: const TextStyle(fontSize: 11.5, color: Colors.grey)),
            Text(deadline!.ddMM, style: const TextStyle(fontSize: 11.5, color: Colors.grey)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Stack(
            children: [
              Container(height: 6, color: barColor.withValues(alpha: 0.15)),
              FractionallySizedBox(
                widthFactor: progress,
                child: Container(height: 6, color: barColor),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          AppDateUtils.describeDeadline(deadline!),
          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: barColor),
        ),
      ],
    );
  }
}
