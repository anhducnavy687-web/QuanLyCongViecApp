import 'package:flutter/material.dart';

import '../core/extensions/context_extensions.dart';

/// Khung card dùng chung cho các khu vực trong trang Chi tiết hồ sơ
/// (Tiến độ, Tiền, Cộng tác viên, Tài liệu...).
class SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;

  const SectionCard({super.key, required this.title, required this.child, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                ?trailing,
              ],
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}
