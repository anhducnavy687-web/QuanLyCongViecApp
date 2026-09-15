import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/extensions/context_extensions.dart';
import '../core/theme/app_colors.dart';
import '../models/models.dart';
import '../repositories/app_repository.dart';
import 'section_card.dart';

/// Hiển thị tiến độ theo CÁC BƯỚC (không dùng phần trăm): bước đã hoàn
/// thành, bước hiện tại, bước tiếp theo, các bước chưa thực hiện.
class StageStepList extends StatelessWidget {
  final String profileId;
  const StageStepList({super.key, required this.profileId});

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<AppRepository>();
    final stages = repo.stagesOf(profileId);

    return SectionCard(
      title: 'Các bước xử lý',
      trailing: IconButton(
        icon: const Icon(Icons.add_rounded),
        onPressed: () => _showAddStageDialog(context, repo, stages.length),
      ),
      child: stages.isEmpty
          ? Text('Chưa có bước nào', style: context.textTheme.bodySmall)
          : Column(
              children: [
                for (var i = 0; i < stages.length; i++)
                  _StageTile(
                    stage: stages[i],
                    isLast: i == stages.length - 1,
                    onTap: () => _showStageActions(context, repo, stages[i]),
                  ),
              ],
            ),
    );
  }

  void _showAddStageDialog(BuildContext context, AppRepository repo, int currentCount) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Thêm bước mới'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Tên bước'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          FilledButton(
            onPressed: () {
              final name = ctrl.text.trim();
              if (name.isEmpty) return;
              repo.addStage(WorkStage(
                id: '',
                profileId: profileId,
                name: name,
                order: currentCount,
              ));
              Navigator.pop(ctx);
            },
            child: const Text('Thêm'),
          ),
        ],
      ),
    );
  }

  void _showStageActions(BuildContext context, AppRepository repo, WorkStage stage) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              title: Text(stage.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(stage.status.label),
            ),
            const Divider(height: 1),
            if (stage.status != StageStatus.completed)
              ListTile(
                leading: const Icon(Icons.check_circle_outline_rounded, color: AppColors.completed),
                title: const Text('Đánh dấu hoàn thành'),
                onTap: () {
                  repo.markStageCompleted(stage.id);
                  Navigator.pop(ctx);
                },
              ),
            if (stage.status == StageStatus.pending)
              ListTile(
                leading: const Icon(Icons.play_circle_outline_rounded, color: AppColors.inProgress),
                title: const Text('Chuyển thành bước hiện tại'),
                onTap: () {
                  repo.setStageInProgress(stage.id);
                  Navigator.pop(ctx);
                },
              ),
            if (stage.status == StageStatus.completed)
              ListTile(
                leading: const Icon(Icons.undo_rounded),
                title: const Text('Bỏ đánh dấu hoàn thành'),
                onTap: () {
                  repo.setStageInProgress(stage.id);
                  Navigator.pop(ctx);
                },
              ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Sửa tên bước'),
              onTap: () {
                Navigator.pop(ctx);
                _editStageName(context, repo, stage);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline_rounded, color: context.colors.error),
              title: Text('Xóa bước', style: TextStyle(color: context.colors.error)),
              onTap: () {
                repo.deleteStage(stage.id);
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _editStageName(BuildContext context, AppRepository repo, WorkStage stage) {
    final ctrl = TextEditingController(text: stage.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sửa tên bước'),
        content: TextField(controller: ctrl, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          FilledButton(
            onPressed: () {
              final name = ctrl.text.trim();
              if (name.isNotEmpty) {
                repo.updateStage(stage.copyWith(name: name));
              }
              Navigator.pop(ctx);
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }
}

class _StageTile extends StatelessWidget {
  final WorkStage stage;
  final bool isLast;
  final VoidCallback onTap;

  const _StageTile({required this.stage, required this.isLast, required this.onTap});

  (Color, IconData) get _style {
    switch (stage.status) {
      case StageStatus.completed:
        return (AppColors.completed, Icons.check_rounded);
      case StageStatus.inProgress:
        return (AppColors.inProgress, Icons.play_arrow_rounded);
      case StageStatus.skipped:
        return (AppColors.cancelled, Icons.remove_rounded);
      case StageStatus.pending:
        return (Colors.grey, Icons.circle_outlined);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (color, icon) = _style;
    final isCurrent = stage.status == StageStatus.inProgress;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: stage.status == StageStatus.pending ? Colors.transparent : color,
                      shape: BoxShape.circle,
                      border: Border.all(color: color, width: 2),
                    ),
                    child: Icon(
                      icon,
                      size: 16,
                      color: stage.status == StageStatus.pending ? color : Colors.white,
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(width: 2, color: color.withValues(alpha: 0.3)),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stage.name,
                        style: TextStyle(
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                          color: stage.status == StageStatus.skipped ? Colors.grey : null,
                          decoration:
                              stage.status == StageStatus.skipped ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      if (isCurrent)
                        const Text(
                          'ĐANG THỰC HIỆN',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.inProgress,
                            letterSpacing: 0.5,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
