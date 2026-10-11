import '../../models/models.dart';
import '../../screens/groups/group_profile_template_builder.dart';
import '../../services/profile_field_resolver.dart';

class ProfileInformationTextBuilder {
  const ProfileInformationTextBuilder({
    this.resolver = const ProfileFieldResolver(),
  });

  static const profileCopyHeader = 'THÔNG TIN HỒ SƠ';

  final ProfileFieldResolver resolver;

  String build(
    WorkGroup group,
    Profile profile, {
    GroupProfileTemplateMode mode = GroupProfileTemplateMode.allEnabled,
    String header = profileCopyHeader,
  }) {
    final fields = resolver
        .resolve(group, profile)
        .where(
          (field) =>
              mode == GroupProfileTemplateMode.allEnabled || field.required,
        )
        .toList();
    if (fields.isEmpty) return '';

    final lines = fields.map((field) {
      final label = field.label.trim();
      final value = _displayValue(field, group).trimRight();
      return value.isEmpty ? '$label:' : '$label: $value';
    });
    return '$header\n\n${lines.join('\n')}';
  }

  String _displayValue(ResolvedProfileField field, WorkGroup group) {
    final value = field.value;
    if (value == null) return '';

    if (field.type == ProfileFieldType.date && value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) {
        return resolver.displayValue(
          ResolvedProfileField(
            id: field.id,
            label: field.label,
            section: field.section,
            type: field.type,
            required: field.required,
            value: parsed,
            custom: field.custom,
          ),
          group,
        );
      }
    }
    if (field.type == ProfileFieldType.year) {
      if (value is DateTime) return value.year.toString();
      if (value is num) return value.toInt().toString();
    }
    if (field.type == ProfileFieldType.number && value is num) {
      return value == value.toInt()
          ? value.toInt().toString()
          : value.toString();
    }
    return resolver.displayValue(field, group);
  }
}
