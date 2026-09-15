/// Các hàm kiểm tra dữ liệu đầu vào, trả về thông báo lỗi tiếng Việt hoặc
/// `null` nếu hợp lệ. Dùng trực tiếp làm `validator` cho `TextFormField`.
class Validators {
  Validators._();

  static String? required(String? value, {String field = 'Trường này'}) {
    if (value == null || value.trim().isEmpty) {
      return '$field không được để trống';
    }
    return null;
  }

  static String? fullName(String? value) => required(value, field: 'Họ tên');

  static String? workTarget(String? value) =>
      required(value, field: 'Đích công việc');

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final cleaned = value.replaceAll(RegExp(r'[\s.-]'), '');
    if (!RegExp(r'^(\+84|0)\d{9,10}$').hasMatch(cleaned)) {
      return 'Số điện thoại không hợp lệ';
    }
    return null;
  }

  static String? nonNegativeAmount(String? value, {String field = 'Số tiền'}) {
    if (value == null || value.trim().isEmpty) return null;
    final amount = num.tryParse(value.replaceAll('.', '').replaceAll(',', ''));
    if (amount == null) return '$field không hợp lệ';
    if (amount < 0) return '$field phải lớn hơn hoặc bằng 0';
    return null;
  }

  static String? paidNotExceedingCommission(num paid, num commission) {
    if (paid < 0) return 'Số tiền đã trả phải lớn hơn hoặc bằng 0';
    if (paid > commission) {
      return 'Số tiền đã trả không được vượt quá hoa hồng';
    }
    return null;
  }

  static String? deadlineNotBeforeStart(DateTime? start, DateTime? deadline) {
    if (start == null || deadline == null) return null;
    if (deadline.isBefore(start)) {
      return 'Hạn hoàn thành không được trước ngày bắt đầu';
    }
    return null;
  }
}
