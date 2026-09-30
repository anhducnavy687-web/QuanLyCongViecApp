import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:quanlycongviecapp/models/models.dart';
import 'package:quanlycongviecapp/repositories/app_repository.dart';
import 'package:quanlycongviecapp/repositories/demo_repository.dart';
import 'package:quanlycongviecapp/screens/profiles/add_edit_profile_screen.dart';

void main() {
  void useTallSurface(WidgetTester tester) {
    tester.view.physicalSize = const Size(900, 6000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  Future<void> pumpForm(
    WidgetTester tester,
    DemoRepository repo,
    WorkGroup group, {
    Profile? profile,
  }) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<AppRepository>.value(
        value: repo,
        child: MaterialApp(
          home: AddEditProfileScreen(
            profile: profile,
            initialGroupId: group.id,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder fieldLabel(String label) => find.text(label);

  testWidgets('new group form renders the exact default schema once', (
    tester,
  ) async {
    useTallSurface(tester);
    final repo = DemoRepository();
    await repo.init();
    final group = await repo.addGroupConfigured(
      name: 'Nhóm mới',
      profileFieldConfigs: ProfileFieldCatalog.defaultConfigs(),
    );
    await pumpForm(tester, repo, group);

    for (final label in const [
      'Nhóm công việc *',
      'Họ và tên *',
      'Ngày sinh *',
      'Số CCCD',
      'Cấp bậc *',
      'Chức vụ *',
      'Đơn vị *',
      'Nhập ngũ *',
      'Quê quán *',
      'Nơi ở hiện nay *',
      'Trình độ',
      'Chuyên ngành',
      'Qua trường',
      'Xếp loại cán bộ',
      'Nguyện vọng 1 *',
      'Nguyện vọng 2 *',
      'Nguyện vọng 3 *',
    ]) {
      expect(fieldLabel(label), findsOneWidget, reason: label);
    }
    for (final label in const [
      'Số điện thoại',
      'Đích công việc',
      'Mục tiêu/Nội dung công việc',
      'Mô tả',
      'Mô tả/Yêu cầu',
      'Ghi chú',
      'Họ và tên bố',
      'Họ và tên mẹ',
      'Trạng thái',
    ]) {
      expect(fieldLabel(label), findsNothing, reason: label);
    }
    expect(
      ProfileStatus.newProfile,
      Profile(
        id: 'id',
        groupId: 'group',
        fullName: 'Nguyễn Văn A',
        workTarget: '',
        startDate: DateTime(2026),
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      ).status,
    );
    repo.dispose();
  });

  testWidgets('enabled legacy built-ins are rendered once by the schema', (
    tester,
  ) async {
    useTallSurface(tester);
    final repo = DemoRepository();
    await repo.init();
    const legacyIds = {'phone', 'workTarget', 'description', 'note'};
    final group = await repo.addGroupConfigured(
      name: 'Nhóm tương thích',
      profileFieldConfigs: [
        for (final config in ProfileFieldCatalog.defaultConfigs())
          legacyIds.contains(config.fieldId)
              ? config.copyWith(enabled: true)
              : config,
      ],
    );
    await pumpForm(tester, repo, group);

    for (final label in const [
      'Số điện thoại',
      'Mục tiêu/Nội dung công việc',
      'Mô tả/Yêu cầu',
      'Ghi chú',
    ]) {
      expect(fieldLabel(label), findsOneWidget, reason: label);
    }
    repo.dispose();
  });

  testWidgets('editing another field preserves hidden legacy values', (
    tester,
  ) async {
    useTallSurface(tester);
    final repo = DemoRepository();
    await repo.init();
    final group = await repo.addGroupConfigured(
      name: 'Nhóm ẩn legacy',
      profileFieldConfigs: ProfileFieldCatalog.defaultConfigs(),
    );
    final now = DateTime(2026, 9, 29);
    final profile = await repo.addProfile(
      Profile(
        id: '',
        groupId: group.id,
        fullName: 'Nguyễn Văn A',
        phone: '0123456789',
        workTarget: 'Mục tiêu cũ',
        description: 'Mô tả cũ',
        note: 'Ghi chú cũ',
        startDate: now,
        createdAt: now,
        updatedAt: now,
        dateOfBirth: DateTime(1990, 1, 1),
        rank: 'Thiếu tá',
        position: 'Trợ lý',
        unit: 'Đơn vị A',
        enlistment: '2008',
        hometown: 'Hà Nội',
        currentResidence: 'Đà Nẵng',
        aspiration1: 'Một',
        aspiration2: 'Hai',
        aspiration3: 'Ba',
      ),
      withDefaultStages: false,
    );
    await pumpForm(tester, repo, group, profile: profile);

    final rankField = find.ancestor(
      of: find.text('Cấp bậc *'),
      matching: find.byType(TextFormField),
    );
    await tester.enterText(rankField, 'Trung tá');
    await tester.tap(find.widgetWithText(FilledButton, 'Lưu thay đổi'));
    await tester.pumpAndSettle();

    final saved = repo.profileById(profile.id)!;
    expect(saved.rank, 'Trung tá');
    expect(saved.phone, '0123456789');
    expect(saved.workTarget, 'Mục tiêu cũ');
    expect(saved.description, 'Mô tả cũ');
    expect(saved.note, 'Ghi chú cũ');
    repo.dispose();
  });

  for (final size in const [
    Size(390, 844),
    Size(430, 932),
    Size(768, 1024),
    Size(1440, 900),
  ]) {
    testWidgets('dynamic profile form has no overflow at $size', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final repo = DemoRepository();
      await repo.init();
      final group = await repo.addGroupConfigured(
        name: 'Responsive',
        profileFieldConfigs: ProfileFieldCatalog.defaultConfigs(),
      );
      await pumpForm(tester, repo, group);
      expect(tester.takeException(), isNull);
      repo.dispose();
    });
  }
}
