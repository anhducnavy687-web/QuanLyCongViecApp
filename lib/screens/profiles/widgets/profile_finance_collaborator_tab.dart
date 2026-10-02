import 'package:flutter/material.dart';

import '../../../widgets/collaborator_assignment_section.dart';
import '../../../widgets/money_section.dart';

class ProfileFinanceCollaboratorTab extends StatelessWidget {
  const ProfileFinanceCollaboratorTab({
    super.key,
    required this.profileId,
    this.openTransactionForm = false,
  });
  final String profileId;
  final bool openTransactionForm;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 840),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: [
          MoneySection(
            profileId: profileId,
            openAddOnMount: openTransactionForm,
          ),
          const SizedBox(height: 12),
          CollaboratorAssignmentSection(profileId: profileId),
        ],
      ),
    ),
  );
}
