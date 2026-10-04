import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/responsive/responsive.dart';
import '../../repositories/app_repository.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/profile_card.dart';
import 'profile_list_query.dart';

export 'profile_list_query.dart' show ProfileFilter;

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
  ProfileSort _sort = ProfileSort.urgency;
  String? _groupId;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<AppRepository>();
    final results = ProfileListQuery.apply(
      source: repo.allAggregates,
      query: _query,
      filter: _filter,
      groupId: _groupId,
      sort: _sort,
    );
    final selectedGroup = _groupId == null
        ? null
        : repo.groups.where((group) => group.id == _groupId).firstOrNull;

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
      body: ResponsivePage(
        child: Column(
          children: [
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
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
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showGroupFilter(context, repo),
                      icon: const Icon(Icons.folder_outlined, size: 18),
                      label: Text(
                        selectedGroup?.name ?? 'Tất cả nhóm',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  PopupMenuButton<ProfileSort>(
                    tooltip: 'Sắp xếp hồ sơ',
                    initialValue: _sort,
                    onSelected: (value) => setState(() => _sort = value),
                    itemBuilder: (_) => [
                      for (final value in ProfileSort.values)
                        PopupMenuItem(value: value, child: Text(value.label)),
                    ],
                    child: Chip(
                      avatar: const Icon(Icons.sort_rounded, size: 18),
                      label: Text(_sort.label),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${results.length} hồ sơ',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
            ),
            Expanded(
              child: results.isEmpty
                  ? EmptyState(
                      icon: Icons.search_off_rounded,
                      title: repo.profiles.isEmpty
                          ? 'Chưa có hồ sơ'
                          : 'Không tìm thấy hồ sơ phù hợp',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
                      itemCount: results.length,
                      itemBuilder: (context, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: ProfileCard(
                          aggregate: results[i],
                          showGroupLabel: true,
                          compact: true,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showGroupFilter(
    BuildContext context,
    AppRepository repo,
  ) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const ListTile(
              title: Text(
                'Lọc theo nhóm công việc',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: Icon(
                _groupId == null
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
              ),
              title: const Text('Tất cả nhóm'),
              onTap: () => Navigator.pop(context, ''),
            ),
            for (final group in repo.groups)
              ListTile(
                leading: Icon(
                  _groupId == group.id
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                ),
                title: Text(group.name),
                onTap: () => Navigator.pop(context, group.id),
              ),
          ],
        ),
      ),
    );
    if (!mounted || selected == null) return;
    setState(() => _groupId = selected.isEmpty ? null : selected);
  }
}
