enum TaskStatus {
  todo('todo', 'Cần làm'),
  inProgress('in_progress', 'Đang làm'),
  waiting('waiting', 'Đang chờ'),
  completed('completed', 'Hoàn thành'),
  cancelled('cancelled', 'Đã hủy');

  const TaskStatus(this.value, this.label);

  final String value;
  final String label;

  static TaskStatus fromValue(String value) {
    return TaskStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TaskStatus.todo,
    );
  }
}

enum TaskPriority {
  low('low', 'Thấp'),
  normal('normal', 'Bình thường'),
  high('high', 'Cao'),
  urgent('urgent', 'Khẩn cấp');

  const TaskPriority(this.value, this.label);

  final String value;
  final String label;

  static TaskPriority fromValue(String value) {
    return TaskPriority.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TaskPriority.normal,
    );
  }
}

class TaskItem {
  const TaskItem({
    required this.id,
    required this.profileId,
    required this.title,
    this.description = '',
    this.status = TaskStatus.todo,
    this.priority = TaskPriority.normal,
    this.dueDate,
    this.waitingReason,
    this.waitingSince,
    this.expectedResponseDate,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
    this.note = '',
  });

  final String id;
  final String profileId;
  final String title;
  final String description;
  final TaskStatus status;
  final TaskPriority priority;
  final DateTime? dueDate;
  final String? waitingReason;
  final DateTime? waitingSince;
  final DateTime? expectedResponseDate;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String note;

  TaskItem copyWith({
    String? title,
    String? description,
    TaskStatus? status,
    TaskPriority? priority,
    DateTime? dueDate,
    bool clearDueDate = false,
    String? waitingReason,
    bool clearWaitingReason = false,
    DateTime? waitingSince,
    bool clearWaitingSince = false,
    DateTime? expectedResponseDate,
    bool clearExpectedResponseDate = false,
    DateTime? completedAt,
    bool clearCompletedAt = false,
    DateTime? updatedAt,
    String? note,
  }) {
    return TaskItem(
      id: id,
      profileId: profileId,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      waitingReason: clearWaitingReason
          ? null
          : (waitingReason ?? this.waitingReason),
      waitingSince: clearWaitingSince
          ? null
          : (waitingSince ?? this.waitingSince),
      expectedResponseDate: clearExpectedResponseDate
          ? null
          : (expectedResponseDate ?? this.expectedResponseDate),
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      note: note ?? this.note,
    );
  }

  factory TaskItem.fromJson(Map<String, dynamic> json) {
    return TaskItem(
      id: json['id'] as String,
      profileId: json['profileId'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      status: TaskStatus.fromValue(json['status'] as String? ?? 'todo'),
      priority: TaskPriority.fromValue(
        json['priority'] as String? ?? 'normal',
      ),
      dueDate: json['dueDate'] != null
          ? DateTime.parse(json['dueDate'] as String)
          : null,
      waitingReason: json['waitingReason'] as String?,
      waitingSince: json['waitingSince'] != null
          ? DateTime.parse(json['waitingSince'] as String)
          : null,
      expectedResponseDate: json['expectedResponseDate'] != null
          ? DateTime.parse(json['expectedResponseDate'] as String)
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      note: json['note'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'profileId': profileId,
      'title': title,
      'description': description,
      'status': status.value,
      'priority': priority.value,
      'dueDate': dueDate?.toIso8601String(),
      'waitingReason': waitingReason,
      'waitingSince': waitingSince?.toIso8601String(),
      'expectedResponseDate': expectedResponseDate?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'note': note,
    };
  }
}
