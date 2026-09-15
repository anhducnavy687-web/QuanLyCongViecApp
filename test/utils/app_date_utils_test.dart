import 'package:flutter_test/flutter_test.dart';
import 'package:quanlycongviecapp/core/utils/app_date_utils.dart';

void main() {
  group('AppDateUtils.daysUntil / isOverdue / isToday / isUpcoming', () {
    final today = DateTime(2026, 9, 15);

    test('trả về số ngày còn lại dương khi deadline ở tương lai', () {
      final deadline = DateTime(2026, 9, 20);
      expect(AppDateUtils.daysUntil(deadline, from: today), 5);
      expect(AppDateUtils.isOverdue(deadline, from: today), isFalse);
      expect(AppDateUtils.isUpcoming(deadline, 5, from: today), isTrue);
      expect(AppDateUtils.isUpcoming(deadline, 3, from: today), isFalse);
    });

    test('trả về số âm khi deadline đã qua (quá hạn)', () {
      final deadline = DateTime(2026, 9, 10);
      expect(AppDateUtils.daysUntil(deadline, from: today), -5);
      expect(AppDateUtils.isOverdue(deadline, from: today), isTrue);
    });

    test('nhận diện đúng deadline là hôm nay', () {
      final deadline = DateTime(2026, 9, 15);
      expect(AppDateUtils.isToday(deadline, from: today), isTrue);
      expect(AppDateUtils.isOverdue(deadline, from: today), isFalse);
    });

    test('daysSince tính đúng số ngày đã trôi qua kể từ ngày bắt đầu', () {
      final start = DateTime(2026, 8, 9);
      expect(AppDateUtils.daysSince(start, until: today), 37);
    });

    test('describeDeadline trả về chuỗi tiếng Việt đúng ngữ cảnh', () {
      expect(AppDateUtils.describeDeadline(DateTime(2026, 9, 10), from: today), 'Quá hạn 5 ngày');
      expect(AppDateUtils.describeDeadline(DateTime(2026, 9, 15), from: today), 'Đến hạn hôm nay');
      expect(AppDateUtils.describeDeadline(DateTime(2026, 9, 16), from: today), 'Còn 1 ngày');
      expect(AppDateUtils.describeDeadline(DateTime(2026, 9, 20), from: today), 'Còn 5 ngày');
    });

    test('describeStartedWithoutDeadline trả về chuỗi hợp lý', () {
      expect(
        AppDateUtils.describeStartedWithoutDeadline(DateTime(2026, 8, 9), until: today),
        'Đã bắt đầu 37 ngày',
      );
      expect(
        AppDateUtils.describeStartedWithoutDeadline(today, until: today),
        'Mới bắt đầu hôm nay',
      );
    });
  });
}
