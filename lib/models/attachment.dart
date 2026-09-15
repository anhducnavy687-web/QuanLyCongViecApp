enum AttachmentType {
  pdf,
  doc,
  docx,
  jpg,
  jpeg,
  png,
  webp,
  other;

  static AttachmentType fromExtension(String ext) {
    final e = ext.toLowerCase().replaceAll('.', '');
    return AttachmentType.values.firstWhere(
      (t) => t.name == e,
      orElse: () => AttachmentType.other,
    );
  }

  bool get isImage =>
      this == AttachmentType.jpg ||
      this == AttachmentType.jpeg ||
      this == AttachmentType.png ||
      this == AttachmentType.webp;
}

/// Metadata của một file/tài liệu đính kèm hồ sơ.
/// File thực tế được lưu ở Firebase Storage (khi online) hoặc trên máy
/// (Demo Mode); model này chỉ lưu thông tin mô tả.
class Attachment {
  final String id;
  final String profileId;
  final String fileName;
  final AttachmentType type;

  /// Đường dẫn cục bộ (Demo Mode) hoặc download URL (Firebase Storage).
  final String localPathOrUrl;

  /// Storage path dự kiến: users/{uid}/profiles/{profileId}/attachments/{id}
  final String? storagePath;
  final int sizeBytes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Attachment({
    required this.id,
    required this.profileId,
    required this.fileName,
    required this.type,
    required this.localPathOrUrl,
    this.storagePath,
    this.sizeBytes = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  Attachment copyWith({
    String? id,
    String? profileId,
    String? fileName,
    AttachmentType? type,
    String? localPathOrUrl,
    String? storagePath,
    int? sizeBytes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Attachment(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      fileName: fileName ?? this.fileName,
      type: type ?? this.type,
      localPathOrUrl: localPathOrUrl ?? this.localPathOrUrl,
      storagePath: storagePath ?? this.storagePath,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Attachment.fromJson(Map<String, dynamic> json) {
    return Attachment(
      id: json['id'] as String,
      profileId: json['profileId'] as String,
      fileName: json['fileName'] as String,
      type: AttachmentType.fromExtension(json['type'] as String? ?? 'other'),
      localPathOrUrl: json['localPathOrUrl'] as String,
      storagePath: json['storagePath'] as String?,
      sizeBytes: json['sizeBytes'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'profileId': profileId,
      'fileName': fileName,
      'type': type.name,
      'localPathOrUrl': localPathOrUrl,
      'storagePath': storagePath,
      'sizeBytes': sizeBytes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
