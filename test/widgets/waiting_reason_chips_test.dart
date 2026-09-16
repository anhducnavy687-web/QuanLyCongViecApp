import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quanlycongviecapp/widgets/waiting_reason_chips.dart';

void main() {
  testWidgets('WaitingReasonChips hiển thị đủ preset và báo đúng lựa chọn', (tester) async {
    String? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WaitingReasonChips(
            currentValue: '',
            onSelected: (v) => selected = v,
          ),
        ),
      ),
    );

    for (final label in ['Chờ khách hàng', 'Chờ bên liên quan', 'Chờ hồ sơ/tài liệu', 'Chờ phản hồi', 'Chờ thanh toán', 'Chờ phê duyệt', 'Khác']) {
      expect(find.text(label), findsOneWidget);
    }

    await tester.tap(find.text('Chờ thanh toán'));
    await tester.pump();
    expect(selected, 'Chờ thanh toán');
  });

  testWidgets('Chip đang khớp currentValue được đánh dấu selected', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WaitingReasonChips(
            currentValue: 'Chờ phê duyệt',
            onSelected: (_) {},
          ),
        ),
      ),
    );

    final chip = tester.widget<ChoiceChip>(
      find.ancestor(of: find.text('Chờ phê duyệt'), matching: find.byType(ChoiceChip)),
    );
    expect(chip.selected, isTrue);

    final otherChip = tester.widget<ChoiceChip>(
      find.ancestor(of: find.text('Chờ khách hàng'), matching: find.byType(ChoiceChip)),
    );
    expect(otherChip.selected, isFalse);
  });
}
