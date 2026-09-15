enum StageStatus {
  pending,
  inProgress,
  completed,
  skipped;

  static StageStatus fromValue(String value) {
    return StageStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => StageStatus.pending,
    );
  }

  String get value {
    switch (this) {
      case StageStatus.pending:
        return 'pending';
      case StageStatus.inProgress:
        return 'inProgress';
      case StageStatus.completed:
        return 'completed';
      case StageStatus.skipped:
        return 'skipped';
    }
  }

  String get label {
    switch (this) {
      case StageStatus.pending:
        return 'Chưa thực hiện';
      case StageStatus.inProgress:
        return 'Đang thực hiện';
      case StageStatus.completed:
        return 'Đã hoàn thành';
      case StageStatus.skipped:
        return 'Bỏ qua';
    }
  }
}

/// Một bước trong quy trình xử lý của hồ sơ (thay cho hiển thị % tiến độ).
class WorkStage {
  final String id;
  final String profileId;
  final String name;
  final int order;
  final StageStatus status;
  final DateTime? startDate;
  final DateTime? completedAt;
  final DateTime? deadline;
  final String note;

  const WorkStage({
    required this.id,
    required this.profileId,
    required this.name,
    required this.order,
    this.status = StageStatus.pending,
    this.startDate,
    this.completedAt,
    this.deadline,
    this.note = '',
  });

  WorkStage copyWith({
    String? id,
    String? profileId,
    String? name,
    int? order,
    StageStatus? status,
    DateTime? startDate,
    DateTime? completedAt,
    DateTime? deadline,
    String? note,
    bool clearCompletedAt = false,
  }) {
    return WorkStage(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      name: name ?? this.name,
      order: order ?? this.order,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      completedAt:
          clearCompletedAt ? null : (completedAt ?? this.completedAt),
      deadline: deadline ?? this.deadline,
      note: note ?? this.note,
    );
  }

  factory WorkStage.fromJson(Map<String, dynamic> json) {
    return WorkStage(
      id: json['id'] as String,
      profileId: json['profileId'] as String,
      name: json['name'] as String,
      order: json['order'] as int,
      status: StageStatus.fromValue(json['status'] as String? ?? 'pending'),
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'] as String)
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      deadline: json['deadline'] != null
          ? DateTime.parse(json['deadline'] as String)
          : null,
      note: json['note'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'profileId': profileId,
      'name': name,
      'order': order,
      'status': status.value,
      'startDate': startDate?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'deadline': deadline?.toIso8601String(),
      'note': note,
    };
  }
}
