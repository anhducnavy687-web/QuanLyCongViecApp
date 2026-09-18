import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:quanlycongviecapp/models/models.dart';
import 'package:quanlycongviecapp/repositories/app_repository.dart';
import 'package:quanlycongviecapp/repositories/demo_repository.dart';
import 'package:quanlycongviecapp/screens/profiles/profile_detail_screen.dart';
import 'package:quanlycongviecapp/widgets/money_section.dart';

class ControlledMoneyRepository extends DemoRepository {
  final Completer<void> pending = Completer<void>();
  int attempts = 0;

  @override
  Future<MoneyTransaction> addTransaction(MoneyTransaction transaction) async {
    attempts++;
    await pending.future;
    return super.addTransaction(transaction);
  }
}

class RetryMoneyRepository extends DemoRepository {
  int attempts = 0;

  @override
  Future<MoneyTransaction> addTransaction(MoneyTransaction transaction) async {
    attempts++;
    if (attempts == 1) {
      throw FirebaseException(plugin: 'cloud_firestore', code: 'unavailable');
    }
    return super.addTransaction(transaction);
  }
}

class ControlledDeleteRepository extends DemoRepository {
  final Completer<void> pendingDelete = Completer<void>();
  int deleteAttempts = 0;

  @override
  Future<void> deleteProfile(String id) async {
    deleteAttempts++;
    await pendingDelete.future;
    return super.deleteProfile(id);
  }
}

Future<String> pumpMoney(WidgetTester tester, DemoRepository repo) async {
  tester.view.physicalSize = const Size(1200, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await repo.init();
  final profileId = repo.profiles.first.id;
  await tester.pumpWidget(
    ChangeNotifierProvider<AppRepository>.value(
      value: repo,
      child: MaterialApp(
        home: Scaffold(body: MoneySection(profileId: profileId)),
      ),
    ),
  );
  await tester.tap(find.byTooltip('Thêm giao dịch'));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField).first, '100');
  return profileId;
}

void main() {
  testWidgets('double submit creates only one transaction', (tester) async {
    final repo = ControlledMoneyRepository();
    await pumpMoney(tester, repo);
    await tester.tap(find.text('Lưu'));
    await tester.pump();
    await tester.tap(find.text('Lưu'));
    await tester.pump();
    expect(repo.attempts, 1);
    repo.pending.complete();
    await tester.pumpAndSettle();
    expect(repo.attempts, 1);
    await tester.pumpWidget(const SizedBox.shrink());
    repo.dispose();
  });

  testWidgets('failed transaction stays open and retry succeeds', (
    tester,
  ) async {
    final repo = RetryMoneyRepository();
    await pumpMoney(tester, repo);
    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();
    expect(repo.attempts, 1);
    expect(find.text('Thêm giao dịch'), findsOneWidget);
    expect(find.textContaining('mạng'), findsOneWidget);

    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();
    expect(repo.attempts, 2);
    expect(find.text('Thêm giao dịch'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    repo.dispose();
  });

  testWidgets('profile delete does not report completion before write finishes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repo = ControlledDeleteRepository();
    await repo.init();
    final profileId = repo.profiles.first.id;
    await tester.pumpWidget(
      ChangeNotifierProvider<AppRepository>.value(
        value: repo,
        child: MaterialApp(home: ProfileDetailScreen(profileId: profileId)),
      ),
    );

    await tester.tap(find.byType(PopupMenuButton<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xóa hồ sơ'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Xóa'));
    await tester.pump();

    expect(repo.deleteAttempts, 1);
    expect(repo.profileById(profileId), isNotNull);
    expect(find.text('Xóa hồ sơ?'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    repo.pendingDelete.complete();
    await tester.pumpAndSettle();
    expect(repo.profileById(profileId), isNull);
    expect(find.text('Xóa hồ sơ?'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    repo.dispose();
  });
}
