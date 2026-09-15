import 'package:intl/intl.dart';

/// Tiện ích xử lý ngày giờ dùng chung cho toàn app.
class AppDateUtils {
  AppDateUtils._();

  static final DateFormat _dayFormat = DateFormat('dd/MM/yyyy');
  static final DateFormat _dayMonthFormat = DateFormat('dd/MM');
  static final DateFormat _dayTimeFormat = DateFormat('dd/MM/yyyy HH:mm');

  static String formatDate(DateTime? date) {
    if (date == null) return '--';
    return _dayFormat.format(date);
  }

  static String formatDayMonth(DateTime? date) {
    if (date == null) return '--';
    return _dayMonthFormat.format(date);
  }

  static String formatDateTime(DateTime? date) {
    if (date == null) return '--';
    return _dayTimeFormat.format(date);
  }

  static DateTime stripTime(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Số ngày còn lại đến [deadline] tính từ hôm nay.
  /// Số dương: còn lại. Số âm: đã quá hạn (số ngày quá hạn = -kết quả).
  static int daysUntil(DateTime deadline, {DateTime? from}) {
    final today = stripTime(from ?? DateTime.now());
    final target = stripTime(deadline);
    return target.difference(today).inDays;
  }

  /// Số ngày đã trôi qua kể từ [startDate] cho tới hôm nay (dùng khi hồ sơ
  /// không có deadline, để người dùng biết công việc đã kéo dài bao lâu).
  static int daysSince(DateTime startDate, {DateTime? until}) {
    final today = stripTime(until ?? DateTime.now());
    final start = stripTime(startDate);
    return today.difference(start).inDays;
  }

  static bool isOverdue(DateTime deadline, {DateTime? from}) {
    return daysUntil(deadline, from: from) < 0;
  }

  static bool isToday(DateTime deadline, {DateTime? from}) {
    return daysUntil(deadline, from: from) == 0;
  }

  static bool isUpcoming(DateTime deadline, int thresholdDays, {DateTime? from}) {
    final d = daysUntil(deadline, from: from);
    return d > 0 && d <= thresholdDays;
  }

  /// Diễn giải bằng tiếng Việt số ngày còn lại/quá hạn của deadline.
  static String describeDeadline(DateTime deadline, {DateTime? from}) {
    final d = daysUntil(deadline, from: from);
    if (d < 0) return 'Quá hạn ${-d} ngày';
    if (d == 0) return 'Đến hạn hôm nay';
    if (d == 1) return 'Còn 1 ngày';
    return 'Còn $d ngày';
  }

  /// Diễn giải bằng tiếng Việt cho hồ sơ không có deadline.
  static String describeStartedWithoutDeadline(DateTime startDate, {DateTime? until}) {
    final days = daysSince(startDate, until: until);
    if (days <= 0) return 'Mới bắt đầu hôm nay';
    return 'Đã bắt đầu $days ngày';
  }
}
