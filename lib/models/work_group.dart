import 'profile_field_schema.dart';

/// Nhóm công việc, dùng để phân loại các hồ sơ (VD: Đất đai, Hành chính...).
class WorkGroup {
  final String id;
  final String name;
  final String description;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int profileFieldSchemaVersion;
  final List<ProfileFieldConfig> profileFieldConfigs;
  final List<CustomFieldDefinition> customFieldDefinitions;

  const WorkGroup({
    required this.id,
    required this.name,
    this.description = '',
    required this.createdAt,
    required this.updatedAt,
    this.profileFieldSchemaVersion = 2,
    this.profileFieldConfigs = const [],
    this.customFieldDefinitions = const [],
  });

  WorkGroup copyWith({
    String? id,
    String? name,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? profileFieldSchemaVersion,
    List<ProfileFieldConfig>? profileFieldConfigs,
    List<CustomFieldDefinition>? customFieldDefinitions,
  }) {
    return WorkGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      profileFieldSchemaVersion:
          profileFieldSchemaVersion ?? this.profileFieldSchemaVersion,
      profileFieldConfigs: profileFieldConfigs ?? this.profileFieldConfigs,
      customFieldDefinitions:
          customFieldDefinitions ?? this.customFieldDefinitions,
    );
  }

  factory WorkGroup.fromJson(Map<String, dynamic> json) {
    return WorkGroup(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      profileFieldSchemaVersion: json['profileFieldSchemaVersion'] as int? ?? 1,
      profileFieldConfigs: [
        for (final value in (json['profileFieldConfigs'] as List? ?? const []))
          ProfileFieldConfig.fromJson(Map<String, dynamic>.from(value as Map)),
      ],
      customFieldDefinitions: [
        for (final value
            in (json['customFieldDefinitions'] as List? ?? const []))
          CustomFieldDefinition.fromJson(
            Map<String, dynamic>.from(value as Map),
          ),
      ],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'profileFieldSchemaVersion': profileFieldSchemaVersion,
      'profileFieldConfigs': effectiveFieldConfigs
          .map((e) => e.toJson())
          .toList(),
      'customFieldDefinitions': customFieldDefinitions
          .map((e) => e.toJson())
          .toList(),
    };
  }

  List<ProfileFieldConfig> get effectiveFieldConfigs =>
      profileFieldConfigs.isEmpty
      ? ProfileFieldCatalog.legacyCompatibleConfigs()
      : List.unmodifiable(profileFieldConfigs);
}
