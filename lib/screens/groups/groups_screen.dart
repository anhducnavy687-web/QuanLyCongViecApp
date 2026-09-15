import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/extensions/context_extensions.dart';
import '../../models/models.dart';
import '../../repositories/app_repository.dart';
import '../../widgets/empty_state.dart';
import 'add_edit_group_sheet.dart';
import 'group_detail_screen.dart';

class GroupsScreen extends StatelessWidget {
  const GroupsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<AppRepository>();
    final groups = repo.groups;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nhóm công việc'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (_) => const AddEditGroupSheet(),
            ),
          ),
        ],
      ),
      body: groups.isEmpty
          ? const EmptyState(icon: Icons.folder_off_outlined, title: 'Chưa có nhóm công việc nào')
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              itemCount: groups.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) => _GroupCard(group: groups[i]),
            ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  final WorkGroup group;
  const _GroupCard({required this.group});

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<AppRepository>();
    final profiles = repo.profilesByGroup(group.id);
    final total = profiles.length;
    final inProgress = profiles.where((p) => p.status == ProfileStatus.inProgress).length;
    final waiting = profiles.where((p) => p.status == ProfileStatus.waiting).length;
    final completed = profiles.where((p) => p.status == ProfileStatus.completed).length;
    final overdue = profiles.where((p) {
      if (!p.hasDeadline || p.deadline == null) return false;
      return repo.aggregateOf(p.id).deadlineCategory == DeadlineCategory.overdue;
    }).length;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => GroupDetailScreen(groupId: group.id)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: context.colors.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.folder_rounded, color: context.colors.onPrimaryContainer, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      group.name,
                      style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: context.colors.onSurfaceVariant),
                ],
              ),
              if (group.description.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  group.description,
                  style: context.textTheme.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _miniStat(context, 'Tổng', total, context.colors.onSurfaceVariant),
                  _miniStat(context, 'Đang xử lý', inProgress, Colors.blue),
                  _miniStat(context, 'Đang chờ', waiting, Colors.purple),
                  _miniStat(context, 'Quá hạn', overdue, Colors.red),
                  _miniStat(context, 'Hoàn thành', completed, Colors.green),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniStat(BuildContext context, String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
