enum MilestoneStatus {
  pending,
  completed;

  static MilestoneStatus fromValue(String value) {
    return MilestoneStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => MilestoneStatus.pending,
    );
  }

  String get value => this == MilestoneStatus.completed ? 'completed' : 'pending';

  String get label => this == MilestoneStatus.completed ? 'Hoàn thành' : 'Chưa hoàn thành';
}

/// Phân loại thời gian tự động của milestone, dùng để hiển thị trên Lịch/Dashboard.
enum MilestoneTiming { overdue, today, upcoming, completed, normal }

/// Mốc thời gian quan trọng của một hồ sơ (VD: Nộp hồ sơ, Nhận kết quả...).
class Milestone {
  final String id;
  final String profileId;
  final String title;
  final DateTime dueDate;
  final MilestoneStatus status;
  final DateTime? completedAt;
  final String note;

  const Milestone({
    required this.id,
    required this.profileId,
    required this.title,
    required this.dueDate,
    this.status = MilestoneStatus.pending,
    this.completedAt,
    this.note = '',
  });

  MilestoneTiming timing({DateTime? from, int upcomingThresholdDays = 3}) {
    if (status == MilestoneStatus.completed) return MilestoneTiming.completed;
    final today = DateTime(
      (from ?? DateTime.now()).year,
      (from ?? DateTime.now()).month,
      (from ?? DateTime.now()).day,
    );
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final diff = due.difference(today).inDays;
    if (diff < 0) return MilestoneTiming.overdue;
    if (diff == 0) return MilestoneTiming.today;
    if (diff <= upcomingThresholdDays) return MilestoneTiming.upcoming;
    return MilestoneTiming.normal;
  }

  Milestone copyWith({
    String? id,
    String? profileId,
    String? title,
    DateTime? dueDate,
    MilestoneStatus? status,
    DateTime? completedAt,
    String? note,
    bool clearCompletedAt = false,
  }) {
    return Milestone(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      title: title ?? this.title,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      completedAt:
          clearCompletedAt ? null : (completedAt ?? this.completedAt),
      note: note ?? this.note,
    );
  }

  factory Milestone.fromJson(Map<String, dynamic> json) {
    return Milestone(
      id: json['id'] as String,
      profileId: json['profileId'] as String,
      title: json['title'] as String,
      dueDate: DateTime.parse(json['dueDate'] as String),
      status: MilestoneStatus.fromValue(json['status'] as String? ?? 'pending'),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      note: json['note'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'profileId': profileId,
      'title': title,
      'dueDate': dueDate.toIso8601String(),
      'status': status.value,
      'completedAt': completedAt?.toIso8601String(),
      'note': note,
    };
  }
}
