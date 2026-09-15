import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../models/models.dart';

/// Dòng tóm tắt bước hiện tại trên card hồ sơ — thay thế hoàn toàn cho việc
/// hiển thị phần trăm tiến độ.
class StageProgressSummary extends StatelessWidget {
  final WorkStage? currentStage;
  final int completedCount;
  final int totalCount;

  const StageProgressSummary({
    super.key,
    required this.currentStage,
    required this.completedCount,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    if (currentStage == null) {
      return Row(
        children: [
          const Icon(Icons.flag_rounded, size: 16, color: AppColors.completed),
          const SizedBox(width: 6),
          Text(
            'Đã hoàn thành tất cả $totalCount bước',
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.completed),
          ),
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.play_circle_outline_rounded, size: 16, color: AppColors.inProgress),
        const SizedBox(width: 6),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: DefaultTextStyle.of(context).style.copyWith(fontSize: 12.5),
              children: [
                const TextSpan(
                  text: 'Đang thực hiện: ',
                  style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
                ),
                TextSpan(
                  text: currentStage!.name,
                  style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.inProgress),
                ),
                TextSpan(
                  text: '  (Bước ${completedCount + 1}/$totalCount)',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
