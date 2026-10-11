import '../../models/models.dart';

enum GroupProfileTemplateMode { allEnabled, requiredOnly }

class GroupProfileTemplateBuilder {
  const GroupProfileTemplateBuilder();

  static const intro =
      'Vui lòng điền các thông tin dưới đây và gửi lại giúp tôi:';
  static const maxInlineOptions = 6;

  String build(
    WorkGroup group, {
    GroupProfileTemplateMode mode = GroupProfileTemplateMode.allEnabled,
  }) {
    final configs = group.effectiveFieldConfigs;
    final definitions = {
      for (final definition in group.customFieldDefinitions)
        definition.id: definition,
    };
    final normal = <_TemplateField>[];
    final pinned = <_TemplateField>[];

    for (final config in configs) {
      if (!config.enabled ||
          (mode == GroupProfileTemplateMode.requiredOnly && !config.required)) {
        continue;
      }
      final builtIn = ProfileFieldCatalog.byId(config.fieldId);
      final custom = definitions[config.fieldId];
      if (builtIn == null && custom == null) continue;
      if (custom != null && !custom.active) continue;

      final field = _TemplateField(
        id: config.fieldId,
        label: (builtIn?.labelVi ?? custom!.label).trim(),
        section: builtIn?.section ?? custom!.section,
        type: builtIn?.type ?? custom!.type,
        order: config.order,
        pinnedOrder: builtIn?.isPinnedBottom == true
            ? builtIn!.pinnedOrder
            : null,
        options: custom?.options ?? const [],
      );
      if (field.label.isEmpty) continue;
      (field.pinnedOrder == null ? normal : pinned).add(field);
    }

    normal.sort((a, b) {
      final bySection = _sectionOrder(a.section)
          .compareTo(_sectionOrder(b.section));
      if (bySection != 0) return bySection;
      final byOrder = a.order.compareTo(b.order);
      return byOrder != 0 ? byOrder : a.id.compareTo(b.id);
    });
    pinned.sort((a, b) {
      final byPinnedOrder = a.pinnedOrder!.compareTo(b.pinnedOrder!);
      return byPinnedOrder != 0 ? byPinnedOrder : a.id.compareTo(b.id);
    });

    final fields = [...normal, ...pinned];
    if (fields.isEmpty) return '';
    return '$intro\n\n${fields.map(_render).join('\n')}';
  }

  static int _sectionOrder(ProfileFieldSection section) => switch (section) {
    ProfileFieldSection.subject => 0,
    ProfileFieldSection.family => 1,
    ProfileFieldSection.workContent => 2,
    ProfileFieldSection.aspiration => 3,
  };

  static String _render(_TemplateField field) {
    if (field.type == ProfileFieldType.boolean) {
      return '${field.label} (Có/Không):';
    }
    if (field.type == ProfileFieldType.singleSelect) {
      final options = field.options.where((option) => option.active).toList()
        ..sort((a, b) {
          final byOrder = a.order.compareTo(b.order);
          return byOrder != 0 ? byOrder : a.id.compareTo(b.id);
        });
      final labels = options
          .map((option) => option.label.trim())
          .where((label) => label.isNotEmpty)
          .toList();
      if (labels.isNotEmpty && labels.length <= maxInlineOptions) {
        return '${field.label} (${labels.join(' / ')}):';
      }
    }
    return '${field.label}:';
  }
}

class _TemplateField {
  const _TemplateField({
    required this.id,
    required this.label,
    required this.section,
    required this.type,
    required this.order,
    required this.pinnedOrder,
    required this.options,
  });

  final String id;
  final String label;
  final ProfileFieldSection section;
  final ProfileFieldType type;
  final int order;
  final int? pinnedOrder;
  final List<CustomFieldOption> options;
}
