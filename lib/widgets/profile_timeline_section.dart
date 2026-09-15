import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/extensions/context_extensions.dart';
import '../core/extensions/datetime_extensions.dart';
import '../models/models.dart';
import '../repositories/app_repository.dart';
import 'section_card.dart';

IconData _iconFor(TimelineEventType type) {
  switch (type) {
    case TimelineEventType.profileCreated:
      return Icons.person_add_rounded;
    case TimelineEventType.profileUpdated:
      return Icons.edit_rounded;
    case TimelineEventType.statusChanged:
      return Icons.sync_alt_rounded;
    case TimelineEventType.stageCompleted:
      return Icons.check_circle_rounded;
    case TimelineEventType.taskCreated:
      return Icons.playlist_add_rounded;
    case TimelineEventType.taskCompleted:
      return Icons.task_alt_rounded;
    case TimelineEventType.waitingStarted:
      return Icons.hourglass_top_rounded;
    case TimelineEventType.waitingResolved:
      return Icons.hourglass_bottom_rounded;
    case TimelineEventType.transaction:
      return Icons.attach_money_rounded;
    case TimelineEventType.note:
      return Icons.sticky_note_2_rounded;
  }
}

/// Lịch sử sự kiện (timeline) của một hồ sơ — hiển thị mới nhất trước, và
/// cho phép thêm ghi chú tự do vào timeline.
class ProfileTimelineSection extends StatelessWidget {
  final String profileId;

  const ProfileTimelineSection({super.key, required this.profileId});

  Future<void> _addNote(BuildContext context) async {
    final repo = context.read<AppRepository>();
    final ctrl = TextEditingController();
    final message = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Thêm ghi chú'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'Nội dung ghi chú...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Hủy')),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, ctrl.text.trim()),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
    if (message != null && message.isNotEmpty) {
      await repo.addTimelineNote(profileId, message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<AppRepository>();
    final events = [...repo.timelineOf(profileId)]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return SectionCard(
      title: 'Mốc thời gian',
      trailing: IconButton(
        icon: const Icon(Icons.add_rounded),
        tooltip: 'Thêm ghi chú',
        onPressed: () => _addNote(context),
      ),
      child: events.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('Chưa có sự kiện nào.'),
            )
          : Column(
              children: [
                for (final e in events)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    leading: Icon(_iconFor(e.type), size: 20, color: context.colors.primary),
                    title: Text(e.message),
                    subtitle: Text(e.createdAt.ddMMyyyyHHmm),
                  ),
              ],
            ),
    );
  }
}
