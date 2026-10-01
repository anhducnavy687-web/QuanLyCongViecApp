import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:quanlycongviecapp/models/models.dart';
import 'package:quanlycongviecapp/repositories/app_repository.dart';
import 'package:quanlycongviecapp/repositories/demo_repository.dart';
import 'package:quanlycongviecapp/screens/profiles/profile_detail_screen.dart';

void main() {
  Future<void> pumpDetail(
    WidgetTester tester,
    DemoRepository repo,
    String profileId, {
    Size size = const Size(900, 1200),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ChangeNotifierProvider<AppRepository>.value(
        value: repo,
        child: MaterialApp(home: ProfileDetailScreen(profileId: profileId)),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> switchTab(WidgetTester tester, int index) async {
    final controller = DefaultTabController.of(
      tester.element(find.byType(TabBar)),
    );
    controller.animateTo(index);
    await tester.pumpAndSettle();
  }

  testWidgets('header and exactly five top-level tabs are available', (
    tester,
  ) async {
    final repo = DemoRepository();
    await repo.init();
    final profile = repo.profiles.first;
    final group = repo.groupById(profile.groupId)!;
    await pumpDetail(tester, repo, profile.id);

    expect(find.text(profile.fullName), findsOneWidget);
    expect(find.text(group.name), findsOneWidget);
    expect(find.text(profile.status.label), findsOneWidget);
    expect(find.byTooltip('Sửa hồ sơ'), findsOneWidget);
    expect(find.byTooltip('Trích ngang'), findsOneWidget);
    expect(find.byType(Tab), findsNWidgets(5));
    for (final label in const [
      'Tổng quan',
      'Thông tin',
      'Công việc',
      'Tài chính & CTV',
      'Tài liệu & Lịch sử',
    ]) {
      expect(find.widgetWithText(Tab, label), findsOneWidget);
    }
    repo.dispose();
  });

  testWidgets('all existing domain actions remain reachable in five tabs', (
    tester,
  ) async {
    final repo = DemoRepository();
    await repo.init();
    await pumpDetail(tester, repo, repo.profiles.first.id);

    expect(find.text('TIẾN ĐỘ'), findsOneWidget);
    expect(find.text('THỜI GIAN'), findsOneWidget);
    expect(find.text('TÀI CHÍNH'), findsOneWidget);

    await switchTab(tester, 2);
    expect(find.byTooltip('Thêm bước xử lý'), findsOneWidget);
    expect(find.byTooltip('Thêm việc'), findsOneWidget);
    expect(find.byTooltip('Thêm mốc thời gian'), findsOneWidget);

    await switchTab(tester, 3);
    expect(find.byTooltip('Thêm giao dịch'), findsOneWidget);
    expect(find.byTooltip('Gán cộng tác viên'), findsOneWidget);

    await switchTab(tester, 4);
    expect(find.byTooltip('Thêm tài liệu'), findsOneWidget);
    expect(find.byTooltip('Thêm ghi chú'), findsOneWidget);
    repo.dispose();
  });

  testWidgets('information follows schema order and field visibility', (
    tester,
  ) async {
    final repo = DemoRepository();
    await repo.init();
    final now = DateTime(2026, 9, 30);
    const customId = 'custom_case_source';
    final configs = [
      for (final config in ProfileFieldCatalog.defaultConfigs())
        config.copyWith(enabled: false, required: false),
      const ProfileFieldConfig(
        fieldId: customId,
        enabled: true,
        required: false,
        order: 2,
      ),
    ];
    void enable(String id, {bool required = false, int? order}) {
      final index = configs.indexWhere((config) => config.fieldId == id);
      configs[index] = configs[index].copyWith(
        enabled: true,
        required: required,
        order: order,
      );
    }

    enable('fullName', required: true, order: 0);
    enable('rank', required: true, order: 1);
    enable('citizenId', order: 3);
    enable('fatherFullName', required: true, order: 0);
    enable('aspiration1', required: true);
    enable('aspiration2', required: true);
    enable('aspiration3', required: true);
    final group = await repo.addGroupConfigured(
      name: 'Nhóm cấu hình động',
      profileFieldConfigs: configs,
      customFieldDefinitions: [
        CustomFieldDefinition(
          id: customId,
          label: 'Nguồn hồ sơ',
          section: ProfileFieldSection.subject,
          type: ProfileFieldType.text,
          createdAt: now,
        ),
      ],
    );
    final profile = await repo.addProfile(
      Profile(
        id: '',
        groupId: group.id,
        fullName: 'Nguyễn Văn Kiểm Thử',
        workTarget: '',
        startDate: now,
        createdAt: now,
        updatedAt: now,
        rank: 'Thiếu tá',
        aspiration1: 'Nguyện vọng thứ nhất',
        aspiration2: 'Nguyện vọng thứ hai',
        aspiration3: 'Nguyện vọng thứ ba',
        customFieldValues: const {customId: 'Giới thiệu'},
      ),
      withDefaultStages: false,
    );
    await pumpDetail(tester, repo, profile.id, size: const Size(900, 3000));
    await switchTab(tester, 1);

    expect(find.text('Cấp bậc'), findsOneWidget);
    expect(find.text('Thiếu tá'), findsOneWidget);
    expect(find.text('Nguồn hồ sơ'), findsOneWidget);
    expect(find.text('Giới thiệu'), findsOneWidget);
    expect(find.text('Số điện thoại'), findsNothing);
    expect(find.text('Số CCCD'), findsNothing);
    expect(find.text('BỐ'), findsOneWidget);
    expect(find.text('Chưa có thông tin'), findsOneWidget);
    final aspirationTitle = tester.getTopLeft(find.text('Nguyện vọng')).dy;
    expect(
      aspirationTitle,
      greaterThan(tester.getTopLeft(find.text('Thông tin gia đình')).dy),
    );
    bool precedes(String first, String second) {
      final a = tester.getTopLeft(find.text(first));
      final b = tester.getTopLeft(find.text(second));
      return a.dy < b.dy || (a.dy == b.dy && a.dx < b.dx);
    }

    expect(precedes('Nguyện vọng 1', 'Nguyện vọng 2'), isTrue);
    expect(precedes('Nguyện vọng 2', 'Nguyện vọng 3'), isTrue);
    repo.dispose();
  });

  for (final size in const [
    Size(390, 844),
    Size(430, 932),
    Size(768, 1024),
    Size(1440, 900),
  ]) {
    testWidgets('five tabs render without overflow at $size', (tester) async {
      final repo = DemoRepository();
      await repo.init();
      await pumpDetail(tester, repo, repo.profiles.first.id, size: size);
      for (var tab = 0; tab < 5; tab++) {
        await switchTab(tester, tab);
        expect(tester.takeException(), isNull, reason: 'tab $tab at $size');
      }
      repo.dispose();
    });
  }
}
