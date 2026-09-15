/// Nhóm công việc, dùng để phân loại các hồ sơ (VD: Đất đai, Hành chính...).
class WorkGroup {
  final String id;
  final String name;
  final String description;
  final DateTime createdAt;
  final DateTime updatedAt;

  const WorkGroup({
    required this.id,
    required this.name,
    this.description = '',
    required this.createdAt,
    required this.updatedAt,
  });

  WorkGroup copyWith({
    String? id,
    String? name,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WorkGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory WorkGroup.fromJson(Map<String, dynamic> json) {
    return WorkGroup(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
