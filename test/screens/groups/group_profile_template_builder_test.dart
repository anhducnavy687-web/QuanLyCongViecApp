import 'package:flutter_test/flutter_test.dart';
import 'package:quanlycongviecapp/models/models.dart';
import 'package:quanlycongviecapp/screens/groups/group_profile_template_builder.dart';

void main() {
  const builder = GroupProfileTemplateBuilder();
  final now = DateTime(2026, 10, 11);

  WorkGroup group({
    required List<ProfileFieldConfig> configs,
    List<CustomFieldDefinition> custom = const [],
  }) => WorkGroup(
    id: 'g1',
    name: 'Nhóm kiểm thử',
    createdAt: now,
    updatedAt: now,
    profileFieldConfigs: configs,
    customFieldDefinitions: custom,
  );

  ProfileFieldConfig config(
    String id, {
    bool enabled = true,
    bool required = false,
    int order = 0,
  }) => ProfileFieldConfig(
    fieldId: id,
    enabled: enabled,
    required: required,
    order: order,
  );

  test('enabled built-ins render with intro and no trailing whitespace', () {
    final text = builder.build(
      group(
        configs: [
          config('fullName', required: true),
          config('dateOfBirth', order: 1),
        ],
      ),
    );
    expect(
      text,
      '${GroupProfileTemplateBuilder.intro}\n\nHọ và tên:\nNgày sinh:',
    );
    expect(text, isNot(endsWith('\n')));
    expect(text.split('\n').any((line) => line.endsWith(' ')), false);
  });

  test('disabled and unknown internal fields are excluded', () {
    final text = builder.build(
      group(
        configs: [
          config('fullName', required: true),
          config('phone', enabled: false),
          config('deadline'),
          config('amount'),
        ],
      ),
    );
    expect(text, contains('Họ và tên:'));
    expect(text, isNot(contains('Số điện thoại')));
    expect(text, isNot(contains('deadline')));
    expect(text, isNot(contains('amount')));
  });

  test('required-only keeps enabled required fields only', () {
    final value = group(
      configs: [
        config('fullName', required: true),
        config('rank', required: true, order: 1),
        config('position', order: 2),
        config('unit', enabled: false, required: true, order: 3),
      ],
    );
    final text = builder.build(
      value,
      mode: GroupProfileTemplateMode.requiredOnly,
    );
    expect(text, contains('Họ và tên:'));
    expect(text, contains('Cấp bậc:'));
    expect(text, isNot(contains('Chức vụ:')));
    expect(text, isNot(contains('Đơn vị:')));
  });

  test('section and configured field order are preserved', () {
    final text = builder.build(
      group(
        configs: [
          config('position', order: 2),
          config('rank', order: 1),
          config('fatherFullName', order: 0),
          config('workTarget', order: 0),
        ],
      ),
    );
    expect(_lines(text), [
      'Cấp bậc:',
      'Chức vụ:',
      'Họ và tên bố:',
      'Mục tiêu/Nội dung công việc:',
    ]);
  });

  test('aspirations stay 1, 2, 3 at the end', () {
    final text = builder.build(
      group(
        configs: [
          config('aspiration3', order: -3),
          config('aspiration1', order: 99),
          config('rank', order: 1),
          config('aspiration2', order: -2),
        ],
      ),
    );
    expect(_lines(text), [
      'Cấp bậc:',
      'Nguyện vọng 1:',
      'Nguyện vọng 2:',
      'Nguyện vọng 3:',
    ]);
  });

  for (final type in [ProfileFieldType.text, ProfileFieldType.multiline]) {
    test('custom ${type.name} field uses current display label', () {
      final text = builder.build(
        group(
          configs: [config('custom_home')],
          custom: [
            CustomFieldDefinition(
              id: 'custom_home',
              label: 'Tình trạng nhà ở',
              section: ProfileFieldSection.subject,
              type: type,
              createdAt: now,
            ),
          ],
        ),
      );
      expect(_lines(text), ['Tình trạng nhà ở:']);
    });
  }

  test('inactive custom field is excluded', () {
    final text = builder.build(
      group(
        configs: [config('custom_hidden')],
        custom: [
          CustomFieldDefinition(
            id: 'custom_hidden',
            label: 'Đã ẩn',
            section: ProfileFieldSection.subject,
            type: ProfileFieldType.text,
            createdAt: now,
            active: false,
          ),
        ],
      ),
    );
    expect(text, isEmpty);
  });

  test('boolean field renders a clear Có/Không hint', () {
    final text = builder.build(
      group(
        configs: [config('custom_boolean')],
        custom: [
          CustomFieldDefinition(
            id: 'custom_boolean',
            label: 'Đã qua trường',
            section: ProfileFieldSection.subject,
            type: ProfileFieldType.boolean,
            createdAt: now,
          ),
        ],
      ),
    );
    expect(_lines(text), ['Đã qua trường (Có/Không):']);
  });

  test('single-select includes active options in configured order', () {
    final text = builder.build(_selectGroup(now));
    expect(_lines(text), ['Xếp loại (A / B / C):']);
    expect(text, isNot(contains('D')));
  });

  test('single-select over threshold omits all option hints', () {
    final options = [
      for (var i = 0; i < GroupProfileTemplateBuilder.maxInlineOptions + 1; i++)
        CustomFieldOption(id: 'o$i', label: 'Lựa chọn $i', order: i),
    ];
    final text = builder.build(
      group(
        configs: [config('custom_select')],
        custom: [
          CustomFieldDefinition(
            id: 'custom_select',
            label: 'Khu vực',
            section: ProfileFieldSection.subject,
            type: ProfileFieldType.singleSelect,
            options: options,
            createdAt: now,
          ),
        ],
      ),
    );
    expect(_lines(text), ['Khu vực:']);
    expect(text, isNot(contains('...')));
  });

  test('legacy Group uses in-memory compatibility configuration', () {
    final legacy = WorkGroup.fromJson({
      'id': 'legacy',
      'name': 'Nhóm cũ',
      'createdAt': now.toIso8601String(),
      'updatedAt': now.toIso8601String(),
    });
    final text = builder.build(legacy);
    expect(text, contains('Họ và tên:'));
    expect(text, contains('Số điện thoại:'));
    expect(text, contains('Mục tiêu/Nội dung công việc:'));
    expect(legacy.profileFieldConfigs, isEmpty);
  });

  test('output is deterministic', () {
    final value = _selectGroup(now);
    expect(builder.build(value), builder.build(value));
  });
}

List<String> _lines(String text) => text.split('\n').skip(2).toList();

WorkGroup _selectGroup(DateTime now) => WorkGroup(
  id: 'g1',
  name: 'Nhóm',
  createdAt: now,
  updatedAt: now,
  profileFieldConfigs: const [
    ProfileFieldConfig(
      fieldId: 'custom_select',
      enabled: true,
      required: false,
      order: 0,
    ),
  ],
  customFieldDefinitions: [
    CustomFieldDefinition(
      id: 'custom_select',
      label: 'Xếp loại',
      section: ProfileFieldSection.subject,
      type: ProfileFieldType.singleSelect,
      createdAt: now,
      options: const [
        CustomFieldOption(id: 'c', label: 'C', order: 2),
        CustomFieldOption(id: 'd', label: 'D', active: false, order: 3),
        CustomFieldOption(id: 'a', label: 'A', order: 0),
        CustomFieldOption(id: 'b', label: 'B', order: 1),
      ],
    ),
  ],
);
