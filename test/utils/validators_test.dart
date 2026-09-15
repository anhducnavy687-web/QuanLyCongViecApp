import 'package:flutter_test/flutter_test.dart';
import 'package:quanlycongviecapp/core/utils/validators.dart';

void main() {
  group('Validators', () {
    test('required báo lỗi khi rỗng, hợp lệ khi có giá trị', () {
      expect(Validators.fullName(''), isNotNull);
      expect(Validators.fullName('  '), isNotNull);
      expect(Validators.fullName('Nguyễn Văn A'), isNull);
    });

    test('nonNegativeAmount từ chối số âm, chấp nhận số hợp lệ', () {
      expect(Validators.nonNegativeAmount('-100'), isNotNull);
      expect(Validators.nonNegativeAmount('abc'), isNotNull);
      expect(Validators.nonNegativeAmount('20000000'), isNull);
      expect(Validators.nonNegativeAmount(''), isNull); // không bắt buộc
    });

    test('paidNotExceedingCommission ngăn trả vượt hoa hồng', () {
      expect(Validators.paidNotExceedingCommission(2000000, 1500000), isNotNull);
      expect(Validators.paidNotExceedingCommission(1500000, 1500000), isNull);
      expect(Validators.paidNotExceedingCommission(-1, 1500000), isNotNull);
    });

    test('deadlineNotBeforeStart phát hiện deadline trước ngày bắt đầu', () {
      final start = DateTime(2026, 9, 15);
      final beforeStart = DateTime(2026, 9, 10);
      final afterStart = DateTime(2026, 9, 20);
      expect(Validators.deadlineNotBeforeStart(start, beforeStart), isNotNull);
      expect(Validators.deadlineNotBeforeStart(start, afterStart), isNull);
      expect(Validators.deadlineNotBeforeStart(start, null), isNull);
    });

    test('phone chấp nhận số Việt Nam hợp lệ, từ chối số sai định dạng', () {
      expect(Validators.phone('0987654321'), isNull);
      expect(Validators.phone('+84987654321'), isNull);
      expect(Validators.phone('123'), isNotNull);
      expect(Validators.phone(''), isNull); // không bắt buộc
    });
  });
}
