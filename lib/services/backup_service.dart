import 'dart:convert';
import 'dart:typed_data';

import '../models/models.dart';
import 'export_snapshot_validator.dart';

class GeneratedExportFile {
  const GeneratedExportFile({
    required this.fileName,
    required this.mimeType,
    required this.bytes,
  });
  final String fileName;
  final String mimeType;
  final Uint8List bytes;
}

class BackupService {
  const BackupService({this.validator = const ExportSnapshotValidator()});
  static const schemaVersion = 1;
  final ExportSnapshotValidator validator;

  GeneratedExportFile createJsonBackup(ExportSnapshot snapshot) {
    validator.validate(snapshot);
    final document = createDocument(snapshot);
    validateDocument(document);
    return GeneratedExportFile(
      fileName: 'QuanLyCongViec_Backup_${_stamp(snapshot.exportedAt)}.json',
      mimeType: 'application/json;charset=utf-8',
      bytes: Uint8List.fromList(
        utf8.encode(const JsonEncoder.withIndent('  ').convert(document)),
      ),
    );
  }

  Map<String, dynamic> createDocument(ExportSnapshot snapshot) => {
    'schemaVersion': schemaVersion,
    'exportedAt': snapshot.exportedAt.toIso8601String(),
    'appVersion': snapshot.appVersion,
    'source': {
      'mode': snapshot.sourceMode,
      'timeZone': snapshot.exportedAt.timeZoneName,
      'recordCounts': snapshot.recordCounts,
      'attachmentBinaryIncluded': false,
      'attachmentPathWarning':
          'localPathOrUrl có thể không sử dụng được trên thiết bị khác.',
    },
    'data': {
      'groups': snapshot.groups.map((e) => e.toJson()).toList(),
      'profiles': snapshot.profiles.map((e) => e.toJson()).toList(),
      'stages': snapshot.stages.map((e) => e.toJson()).toList(),
      'milestones': snapshot.milestones.map((e) => e.toJson()).toList(),
      'tasks': snapshot.tasks.map((e) => e.toJson()).toList(),
      'timelineEvents': snapshot.timelineEvents.map((e) => e.toJson()).toList(),
      'transactions': snapshot.transactions.map((e) => e.toJson()).toList(),
      'collaborators': snapshot.collaborators.map((e) => e.toJson()).toList(),
      'collaboratorAssignments': snapshot.collaboratorAssignments
          .map((e) => e.toJson())
          .toList(),
      'attachments': snapshot.attachments.map((e) => e.toJson()).toList(),
    },
  };

  void validateDocument(Map<String, dynamic> document) {
    try {
      if (document['schemaVersion'] != schemaVersion) {
        throw const ExportValidationException(
          'Phiên bản backup không được hỗ trợ.',
        );
      }
      DateTime.parse(document['exportedAt'] as String);
      final source = _map(document['source']);
      if (!const {'firebase', 'demo'}.contains(source['mode'])) {
        throw const ExportValidationException('Nguồn backup không hợp lệ.');
      }
      final data = _map(document['data']);
      final groups = _items(data, 'groups', WorkGroup.fromJson);
      final profiles = _strictItems(
        data,
        'profiles',
        'status',
        ProfileStatus.values.map((e) => e.value).toSet(),
        Profile.fromJson,
      );
      final stages = _strictItems(
        data,
        'stages',
        'status',
        StageStatus.values.map((e) => e.value).toSet(),
        WorkStage.fromJson,
      );
      final milestones = _strictItems(
        data,
        'milestones',
        'status',
        MilestoneStatus.values.map((e) => e.value).toSet(),
        Milestone.fromJson,
      );
      final tasks = _strictItems(
        data,
        'tasks',
        'status',
        TaskStatus.values.map((e) => e.value).toSet(),
        TaskItem.fromJson,
        extraEnumField: 'priority',
        extraAllowed: TaskPriority.values.map((e) => e.value).toSet(),
      );
      final timeline = _strictItems(
        data,
        'timelineEvents',
        'type',
        TimelineEventType.values.map((e) => e.value).toSet(),
        TimelineEvent.fromJson,
      );
      final transactions = _strictItems(
        data,
        'transactions',
        'type',
        TransactionType.values.map((e) => e.value).toSet(),
        MoneyTransaction.fromJson,
      );
      final collaborators = _items(
        data,
        'collaborators',
        Collaborator.fromJson,
      );
      final assignments = _items(
        data,
        'collaboratorAssignments',
        CollaboratorAssignment.fromJson,
      );
      final attachments = _strictItems(
        data,
        'attachments',
        'type',
        AttachmentType.values.map((e) => e.name).toSet(),
        Attachment.fromJson,
      );
      validator.validate(
        ExportSnapshot(
          exportedAt: DateTime.parse(document['exportedAt'] as String),
          appVersion: document['appVersion'] as String,
          sourceMode: source['mode'] as String,
          repositoryRevision: 0,
          groups: groups,
          profiles: profiles,
          stages: stages,
          milestones: milestones,
          tasks: tasks,
          timelineEvents: timeline,
          transactions: transactions,
          collaborators: collaborators,
          collaboratorAssignments: assignments,
          attachments: attachments,
        ),
      );
    } on ExportValidationException {
      rethrow;
    } catch (_) {
      throw const ExportValidationException(
        'Cấu trúc hoặc kiểu dữ liệu backup không hợp lệ.',
      );
    }
  }

  List<T> _items<T>(
    Map<String, dynamic> data,
    String key,
    T Function(Map<String, dynamic>) decode,
  ) => _list(data[key]).map((e) => decode(_map(e))).toList();

  List<T> _strictItems<T>(
    Map<String, dynamic> data,
    String key,
    String enumField,
    Set<String> allowed,
    T Function(Map<String, dynamic>) decode, {
    String? extraEnumField,
    Set<String>? extraAllowed,
  }) => _list(data[key]).map((raw) {
    final map = _map(raw);
    if (!allowed.contains(map[enumField])) {
      throw ExportValidationException(
        'Giá trị enum $key.$enumField không hợp lệ.',
      );
    }
    if (extraEnumField != null &&
        !extraAllowed!.contains(map[extraEnumField])) {
      throw ExportValidationException(
        'Giá trị enum $key.$extraEnumField không hợp lệ.',
      );
    }
    return decode(map);
  }).toList();

  Map<String, dynamic> _map(Object? value) {
    if (value is! Map) throw const FormatException();
    return value.map((key, value) => MapEntry(key.toString(), value));
  }

  List<dynamic> _list(Object? value) {
    if (value is! List) throw const FormatException();
    return value;
  }

  String _stamp(DateTime value) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${value.year}-${two(value.month)}-${two(value.day)}_'
        '${two(value.hour)}${two(value.minute)}';
  }
}
