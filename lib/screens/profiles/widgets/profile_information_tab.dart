import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../models/models.dart';
import '../../../repositories/app_repository.dart';
import '../../../services/profile_field_resolver.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/section_card.dart';

class ProfileInformationTab extends StatelessWidget {
  const ProfileInformationTab({super.key, required this.profileId});
  final String profileId;

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<AppRepository>();
    final aggregate = repo.aggregateOf(profileId);
    final group = aggregate.group;
    if (group == null) {
      return const EmptyState(
        icon: Icons.info_outline_rounded,
        title: 'Không tìm thấy cấu hình nhóm',
      );
    }
    const resolver = ProfileFieldResolver();
    final fields = resolver.resolve(group, aggregate.profile).where((field) {
      if (field.id == 'fullName') return false;
      final value = resolver.displayValue(field, group);
      return value.isNotEmpty || field.required;
    }).toList();

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1040),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          children: [
            for (final section in ProfileFieldSection.values)
              if (fields.any((field) => field.section == section))
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _InformationSection(
                    section: section,
                    fields: fields
                        .where((field) => field.section == section)
                        .toList(),
                    group: group,
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _InformationSection extends StatelessWidget {
  const _InformationSection({
    required this.section,
    required this.fields,
    required this.group,
  });
  final ProfileFieldSection section;
  final List<ResolvedProfileField> fields;
  final WorkGroup group;

  @override
  Widget build(BuildContext context) => SectionCard(
    title: switch (section) {
      ProfileFieldSection.subject => 'Thông tin đối tượng',
      ProfileFieldSection.family => 'Thông tin gia đình',
      ProfileFieldSection.workContent => 'Nội dung công việc',
      ProfileFieldSection.aspiration => 'Nguyện vọng',
    },
    child: LayoutBuilder(
      builder: (context, constraints) {
        final twoColumns = constraints.maxWidth >= 680;
        final width = twoColumns
            ? (constraints.maxWidth - 24) / 2
            : constraints.maxWidth;
        return Wrap(
          spacing: 24,
          runSpacing: 0,
          children: [
            for (var index = 0; index < fields.length; index++)
              SizedBox(
                width: width,
                child: _InformationRow(
                  field: fields[index],
                  group: group,
                  familyLabel: _familyLabel(index),
                ),
              ),
          ],
        );
      },
    ),
  );

  String? _familyLabel(int index) {
    if (section != ProfileFieldSection.family) return null;
    final id = fields[index].id;
    if (id.startsWith('father') &&
        (index == 0 || !fields[index - 1].id.startsWith('father'))) {
      return 'BỐ';
    }
    if (id.startsWith('mother') &&
        (index == 0 || !fields[index - 1].id.startsWith('mother'))) {
      return 'MẸ';
    }
    return null;
  }
}

class _InformationRow extends StatelessWidget {
  const _InformationRow({
    required this.field,
    required this.group,
    this.familyLabel,
  });
  final ResolvedProfileField field;
  final WorkGroup group;
  final String? familyLabel;

  @override
  Widget build(BuildContext context) {
    final value = const ProfileFieldResolver().displayValue(field, group);
    final missing = value.isEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (familyLabel != null)
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 2),
            child: Text(familyLabel!, style: context.textTheme.labelLarge),
          ),
        const Divider(height: 16),
        Text(field.label, style: context.textTheme.labelMedium),
        const SizedBox(height: 3),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (missing) ...[
              Icon(
                Icons.info_outline_rounded,
                size: 16,
                color: context.colors.outline,
              ),
              const SizedBox(width: 5),
            ],
            Expanded(
              child: Text(
                missing ? 'Chưa có thông tin' : value,
                style: TextStyle(
                  color: missing ? context.colors.outline : null,
                  fontStyle: missing ? FontStyle.italic : null,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
