import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/extensions/context_extensions.dart';
import '../core/utils/money_utils.dart';
import '../core/utils/validators.dart';
import '../models/models.dart';
import '../repositories/app_repository.dart';
import 'section_card.dart';

class CollaboratorAssignmentSection extends StatelessWidget {
  final String profileId;
  const CollaboratorAssignmentSection({super.key, required this.profileId});

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<AppRepository>();
    final assignments = repo.assignmentsOf(profileId);

    return SectionCard(
      title: 'Cộng tác viên',
      trailing: IconButton(
        icon: const Icon(Icons.person_add_alt_1_rounded),
        onPressed: () => _showAssignDialog(context, repo),
      ),
      child: assignments.isEmpty
          ? Text('Chưa gán cộng tác viên nào', style: context.textTheme.bodySmall)
          : Column(
              children: assignments.map((a) {
                final collaborator = repo.collaboratorById(a.collaboratorId);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(collaborator?.name ?? 'Đã xóa',
                                    style: const TextStyle(fontWeight: FontWeight.w700)),
                                if (a.role.isNotEmpty)
                                  Text(a.role, style: context.textTheme.bodySmall),
                              ],
                            ),
                          ),
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert_rounded, size: 18),
                            onSelected: (v) {
                              if (v == 'pay') {
                                _showPayDialog(context, repo, a);
                              } else if (v == 'delete') {
                                repo.deleteAssignment(a.id);
                              }
                            },
                            itemBuilder: (ctx) => const [
                              PopupMenuItem(value: 'pay', child: Text('Trả hoa hồng')),
                              PopupMenuItem(value: 'delete', child: Text('Gỡ khỏi hồ sơ')),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${MoneyUtils.format(a.paidAmount)} / ${MoneyUtils.format(a.commissionAmount)}'
                        ' (còn ${MoneyUtils.format(a.remainingAmount)})',
                        style: const TextStyle(fontSize: 12.5),
                      ),
                      const Divider(height: 16),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  void _showAssignDialog(BuildContext context, AppRepository repo) {
    final collaborators = repo.collaborators;
    if (collaborators.isEmpty) {
      context.showSnackBar('Chưa có cộng tác viên nào. Hãy thêm ở tab Cộng tác viên.', isError: true);
      return;
    }
    String? selectedId = collaborators.first.id;
    final roleCtrl = TextEditingController();
    final commissionCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Gán cộng tác viên'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: selectedId,
                  decoration: const InputDecoration(labelText: 'Cộng tác viên'),
                  items: [
                    for (final c in collaborators)
                      DropdownMenuItem(value: c.id, child: Text(c.name)),
                  ],
                  onChanged: (v) => setState(() => selectedId = v),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: roleCtrl,
                  decoration: const InputDecoration(labelText: 'Vai trò (VD: Đo đạc, Hỗ trợ pháp lý...)'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: commissionCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Hoa hồng (đ)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
            FilledButton(
              onPressed: () {
                final commission =
                    num.tryParse(commissionCtrl.text.replaceAll('.', '').replaceAll(',', '')) ?? 0;
                if (selectedId == null || commission < 0) return;
                repo.addAssignment(CollaboratorAssignment(
                  id: '',
                  profileId: profileId,
                  collaboratorId: selectedId!,
                  role: roleCtrl.text.trim(),
                  commissionAmount: commission,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                ));
                Navigator.pop(ctx);
              },
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
  }

  void _showPayDialog(BuildContext context, AppRepository repo, CollaboratorAssignment assignment) {
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Trả hoa hồng'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Còn phải trả: ${MoneyUtils.format(assignment.remainingAmount)}'),
            const SizedBox(height: 12),
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Số tiền trả (đ)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteCtrl,
              decoration: const InputDecoration(labelText: 'Ghi chú'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          FilledButton(
            onPressed: () {
              final amount = num.tryParse(amountCtrl.text.replaceAll('.', '').replaceAll(',', ''));
              if (amount == null) return;
              final newPaid = assignment.paidAmount + amount;
              final error = Validators.paidNotExceedingCommission(newPaid, assignment.commissionAmount);
              if (error != null) {
                context.showSnackBar(error, isError: true);
                return;
              }
              repo.payCommission(
                assignmentId: assignment.id,
                amount: amount,
                date: DateTime.now(),
                note: noteCtrl.text.trim(),
              );
              Navigator.pop(ctx);
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }
}
