/// Việc gán một cộng tác viên vào một hồ sơ, kèm hoa hồng thỏa thuận.
///
/// Lưu ý kiến trúc: [paidAmount] là giá trị CACHE được repository tính lại
/// mỗi khi có giao dịch COLLABORATOR_PAYMENT mới (xem MoneyTransaction).
/// Nguồn sự thật thực sự là lịch sử transaction — cache này chỉ để hiển thị
/// nhanh mà không phải quét lại toàn bộ transaction ở mọi nơi trong UI.
class CollaboratorAssignment {
  final String id;
  final String profileId;
  final String collaboratorId;
  final String role;
  final num commissionAmount;
  final num paidAmount;
  final String note;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? archivedAt;

  const CollaboratorAssignment({
    required this.id,
    required this.profileId,
    required this.collaboratorId,
    this.role = '',
    this.commissionAmount = 0,
    this.paidAmount = 0,
    this.note = '',
    required this.createdAt,
    required this.updatedAt,
    this.archivedAt,
  });

  bool get isArchived => archivedAt != null;

  num get remainingAmount {
    final remaining = commissionAmount - paidAmount;
    return remaining < 0 ? 0 : remaining;
  }

  CollaboratorAssignment copyWith({
    String? id,
    String? profileId,
    String? collaboratorId,
    String? role,
    num? commissionAmount,
    num? paidAmount,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? archivedAt,
    bool clearArchivedAt = false,
  }) {
    return CollaboratorAssignment(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      collaboratorId: collaboratorId ?? this.collaboratorId,
      role: role ?? this.role,
      commissionAmount: commissionAmount ?? this.commissionAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      archivedAt: clearArchivedAt ? null : (archivedAt ?? this.archivedAt),
    );
  }

  factory CollaboratorAssignment.fromJson(Map<String, dynamic> json) {
    return CollaboratorAssignment(
      id: json['id'] as String,
      profileId: json['profileId'] as String,
      collaboratorId: json['collaboratorId'] as String,
      role: json['role'] as String? ?? '',
      commissionAmount: json['commissionAmount'] as num? ?? 0,
      paidAmount: json['paidAmount'] as num? ?? 0,
      note: json['note'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      archivedAt: json['archivedAt'] != null
          ? DateTime.parse(json['archivedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'profileId': profileId,
      'collaboratorId': collaboratorId,
      'role': role,
      'commissionAmount': commissionAmount,
      'paidAmount': paidAmount,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'archivedAt': archivedAt?.toIso8601String(),
    };
  }
}
