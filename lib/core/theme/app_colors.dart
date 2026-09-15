import 'package:flutter/material.dart';

/// Màu trạng thái dùng thống nhất trong toàn app.
///
/// Lưu ý: màu KHÔNG được dùng làm dấu hiệu duy nhất để phân biệt trạng thái —
/// mọi nơi hiển thị màu đều phải đi kèm icon hoặc chữ.
class AppColors {
  AppColors._();

  static const Color overdue = Color(0xFFD32F2F); // đỏ - quá hạn
  static const Color dueToday = Color(0xFFE65100); // cam đậm - hôm nay
  static const Color upcoming = Color(0xFFF57C00); // cam - sắp đến hạn
  static const Color stalled = Color(0xFFF9A825); // vàng - trì trệ
  static const Color completed = Color(0xFF2E7D32); // xanh - hoàn thành
  static const Color inProgress = Color(0xFF1565C0); // xanh dương - đang xử lý
  static const Color waiting = Color(0xFF6A1B9A); // tím - đang chờ
  static const Color neutral = Color(0xFF757575); // xám - trung tính
  static const Color cancelled = Color(0xFF9E9E9E); // xám nhạt - đã hủy

  static const Color seed = Color(0xFF1E6091);
}
