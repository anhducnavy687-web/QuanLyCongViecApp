import 'package:flutter_test/flutter_test.dart';
import 'package:quanlycongviecapp/models/models.dart';
import 'package:quanlycongviecapp/screens/profiles/profile_smart_paste_parser.dart';

void main() {
  WorkGroup group({
    List<ProfileFieldConfig>? configs,
    List<CustomFieldDefinition> custom = const [],
  }) => WorkGroup(
    id: 'g1',
    name: 'Nhóm thử nghiệm',
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
    profileFieldConfigs: configs ?? ProfileFieldCatalog.defaultConfigs(),
    customFieldDefinitions: custom,
  );

  const parser = ProfileSmartPasteParser();

  test(
    'recognizes exact, alias, punctuation and accent-insensitive labels',
    () {
      final result = parser.parse('''
Họ tên: Nguyễn Văn A
NGAY SINH = 5-9-1991
• CCCD — 012345678901
NV1: Công tác gần nhà
''', group());

      expect(result.applicableValues, containsPair('fullName', 'Nguyễn Văn A'));
      expect(
        result.applicableValues,
        containsPair('dateOfBirth', '1991-09-05'),
      );
      expect(
        result.applicableValues,
        containsPair('citizenId', '012345678901'),
      );
      expect(
        result.applicableValues,
        containsPair('aspiration1', 'Công tác gần nhà'),
      );
    },
  );

  test('only maps enabled fields from the selected group', () {
    final configs = [
      for (final c in ProfileFieldCatalog.defaultConfigs())
        c.fieldId == 'citizenId' ? c.copyWith(enabled: false) : c,
    ];
    final result = parser.parse(
      'Họ và tên: Nguyễn Văn A\nSố CCCD: 123456789012',
      group(configs: configs),
    );
    expect(result.applicableValues, contains('fullName'));
    expect(result.applicableValues, isNot(contains('citizenId')));
    expect(result.items.last.status, SmartPasteStatus.unresolved);
  });

  test('converts custom boolean and select labels to stored values', () {
    final boolField = CustomFieldDefinition(
      id: 'custom_bool',
      label: 'Đã xác minh',
      section: ProfileFieldSection.subject,
      type: ProfileFieldType.boolean,
      createdAt: DateTime(2026),
    );
    final selectField = CustomFieldDefinition(
      id: 'custom_area',
      label: 'Khu vực',
      section: ProfileFieldSection.subject,
      type: ProfileFieldType.singleSelect,
      createdAt: DateTime(2026),
      options: [
        CustomFieldOption(id: 'north', label: 'Miền Bắc', order: 0),
        CustomFieldOption(id: 'south', label: 'Miền Nam', order: 1),
      ],
    );
    final configs = [
      ...ProfileFieldCatalog.defaultConfigs(),
      const ProfileFieldConfig(
        fieldId: 'custom_bool',
        enabled: true,
        required: false,
        order: 20,
      ),
      const ProfileFieldConfig(
        fieldId: 'custom_area',
        enabled: true,
        required: false,
        order: 21,
      ),
    ];
    final result = parser.parse(
      'Đã xác minh: Có\nKhu vực: miền nam',
      group(configs: configs, custom: [boolField, selectField]),
    );
    expect(result.applicableValues['custom_bool'], 'true');
    expect(result.applicableValues['custom_area'], 'south');
  });

  test('invalid typed values and duplicate fields require review', () {
    final result = parser.parse(
      'Ngày sinh: 31/02/2000\nHọ tên: A\nHọ và tên: B',
      group(),
    );
    expect(result.items.first.status, SmartPasteStatus.review);
    expect(result.items.last.status, SmartPasteStatus.review);
    expect(result.applicableValues['fullName'], 'A');
  });

  test('unknown and free-form lines stay unresolved and are preserved', () {
    final result = parser.parse(
      'Mã nội bộ: ABC\nDòng không có dấu phân cách',
      group(),
    );
    expect(result.items, hasLength(1));
    expect(result.items.single.status, SmartPasteStatus.unresolved);
    expect(result.items.single.rawValue, 'ABC\nDòng không có dấu phân cách');
  });

  test('fuzzy matching tolerates a small label typo', () {
    final result = parser.parse('Chuyên ngàh: Luật', group());
    expect(result.applicableValues['specialty'], 'Luật');
  });

  test(
    'preserves multiline values, ignores headers and accepts numbered labels',
    () {
      final result = parser.parse('''
Vui lòng điền các thông tin dưới đây và gửi lại giúp tôi:
1. Họ và tên: Nguyễn Văn A
Nguyện vọng 1:
Dòng thứ nhất
Dòng thứ hai
Dòng thứ ba
Nguyện vọng 2: ABC
''', group());
      expect(result.applicableValues['fullName'], 'Nguyễn Văn A');
      expect(
        result.applicableValues['aspiration1'],
        'Dòng thứ nhất\nDòng thứ hai\nDòng thứ ba',
      );
      expect(result.applicableValues['aspiration2'], 'ABC');
      expect(
        result.items.where((e) => e.status == SmartPasteStatus.unresolved),
        isEmpty,
      );
    },
  );

  test('single select safely fuzzy-matches one option', () {
    final definition = CustomFieldDefinition(
      id: 'rating',
      label: 'Đánh giá',
      section: ProfileFieldSection.subject,
      type: ProfileFieldType.singleSelect,
      createdAt: DateTime(2026),
      options: const [
        CustomFieldOption(id: 'good', label: 'Tốt', order: 0),
        CustomFieldOption(id: 'fair', label: 'Khá', order: 1),
        CustomFieldOption(id: 'average', label: 'Trung bình', order: 2),
      ],
    );
    final configs = [
      ...ProfileFieldCatalog.defaultConfigs(),
      const ProfileFieldConfig(
        fieldId: 'rating',
        enabled: true,
        required: false,
        order: 20,
      ),
    ];
    final result = parser.parse(
      'Đánh giá: Kha',
      group(configs: configs, custom: [definition]),
    );
    expect(result.applicableValues['rating'], 'fair');
  });
}
