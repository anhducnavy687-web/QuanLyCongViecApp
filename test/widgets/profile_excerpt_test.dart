import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:quanlycongviecapp/repositories/app_repository.dart';
import 'package:quanlycongviecapp/repositories/demo_repository.dart';
import 'package:quanlycongviecapp/screens/profiles/profile_detail_screen.dart';

void main() {
  Future<(DemoRepository, String)> pumpDetail(
    WidgetTester tester, {
    Size size = const Size(390, 844),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repo = DemoRepository();
    await repo.init();
    final profile = repo.profiles.first;
    await tester.pumpWidget(
      ChangeNotifierProvider<AppRepository>.value(
        value: repo,
        child: MaterialApp(home: ProfileDetailScreen(profileId: profile.id)),
      ),
    );
    await tester.pumpAndSettle();
    addTearDown(repo.dispose);
    return (repo, profile.id);
  }

  Future<void> openExport(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Trích ngang'));
    await tester.pumpAndSettle();
  }

  String preview(WidgetTester tester) => tester
      .widget<SelectableText>(
        find.byKey(const ValueKey('profile-excerpt-preview')),
      )
      .data!;

  testWidgets('Profile Detail action opens filled preview and closes', (
    tester,
  ) async {
    final (repo, profileId) = await pumpDetail(tester);
    final profile = repo.profileById(profileId)!;
    await openExport(tester);
    expect(find.text('Trích ngang'), findsOneWidget);
    expect(find.text('Sao chép thông tin'), findsNothing);
    expect(find.text('Tất cả trường đang bật'), findsOneWidget);
    expect(preview(tester), contains('Họ và tên: ${profile.fullName}'));
    expect(find.widgetWithText(FilledButton, 'Sao chép'), findsOneWidget);
    await tester.tap(find.widgetWithText(OutlinedButton, 'Đóng'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('profile-excerpt-preview')), findsNothing);
  });

  testWidgets('required-only mode updates preview', (tester) async {
    await pumpDetail(tester);
    await openExport(tester);
    final allEnabled = preview(tester);
    await tester.tap(find.text('Chỉ trường bắt buộc'));
    await tester.pumpAndSettle();
    final requiredOnly = preview(tester);
    expect(requiredOnly, startsWith('THÔNG TIN HỒ SƠ'));
    expect(requiredOnly.length, lessThanOrEqualTo(allEnabled.length));
    expect(requiredOnly, contains('Họ và tên:'));
  });

  testWidgets('copy receives exact preview once and confirms', (tester) async {
    await pumpDetail(tester);
    var writes = 0;
    String? clipboardText;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          writes++;
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
    await openExport(tester);
    final expected = preview(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Sao chép'));
    await tester.pump();
    expect(writes, 1);
    expect(clipboardText, expected);
    expect(find.text('Đã sao chép trích ngang'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('profile-excerpt-preview')),
      findsOneWidget,
    );
  });

  for (final size in const [
    Size(320, 568),
    Size(390, 844),
    Size(430, 932),
    Size(768, 1024),
    Size(1440, 900),
  ]) {
    testWidgets('long export sheet has no overflow at $size', (tester) async {
      await pumpDetail(tester, size: size);
      await openExport(tester);
      expect(tester.takeException(), isNull);
      expect(find.widgetWithText(FilledButton, 'Sao chép'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Đóng'), findsOneWidget);
    });
  }
}
