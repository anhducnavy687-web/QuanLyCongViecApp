import 'package:flutter_test/flutter_test.dart';
import 'package:quanlycongviecapp/models/models.dart';
import 'package:quanlycongviecapp/services/profile_field_resolver.dart';

void main() {
  final now = DateTime(2026, 9, 29);
  Profile profile({Map<String, dynamic> custom = const {}}) => Profile(
    id: 'p1',
    groupId: 'g1',
    fullName: 'Nguyễn Văn A',
    workTarget: 'Công việc',
    startDate: now,
    createdAt: now,
    updatedAt: now,
    citizenId: '001234',
    aspiration1: 'Nguyện vọng A',
    customFieldValues: custom,
  );

  test('catalog defaults and pinned aspiration order follow the contract', () {
    final defaults = ProfileFieldCatalog.defaultConfigs();
    ProfileFieldConfig config(String id) =>
        defaults.firstWhere((e) => e.fieldId == id);
    expect(config('fullName').enabled, true);
    expect(config('fullName').required, true);
    expect(config('dateOfBirth').required, true);
    expect(config('citizenId').required, false);
    expect(config('fatherFullName').enabled, false);
    expect(config('phone').enabled, false);
    expect(config('workTarget').enabled, false);
    expect(config('description').enabled, false);
    expect(config('note').enabled, false);
    for (final id in [
      'citizenId',
      'educationLevel',
      'specialty',
      'schoolHistory',
      'officerRating',
    ]) {
      expect(config(id).enabled, true, reason: id);
      expect(config(id).required, false, reason: id);
    }
    expect(config('aspiration1').required, true);
    expect(
      ProfileFieldCatalog.definitions
          .where((e) => e.section == ProfileFieldSection.subject)
          .map((e) => e.id)
          .take(3),
      ['fullName', 'dateOfBirth', 'citizenId'],
    );
    expect(defaults.where((c) => c.enabled).map((c) => c.fieldId).toList(), [
      'fullName',
      'dateOfBirth',
      'citizenId',
      'rank',
      'position',
      'unit',
      'enlistment',
      'hometown',
      'currentResidence',
      'educationLevel',
      'specialty',
      'schoolHistory',
      'officerRating',
      'aspiration1',
      'aspiration2',
      'aspiration3',
    ]);
  });

  test('legacy group receives defaults in memory without mutating storage', () {
    final group = WorkGroup.fromJson({
      'id': 'g1',
      'name': 'Nhóm cũ',
      'createdAt': now.toIso8601String(),
      'updatedAt': now.toIso8601String(),
    });
    expect(group.profileFieldSchemaVersion, 1);
    expect(group.profileFieldConfigs, isEmpty);
    expect(group.effectiveFieldConfigs, isNotEmpty);
    ProfileFieldConfig legacy(String id) =>
        group.effectiveFieldConfigs.firstWhere((e) => e.fieldId == id);
    expect(legacy('phone').enabled, true);
    expect(legacy('workTarget').enabled, true);
    expect(legacy('description').enabled, true);
    expect(legacy('note').enabled, true);
  });

  test('custom ID generator is stable-format and collision resistant', () {
    final instant = DateTime(2026, 1, 1);
    final generator = CustomFieldIdGenerator(clock: () => instant);
    final first = generator.nextFieldId();
    final second = generator.nextFieldId();
    expect(first, startsWith('custom_'));
    expect(first, isNot(second));
    expect(first, isNot(contains('/')));
  });

  test('new built-ins and custom values round-trip with canonical types', () {
    final original = profile(
      custom: {
        'custom_text': 'abc',
        'custom_number': 12.5,
        'custom_year': 2020,
        'custom_boolean': true,
        'custom_date': '2026-01-02',
        'custom_select': 'option_1',
      },
    );
    final restored = Profile.fromJson(original.toJson());
    expect(restored.citizenId, '001234');
    expect(restored.customFieldValues, original.customFieldValues);
    expect(restored.customFieldValues['custom_number'], isA<num>());
    expect(restored.customFieldValues['custom_year'], isA<int>());
    expect(restored.customFieldValues['custom_boolean'], isA<bool>());
  });

  test(
    'replaceDynamicValues can clear enabled values while hidden values persist',
    () {
      final original = profile(custom: {'custom_hidden': 'kept'});
      final cleared = original.replaceDynamicValues(
        citizenId: null,
        customFieldValues: Map.of(original.customFieldValues),
      );
      expect(cleared.citizenId, isNull);
      expect(cleared.customFieldValues['custom_hidden'], 'kept');
    },
  );

  test('group schema and custom single-select definitions round-trip', () {
    final definition = CustomFieldDefinition(
      id: 'custom_safe_1',
      label: 'Khu vực',
      section: ProfileFieldSection.subject,
      type: ProfileFieldType.singleSelect,
      createdAt: now,
      options: const [
        CustomFieldOption(id: 'north', label: 'Miền Bắc', order: 0),
      ],
    );
    final group = WorkGroup(
      id: 'g1',
      name: 'Nhóm',
      createdAt: now,
      updatedAt: now,
      profileFieldConfigs: [
        ...ProfileFieldCatalog.defaultConfigs(),
        const ProfileFieldConfig(
          fieldId: 'custom_safe_1',
          enabled: true,
          required: true,
          order: 20,
        ),
      ],
      customFieldDefinitions: [definition],
    );
    final restored = WorkGroup.fromJson(group.toJson());
    expect(restored.customFieldDefinitions.single.id, 'custom_safe_1');
    expect(restored.customFieldDefinitions.single.options.single.id, 'north');
    expect(restored.profileFieldConfigs.last.required, true);
  });

  test('renaming custom field and option preserves stable IDs and values', () {
    final option = const CustomFieldOption(
      id: 'option_stable',
      label: 'Cũ',
      order: 0,
    );
    final definition = CustomFieldDefinition(
      id: 'custom_stable',
      label: 'Tên cũ',
      section: ProfileFieldSection.subject,
      type: ProfileFieldType.singleSelect,
      options: [option],
      createdAt: now,
    );
    final renamed = definition.copyWith(
      label: 'Tên mới',
      options: [
        CustomFieldOption(
          id: option.id,
          label: 'Mới',
          active: false,
          order: option.order,
        ),
      ],
    );
    final value = profile(custom: {'custom_stable': 'option_stable'});
    expect(renamed.id, definition.id);
    expect(renamed.type, definition.type);
    expect(renamed.options.single.id, option.id);
    expect(renamed.options.single.active, false);
    expect(value.customFieldValues['custom_stable'], 'option_stable');
  });

  test('resolver honors enabled/order and always pins aspirations last', () {
    final defaults = ProfileFieldCatalog.defaultConfigs()
        .map((c) => c.fieldId == 'citizenId' ? c.copyWith(order: -1) : c)
        .toList();
    final group = WorkGroup(
      id: 'g1',
      name: 'Nhóm',
      createdAt: now,
      updatedAt: now,
      profileFieldConfigs: defaults,
    );
    final fields = const ProfileFieldResolver().resolve(group, profile());
    expect(fields.first.id, 'citizenId');
    expect(fields.sublist(fields.length - 3).map((e) => e.id), [
      'aspiration1',
      'aspiration2',
      'aspiration3',
    ]);
    expect(fields.any((e) => e.id == 'fatherFullName'), false);
  });
}
