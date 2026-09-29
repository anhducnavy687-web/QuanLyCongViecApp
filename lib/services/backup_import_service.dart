import 'dart:convert';

import '../core/constants/app_constants.dart';
import '../models/models.dart';
import 'backup_file_picker.dart';
import 'backup_service.dart';
import 'export_snapshot_validator.dart';

/// Strict JSON v1 reader. The returned snapshot is validated, never applied.
class BackupImportService {
  const BackupImportService({this.validator = const ExportSnapshotValidator()});
  static const maxFileBytes = 50 * 1024 * 1024;
  final ExportSnapshotValidator validator;

  RestorePreview inspect(PickedBackupFile file) {
    if (!file.name.toLowerCase().endsWith('.json')) {
      throw const BackupImportException('Chỉ chấp nhận file .json.');
    }
    if (file.size == 0 || file.bytes.isEmpty) {
      throw const BackupImportException('File sao lưu đang trống.');
    }
    if (file.size > maxFileBytes || file.bytes.length > maxFileBytes) {
      throw const BackupImportException('File vượt quá giới hạn 50 MB.');
    }
    if (file.size != file.bytes.length) {
      throw const BackupImportException(
        'Dung lượng file không khớp nội dung đã đọc.',
      );
    }
    late final String text;
    try {
      text = utf8.decode(file.bytes, allowMalformed: false);
    } on FormatException {
      throw const BackupImportException('File không phải UTF-8 hợp lệ.');
    }
    late final Object? raw;
    try {
      raw = jsonDecode(text);
    } on FormatException {
      throw const BackupImportException('Nội dung JSON không hợp lệ.');
    }
    return inspectDocument(file.name, file.size, raw);
  }

  RestorePreview inspectDocument(String name, int size, Object? raw) {
    final root = _object(raw, 'File');
    final version = root['schemaVersion'];
    if (version is! int) {
      throw const BackupImportException('Thiếu hoặc sai kiểu schemaVersion.');
    }
    if (version > BackupService.schemaVersion) {
      throw const BackupImportException(
        'Bản sao lưu được tạo bởi phiên bản mới hơn của ứng dụng.',
      );
    }
    if (version < BackupService.schemaVersion) {
      throw const BackupImportException(
        'Phiên bản bản sao lưu cũ không được hỗ trợ.',
      );
    }
    final exportedAt = _date(root, 'exportedAt', 'File');
    final appVersion = _string(root, 'appVersion', 'File', nonempty: true);
    final source = _object(root['source'], 'source');
    final sourceMode = _enum(source, 'mode', 'source', const {
      'firebase',
      'demo',
    });
    final data = _object(root['data'], 'data');

    List<T> parse<T>(
      String key,
      Map<String, String> fields,
      T Function(Map<String, dynamic>) decode, {
      Map<String, Set<String>> enums = const {},
    }) {
      final rawItems = data[key];
      if (rawItems is! List) {
        throw BackupImportException('data.$key phải là danh sách.');
      }
      return [
        for (var i = 0; i < rawItems.length; i++)
          _decodeItem(key, i, rawItems[i], fields, enums, decode),
      ];
    }

    final snapshot = ExportSnapshot(
      exportedAt: exportedAt,
      appVersion: appVersion,
      sourceMode: sourceMode,
      repositoryRevision: 0,
      groups: parse('groups', _group, WorkGroup.fromJson),
      profiles: parse(
        'profiles',
        _profile,
        Profile.fromJson,
        enums: {'status': ProfileStatus.values.map((e) => e.value).toSet()},
      ),
      stages: parse(
        'stages',
        _stage,
        WorkStage.fromJson,
        enums: {'status': StageStatus.values.map((e) => e.value).toSet()},
      ),
      milestones: parse(
        'milestones',
        _milestone,
        Milestone.fromJson,
        enums: {'status': MilestoneStatus.values.map((e) => e.value).toSet()},
      ),
      tasks: parse(
        'tasks',
        _task,
        TaskItem.fromJson,
        enums: {
          'status': TaskStatus.values.map((e) => e.value).toSet(),
          'priority': TaskPriority.values.map((e) => e.value).toSet(),
        },
      ),
      timelineEvents: parse(
        'timelineEvents',
        _timeline,
        TimelineEvent.fromJson,
        enums: {'type': TimelineEventType.values.map((e) => e.value).toSet()},
      ),
      transactions: parse(
        'transactions',
        _transaction,
        MoneyTransaction.fromJson,
        enums: {'type': TransactionType.values.map((e) => e.value).toSet()},
      ),
      collaborators: parse(
        'collaborators',
        _collaborator,
        Collaborator.fromJson,
      ),
      collaboratorAssignments: parse(
        'collaboratorAssignments',
        _assignment,
        CollaboratorAssignment.fromJson,
      ),
      attachments: parse(
        'attachments',
        _attachment,
        Attachment.fromJson,
        enums: {'type': AttachmentType.values.map((e) => e.name).toSet()},
      ),
    );
    for (final profile in snapshot.profiles) {
      if (profile.status != ProfileStatus.waiting &&
          profile.waitingReason != null) {
        throw BackupImportException(
          'Profile ${profile.id} có lý do chờ khi không ở trạng thái Đang chờ.',
        );
      }
    }
    for (final task in snapshot.tasks) {
      if (task.status != TaskStatus.waiting && task.waitingReason != null) {
        throw BackupImportException(
          'Task ${task.id} có lý do chờ khi không ở trạng thái Đang chờ.',
        );
      }
    }
    try {
      validator.validate(snapshot);
    } on ExportValidationException catch (error) {
      throw BackupImportException(error.message);
    }
    final warnings = <String>[];
    if (appVersion != AppConstants.appVersion) {
      warnings.add('Phiên bản ứng dụng tạo backup khác phiên bản hiện tại.');
    }
    if (sourceMode == 'demo') {
      warnings.add('Đây là dữ liệu từ Chế độ Demo.');
    }
    if (!source.containsKey('timeZone') ||
        !source.containsKey('recordCounts')) {
      warnings.add('Một số thông tin nguồn tùy chọn không có trong file.');
    }
    if (snapshot.attachments.isNotEmpty) {
      warnings.add(
        'Tài liệu đính kèm trong bản sao lưu chỉ chứa metadata, không bao gồm nội dung file.',
      );
      if (snapshot.attachments.any(
        (a) => a.localPathOrUrl?.isNotEmpty == true,
      )) {
        warnings.add(
          'Đường dẫn tài liệu cục bộ có thể không hoạt động trên thiết bị này.',
        );
      }
    }
    final rebuilt = <String, num>{};
    num received = 0;
    num expense = 0;
    num payment = 0;
    for (final transaction in snapshot.transactions) {
      switch (transaction.type) {
        case TransactionType.received:
          received += transaction.amount;
        case TransactionType.expense:
          expense += transaction.amount;
        case TransactionType.collaboratorPayment:
          payment += transaction.amount;
          final id = transaction.collaboratorAssignmentId!;
          rebuilt[id] = (rebuilt[id] ?? 0) + transaction.amount;
      }
    }
    return RestorePreview(
      fileName: name,
      fileSize: size,
      snapshot: snapshot,
      warnings: warnings,
      totalReceived: received,
      totalExpense: expense,
      totalCollaboratorPayment: payment,
      rebuiltPaidAmounts: rebuilt,
    );
  }

  T _decodeItem<T>(
    String kind,
    int index,
    Object? raw,
    Map<String, String> fields,
    Map<String, Set<String>> enums,
    T Function(Map<String, dynamic>) decode,
  ) {
    final map = _object(raw, '$kind[$index]');
    final id = map['id'] is String ? map['id'] as String : '#$index';
    final label = '$kind $id';
    for (final field in fields.entries) {
      _field(map, field.key, field.value, label);
    }
    for (final field in enums.entries) {
      _enum(map, field.key, label, field.value);
    }
    try {
      return decode(map);
    } catch (_) {
      throw BackupImportException('$label có cấu trúc không hợp lệ.');
    }
  }

  Map<String, dynamic> _object(Object? raw, String label) {
    if (raw is! Map<String, dynamic>) {
      throw BackupImportException('$label phải là object JSON.');
    }
    return raw;
  }

  String _string(
    Map<String, dynamic> map,
    String key,
    String label, {
    bool nonempty = false,
  }) {
    final value = map[key];
    if (value is! String || (nonempty && value.trim().isEmpty)) {
      throw BackupImportException(
        '$label.$key phải là chuỗi${nonempty ? ' không rỗng' : ''}.',
      );
    }
    return value;
  }

  String _enum(
    Map<String, dynamic> map,
    String key,
    String label,
    Set<String> allowed,
  ) {
    final value = _string(map, key, label);
    if (!allowed.contains(value)) {
      throw BackupImportException('$label.$key có giá trị enum không hợp lệ.');
    }
    return value;
  }

  DateTime _date(Map<String, dynamic> map, String key, String label) {
    final value = _string(map, key, label);
    final match = RegExp(
      r'^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})(?:\.(\d{1,6}))?(Z|[+-]\d{2}:\d{2})?$',
    ).firstMatch(value);
    if (match == null) {
      throw BackupImportException(
        '$label.$key không phải timestamp ISO 8601 hợp lệ.',
      );
    }
    final year = int.parse(match[1]!);
    final month = int.parse(match[2]!);
    final day = int.parse(match[3]!);
    final hour = int.parse(match[4]!);
    final minute = int.parse(match[5]!);
    final second = int.parse(match[6]!);
    final calendar = DateTime.utc(year, month, day);
    final zone = match[8];
    if (calendar.year != year ||
        calendar.month != month ||
        calendar.day != day ||
        hour > 23 ||
        minute > 59 ||
        second > 59 ||
        (zone != null &&
            zone != 'Z' &&
            (int.parse(zone.substring(1, 3)) > 23 ||
                int.parse(zone.substring(4, 6)) > 59))) {
      throw BackupImportException(
        '$label.$key không phải timestamp ISO 8601 hợp lệ.',
      );
    }
    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      throw BackupImportException(
        '$label.$key không phải timestamp ISO 8601 hợp lệ.',
      );
    }
    return parsed;
  }

  void _field(Map<String, dynamic> map, String key, String type, String label) {
    if (!map.containsKey(key)) {
      throw BackupImportException('$label thiếu trường $key.');
    }
    final value = map[key];
    if (type.startsWith('?') && value == null) return;
    switch (type.replaceFirst('?', '')) {
      case 'id':
        _string(map, key, label, nonempty: true);
      case 's':
        _string(map, key, label);
      case 't':
        _date(map, key, label);
      case 'n':
        if (value is! num || !value.isFinite) {
          throw BackupImportException('$label.$key phải là số hữu hạn.');
        }
      case 'i':
        if (value is! int) {
          throw BackupImportException('$label.$key phải là số nguyên.');
        }
      case 'b':
        if (value is! bool) {
          throw BackupImportException('$label.$key phải là boolean.');
        }
    }
  }

  static const _group = {
    'id': 'id',
    'name': 's',
    'description': 's',
    'createdAt': 't',
    'updatedAt': 't',
  };
  static const _profile = {
    'id': 'id',
    'groupId': 'id',
    'fullName': 's',
    'phone': 's',
    'workTarget': 's',
    'description': 's',
    'startDate': 't',
    'deadline': '?t',
    'hasDeadline': 'b',
    'status': 's',
    'totalAmount': 'n',
    'note': 's',
    'createdAt': 't',
    'updatedAt': 't',
    'completedAt': '?t',
    'waitingReason': '?s',
    'waitingSince': '?t',
    'expectedResponseDate': '?t',
  };
  static const _stage = {
    'id': 'id',
    'profileId': 'id',
    'name': 's',
    'order': 'i',
    'status': 's',
    'startDate': '?t',
    'completedAt': '?t',
    'deadline': '?t',
    'note': 's',
  };
  static const _milestone = {
    'id': 'id',
    'profileId': 'id',
    'title': 's',
    'dueDate': 't',
    'status': 's',
    'completedAt': '?t',
    'note': 's',
  };
  static const _task = {
    'id': 'id',
    'profileId': 'id',
    'title': 's',
    'description': 's',
    'status': 's',
    'priority': 's',
    'dueDate': '?t',
    'waitingReason': '?s',
    'waitingSince': '?t',
    'expectedResponseDate': '?t',
    'completedAt': '?t',
    'createdAt': 't',
    'updatedAt': 't',
    'note': 's',
  };
  static const _timeline = {
    'id': 'id',
    'profileId': 'id',
    'type': 's',
    'message': 's',
    'createdAt': 't',
  };
  static const _transaction = {
    'id': 'id',
    'profileId': 'id',
    'type': 's',
    'amount': 'n',
    'date': 't',
    'note': 's',
    'createdAt': 't',
    'collaboratorAssignmentId': '?id',
  };
  static const _collaborator = {
    'id': 'id',
    'name': 's',
    'phone': 's',
    'note': 's',
    'active': 'b',
    'createdAt': 't',
    'updatedAt': 't',
  };
  static const _assignment = {
    'id': 'id',
    'profileId': 'id',
    'collaboratorId': 'id',
    'role': 's',
    'commissionAmount': 'n',
    'paidAmount': 'n',
    'note': 's',
    'createdAt': 't',
    'updatedAt': 't',
    'archivedAt': '?t',
  };
  static const _attachment = {
    'id': 'id',
    'profileId': 'id',
    'fileName': 'id',
    'type': 's',
    'localPathOrUrl': '?s',
    'storagePath': '?s',
    'sizeBytes': 'i',
    'createdAt': 't',
    'updatedAt': 't',
  };
}
