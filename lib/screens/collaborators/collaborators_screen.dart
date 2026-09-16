import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/extensions/context_extensions.dart';
import '../../core/responsive/responsive.dart';
import '../../core/utils/money_utils.dart';
import '../../repositories/app_repository.dart';
import '../../widgets/empty_state.dart';
import 'add_edit_collaborator_sheet.dart';
import 'collaborator_detail_screen.dart';

class CollaboratorsScreen extends StatelessWidget {
  const CollaboratorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<AppRepository>();
    final collaborators = repo.collaborators;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cộng tác viên'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Thêm cộng tác viên',
            onPressed: () => showResponsiveFormSheet(
              context: context,
              builder: (_) => const AddEditCollaboratorSheet(),
            ),
          ),
        ],
      ),
      body: collaborators.isEmpty
          ? const EmptyState(
              icon: Icons.people_outline_rounded,
              title: 'Chưa có cộng tác viên nào',
            )
          : ResponsivePage(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                itemCount: collaborators.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final c = collaborators[i];
                  final assignments = repo.assignmentsOfCollaborator(c.id);
                  final remaining = assignments.fold<num>(
                    0,
                    (s, a) => s + a.remainingAmount,
                  );
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: c.active
                            ? context.colors.primaryContainer
                            : context.colors.surfaceContainerHighest,
                        child: Text(
                          c.name.isNotEmpty ? c.name[0].toUpperCase() : '?',
                        ),
                      ),
                      title: Text(
                        c.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        '${assignments.length} hồ sơ • Còn phải trả: ${MoneyUtils.format(remaining)}',
                      ),
                      trailing: !c.active
                          ? const Icon(
                              Icons.pause_circle_outline_rounded,
                              color: Colors.grey,
                              size: 18,
                            )
                          : null,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              CollaboratorDetailScreen(collaboratorId: c.id),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
