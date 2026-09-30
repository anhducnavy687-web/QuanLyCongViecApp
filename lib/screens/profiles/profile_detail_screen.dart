import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/extensions/context_extensions.dart';
import '../../core/responsive/responsive.dart';
import '../../core/utils/repository_action.dart';
import '../../models/models.dart';
import '../../repositories/app_repository.dart';
import '../../services/profile_field_resolver.dart';
import '../../widgets/attachment_section.dart';
import '../../widgets/collaborator_assignment_section.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/money_section.dart';
import '../../widgets/profile_timeline_section.dart';
import '../../widgets/stage_step_list.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/task_list_section.dart';
import '../../widgets/timeline_bar.dart';
import 'add_edit_profile_screen.dart';
import 'trich_ngang_screen.dart';

/// Trang "Hồ sơ 360°" — toàn bộ thông tin của một hồ sơ được tổ chức theo
/// tab để dễ điều hướng: Tổng quan, Bước xử lý, Việc cần làm, Mốc thời gian,
/// Tiền, Cộng tác viên, Tài liệu.
///
/// Nút "Trích ngang" luôn nằm trên AppBar (không thuộc tab nào) để có thể
/// mở nhanh từ bất kỳ tab nào đang xem.
class ProfileDetailScreen extends StatelessWidget {
  final String profileId;
  final int initialTabIndex;
  const ProfileDetailScreen({
    super.key,
    required this.profileId,
    this.initialTabIndex = 0,
  });

  static const _tabs = [
    Tab(text: 'Tổng quan'),
    Tab(text: 'Bước xử lý'),
    Tab(text: 'Việc cần làm'),
    Tab(text: 'Mốc thời gian'),
    Tab(text: 'Tiền'),
    Tab(text: 'Cộng tác viên'),
    Tab(text: 'Tài liệu'),
  ];

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<AppRepository>();
    final profile = repo.profileById(profileId);
    if (profile == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(
          icon: Icons.person_off_rounded,
          title: 'Hồ sơ không tồn tại hoặc đã bị xóa',
        ),
      );
    }

    return DefaultTabController(
      length: _tabs.length,
      initialIndex: initialTabIndex,
      child: Scaffold(
        appBar: AppBar(
          title: Text(profile.fullName),
          actions: [
            IconButton(
              icon: const Icon(Icons.description_outlined),
              tooltip: 'Trích ngang',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => TrichNgangScreen(profileId: profileId),
                ),
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'edit') {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AddEditProfileScreen(profile: profile),
                    ),
                  );
                } else if (v == 'delete') {
                  _confirmDelete(context, repo, profileId);
                }
              },
              itemBuilder: (ctx) => const [
                PopupMenuItem(value: 'edit', child: Text('Sửa hồ sơ')),
                PopupMenuItem(value: 'delete', child: Text('Xóa hồ sơ')),
              ],
            ),
          ],
          bottom: TabBar(isScrollable: true, tabs: _tabs),
        ),
        body: TabBarView(
          children: [
            _OverviewTab(profileId: profileId),
            ResponsivePage(
              maxContentWidth: 720,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                children: [StageStepList(profileId: profileId)],
              ),
            ),
            ResponsivePage(
              maxContentWidth: 720,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                children: [TaskListSection(profileId: profileId)],
              ),
            ),
            ResponsivePage(
              maxContentWidth: 720,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                children: [ProfileTimelineSection(profileId: profileId)],
              ),
            ),
            ResponsivePage(
              maxContentWidth: 720,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                children: [MoneySection(profileId: profileId)],
              ),
            ),
            ResponsivePage(
              maxContentWidth: 720,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                children: [CollaboratorAssignmentSection(profileId: profileId)],
              ),
            ),
            ResponsivePage(
              maxContentWidth: 720,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                children: [AttachmentSection(profileId: profileId)],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    AppRepository repo,
    String profileId,
  ) {
    bool deleting = false;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Xóa hồ sơ?'),
          content: const Text(
            'Toàn bộ dữ liệu liên quan (bước xử lý, giao dịch, tài liệu...) sẽ bị xóa. '
            'Hành động này không thể hoàn tác.',
          ),
          actions: [
            TextButton(
              onPressed: deleting ? null : () => Navigator.pop(ctx),
              child: const Text('Hủy'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error,
              ),
              onPressed: deleting
                  ? null
                  : () async {
                      setState(() => deleting = true);
                      final deleted = await runRepositoryAction(
                        context,
                        () => repo.deleteProfile(profileId),
                      );
                      if (!ctx.mounted) return;
                      if (!deleted) {
                        setState(() => deleting = false);
                        return;
                      }
                      Navigator.pop(ctx);
                      if (context.mounted) Navigator.pop(context);
                    },
              child: deleting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Xóa'),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final String profileId;
  const _OverviewTab({required this.profileId});

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<AppRepository>();
    final profile = repo.profileById(profileId)!;
    final aggregate = repo.aggregateOf(profileId);
    final group = aggregate.group;
    final dynamicFields = group == null
        ? const <ResolvedProfileField>[]
        : const ProfileFieldResolver().resolve(group, profile).where((field) {
            final value = const ProfileFieldResolver().displayValue(
              field,
              group,
            );
            return value.isNotEmpty || field.required;
          }).toList();

    return ResponsivePage(
      maxContentWidth: 720,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [StatusBadge(status: profile.status)]),
                  if (aggregate.group != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.folder_outlined, size: 16),
                        const SizedBox(width: 6),
                        Text(aggregate.group!.name),
                      ],
                    ),
                  ],
                  const SizedBox(height: 14),
                  TimelineBar(
                    startDate: profile.startDate,
                    deadline: profile.deadline,
                    hasDeadline: profile.hasDeadline,
                  ),
                ],
              ),
            ),
          ),
          if (group != null && dynamicFields.isNotEmpty) ...[
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final section in ProfileFieldSection.values)
                      if (dynamicFields.any((f) => f.section == section)) ...[
                        Padding(
                          padding: const EdgeInsets.only(top: 8, bottom: 4),
                          child: Text(switch (section) {
                            ProfileFieldSection.subject =>
                              'Thông tin đối tượng',
                            ProfileFieldSection.family => 'Thông tin gia đình',
                            ProfileFieldSection.workContent =>
                              'Nội dung công việc',
                            ProfileFieldSection.aspiration => 'Nguyện vọng',
                          }, style: context.textTheme.titleMedium),
                        ),
                        for (final field in dynamicFields.where(
                          (f) => f.section == section,
                        ))
                          _DynamicDetailRow(field: field, group: group),
                      ],
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          ProfileTimelineSection(profileId: profileId),
        ],
      ),
    );
  }
}

class _DynamicDetailRow extends StatelessWidget {
  const _DynamicDetailRow({required this.field, required this.group});
  final ResolvedProfileField field;
  final WorkGroup group;

  @override
  Widget build(BuildContext context) {
    final value = const ProfileFieldResolver().displayValue(field, group);
    final isFather = field.id.startsWith('father');
    final isMother = field.id.startsWith('mother');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (field.id == 'fatherFullName' || field.id == 'motherFullName')
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              isFather ? 'Thông tin bố' : (isMother ? 'Thông tin mẹ' : ''),
              style: context.textTheme.labelLarge,
            ),
          ),
        const Divider(height: 16),
        Text(field.label, style: context.textTheme.labelMedium),
        const SizedBox(height: 2),
        Text(
          value.isEmpty ? 'Chưa có thông tin' : value,
          style: TextStyle(color: value.isEmpty ? context.colors.error : null),
        ),
      ],
    );
  }
}
