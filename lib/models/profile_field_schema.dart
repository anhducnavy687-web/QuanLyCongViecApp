enum ProfileFieldSection { subject, family, workContent, aspiration }

enum ProfileFieldType {
  text,
  multiline,
  number,
  date,
  year,
  boolean,
  singleSelect,
}

class CustomFieldIdGenerator {
  CustomFieldIdGenerator({DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;
  final DateTime Function() _clock;
  static int _sequence = 0;

  String nextFieldId() =>
      'custom_${_clock().microsecondsSinceEpoch}_${_sequence++}';
  String nextOptionId() =>
      'option_${_clock().microsecondsSinceEpoch}_${_sequence++}';
}

class ProfileBuiltInFieldDefinition {
  const ProfileBuiltInFieldDefinition({
    required this.id,
    required this.labelVi,
    required this.section,
    required this.type,
    required this.defaultEnabled,
    required this.defaultRequired,
    required this.defaultOrder,
    this.isSystemRequired = false,
    this.isPinnedBottom = false,
    this.pinnedOrder,
  });
  final String id;
  String get storageKey => id;
  final String labelVi;
  final ProfileFieldSection section;
  final ProfileFieldType type;
  final bool defaultEnabled;
  final bool defaultRequired;
  final int defaultOrder;
  final bool isSystemRequired;
  final bool isPinnedBottom;
  final int? pinnedOrder;
}

class ProfileFieldCatalog {
  static const definitions = <ProfileBuiltInFieldDefinition>[
    ProfileBuiltInFieldDefinition(
      id: 'fullName',
      labelVi: 'Họ và tên',
      section: ProfileFieldSection.subject,
      type: ProfileFieldType.text,
      defaultEnabled: true,
      defaultRequired: true,
      defaultOrder: 0,
      isSystemRequired: true,
    ),
    ProfileBuiltInFieldDefinition(
      id: 'dateOfBirth',
      labelVi: 'Ngày sinh',
      section: ProfileFieldSection.subject,
      type: ProfileFieldType.date,
      defaultEnabled: true,
      defaultRequired: true,
      defaultOrder: 1,
    ),
    ProfileBuiltInFieldDefinition(
      id: 'citizenId',
      labelVi: 'Số CCCD',
      section: ProfileFieldSection.subject,
      type: ProfileFieldType.text,
      defaultEnabled: true,
      defaultRequired: false,
      defaultOrder: 2,
    ),
    ProfileBuiltInFieldDefinition(
      id: 'rank',
      labelVi: 'Cấp bậc',
      section: ProfileFieldSection.subject,
      type: ProfileFieldType.text,
      defaultEnabled: true,
      defaultRequired: true,
      defaultOrder: 3,
    ),
    ProfileBuiltInFieldDefinition(
      id: 'position',
      labelVi: 'Chức vụ',
      section: ProfileFieldSection.subject,
      type: ProfileFieldType.text,
      defaultEnabled: true,
      defaultRequired: true,
      defaultOrder: 4,
    ),
    ProfileBuiltInFieldDefinition(
      id: 'unit',
      labelVi: 'Đơn vị',
      section: ProfileFieldSection.subject,
      type: ProfileFieldType.text,
      defaultEnabled: true,
      defaultRequired: true,
      defaultOrder: 5,
    ),
    ProfileBuiltInFieldDefinition(
      id: 'enlistment',
      labelVi: 'Nhập ngũ',
      section: ProfileFieldSection.subject,
      type: ProfileFieldType.text,
      defaultEnabled: true,
      defaultRequired: true,
      defaultOrder: 6,
    ),
    ProfileBuiltInFieldDefinition(
      id: 'hometown',
      labelVi: 'Quê quán',
      section: ProfileFieldSection.subject,
      type: ProfileFieldType.multiline,
      defaultEnabled: true,
      defaultRequired: true,
      defaultOrder: 7,
    ),
    ProfileBuiltInFieldDefinition(
      id: 'currentResidence',
      labelVi: 'Nơi ở hiện nay',
      section: ProfileFieldSection.subject,
      type: ProfileFieldType.multiline,
      defaultEnabled: true,
      defaultRequired: true,
      defaultOrder: 8,
    ),
    ProfileBuiltInFieldDefinition(
      id: 'educationLevel',
      labelVi: 'Trình độ',
      section: ProfileFieldSection.subject,
      type: ProfileFieldType.text,
      defaultEnabled: true,
      defaultRequired: false,
      defaultOrder: 9,
    ),
    ProfileBuiltInFieldDefinition(
      id: 'specialty',
      labelVi: 'Chuyên ngành',
      section: ProfileFieldSection.subject,
      type: ProfileFieldType.text,
      defaultEnabled: true,
      defaultRequired: false,
      defaultOrder: 10,
    ),
    ProfileBuiltInFieldDefinition(
      id: 'schoolHistory',
      labelVi: 'Qua trường',
      section: ProfileFieldSection.subject,
      type: ProfileFieldType.multiline,
      defaultEnabled: true,
      defaultRequired: false,
      defaultOrder: 11,
    ),
    ProfileBuiltInFieldDefinition(
      id: 'officerRating',
      labelVi: 'Xếp loại cán bộ',
      section: ProfileFieldSection.subject,
      type: ProfileFieldType.text,
      defaultEnabled: true,
      defaultRequired: false,
      defaultOrder: 12,
    ),
    ProfileBuiltInFieldDefinition(
      id: 'fatherFullName',
      labelVi: 'Họ và tên bố',
      section: ProfileFieldSection.family,
      type: ProfileFieldType.text,
      defaultEnabled: false,
      defaultRequired: false,
      defaultOrder: 0,
    ),
    ProfileBuiltInFieldDefinition(
      id: 'fatherBirthYear',
      labelVi: 'Năm sinh bố',
      section: ProfileFieldSection.family,
      type: ProfileFieldType.year,
      defaultEnabled: false,
      defaultRequired: false,
      defaultOrder: 1,
    ),
    ProfileBuiltInFieldDefinition(
      id: 'fatherOccupation',
      labelVi: 'Nghề nghiệp bố',
      section: ProfileFieldSection.family,
      type: ProfileFieldType.text,
      defaultEnabled: false,
      defaultRequired: false,
      defaultOrder: 2,
    ),
    ProfileBuiltInFieldDefinition(
      id: 'fatherHometown',
      labelVi: 'Quê quán bố',
      section: ProfileFieldSection.family,
      type: ProfileFieldType.text,
      defaultEnabled: false,
      defaultRequired: false,
      defaultOrder: 3,
    ),
    ProfileBuiltInFieldDefinition(
      id: 'fatherCurrentResidence',
      labelVi: 'Nơi ở hiện nay của bố',
      section: ProfileFieldSection.family,
      type: ProfileFieldType.multiline,
      defaultEnabled: false,
      defaultRequired: false,
      defaultOrder: 4,
    ),
    ProfileBuiltInFieldDefinition(
      id: 'motherFullName',
      labelVi: 'Họ và tên mẹ',
      section: ProfileFieldSection.family,
      type: ProfileFieldType.text,
      defaultEnabled: false,
      defaultRequired: false,
      defaultOrder: 5,
    ),
    ProfileBuiltInFieldDefinition(
      id: 'motherBirthYear',
      labelVi: 'Năm sinh mẹ',
      section: ProfileFieldSection.family,
      type: ProfileFieldType.year,
      defaultEnabled: false,
      defaultRequired: false,
      defaultOrder: 6,
    ),
    ProfileBuiltInFieldDefinition(
      id: 'motherOccupation',
      labelVi: 'Nghề nghiệp mẹ',
      section: ProfileFieldSection.family,
      type: ProfileFieldType.text,
      defaultEnabled: false,
      defaultRequired: false,
      defaultOrder: 7,
    ),
    ProfileBuiltInFieldDefinition(
      id: 'motherHometown',
      labelVi: 'Quê quán mẹ',
      section: ProfileFieldSection.family,
      type: ProfileFieldType.text,
      defaultEnabled: false,
      defaultRequired: false,
      defaultOrder: 8,
    ),
    ProfileBuiltInFieldDefinition(
      id: 'motherCurrentResidence',
      labelVi: 'Nơi ở hiện nay của mẹ',
      section: ProfileFieldSection.family,
      type: ProfileFieldType.multiline,
      defaultEnabled: false,
      defaultRequired: false,
      defaultOrder: 9,
    ),
    ProfileBuiltInFieldDefinition(
      id: 'phone',
      labelVi: 'Số điện thoại',
      section: ProfileFieldSection.workContent,
      type: ProfileFieldType.text,
      defaultEnabled: false,
      defaultRequired: false,
      defaultOrder: 0,
    ),
    ProfileBuiltInFieldDefinition(
      id: 'workTarget',
      labelVi: 'Mục tiêu/Nội dung công việc',
      section: ProfileFieldSection.workContent,
      type: ProfileFieldType.text,
      defaultEnabled: false,
      defaultRequired: false,
      defaultOrder: 1,
    ),
    ProfileBuiltInFieldDefinition(
      id: 'description',
      labelVi: 'Mô tả/Yêu cầu',
      section: ProfileFieldSection.workContent,
      type: ProfileFieldType.multiline,
      defaultEnabled: false,
      defaultRequired: false,
      defaultOrder: 2,
    ),
    ProfileBuiltInFieldDefinition(
      id: 'note',
      labelVi: 'Ghi chú',
      section: ProfileFieldSection.workContent,
      type: ProfileFieldType.multiline,
      defaultEnabled: false,
      defaultRequired: false,
      defaultOrder: 3,
    ),
    ProfileBuiltInFieldDefinition(
      id: 'aspiration1',
      labelVi: 'Nguyện vọng 1',
      section: ProfileFieldSection.aspiration,
      type: ProfileFieldType.multiline,
      defaultEnabled: true,
      defaultRequired: true,
      defaultOrder: 0,
      isPinnedBottom: true,
      pinnedOrder: 0,
    ),
    ProfileBuiltInFieldDefinition(
      id: 'aspiration2',
      labelVi: 'Nguyện vọng 2',
      section: ProfileFieldSection.aspiration,
      type: ProfileFieldType.multiline,
      defaultEnabled: true,
      defaultRequired: true,
      defaultOrder: 1,
      isPinnedBottom: true,
      pinnedOrder: 1,
    ),
    ProfileBuiltInFieldDefinition(
      id: 'aspiration3',
      labelVi: 'Nguyện vọng 3',
      section: ProfileFieldSection.aspiration,
      type: ProfileFieldType.multiline,
      defaultEnabled: true,
      defaultRequired: true,
      defaultOrder: 2,
      isPinnedBottom: true,
      pinnedOrder: 2,
    ),
  ];
  static ProfileBuiltInFieldDefinition? byId(String id) {
    for (final value in definitions) {
      if (value.id == id) return value;
    }
    return null;
  }

  static List<ProfileFieldConfig> defaultConfigs() => [
    for (final d in definitions)
      ProfileFieldConfig(
        fieldId: d.id,
        enabled: d.defaultEnabled,
        required: d.defaultRequired,
        order: d.defaultOrder,
      ),
  ];

  /// Compatibility policy for groups created before configurable fields.
  /// Legacy fields stay visible so existing production data does not appear
  /// to disappear. This value is computed only in memory until the group is
  /// explicitly saved.
  static List<ProfileFieldConfig> legacyCompatibleConfigs() => [
    for (final config in defaultConfigs())
      const {
            'phone',
            'workTarget',
            'description',
            'note',
          }.contains(config.fieldId)
          ? config.copyWith(enabled: true)
          : config,
  ];
}

class ProfileFieldConfig {
  const ProfileFieldConfig({
    required this.fieldId,
    required this.enabled,
    required this.required,
    required this.order,
  });
  final String fieldId;
  final bool enabled;
  final bool required;
  final int order;
  factory ProfileFieldConfig.fromJson(Map<String, dynamic> j) =>
      ProfileFieldConfig(
        fieldId: j['fieldId'] as String,
        enabled: j['enabled'] as bool? ?? false,
        required: j['required'] as bool? ?? false,
        order: j['order'] as int? ?? 0,
      );
  Map<String, dynamic> toJson() => {
    'fieldId': fieldId,
    'enabled': enabled,
    'required': required,
    'order': order,
  };
  ProfileFieldConfig copyWith({bool? enabled, bool? required, int? order}) =>
      ProfileFieldConfig(
        fieldId: fieldId,
        enabled: enabled ?? this.enabled,
        required: required ?? this.required,
        order: order ?? this.order,
      );
}

class CustomFieldOption {
  const CustomFieldOption({
    required this.id,
    required this.label,
    this.active = true,
    required this.order,
  });
  final String id;
  final String label;
  final bool active;
  final int order;
  factory CustomFieldOption.fromJson(Map<String, dynamic> j) =>
      CustomFieldOption(
        id: j['id'] as String,
        label: j['label'] as String,
        active: j['active'] as bool? ?? true,
        order: j['order'] as int? ?? 0,
      );
  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'active': active,
    'order': order,
  };
}

class CustomFieldDefinition {
  const CustomFieldDefinition({
    required this.id,
    required this.label,
    required this.section,
    required this.type,
    this.options = const [],
    required this.createdAt,
    this.active = true,
  });
  final String id;
  final String label;
  final ProfileFieldSection section;
  final ProfileFieldType type;
  final List<CustomFieldOption> options;
  final DateTime createdAt;
  final bool active;
  factory CustomFieldDefinition.fromJson(Map<String, dynamic> j) =>
      CustomFieldDefinition(
        id: j['id'] as String,
        label: j['label'] as String,
        section: ProfileFieldSection.values.byName(j['section'] as String),
        type: ProfileFieldType.values.byName(j['type'] as String),
        options: [
          for (final o in (j['options'] as List? ?? const []))
            CustomFieldOption.fromJson(Map<String, dynamic>.from(o as Map)),
        ],
        createdAt: DateTime.parse(j['createdAt'] as String),
        active: j['active'] as bool? ?? true,
      );
  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'section': section.name,
    'type': type.name,
    'options': options.map((e) => e.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'active': active,
  };

  CustomFieldDefinition copyWith({
    String? label,
    List<CustomFieldOption>? options,
    bool? active,
  }) => CustomFieldDefinition(
    id: id,
    label: label ?? this.label,
    section: section,
    type: type,
    options: options ?? this.options,
    createdAt: createdAt,
    active: active ?? this.active,
  );
}
