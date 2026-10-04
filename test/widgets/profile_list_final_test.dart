import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:quanlycongviecapp/repositories/app_repository.dart';
import 'package:quanlycongviecapp/repositories/demo_repository.dart';
import 'package:quanlycongviecapp/screens/profiles/profile_detail_screen.dart';
import 'package:quanlycongviecapp/screens/search/search_screen.dart';
import 'package:quanlycongviecapp/widgets/profile_card.dart';

void main() {
  Future<DemoRepository> pumpSearch(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repo = DemoRepository();
    await repo.init();
    addTearDown(repo.dispose);
    await tester.pumpWidget(
      ChangeNotifierProvider<AppRepository>.value(
        value: repo,
        child: const MaterialApp(home: SearchScreen(autofocusSearch: false)),
      ),
    );
    await tester.pumpAndSettle();
    return repo;
  }

  testWidgets('mobile profile list supports search, filter, group and sort', (
    tester,
  ) async {
    final repo = await pumpSearch(tester);
    expect(find.text('Tất cả nhóm'), findsOneWidget);
    expect(find.text('Ưu tiên deadline'), findsOneWidget);

    final name = repo.profiles.first.fullName;
    await tester.enterText(find.byType(TextField), name);
    await tester.pumpAndSettle();
    expect(find.text(name), findsWidgets);
    expect(find.text('1 hồ sơ'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '');
    await tester.pumpAndSettle();
    final filterStrip = find.byType(ListView).first;
    for (var i = 0; i < 8 && find.text('Đang chờ').evaluate().isEmpty; i++) {
      await tester.drag(filterStrip, const Offset(-180, 0));
      await tester.pump();
    }
    await tester.ensureVisible(find.text('Đang chờ'));
    await tester.pump();
    await tester.tap(find.text('Đang chờ'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tất cả nhóm'));
    await tester.pumpAndSettle();
    expect(find.text('Lọc theo nhóm công việc'), findsOneWidget);
    await tester.tap(find.text(repo.groups.first.name).last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ưu tiên deadline'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Họ tên A–Z').last);
    await tester.pumpAndSettle();
    expect(find.text('Họ tên A–Z'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('profile card still opens profile detail', (tester) async {
    await pumpSearch(tester);
    expect(find.byType(ProfileCard), findsWidgets);
    await tester.tap(find.byType(ProfileCard).first);
    await tester.pumpAndSettle();
    expect(find.byType(ProfileDetailScreen), findsOneWidget);
    expect(find.text('Tài chính & CTV'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
