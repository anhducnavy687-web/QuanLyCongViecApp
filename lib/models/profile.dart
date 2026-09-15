/// Trạng thái tổng thể của một hồ sơ.
enum ProfileStatus {
  newProfile,
  inProgress,
  waiting,
  completed,
  cancelled;

  static ProfileStatus fromValue(String value) {
    return ProfileStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ProfileStatus.newProfile,
    );
  }

  String get value {
    switch (this) {
      case ProfileStatus.newProfile:
        return 'new';
      case ProfileStatus.inProgress:
        return 'inProgress';
      case ProfileStatus.waiting:
        return 'waiting';
      case ProfileStatus.completed:
        return 'completed';
      case ProfileStatus.cancelled:
        return 'cancelled';
    }
  }

  String get label {
    switch (this) {
      case ProfileStatus.newProfile:
        return 'Mới tiếp nhận';
      case ProfileStatus.inProgress:
        return 'Đang xử lý';
      case ProfileStatus.waiting:
        return 'Đang chờ';
      case ProfileStatus.completed:
        return 'Hoàn thành';
      case ProfileStatus.cancelled:
        return 'Đã hủy';
    }
  }
}

/// Hồ sơ / người cần xử lý — thực thể trung tâm của ứng dụng.
class Profile {
  final String id;
  final String groupId;
  final String fullName;
  final String phone;
  final String workTarget;
  final String description;
  final DateTime startDate;
  final DateTime? deadline;
  final bool hasDeadline;
  final ProfileStatus status;
  final num totalAmount;
  final String note;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;

  const Profile({
    required this.id,
    required this.groupId,
    required this.fullName,
    this.phone = '',
    required this.workTarget,
    this.description = '',
    required this.startDate,
    this.deadline,
    this.hasDeadline = false,
    this.status = ProfileStatus.newProfile,
    this.totalAmount = 0,
    this.note = '',
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
  });

  Profile copyWith({
    String? id,
    String? groupId,
    String? fullName,
    String? phone,
    String? workTarget,
    String? description,
    DateTime? startDate,
    DateTime? deadline,
    bool? hasDeadline,
    ProfileStatus? status,
    num? totalAmount,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
    bool clearDeadline = false,
    bool clearCompletedAt = false,
  }) {
    return Profile(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      workTarget: workTarget ?? this.workTarget,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      deadline: clearDeadline ? null : (deadline ?? this.deadline),
      hasDeadline: hasDeadline ?? this.hasDeadline,
      status: status ?? this.status,
      totalAmount: totalAmount ?? this.totalAmount,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt:
          clearCompletedAt ? null : (completedAt ?? this.completedAt),
    );
  }

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      groupId: json['groupId'] as String,
      fullName: json['fullName'] as String,
      phone: json['phone'] as String? ?? '',
      workTarget: json['workTarget'] as String,
      description: json['description'] as String? ?? '',
      startDate: DateTime.parse(json['startDate'] as String),
      deadline: json['deadline'] != null
          ? DateTime.parse(json['deadline'] as String)
          : null,
      hasDeadline: json['hasDeadline'] as bool? ?? false,
      status: ProfileStatus.fromValue(json['status'] as String? ?? 'new'),
      totalAmount: json['totalAmount'] as num? ?? 0,
      note: json['note'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'groupId': groupId,
      'fullName': fullName,
      'phone': phone,
      'workTarget': workTarget,
      'description': description,
      'startDate': startDate.toIso8601String(),
      'deadline': deadline?.toIso8601String(),
      'hasDeadline': hasDeadline,
      'status': status.value,
      'totalAmount': totalAmount,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }
}
