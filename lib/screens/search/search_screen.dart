import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../repositories/app_repository.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/profile_card.dart';

enum _Filter {
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

extension on _Filter {
  String get label {
    switch (this) {
      case _Filter.all:
        return 'Tất cả';
      case _Filter.needsAction:
        return 'Cần xử lý';
      case _Filter.overdue:
        return 'Quá hạn';
      case _Filter.today:
        return 'Hôm nay';
      case _Filter.upcoming:
        return 'Sắp đến hạn';
      case _Filter.inProgress:
        return 'Đang xử lý';
      case _Filter.waiting:
        return 'Đang chờ';
      case _Filter.noDeadline:
        return 'Không có deadline';
      case _Filter.completed:
        return 'Hoàn thành';
    }
  }
}

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchCtrl = TextEditingController();
  _Filter _filter = _Filter.all;
  String _query = '';

  bool _matchesFilter(ProfileAggregate a) {
    switch (_filter) {
      case _Filter.all:
        return true;
      case _Filter.needsAction:
        return a.deadlineCategory == DeadlineCategory.overdue ||
            a.deadlineCategory == DeadlineCategory.dueToday ||
            a.deadlineCategory == DeadlineCategory.upcoming ||
            a.deadlineCategory == DeadlineCategory.stalled;
      case _Filter.overdue:
        return a.deadlineCategory == DeadlineCategory.overdue;
      case _Filter.today:
        return a.deadlineCategory == DeadlineCategory.dueToday;
      case _Filter.upcoming:
        return a.deadlineCategory == DeadlineCategory.upcoming;
      case _Filter.inProgress:
        return a.profile.status == ProfileStatus.inProgress;
      case _Filter.waiting:
        return a.profile.status == ProfileStatus.waiting;
      case _Filter.noDeadline:
        return !a.profile.hasDeadline;
      case _Filter.completed:
        return a.profile.status == ProfileStatus.completed;
    }
  }

  bool _matchesQuery(ProfileAggregate a) {
    if (_query.isEmpty) return true;
    final q = _query.toLowerCase();
    final p = a.profile;
    return p.fullName.toLowerCase().contains(q) ||
        p.phone.toLowerCase().contains(q) ||
        p.workTarget.toLowerCase().contains(q) ||
        p.description.toLowerCase().contains(q) ||
        (a.group?.name.toLowerCase().contains(q) ?? false);
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
          autofocus: true,
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
                for (final f in _Filter.values)
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
