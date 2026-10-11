import 'package:flutter_test/flutter_test.dart';
import 'package:quanlycongviecapp/models/models.dart';
import 'package:quanlycongviecapp/screens/groups/group_profile_template_builder.dart';
import 'package:quanlycongviecapp/core/utils/profile_information_text_builder.dart';

void main() {
  final now = DateTime(2026, 10, 11);
  final configs = [
    for (final config in ProfileFieldCatalog.defaultConfigs())
      config.copyWith(enabled: false, required: false),
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
  enable('dateOfBirth', order: 1);
  enable('rank', required: true, order: 2);
  enable('position', order: 3);
  enable('fatherFullName', order: 0);
  enable('fatherBirthYear', order: 1);
  enable('aspiration1');
  enable('aspiration2');
  enable('aspiration3');
  for (var i = 0; i < 9; i++) {
    configs.add(
      ProfileFieldConfig(
        fieldId: [
          'custom_text',
          'custom_multiline',
          'custom_number',
          'custom_date',
          'custom_year',
          'custom_bool',
          'custom_bool_false',
          'custom_bool_missing',
          'custom_select',
        ][i],
        enabled: true,
        required: i == 0,
        order: 4 + i,
      ),
    );
  }

  final definitions = [
    CustomFieldDefinition(
      id: 'custom_text',
      label: 'Biệt danh',
      section: ProfileFieldSection.subject,
      type: ProfileFieldType.text,
      createdAt: now,
    ),
    CustomFieldDefinition(
      id: 'custom_multiline',
      label: 'Tự giới thiệu',
      section: ProfileFieldSection.subject,
      type: ProfileFieldType.multiline,
      createdAt: now,
    ),
    CustomFieldDefinition(
      id: 'custom_number',
      label: 'Số con',
      section: ProfileFieldSection.family,
      type: ProfileFieldType.number,
      createdAt: now,
    ),
    CustomFieldDefinition(
      id: 'custom_date',
      label: 'Ngày xác nhận',
      section: ProfileFieldSection.workContent,
      type: ProfileFieldType.date,
      createdAt: now,
    ),
    CustomFieldDefinition(
      id: 'custom_year',
      label: 'Năm tốt nghiệp',
      section: ProfileFieldSection.subject,
      type: ProfileFieldType.year,
      createdAt: now,
    ),
    CustomFieldDefinition(
      id: 'custom_bool',
      label: 'Đã xác minh',
      section: ProfileFieldSection.workContent,
      type: ProfileFieldType.boolean,
      createdAt: now,
    ),
    CustomFieldDefinition(
      id: 'custom_bool_false',
      label: 'Đã bổ sung',
      section: ProfileFieldSection.workContent,
      type: ProfileFieldType.boolean,
      createdAt: now,
    ),
    CustomFieldDefinition(
      id: 'custom_bool_missing',
      label: 'Đã đối chiếu',
      section: ProfileFieldSection.workContent,
      type: ProfileFieldType.boolean,
      createdAt: now,
    ),
    CustomFieldDefinition(
      id: 'custom_select',
      label: 'Xếp loại riêng',
      section: ProfileFieldSection.subject,
      type: ProfileFieldType.singleSelect,
      options: const [
        CustomFieldOption(
          id: 'inactive_good',
          label: 'Tốt',
          active: false,
          order: 0,
        ),
      ],
      createdAt: now,
    ),
  ];

  WorkGroup group({bool legacy = false}) => WorkGroup(
    id: 'group',
    name: 'Nhóm',
    createdAt: now,
    updatedAt: now,
    profileFieldConfigs: legacy ? const [] : configs,
    customFieldDefinitions: legacy ? const [] : definitions,
  );

  Profile profile({Map<String, dynamic>? customValues}) => Profile(
    id: 'profile',
    groupId: 'group',
    fullName: 'Nguyễn Văn A',
    phone: '0901',
    workTarget: 'Hoàn thiện hồ sơ',
    description: 'Không được xuất',
    startDate: now,
    createdAt: now,
    updatedAt: now,
    dateOfBirth: DateTime(1988, 3, 12),
    rank: 'Thiếu tá',
    fatherFullName: 'Nguyễn Văn B',
    fatherBirthYear: 1960,
    aspiration1: 'NV một',
    aspiration2: 'NV hai',
    aspiration3: 'NV ba',
    customFieldValues:
        customValues ??
        const {
          'custom_text': 'Văn A',
          'custom_multiline': 'Dòng một\nDòng hai',
          'custom_number': 2.0,
          'custom_date': '2026-10-09T00:00:00.000',
          'custom_year': 2010,
          'custom_bool': true,
          'custom_bool_false': false,
          'custom_select': 'inactive_good',
        },
  );

  const builder = ProfileInformationTextBuilder();

  test('built-ins, exact order, empty values and aspirations render', () {
    final result = builder.build(group(), profile());
    expect(result, startsWith('THÔNG TIN HỒ SƠ\n\n'));
    expect(result, contains('Họ và tên: Nguyễn Văn A'));
    expect(result, contains('Ngày sinh: 12/03/1988'));
    expect(result, contains('Cấp bậc: Thiếu tá'));
    expect(result, contains('Chức vụ:'));
    expect(result.indexOf('Họ và tên:'), lessThan(result.indexOf('Cấp bậc:')));
    expect(
      result.indexOf('Nguyện vọng 1:'),
      greaterThan(result.indexOf('Năm sinh bố:')),
    );
    expect(
      result.indexOf('Nguyện vọng 1:'),
      lessThan(result.indexOf('Nguyện vọng 2:')),
    );
    expect(
      result.indexOf('Nguyện vọng 2:'),
      lessThan(result.indexOf('Nguyện vọng 3:')),
    );
  });

  test('required-only includes only enabled required fields', () {
    final result = builder.build(
      group(),
      profile(),
      mode: GroupProfileTemplateMode.requiredOnly,
    );
    expect(result, contains('Họ và tên: Nguyễn Văn A'));
    expect(result, contains('Cấp bậc: Thiếu tá'));
    expect(result, contains('Biệt danh: Văn A'));
    expect(result, isNot(contains('Ngày sinh:')));
    expect(result, isNot(contains('Nguyện vọng 1:')));
  });

  test('custom field types use readable canonical values', () {
    final result = builder.build(group(), profile());
    expect(result, contains('Tự giới thiệu: Dòng một\nDòng hai'));
    expect(result, contains('Số con: 2'));
    expect(result, contains('Ngày xác nhận: 09/10/2026'));
    expect(result, contains('Năm tốt nghiệp: 2010'));
    expect(result, contains('Đã xác minh: Có'));
    expect(result, contains('Đã bổ sung: Không'));
    expect(result, contains('Đã đối chiếu:'));
    expect(result, contains('Xếp loại riêng: Tốt'));
    expect(result, isNot(contains('inactive_good')));
  });

  test('disabled and operational internal fields are excluded', () {
    final result = builder.build(group(), profile());
    expect(result, isNot(contains('Số điện thoại:')));
    expect(result, isNot(contains('Mô tả / Yêu cầu:')));
    for (final value in [
      'Profile ID',
      'Group ID',
      'deadline',
      'totalAmount',
      'createdAt',
    ]) {
      expect(result, isNot(contains(value)));
    }
  });

  test('legacy Group uses effective compatibility configuration', () {
    final result = builder.build(group(legacy: true), profile());
    expect(result, contains('Họ và tên: Nguyễn Văn A'));
    expect(result, contains('Cấp bậc: Thiếu tá'));
    expect(result, contains('Nguyện vọng 3: NV ba'));
  });

  test('output is deterministic with no null or trailing whitespace', () {
    final first = builder.build(group(), profile(customValues: const {}));
    expect(builder.build(group(), profile(customValues: const {})), first);
    expect(first, isNot(contains('null')));
    expect(first.split('\n').where((line) => line.endsWith(' ')), isEmpty);
    expect(RegExp(r'\s$').hasMatch(first), isFalse);
  });
}
