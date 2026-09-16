import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/vietnamese_utils.dart';
import '../../models/models.dart';
import '../../repositories/app_repository.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/profile_card.dart';

enum ProfileFilter {
  all,
  needsAction,
  overdue,
  today,
  upcoming,
  inProgress,
  waiting,
  noDeadline,
  completed,
}

extension ProfileFilterX on ProfileFilter {
  String get label {
    switch (this) {
      case ProfileFilter.all:
        return 'Tất cả';
      case ProfileFilter.needsAction:
        return 'Cần xử lý';
      case ProfileFilter.overdue:
        return 'Quá hạn';
      case ProfileFilter.today:
        return 'Hôm nay';
      case ProfileFilter.upcoming:
        return 'Sắp đến hạn';
      case ProfileFilter.inProgress:
        return 'Đang xử lý';
      case ProfileFilter.waiting:
        return 'Đang chờ';
      case ProfileFilter.noDeadline:
        return 'Không có deadline';
      case ProfileFilter.completed:
        return 'Hoàn thành';
    }
  }
}

/// Màn hình tìm kiếm/lọc hồ sơ. Cũng dùng làm màn hình "drill-down" từ
/// Dashboard: chạm vào một stat/section trên Dashboard sẽ mở màn hình này
/// với [initialFilter] tương ứng đã được chọn sẵn.
class SearchScreen extends StatefulWidget {
  final ProfileFilter initialFilter;
  final bool autofocusSearch;

  const SearchScreen({
    super.key,
    this.initialFilter = ProfileFilter.all,
    this.autofocusSearch = true,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchCtrl = TextEditingController();
  late ProfileFilter _filter = widget.initialFilter;
  String _query = '';

  bool _matchesFilter(ProfileAggregate a) {
    switch (_filter) {
      case ProfileFilter.all:
        return true;
      case ProfileFilter.needsAction:
        return a.deadlineCategory == DeadlineCategory.overdue ||
            a.deadlineCategory == DeadlineCategory.dueToday ||
            a.deadlineCategory == DeadlineCategory.upcoming ||
            a.deadlineCategory == DeadlineCategory.stalled ||
            a.isWaiting;
      case ProfileFilter.overdue:
        return a.deadlineCategory == DeadlineCategory.overdue;
      case ProfileFilter.today:
        return a.deadlineCategory == DeadlineCategory.dueToday;
      case ProfileFilter.upcoming:
        return a.deadlineCategory == DeadlineCategory.upcoming;
      case ProfileFilter.inProgress:
        return a.profile.status == ProfileStatus.inProgress;
      case ProfileFilter.waiting:
        return a.profile.status == ProfileStatus.waiting;
      case ProfileFilter.noDeadline:
        return !a.profile.hasDeadline;
      case ProfileFilter.completed:
        return a.profile.status == ProfileStatus.completed;
    }
  }

  bool _matchesQuery(ProfileAggregate a) {
    if (_query.isEmpty) return true;
    // Bỏ dấu cả hai phía để tìm kiếm không phân biệt có dấu/không dấu
    // (VD: gõ "nguyen van a" vẫn khớp "Nguyễn Văn A").
    final q = VietnameseUtils.removeDiacritics(_query);
    final p = a.profile;
    bool has(String field) => VietnameseUtils.removeDiacritics(field).contains(q);
    return has(p.fullName) ||
        has(p.phone) ||
        has(p.workTarget) ||
        has(p.description) ||
        has(p.status.label) ||
        (a.group != null && has(a.group!.name)) ||
        a.tasks.any((t) => has(t.title) || has(t.description) || has(t.status.label));
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<AppRepository>();
    final results = repo.allAggregates.where((a) => _matchesQuery(a) && _matchesFilter(a)).toList()
      ..sort((a, b) => a.deadlineCategory.priority.compareTo(b.deadlineCategory.priority));

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchCtrl,
          autofocus: widget.autofocusSearch,
          decoration: const InputDecoration(
            hintText: 'Tìm theo tên, SĐT, đích công việc...',
            border: InputBorder.none,
          ),
          onChanged: (v) => setState(() => _query = v),
        ),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              children: [
                for (final f in ProfileFilter.values)
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
            child: results.isEmpty
                ? const EmptyState(icon: Icons.search_off_rounded, title: 'Không tìm thấy hồ sơ phù hợp')
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
                    itemCount: results.length,
                    itemBuilder: (context, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: ProfileCard(aggregate: results[i], showGroupLabel: true),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
