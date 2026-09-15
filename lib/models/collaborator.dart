/// Cộng tác viên — có thể tham gia hỗ trợ nhiều hồ sơ khác nhau.
class Collaborator {
  final String id;
  final String name;
  final String phone;
  final String note;
  final bool active;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Collaborator({
    required this.id,
    required this.name,
    this.phone = '',
    this.note = '',
    this.active = true,
    required this.createdAt,
    required this.updatedAt,
  });

  Collaborator copyWith({
    String? id,
    String? name,
    String? phone,
    String? note,
    bool? active,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Collaborator(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      note: note ?? this.note,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Collaborator.fromJson(Map<String, dynamic> json) {
    return Collaborator(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String? ?? '',
      note: json['note'] as String? ?? '',
      active: json['active'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'note': note,
      'active': active,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
