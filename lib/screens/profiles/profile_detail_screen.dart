import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/repository_action.dart';
import '../../repositories/app_repository.dart';
import '../../widgets/empty_state.dart';
import 'add_edit_profile_screen.dart';
import 'trich_ngang_screen.dart';
import 'widgets/profile_detail_header.dart';
import 'widgets/profile_documents_history_tab.dart';
import 'widgets/profile_finance_collaborator_tab.dart';
import 'widgets/profile_information_tab.dart';
import 'widgets/profile_overview_tab.dart';
import 'widgets/profile_work_tab.dart';

class ProfileDetailScreen extends StatelessWidget {
  final String profileId;
  final int initialTabIndex;
  final bool openTransactionForm;

  const ProfileDetailScreen({
    super.key,
    required this.profileId,
    this.initialTabIndex = 0,
    this.openTransactionForm = false,
  });

  static const _tabs = [
    Tab(text: 'Tổng quan'),
    Tab(text: 'Thông tin'),
    Tab(text: 'Công việc'),
    Tab(text: 'Tài chính & CTV'),
    Tab(text: 'Tài liệu & Lịch sử'),
  ];

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<AppRepository>();
    final profile = repo.profileById(profileId);
    if (profile == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(
          icon: Icons.person_off_rounded,
          title: 'Hồ sơ không tồn tại hoặc đã bị xóa',
        ),
      );
    }
    final aggregate = repo.aggregateOf(profileId);
    final safeInitialIndex = initialTabIndex.clamp(0, _tabs.length - 1);

    return DefaultTabController(
      length: _tabs.length,
      initialIndex: safeInitialIndex,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Chi tiết hồ sơ'),
          actions: [
            IconButton(
              icon: const Icon(Icons.description_outlined),
              tooltip: 'Trích ngang',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => TrichNgangScreen(profileId: profileId),
                ),
              ),
            ),
            PopupMenuButton<String>(
              tooltip: 'Thêm tùy chọn',
              onSelected: (value) {
                if (value == 'delete') {
                  _confirmDelete(context, repo, profileId);
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'delete', child: Text('Xóa hồ sơ')),
              ],
            ),
          ],
        ),
        body: Column(
          children: [
            ProfileDetailHeader(
              aggregate: aggregate,
              onEdit: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AddEditProfileScreen(profile: profile),
                ),
              ),
            ),
            LayoutBuilder(
              builder: (context, constraints) => Material(
                color: Theme.of(context).colorScheme.surface,
                child: TabBar(
                  isScrollable: constraints.maxWidth < 760,
                  tabAlignment: constraints.maxWidth < 760
                      ? TabAlignment.start
                      : TabAlignment.fill,
                  tabs: _tabs,
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  ProfileOverviewTab(profileId: profileId),
                  ProfileInformationTab(profileId: profileId),
                  ProfileWorkTab(profileId: profileId),
                  ProfileFinanceCollaboratorTab(
                    profileId: profileId,
                    openTransactionForm: openTransactionForm,
                  ),
                  ProfileDocumentsHistoryTab(profileId: profileId),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    AppRepository repo,
    String profileId,
  ) {
    bool deleting = false;
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: const Text('Xóa hồ sơ?'),
          content: const Text(
            'Toàn bộ dữ liệu liên quan (bước xử lý, giao dịch, tài liệu...) sẽ bị xóa. '
            'Hành động này không thể hoàn tác.',
          ),
          actions: [
            TextButton(
              onPressed: deleting ? null : () => Navigator.pop(dialogContext),
              child: const Text('Hủy'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(dialogContext).colorScheme.error,
              ),
              onPressed: deleting
                  ? null
                  : () async {
                      setState(() => deleting = true);
                      final deleted = await runRepositoryAction(
                        context,
                        () => repo.deleteProfile(profileId),
                      );
                      if (!dialogContext.mounted) return;
                      if (!deleted) {
                        setState(() => deleting = false);
                        return;
                      }
                      Navigator.pop(dialogContext);
                      if (context.mounted) Navigator.pop(context);
                    },
              child: deleting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Xóa'),
            ),
          ],
        ),
      ),
    );
  }
}
