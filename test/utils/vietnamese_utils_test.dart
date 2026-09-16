import 'package:flutter_test/flutter_test.dart';
import 'package:quanlycongviecapp/core/utils/vietnamese_utils.dart';

void main() {
  group('VietnameseUtils.removeDiacritics', () {
    test('bỏ dấu và chuyển chữ thường', () {
      expect(VietnameseUtils.removeDiacritics('Nguyễn Văn A'), 'nguyen van a');
      expect(VietnameseUtils.removeDiacritics('Đặng Thị Đông'), 'dang thi dong');
      expect(VietnameseUtils.removeDiacritics('CHUYỂN NHƯỢNG ĐẤT'), 'chuyen nhuong dat');
    });

    test('chuỗi không dấu giữ nguyên (chỉ đổi chữ thường)', () {
      expect(VietnameseUtils.removeDiacritics('Nguyen Van A'), 'nguyen van a');
    });

    test('tìm kiếm không dấu khớp với chuỗi có dấu', () {
      final query = VietnameseUtils.removeDiacritics('nguyen van a');
      final target = VietnameseUtils.removeDiacritics('Nguyễn Văn A - Chuyển nhượng đất');
      expect(target.contains(query), isTrue);
    });

    test('không đổi số và ký tự không phải tiếng Việt', () {
      expect(VietnameseUtils.removeDiacritics('0987654321'), '0987654321');
    });
  });
}
