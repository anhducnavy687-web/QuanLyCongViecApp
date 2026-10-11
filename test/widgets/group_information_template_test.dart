import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:quanlycongviecapp/models/models.dart';
import 'package:quanlycongviecapp/repositories/app_repository.dart';
import 'package:quanlycongviecapp/repositories/demo_repository.dart';
import 'package:quanlycongviecapp/screens/groups/group_detail_screen.dart';

void main() {
  Future<(DemoRepository, WorkGroup)> pumpGroup(
    WidgetTester tester, {
    Size size = const Size(390, 844),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repo = DemoRepository();
    await repo.init();
    final now = DateTime(2026, 10, 11);
    final configs = [
      for (final value in ProfileFieldCatalog.defaultConfigs())
        value.copyWith(enabled: false, required: false),
      const ProfileFieldConfig(
        fieldId: 'custom_long',
        enabled: true,
        required: false,
        order: 2,
      ),
    ];
    void enable(String id, {bool required = false, int? order}) {
      final index = configs.indexWhere((value) => value.fieldId == id);
      configs[index] = configs[index].copyWith(
        enabled: true,
        required: required,
        order: order,
      );
    }

    enable('fullName', required: true, order: 0);
    enable('rank', required: true, order: 1);
    enable('position', order: 3);
    enable('aspiration1', required: true);
    enable('aspiration2');
    enable('aspiration3');
    final group = await repo.addGroupConfigured(
      name: 'Nhóm mẫu thông tin',
      profileFieldConfigs: configs,
      customFieldDefinitions: [
        CustomFieldDefinition(
          id: 'custom_long',
          label: 'Trường tùy chỉnh có nhãn dài để kiểm tra giao diện',
          section: ProfileFieldSection.subject,
          type: ProfileFieldType.multiline,
          createdAt: now,
        ),
      ],
    );
    await tester.pumpWidget(
      ChangeNotifierProvider<AppRepository>.value(
        value: repo,
        child: MaterialApp(home: GroupDetailScreen(groupId: group.id)),
      ),
    );
    await tester.pumpAndSettle();
    addTearDown(repo.dispose);
    return (repo, group);
  }

  testWidgets('Group Detail action opens preview and Close dismisses it', (
    tester,
  ) async {
    await pumpGroup(tester);
    expect(find.text('Mẫu thu thập thông tin'), findsOneWidget);
    await tester.tap(find.text('Mẫu thu thập thông tin'));
    await tester.pumpAndSettle();
    expect(find.text('Mẫu thu thập thông tin'), findsWidgets);
    expect(find.text('Tất cả trường đang bật'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('group-template-preview')),
      findsOneWidget,
    );
    expect(find.widgetWithText(FilledButton, 'Sao chép'), findsOneWidget);
    await tester.tap(find.widgetWithText(OutlinedButton, 'Đóng'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('group-template-preview')), findsNothing);
  });

  testWidgets('required-only updates preview without duplicates', (
    tester,
  ) async {
    await pumpGroup(tester);
    await tester.tap(find.text('Mẫu thu thập thông tin'));
    await tester.pumpAndSettle();
    String preview() => tester
        .widget<SelectableText>(
          find.byKey(const ValueKey('group-template-preview')),
        )
        .data!;
    expect(preview(), contains('Chức vụ:'));
    expect(preview(), contains('Trường tùy chỉnh'));
    await tester.tap(find.text('Chỉ trường bắt buộc'));
    await tester.pumpAndSettle();
    expect(preview(), contains('Họ và tên:'));
    expect(preview(), contains('Cấp bậc:'));
    expect(preview(), contains('Nguyện vọng 1:'));
    expect(preview(), isNot(contains('Chức vụ:')));
    expect(preview(), isNot(contains('Trường tùy chỉnh')));
    expect(RegExp('Họ và tên:').allMatches(preview()), hasLength(1));
  });

  testWidgets('copy uses exact preview and shows confirmation', (tester) async {
    await pumpGroup(tester);
    String? clipboardText;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          clipboardText = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await tester.tap(find.text('Mẫu thu thập thông tin'));
    await tester.pumpAndSettle();
    final preview = tester
        .widget<SelectableText>(
          find.byKey(const ValueKey('group-template-preview')),
        )
        .data!;
    await tester.tap(find.widgetWithText(FilledButton, 'Sao chép'));
    await tester.pump();
    expect(clipboardText, preview);
    expect(find.text('Đã sao chép mẫu thông tin'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('group-template-preview')),
      findsOneWidget,
    );
  });

  for (final size in [
    const Size(320, 568),
    const Size(390, 844),
    const Size(430, 932),
    const Size(768, 1024),
    const Size(1440, 900),
  ]) {
    testWidgets('long template has no overflow at $size', (tester) async {
      await pumpGroup(tester, size: size);
      await tester.tap(find.text('Mẫu thu thập thông tin'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.widgetWithText(FilledButton, 'Sao chép'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Đóng'), findsOneWidget);
    });
  }
}
