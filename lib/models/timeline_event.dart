enum TimelineEventType {
  profileCreated('profile_created', 'Tạo hồ sơ'),
  profileUpdated('profile_updated', 'Cập nhật hồ sơ'),
  statusChanged('status_changed', 'Đổi trạng thái'),
  stageCompleted('stage_completed', 'Hoàn thành bước'),
  taskCreated('task_created', 'Tạo việc cần làm'),
  taskCompleted('task_completed', 'Hoàn thành việc'),
  waitingStarted('waiting_started', 'Bắt đầu chờ'),
  waitingResolved('waiting_resolved', 'Kết thúc chờ'),
  transaction('transaction', 'Giao dịch tiền'),
  note('note', 'Ghi chú');

  const TimelineEventType(this.value, this.label);

  final String value;
  final String label;

  static TimelineEventType fromValue(String value) {
    return TimelineEventType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TimelineEventType.note,
    );
  }
}

class TimelineEvent {
  const TimelineEvent({
    required this.id,
    required this.profileId,
    required this.type,
    required this.message,
    required this.createdAt,
  });

  final String id;
  final String profileId;
  final TimelineEventType type;
  final String message;
  final DateTime createdAt;

  factory TimelineEvent.fromJson(Map<String, dynamic> json) {
    return TimelineEvent(
      id: json['id'] as String,
      profileId: json['profileId'] as String,
      type: TimelineEventType.fromValue(json['type'] as String? ?? 'note'),
      message: json['message'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'profileId': profileId,
      'type': type.value,
      'message': message,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
