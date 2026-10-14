import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:quanlycongviecapp/models/models.dart';
import 'package:quanlycongviecapp/repositories/app_repository.dart';
import 'package:quanlycongviecapp/repositories/demo_repository.dart';
import 'package:quanlycongviecapp/widgets/attachment_section.dart';

void main() {
  late DemoRepository repository;
  late String profileId;

  setUp(() async {
    repository = DemoRepository();
    await repository.init();
    profileId = repository.profiles.first.id;
  });

  tearDown(() => repository.dispose());

  Future<void> pumpSection(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ChangeNotifierProvider<AppRepository>.value(
        value: repository,
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AttachmentSection(profileId: profileId),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('390x844 add sheet exposes Drive and blocks Demo cloud upload', (
    tester,
  ) async {
    await pumpSection(tester);
    await tester.tap(find.byTooltip('Thêm tài liệu'));
    await tester.pumpAndSettle();
    expect(find.text('Tải lên Google Drive'), findsOneWidget);
    expect(find.text('Tệp riêng tư trong Drive của bạn'), findsOneWidget);
    await tester.tap(find.text('Tải lên Google Drive'));
    await tester.pumpAndSettle();
    expect(
      find.text('Không tải tệp thật lên Google Drive trong chế độ Demo.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Drive attachment has open copy remove and trash actions', (
    tester,
  ) async {
    final now = DateTime(2026, 10, 12);
    await repository.addAttachment(
      Attachment(
        id: 'drive-attachment',
        profileId: profileId,
        fileName: 'Quyết định điều động rất dài.pdf',
        type: AttachmentType.pdf,
        localPathOrUrl: 'https://drive.google.com/file/d/file-1/view',
        sizeBytes: 2048,
        storageProvider: AttachmentStorageProvider.googleDrive,
        externalFileId: 'file-1',
        mimeType: 'application/pdf',
        createdAt: now,
        updatedAt: now,
      ),
    );
    await pumpSection(tester);
    expect(find.textContaining('Google Drive'), findsOneWidget);
    final driveTile = find.ancestor(
      of: find.text('Quyết định điều động rất dài.pdf'),
      matching: find.byType(ListTile),
    );
    await tester.tap(
      find.descendant(
        of: driveTile,
        matching: find.byType(PopupMenuButton<String>),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Mở tệp'), findsOneWidget);
    expect(find.text('Sao chép liên kết'), findsOneWidget);
    expect(find.text('Xóa khỏi hồ sơ'), findsOneWidget);
    expect(find.text('Đưa tệp vào Thùng rác'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
