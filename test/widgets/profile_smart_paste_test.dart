import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:quanlycongviecapp/models/models.dart';
import 'package:quanlycongviecapp/repositories/app_repository.dart';
import 'package:quanlycongviecapp/repositories/demo_repository.dart';
import 'package:quanlycongviecapp/screens/profiles/add_edit_profile_screen.dart';

void main() {
  Future<(DemoRepository, WorkGroup)> pumpForm(
    WidgetTester tester, {
    Profile? profile,
    Size size = const Size(390, 844),
    ThemeData? theme,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repo = DemoRepository();
    await repo.init();
    final group = await repo.addGroupConfigured(
      name: 'Nhóm hồ sơ',
      profileFieldConfigs: ProfileFieldCatalog.defaultConfigs(),
    );
    await tester.pumpWidget(
      ChangeNotifierProvider<AppRepository>.value(
        value: repo,
        child: MaterialApp(
          theme: theme,
          home: AddEditProfileScreen(
            profile: profile,
            initialGroupId: group.id,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    addTearDown(repo.dispose);
    return (repo, group);
  }

  testWidgets('new Profile has one Smart Paste action and editing has none', (
    tester,
  ) async {
    final (_, group) = await pumpForm(tester);
    expect(find.text('Dán thông tin'), findsOneWidget);

    final now = DateTime(2026);
    final profile = Profile(
      id: 'p1',
      groupId: group.id,
      fullName: 'Nguyễn Văn A',
      workTarget: '',
      startDate: now,
      createdAt: now,
      updatedAt: now,
    );
    await pumpForm(tester, profile: profile);
    expect(find.text('Dán thông tin'), findsNothing);
  });

  testWidgets('preview applies recognized values without saving Profile', (
    tester,
  ) async {
    final (repo, _) = await pumpForm(tester);
    final before = repo.profiles.length;
    await tester.tap(find.text('Dán thông tin'));
    await tester.pumpAndSettle();
    expect(find.text('Dán thông tin hồ sơ'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('smart-paste-input')),
      'Họ tên: Nguyễn Văn Mới\nNgày sinh: 02/03/1994\nKhông rõ: giữ lại',
    );
    await tester.tap(find.text('Phân tích'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Đã nhận diện'), findsWidgets);
    expect(find.textContaining('Chưa nhận diện'), findsOneWidget);
    final apply = find.byKey(const Key('smart-paste-apply'));
    await tester.ensureVisible(apply);
    await tester.tap(apply);
    await tester.pumpAndSettle();
    expect(repo.profiles, hasLength(before));
    expect(find.text('Nguyễn Văn Mới'), findsOneWidget);
    expect(find.text('1994-03-02'), findsOneWidget);
  });

  testWidgets('existing non-empty values are protected', (tester) async {
    await pumpForm(tester);
    final name = find.ancestor(
      of: find.text('Họ và tên *'),
      matching: find.byType(TextFormField),
    );
    await tester.enterText(name, 'Giữ tên này');
    await tester.tap(find.text('Dán thông tin'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('smart-paste-input')),
      'Họ tên: Không ghi đè',
    );
    await tester.tap(find.text('Phân tích'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('smart-paste-apply')));
    await tester.pumpAndSettle();
    expect(find.text('Giữ tên này'), findsOneWidget);
    expect(find.textContaining('giữ nguyên'), findsOneWidget);
  });

  for (final size in const [
    Size(320, 568),
    Size(430, 932),
    Size(768, 1024),
    Size(1440, 900),
  ]) {
    testWidgets('sheet remains scrollable without overflow at $size', (
      tester,
    ) async {
      await pumpForm(tester, size: size);
      await tester.tap(find.text('Dán thông tin'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('smart-paste-input')),
        List.generate(20, (i) => 'Không rõ $i: Giá trị $i').join('\n'),
      );
      await tester.tap(find.text('Phân tích'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(Scrollable), findsWidgets);
    });
  }

  for (final brightness in [Brightness.light, Brightness.dark]) {
    testWidgets('sheet has no overflow at 390x844 in $brightness mode', (
      tester,
    ) async {
      await pumpForm(
        tester,
        theme: ThemeData(brightness: brightness, useMaterial3: true),
      );
      await tester.tap(find.text('Dán thông tin'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Dán từ Clipboard'), findsOneWidget);
    });
  }
}
