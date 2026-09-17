import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:quanlycongviecapp/models/work_group.dart';
import 'package:quanlycongviecapp/repositories/app_repository.dart';
import 'package:quanlycongviecapp/repositories/demo_repository.dart';
import 'package:quanlycongviecapp/screens/groups/add_edit_group_sheet.dart';

class FailingWriteRepository extends DemoRepository {
  int attempts = 0;
  @override
  Future<WorkGroup> addGroup({
    required String name,
    String description = '',
  }) async {
    attempts++;
    throw FirebaseException(
      plugin: 'cloud_firestore',
      code: 'permission-denied',
      message: 'raw internal detail',
    );
  }
}

void main() {
  testWidgets(
    'failed Firestore save keeps form editable, shows friendly error, permits retry',
    (tester) async {
      final repo = FailingWriteRepository();
      await tester.pumpWidget(
        ChangeNotifierProvider<AppRepository>.value(
          value: repo,
          child: const MaterialApp(home: Scaffold(body: AddEditGroupSheet())),
        ),
      );
      await tester.enterText(find.byType(TextFormField).first, 'Nhóm kiểm thử');
      await tester.tap(find.text('Lưu'));
      await tester.pumpAndSettle();
      expect(find.byType(AddEditGroupSheet), findsOneWidget);
      expect(find.textContaining('Bạn chưa có quyền'), findsOneWidget);
      expect(find.textContaining('raw internal detail'), findsNothing);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNotNull,
      );
      await tester.tap(find.text('Lưu'));
      await tester.pumpAndSettle();
      expect(repo.attempts, 2);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      repo.dispose();
    },
  );
}
