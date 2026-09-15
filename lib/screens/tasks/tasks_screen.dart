import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/extensions/context_extensions.dart';
import '../../core/extensions/datetime_extensions.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/app_date_utils.dart';
import '../../models/models.dart';
import '../../repositories/app_repository.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/task_status_badge.dart';
import '../profiles/profile_detail_screen.dart';

enum _TaskFilter { all, overdue, today, waiting, inProgress, completed }

extension on _TaskFilter {
  String get label {
    switch (this) {
      case _TaskFilter.all:
        return 'Tất cả';
      case _TaskFilter.overdue:
        return 'Quá hạn';
      case _TaskFilter.today:
        return 'Hôm nay';
      case _TaskFilter.waiting:
        return 'Đang chờ';
      case _TaskFilter.inProgress:
        return 'Đang làm';
      case _TaskFilter.completed:
        return 'Hoàn thành';
    }
  }
}

/// Danh sách toàn bộ việc cần làm trên mọi hồ sơ — xem nhanh và lọc theo
/// trạng thái/hạn xử lý mà không cần mở từng hồ sơ.
class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  _TaskFilter _filter = _TaskFilter.all;

  bool _matches(TaskItem t) {
    switch (_filter) {
      case _TaskFilter.all:
        return t.status != TaskStatus.completed && t.status != TaskStatus.cancelled;
      case _TaskFilter.overdue:
        return t.status != TaskStatus.completed &&
            t.status != TaskStatus.cancelled &&
            t.dueDate != null &&
            AppDateUtils.isOverdue(t.dueDate!);
      case _TaskFilter.today:
        return t.status != TaskStatus.completed &&
            t.status != TaskStatus.cancelled &&
            t.dueDate != null &&
            AppDateUtils.isToday(t.dueDate!);
      case _TaskFilter.waiting:
        return t.status == TaskStatus.waiting;
      case _TaskFilter.inProgress:
        return t.status == TaskStatus.inProgress;
      case _TaskFilter.completed:
        return t.status == TaskStatus.completed;
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<AppRepository>();
    final allTasks = repo.allAggregates.expand((a) => a.tasks).toList();
    final tasks = allTasks.where(_matches).toList()
      ..sort((a, b) {
        final ad = a.dueDate;
        final bd = b.dueDate;
        if (ad == null && bd == null) return b.priority.index.compareTo(a.priority.index);
        if (ad == null) return 1;
        if (bd == null) return -1;
        return ad.compareTo(bd);
      });

    return Scaffold(
      appBar: AppBar(title: const Text('Việc cần làm')),
      body: Column(
        children: [
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              children: [
                for (final f in _TaskFilter.values)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text(f.label),
                      selected: _filter == f,
                      onSelected: (_) => setState(() => _filter = f),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: tasks.isEmpty
                ? const EmptyState(icon: Icons.checklist_rounded, title: 'Không có việc nào phù hợp')
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
                    itemCount: tasks.length,
                    itemBuilder: (context, i) => _TaskRow(task: tasks[i], repo: repo),
                  ),
          ),
        ],
      ),
    );
  }
}

class _TaskRow extends StatelessWidget {
  final TaskItem task;
  final AppRepository repo;

  const _TaskRow({required this.task, required this.repo});

  @override
  Widget build(BuildContext context) {
    final profile = repo.profileById(task.profileId);
    final overdue = task.status != TaskStatus.completed &&
        task.status != TaskStatus.cancelled &&
        task.dueDate != null &&
        AppDateUtils.isOverdue(task.dueDate!);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ProfileDetailScreen(profileId: task.profileId)),
        ),
        leading: Checkbox(
          value: task.status == TaskStatus.completed,
          onChanged: (v) {
            if (v == true) repo.markTaskCompleted(task.id);
          },
        ),
        title: Text(task.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Row(
          children: [
            Expanded(
              child: Text(
                profile?.fullName ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.bodySmall,
              ),
            ),
            TaskStatusBadge(status: task.status, compact: true),
          ],
        ),
        trailing: task.dueDate == null
            ? null
            : Text(
                task.dueDate!.ddMM,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: overdue ? FontWeight.bold : null,
                  color: overdue ? AppColors.overdue : context.colors.onSurfaceVariant,
                ),
              ),
      ),
    );
  }
}
