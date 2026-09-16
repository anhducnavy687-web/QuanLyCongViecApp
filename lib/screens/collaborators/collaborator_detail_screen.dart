import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/extensions/context_extensions.dart';
import '../../core/utils/money_utils.dart';
import '../../repositories/app_repository.dart';
import '../../widgets/empty_state.dart';
import '../profiles/profile_detail_screen.dart';
import 'add_edit_collaborator_sheet.dart';

class CollaboratorDetailScreen extends StatelessWidget {
  final String collaboratorId;
  const CollaboratorDetailScreen({super.key, required this.collaboratorId});

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<AppRepository>();
    final collaborator = repo.collaboratorById(collaboratorId);
    if (collaborator == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(icon: Icons.person_off_rounded, title: 'Không tìm thấy cộng tác viên'),
      );
    }
    final assignments = repo.assignmentsOfCollaborator(collaboratorId);
    final totalCommission = assignments.fold<num>(0, (s, a) => s + a.commissionAmount);
    final totalPaid = assignments.fold<num>(0, (s, a) => s + a.paidAmount);
    final totalRemaining = assignments.fold<num>(0, (s, a) => s + a.remainingAmount);

    return Scaffold(
      appBar: AppBar(
        title: Text(collaborator.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Sửa cộng tác viên',
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (_) => AddEditCollaboratorSheet(collaborator: collaborator),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (collaborator.phone.isNotEmpty) ...[
                        const Icon(Icons.phone_outlined, size: 16),
                        const SizedBox(width: 6),
                        Text(collaborator.phone),
                      ],
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: (collaborator.active ? Colors.green : Colors.grey).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          collaborator.active ? 'Đang hoạt động' : 'Ngừng hoạt động',
                          style: TextStyle(
                            fontSize: 11,
                            color: collaborator.active ? Colors.green : Colors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (collaborator.note.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(collaborator.note, style: context.textTheme.bodySmall),
                  ],
                  const Divider(height: 24),
                  _statRow('Tổng hoa hồng', totalCommission),
                  _statRow('Đã trả', totalPaid),
                  _statRow('Còn phải trả', totalRemaining),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Hồ sơ tham gia (${assignments.length})',
              style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (assignments.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text('Chưa tham gia hồ sơ nào'),
            )
          else
            ...assignments.map((a) {
              final profile = repo.profileById(a.profileId);
              return Card(
                child: ListTile(
                  title: Text(profile?.fullName ?? 'Hồ sơ đã xóa'),
                  subtitle: Text('${a.role.isEmpty ? "Cộng tác" : a.role} • '
                      '${MoneyUtils.format(a.paidAmount)} / ${MoneyUtils.format(a.commissionAmount)}'),
                  onTap: profile == null
                      ? null
                      : () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => ProfileDetailScreen(profileId: profile.id)),
                          ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _statRow(String label, num value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(label, overflow: TextOverflow.ellipsis)),
          const SizedBox(width: 8),
          Text(MoneyUtils.format(value), style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
