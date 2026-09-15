import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/extensions/context_extensions.dart';
import '../../core/extensions/datetime_extensions.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/app_date_utils.dart';
import '../../repositories/app_repository.dart';
import '../../widgets/empty_state.dart';
import '../profiles/profile_detail_screen.dart';

enum _EventKind { deadline, milestone, start, completed }

class _CalendarEvent {
  final DateTime date;
  final _EventKind kind;
  final String profileId;
  final String title;
  const _CalendarEvent({
    required this.date,
    required this.kind,
    required this.profileId,
    required this.title,
  });
}

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _visibleMonth;
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _visibleMonth = DateTime(now.year, now.month);
    _selectedDay = DateTime(now.year, now.month, now.day);
  }

  List<_CalendarEvent> _buildEvents(AppRepository repo) {
    final events = <_CalendarEvent>[];
    for (final agg in repo.allAggregates) {
      final p = agg.profile;
      events.add(_CalendarEvent(
        date: AppDateUtils.stripTime(p.startDate),
        kind: _EventKind.start,
        profileId: p.id,
        title: '${p.fullName} — Bắt đầu',
      ));
      if (p.hasDeadline && p.deadline != null) {
        events.add(_CalendarEvent(
          date: AppDateUtils.stripTime(p.deadline!),
          kind: _EventKind.deadline,
          profileId: p.id,
          title: '${p.fullName} — Hạn hoàn thành',
        ));
      }
      if (p.completedAt != null) {
        events.add(_CalendarEvent(
          date: AppDateUtils.stripTime(p.completedAt!),
          kind: _EventKind.completed,
          profileId: p.id,
          title: '${p.fullName} — Đã hoàn thành',
        ));
      }
      for (final m in agg.milestones) {
        events.add(_CalendarEvent(
          date: AppDateUtils.stripTime(m.dueDate),
          kind: _EventKind.milestone,
          profileId: p.id,
          title: '${p.fullName} — ${m.title}',
        ));
      }
    }
    return events;
  }

  Color _colorFor(_EventKind kind) {
    switch (kind) {
      case _EventKind.deadline:
        return AppColors.overdue;
      case _EventKind.milestone:
        return AppColors.upcoming;
      case _EventKind.start:
        return AppColors.inProgress;
      case _EventKind.completed:
        return AppColors.completed;
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<AppRepository>();
    final events = _buildEvents(repo);
    final eventsByDay = <DateTime, List<_CalendarEvent>>{};
    for (final e in events) {
      eventsByDay.putIfAbsent(e.date, () => []).add(e);
    }
    final selectedEvents = eventsByDay[_selectedDay] ?? const [];

    return Scaffold(
      appBar: AppBar(title: const Text('Lịch')),
      // Toàn bộ trang nằm trong một SingleChildScrollView thay vì tách
      // header/lưới (kích thước tự nhiên) + Expanded(danh sách sự kiện):
      // ở màn hình thấp (điện thoại nhỏ, xoay ngang...), header + lưới 6
      // hàng có thể cao hơn không gian còn lại, gây tràn RenderFlex nếu
      // dùng Column cố định. Cuộn cả trang tránh được lỗi này mà không
      // đánh đổi trải nghiệm (lịch tháng vẫn hiển thị đầy đủ, chỉ cuộn
      // xuống để xem hết danh sách sự kiện khi cần).
      body: SingleChildScrollView(
        child: Column(
          children: [
            _MonthHeader(
              month: _visibleMonth,
              onPrev: () => setState(() {
                _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month - 1);
              }),
              onNext: () => setState(() {
                _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1);
              }),
            ),
            _MonthGrid(
              month: _visibleMonth,
              selectedDay: _selectedDay,
              eventsByDay: eventsByDay,
              colorFor: _colorFor,
              onSelect: (d) => setState(() => _selectedDay = d),
            ),
            const Divider(height: 1),
            if (selectedEvents.isEmpty)
              SizedBox(
                height: 240,
                child: EmptyState(
                  icon: Icons.event_available_rounded,
                  title: 'Không có sự kiện',
                  message: 'Ngày ${_selectedDay.ddMMyyyy} không có deadline hay mốc nào.',
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                itemCount: selectedEvents.length,
                itemBuilder: (context, i) {
                  final e = selectedEvents[i];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        radius: 6,
                        backgroundColor: _colorFor(e.kind),
                      ),
                      title: Text(e.title),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ProfileDetailScreen(profileId: e.profileId),
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _MonthHeader extends StatelessWidget {
  final DateTime month;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  const _MonthHeader({required this.month, required this.onPrev, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(icon: const Icon(Icons.chevron_left_rounded), onPressed: onPrev),
          Text(
            'Tháng ${month.month} / ${month.year}',
            style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          IconButton(icon: const Icon(Icons.chevron_right_rounded), onPressed: onNext),
        ],
      ),
    );
  }
}

class _MonthGrid extends StatelessWidget {
  final DateTime month;
  final DateTime selectedDay;
  final Map<DateTime, List<_CalendarEvent>> eventsByDay;
  final Color Function(_EventKind) colorFor;
  final ValueChanged<DateTime> onSelect;

  const _MonthGrid({
    required this.month,
    required this.selectedDay,
    required this.eventsByDay,
    required this.colorFor,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final firstOfMonth = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leadingEmpty = firstOfMonth.weekday % 7; // Monday=1..Sunday=7 -> Sunday-first grid offset
    final today = AppDateUtils.stripTime(DateTime.now());

    const weekdayLabels = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          Row(
            children: [
              for (final l in weekdayLabels)
                Expanded(
                  child: Center(
                    child: Text(l, style: TextStyle(fontSize: 11, color: context.colors.onSurfaceVariant)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7),
            itemCount: leadingEmpty + daysInMonth,
            itemBuilder: (context, index) {
              if (index < leadingEmpty) return const SizedBox.shrink();
              final day = DateTime(month.year, month.month, index - leadingEmpty + 1);
              final isSelected = day == selectedDay;
              final isToday = day == today;
              final dayEvents = eventsByDay[day] ?? const [];
              final kinds = dayEvents.map((e) => e.kind).toSet();

              return InkWell(
                onTap: () => onSelect(day),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isSelected ? context.colors.primary : null,
                    border: isToday && !isSelected
                        ? Border.all(color: context.colors.primary, width: 1.5)
                        : null,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${day.day}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isToday || isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? context.colors.onPrimary : null,
                        ),
                      ),
                      if (kinds.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              for (final k in kinds.take(3))
                                Container(
                                  width: 4,
                                  height: 4,
                                  margin: const EdgeInsets.symmetric(horizontal: 1),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isSelected ? context.colors.onPrimary : colorFor(k),
                                  ),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
