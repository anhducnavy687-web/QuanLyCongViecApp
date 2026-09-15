import '../utils/app_date_utils.dart';

extension DateTimeFormatting on DateTime {
  String get ddMMyyyy => AppDateUtils.formatDate(this);

  String get ddMM => AppDateUtils.formatDayMonth(this);

  String get ddMMyyyyHHmm => AppDateUtils.formatDateTime(this);

  bool isSameDayAs(DateTime other) => AppDateUtils.isSameDay(this, other);
}
