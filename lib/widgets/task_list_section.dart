import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/extensions/context_extensions.dart';
import '../core/extensions/datetime_extensions.dart';
import '../core/theme/app_colors.dart';
import '../models/models.dart';
import '../repositories/app_repository.dart';
import '../screens/tasks/add_edit_task_screen.dart';
import 'section_card.dart';
import 'task_status_badge.dart';

/// Danh sách việc cần làm của một hồ sơ — việc còn mở xếp trước (theo hạn
/// xử lý gần nhất), việc hoàn thành/hủy gộp lại phía dưới.
class TaskListSection extends StatelessWidget {
  final String profileId;

  const TaskListSection({super.key, required this.profileId});

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<AppRepository>();
    final tasks = [...repo.tasksOf(profileId)];

    final open = tasks.where((t) => t.status != TaskStatus.completed && t.status != TaskStatus.cancelled).toList()
      ..sort((a, b) {
        final ad = a.dueDate;
        final bd = b.dueDate;
        if (ad == null && bd == null) return b.priority.index.compareTo(a.priority.index);
        if (ad == null) return 1;
        if (bd == null) return -1;
        return ad.compareTo(bd);
      });
    final done = tasks.where((t) => t.status == TaskStatus.completed || t.status == TaskStatus.cancelled).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    return SectionCard(
      title: 'Việc cần làm',
      trailing: IconButton(
        icon: const Icon(Icons.add_rounded),
        tooltip: 'Thêm việc',
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => AddEditTaskScreen(profileId: profileId)),
        ),
      ),
      child: tasks.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('Chưa có việc cần làm nào.'),
            )
          : Column(
              children: [
                for (final t in open) _TaskTile(task: t, profileId: profileId),
                if (done.isNotEmpty) ...[
                  const Divider(),
                  for (final t in done) _TaskTile(task: t, profileId: profileId),
                ],
              ],
            ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  final TaskItem task;
  final String profileId;

  const _TaskTile({required this.task, required this.profileId});

  @override
  Widget build(BuildContext context) {
    final repo = context.read<AppRepository>();
    final isDone = task.status == TaskStatus.completed || task.status == TaskStatus.cancelled;
    final overdue = !isDone && task.dueDate != null && task.dueDate!.isBefore(DateTime.now()) &&
        !task.dueDate!.isSameDayAs(DateTime.now());

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Checkbox(
        value: task.status == TaskStatus.completed,
        onChanged: (v) {
          if (v == true) {
            repo.markTaskCompleted(task.id);
          }
        },
      ),
      title: Text(
        task.title,
        style: TextStyle(
          decoration: task.status == TaskStatus.completed ? TextDecoration.lineThrough : null,
          color: task.status == TaskStatus.cancelled ? context.colors.outline : null,
        ),
      ),
      subtitle: Row(
        children: [
          TaskStatusBadge(status: task.status, compact: true),
          const SizedBox(width: 6),
          TaskPriorityChip(priority: task.priority),
          if (task.dueDate != null) ...[
            const SizedBox(width: 6),
            Text(
              task.dueDate!.ddMM,
              style: TextStyle(
                fontSize: 11,
                color: overdue ? AppColors.overdue : context.colors.outline,
                fontWeight: overdue ? FontWeight.bold : null,
              ),
            ),
          ],
        ],
      ),
      trailing: PopupMenuButton<String>(
        onSelected: (v) {
          if (v == 'edit') {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => AddEditTaskScreen(profileId: profileId, task: task)),
            );
          } else if (v == 'delete') {
            repo.deleteTask(task.id);
          }
        },
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'edit', child: Text('Sửa')),
          PopupMenuItem(value: 'delete', child: Text('Xóa')),
        ],
      ),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => AddEditTaskScreen(profileId: profileId, task: task)),
      ),
    );
  }
}
