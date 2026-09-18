import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/extensions/context_extensions.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/confirm_destructive_action.dart';
import '../core/utils/repository_action.dart';
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
        tooltip: 'Thêm bước xử lý',
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

  void _showAddStageDialog(
    BuildContext context,
    AppRepository repo,
    int currentCount,
  ) {
    final ctrl = TextEditingController();
    bool saving = false;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Thêm bước mới'),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Tên bước'),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(ctx),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: saving
                  ? null
                  : () async {
                      final name = ctrl.text.trim();
                      if (name.isEmpty) return;
                      setState(() => saving = true);
                      final saved = await runRepositoryAction(
                        context,
                        () async {
                          await repo.addStage(
                            WorkStage(
                              id: '',
                              profileId: profileId,
                              name: name,
                              order: currentCount,
                            ),
                          );
                        },
                      );
                      if (!ctx.mounted) return;
                      if (saved) Navigator.pop(ctx);
                      if (!saved) setState(() => saving = false);
                    },
              child: saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Thêm'),
            ),
          ],
        ),
      ),
    );
  }

  void _showStageActions(
    BuildContext context,
    AppRepository repo,
    WorkStage stage,
  ) {
    bool saving = false;
    showModalBottomSheet(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => SafeArea(
          child: IgnorePointer(
            ignoring: saving,
            child: Wrap(
              children: [
                ListTile(
                  title: Text(
                    stage.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(stage.status.label),
                ),
                const Divider(height: 1),
                if (stage.status != StageStatus.completed)
                  ListTile(
                    leading: const Icon(
                      Icons.check_circle_outline_rounded,
                      color: AppColors.completed,
                    ),
                    title: const Text('Đánh dấu hoàn thành'),
                    onTap: () async {
                      setState(() => saving = true);
                      final saved = await runRepositoryAction(
                        context,
                        () => repo.markStageCompleted(stage.id),
                      );
                      if (!ctx.mounted) return;
                      if (saved) Navigator.pop(ctx);
                      if (!saved) setState(() => saving = false);
                    },
                  ),
                if (stage.status == StageStatus.pending)
                  ListTile(
                    leading: const Icon(
                      Icons.play_circle_outline_rounded,
                      color: AppColors.inProgress,
                    ),
                    title: const Text('Chuyển thành bước hiện tại'),
                    onTap: () async {
                      setState(() => saving = true);
                      final saved = await runRepositoryAction(
                        context,
                        () => repo.setStageInProgress(stage.id),
                      );
                      if (!ctx.mounted) return;
                      if (saved) Navigator.pop(ctx);
                      if (!saved) setState(() => saving = false);
                    },
                  ),
                if (stage.status == StageStatus.completed)
                  ListTile(
                    leading: const Icon(Icons.undo_rounded),
                    title: const Text('Bỏ đánh dấu hoàn thành'),
                    onTap: () async {
                      setState(() => saving = true);
                      final saved = await runRepositoryAction(
                        context,
                        () => repo.setStageInProgress(stage.id),
                      );
                      if (!ctx.mounted) return;
                      if (saved) Navigator.pop(ctx);
                      if (!saved) setState(() => saving = false);
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
                  leading: Icon(
                    Icons.delete_outline_rounded,
                    color: context.colors.error,
                  ),
                  title: Text(
                    'Xóa bước',
                    style: TextStyle(color: context.colors.error),
                  ),
                  onTap: () async {
                    final confirmed = await confirmDestructiveAction(
                      context,
                      title: 'Xóa bước xử lý?',
                      message:
                          'Bước "${stage.name}" sẽ bị xóa và không thể hoàn tác.',
                    );
                    if (!confirmed || !ctx.mounted) return;
                    setState(() => saving = true);
                    final saved = await runRepositoryAction(
                      context,
                      () => repo.deleteStage(stage.id),
                    );
                    if (!ctx.mounted) return;
                    if (saved) Navigator.pop(ctx);
                    if (!saved) setState(() => saving = false);
                  },
                ),
                if (saving)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _editStageName(
    BuildContext context,
    AppRepository repo,
    WorkStage stage,
  ) {
    final ctrl = TextEditingController(text: stage.name);
    bool saving = false;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Sửa tên bước'),
          content: TextField(controller: ctrl, autofocus: true),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(ctx),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: saving
                  ? null
                  : () async {
                      final name = ctrl.text.trim();
                      if (name.isEmpty) return;
                      setState(() => saving = true);
                      final saved = await runRepositoryAction(
                        context,
                        () => repo.updateStage(stage.copyWith(name: name)),
                      );
                      if (!ctx.mounted) return;
                      if (saved) Navigator.pop(ctx);
                      if (!saved) setState(() => saving = false);
                    },
              child: saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StageTile extends StatelessWidget {
  final WorkStage stage;
  final bool isLast;
  final VoidCallback onTap;

  const _StageTile({
    required this.stage,
    required this.isLast,
    required this.onTap,
  });

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
                      color: stage.status == StageStatus.pending
                          ? Colors.transparent
                          : color,
                      shape: BoxShape.circle,
                      border: Border.all(color: color, width: 2),
                    ),
                    child: Icon(
                      icon,
                      size: 16,
                      color: stage.status == StageStatus.pending
                          ? color
                          : Colors.white,
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        color: color.withValues(alpha: 0.3),
                      ),
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
                          fontWeight: isCurrent
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: stage.status == StageStatus.skipped
                              ? Colors.grey
                              : null,
                          decoration: stage.status == StageStatus.skipped
                              ? TextDecoration.lineThrough
                              : null,
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
