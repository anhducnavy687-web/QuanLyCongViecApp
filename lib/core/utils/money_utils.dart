import 'package:intl/intl.dart';

/// Tiện ích định dạng tiền tệ (VNĐ) dùng chung cho toàn app.
class MoneyUtils {
  MoneyUtils._();

  static final NumberFormat _formatter = NumberFormat.decimalPattern('vi_VN');

  /// Định dạng số tiền kiểu "20.000.000 đ".
  static String format(num amount) {
    return '${_formatter.format(amount)} đ';
  }

  /// Định dạng ngắn gọn dùng trong card, ví dụ "12tr", "1,2tỷ".
  static String formatCompact(num amount) {
    if (amount.abs() >= 1000000000) {
      final v = amount / 1000000000;
      return '${_trim(v)}tỷ';
    }
    if (amount.abs() >= 1000000) {
      final v = amount / 1000000;
      return '${_trim(v)}tr';
    }
    if (amount.abs() >= 1000) {
      final v = amount / 1000;
      return '${_trim(v)}k';
    }
    return amount.toStringAsFixed(0);
  }

  static String _trim(double v) {
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    return v.toStringAsFixed(1);
  }

  /// Tỉ lệ đã hoàn thành của một khoản tiền (0..1), dùng để vẽ thanh trực quan.
  /// Không được hiển thị số phần trăm này cho người dùng — chỉ dùng nội bộ để
  /// vẽ độ dài thanh tiến độ tiền.
  static double ratio(num received, num total) {
    if (total <= 0) return 0;
    final r = received / total;
    if (r.isNaN || r.isInfinite) return 0;
    return r.clamp(0, 1).toDouble();
  }
}
