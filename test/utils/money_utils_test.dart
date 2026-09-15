import 'package:flutter_test/flutter_test.dart';
import 'package:quanlycongviecapp/core/utils/money_utils.dart';

void main() {
  group('MoneyUtils', () {
    test('format thêm dấu phân cách hàng nghìn và hậu tố đ', () {
      expect(MoneyUtils.format(20000000), '20.000.000 đ');
      expect(MoneyUtils.format(0), '0 đ');
    });

    test('ratio tính đúng tỉ lệ đã nhận/tổng, luôn trong [0,1]', () {
      expect(MoneyUtils.ratio(12000000, 20000000), closeTo(0.6, 0.0001));
      expect(MoneyUtils.ratio(25000000, 20000000), 1); // không vượt quá 1
      expect(MoneyUtils.ratio(5000000, 0), 0); // tránh chia cho 0
    });

    test('formatCompact rút gọn theo tr/tỷ/k', () {
      expect(MoneyUtils.formatCompact(20000000), '20tr');
      expect(MoneyUtils.formatCompact(1500000000), '1.5tỷ');
      expect(MoneyUtils.formatCompact(500), '500');
    });
  });
}
