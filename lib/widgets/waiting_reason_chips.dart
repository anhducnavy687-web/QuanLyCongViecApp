import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';

/// Dãy chip gợi ý lý do "Đang chờ" thường gặp — chọn nhanh thay vì phải gõ
/// tay. Chỉ là gợi ý điền nhanh vào ô văn bản tự do bên dưới, không đổi
/// kiểu dữ liệu của `waitingReason` (vẫn là String để tương thích dữ liệu cũ).
class WaitingReasonChips extends StatelessWidget {
  final String currentValue;
  final ValueChanged<String> onSelected;

  const WaitingReasonChips({
    super.key,
    required this.currentValue,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final preset in AppConstants.waitingReasonPresets)
          ChoiceChip(
            label: Text(preset),
            selected: currentValue == preset,
            onSelected: (_) => onSelected(preset),
          ),
      ],
    );
  }
}
