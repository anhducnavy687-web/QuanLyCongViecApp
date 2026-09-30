import '../models/models.dart';

class ResolvedProfileField {
  const ResolvedProfileField({
    required this.id,
    required this.label,
    required this.section,
    required this.type,
    required this.required,
    required this.value,
    this.custom = false,
  });
  final String id, label;
  final ProfileFieldSection section;
  final ProfileFieldType type;
  final bool required, custom;
  final Object? value;
}

class ProfileFieldResolver {
  const ProfileFieldResolver();
  List<ResolvedProfileField> resolve(
    WorkGroup group,
    Profile profile, {
    bool enabledOnly = true,
  }) {
    final configs = group.effectiveFieldConfigs;
    final normal = <ResolvedProfileField>[];
    final pinned = <ResolvedProfileField>[];
    for (final config in configs) {
      if (enabledOnly && !config.enabled) continue;
      final builtIn = ProfileFieldCatalog.byId(config.fieldId);
      CustomFieldDefinition? custom;
      for (final value in group.customFieldDefinitions) {
        if (value.id == config.fieldId) custom = value;
      }
      if (builtIn == null && custom == null) continue;
      if (custom != null && !custom.active) continue;
      final field = ResolvedProfileField(
        id: config.fieldId,
        label: builtIn?.labelVi ?? custom!.label,
        section: builtIn?.section ?? custom!.section,
        type: builtIn?.type ?? custom!.type,
        required: config.required,
        value: builtIn == null
            ? profile.customFieldValues[config.fieldId]
            : builtInValue(profile, config.fieldId),
        custom: builtIn == null,
      );
      (builtIn?.isPinnedBottom == true ? pinned : normal).add(field);
    }
    int sectionOrder(ProfileFieldSection section) => switch (section) {
      ProfileFieldSection.subject => 0,
      ProfileFieldSection.family => 1,
      ProfileFieldSection.workContent => 2,
      ProfileFieldSection.aspiration => 3,
    };
    normal.sort((a, b) {
      final bySection = sectionOrder(a.section)
          .compareTo(sectionOrder(b.section));
      if (bySection != 0) return bySection;
      return configs
          .firstWhere((e) => e.fieldId == a.id)
          .order
          .compareTo(configs.firstWhere((e) => e.fieldId == b.id).order);
    });
    pinned.sort(
      (a, b) => (ProfileFieldCatalog.byId(
        a.id,
      )!.pinnedOrder!).compareTo(ProfileFieldCatalog.byId(b.id)!.pinnedOrder!),
    );
    return [...normal, ...pinned];
  }

  Object? builtInValue(Profile p, String id) => switch (id) {
    'fullName' => p.fullName,
    'phone' => p.phone,
    'workTarget' => p.workTarget,
    'description' => p.description,
    'note' => p.note,
    'dateOfBirth' => p.dateOfBirth,
    'citizenId' => p.citizenId,
    'rank' => p.rank,
    'position' => p.position,
    'unit' => p.unit,
    'enlistment' => p.enlistment,
    'hometown' => p.hometown,
    'currentResidence' => p.currentResidence,
    'educationLevel' => p.educationLevel,
    'specialty' => p.specialty,
    'schoolHistory' => p.schoolHistory,
    'officerRating' => p.officerRating,
    'fatherFullName' => p.fatherFullName,
    'fatherBirthYear' => p.fatherBirthYear,
    'fatherOccupation' => p.fatherOccupation,
    'fatherHometown' => p.fatherHometown,
    'fatherCurrentResidence' => p.fatherCurrentResidence,
    'motherFullName' => p.motherFullName,
    'motherBirthYear' => p.motherBirthYear,
    'motherOccupation' => p.motherOccupation,
    'motherHometown' => p.motherHometown,
    'motherCurrentResidence' => p.motherCurrentResidence,
    'aspiration1' => p.aspiration1,
    'aspiration2' => p.aspiration2,
    'aspiration3' => p.aspiration3,
    _ => null,
  };
  String displayValue(ResolvedProfileField f, WorkGroup group) {
    final v = f.value;
    if (v == null) return '';
    if (v is DateTime) {
      return '${v.day.toString().padLeft(2, '0')}/${v.month.toString().padLeft(2, '0')}/${v.year}';
    }
    if (v is bool) return v ? 'Có' : 'Không';
    if (f.type == ProfileFieldType.singleSelect) {
      for (final d in group.customFieldDefinitions.where((e) => e.id == f.id)) {
        for (final o in d.options) {
          if (o.id == v) return o.label;
        }
      }
    }
    return v.toString();
  }
}
