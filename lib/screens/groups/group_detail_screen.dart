import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/extensions/context_extensions.dart';
import '../../core/responsive/responsive.dart';
import '../../core/utils/repository_action.dart';
import '../../models/models.dart';
import '../../repositories/app_repository.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/profile_card.dart';
import 'add_edit_group_sheet.dart';

class GroupDetailScreen extends StatelessWidget {
  final String groupId;
  const GroupDetailScreen({super.key, required this.groupId});

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<AppRepository>();
    final group = repo.groupById(groupId);
    if (group == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(
          icon: Icons.folder_off_rounded,
          title: 'Nhóm không tồn tại',
        ),
      );
    }
    final aggregates =
        repo
            .profilesByGroup(groupId)
            .map((p) => repo.aggregateOf(p.id))
            .toList()
          ..sort(
            (a, b) => a.deadlineCategory.priority.compareTo(
              b.deadlineCategory.priority,
            ),
          );

    return Scaffold(
      appBar: AppBar(
        title: Text(group.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Sửa nhóm',
            onPressed: () => showResponsiveFormSheet(
              context: context,
              builder: (_) => AddEditGroupSheet(group: group),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            tooltip: 'Xóa nhóm',
            onPressed: () => _confirmDelete(context, repo, group),
          ),
        ],
      ),
      body: ResponsivePage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (group.description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Text(
                  group.description,
                  style: context.textTheme.bodyMedium,
                ),
              ),
            Expanded(
              child: aggregates.isEmpty
                  ? const EmptyState(
                      icon: Icons.folder_open_rounded,
                      title: 'Nhóm chưa có hồ sơ nào',
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                      children: [
                        for (final a in aggregates)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: ProfileCard(aggregate: a),
                          ),
                      ],
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
    WorkGroup group,
  ) {
    bool deleting = false;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Xóa nhóm công việc?'),
          content: Text(
            'Toàn bộ hồ sơ thuộc nhóm "${group.name}" sẽ bị xóa theo. '
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
                        () => repo.deleteGroup(group.id),
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
