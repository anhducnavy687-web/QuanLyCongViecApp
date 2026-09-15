enum TransactionType {
  received,
  expense,
  collaboratorPayment;

  static TransactionType fromValue(String value) {
    return TransactionType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TransactionType.received,
    );
  }

  String get value {
    switch (this) {
      case TransactionType.received:
        return 'RECEIVED';
      case TransactionType.expense:
        return 'EXPENSE';
      case TransactionType.collaboratorPayment:
        return 'COLLABORATOR_PAYMENT';
    }
  }

  String get label {
    switch (this) {
      case TransactionType.received:
        return 'Tiền đã nhận';
      case TransactionType.expense:
        return 'Chi phí';
      case TransactionType.collaboratorPayment:
        return 'Trả hoa hồng CTV';
    }
  }
}

/// Một giao dịch tiền gắn với hồ sơ. Toàn bộ số liệu tổng hợp (đã nhận, chi
/// phí, hoa hồng đã trả...) phải được TÍNH TỪ danh sách transaction này chứ
/// không lưu sẵn ở nơi khác, để tránh lệch số liệu.
class MoneyTransaction {
  final String id;
  final String profileId;
  final TransactionType type;
  final num amount;
  final DateTime date;
  final String note;
  final DateTime createdAt;

  /// Chỉ có giá trị khi [type] là [TransactionType.collaboratorPayment] —
  /// liên kết tới CollaboratorAssignment để biết khoản hoa hồng trả cho ai.
  final String? collaboratorAssignmentId;

  const MoneyTransaction({
    required this.id,
    required this.profileId,
    required this.type,
    required this.amount,
    required this.date,
    this.note = '',
    required this.createdAt,
    this.collaboratorAssignmentId,
  });

  MoneyTransaction copyWith({
    String? id,
    String? profileId,
    TransactionType? type,
    num? amount,
    DateTime? date,
    String? note,
    DateTime? createdAt,
    String? collaboratorAssignmentId,
  }) {
    return MoneyTransaction(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      collaboratorAssignmentId:
          collaboratorAssignmentId ?? this.collaboratorAssignmentId,
    );
  }

  factory MoneyTransaction.fromJson(Map<String, dynamic> json) {
    return MoneyTransaction(
      id: json['id'] as String,
      profileId: json['profileId'] as String,
      type: TransactionType.fromValue(json['type'] as String),
      amount: json['amount'] as num,
      date: DateTime.parse(json['date'] as String),
      note: json['note'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
      collaboratorAssignmentId: json['collaboratorAssignmentId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'profileId': profileId,
      'type': type.value,
      'amount': amount,
      'date': date.toIso8601String(),
      'note': note,
      'createdAt': createdAt.toIso8601String(),
      'collaboratorAssignmentId': collaboratorAssignmentId,
    };
  }
}
