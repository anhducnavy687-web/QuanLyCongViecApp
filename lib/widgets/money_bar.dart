import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/utils/money_utils.dart';

/// Thanh trực quan hiển thị "Đã nhận / Tổng tiền" — KHÔNG dùng phần trăm.
class MoneyBar extends StatelessWidget {
  final num received;
  final num total;

  const MoneyBar({super.key, required this.received, required this.total});

  @override
  Widget build(BuildContext context) {
    final ratio = MoneyUtils.ratio(received, total);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Stack(
            children: [
              Container(height: 8, color: AppColors.completed.withValues(alpha: 0.15)),
              FractionallySizedBox(
                widthFactor: ratio,
                child: Container(height: 8, color: AppColors.completed),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: MoneyUtils.format(received),
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
              const TextSpan(text: '  /  ', style: TextStyle(color: Colors.grey)),
              TextSpan(
                text: MoneyUtils.format(total),
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
