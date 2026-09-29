import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:quanlycongviecapp/repositories/demo_repository.dart';
import 'package:quanlycongviecapp/services/backup_file_picker.dart';
import 'package:quanlycongviecapp/services/backup_import_service.dart';
import 'package:quanlycongviecapp/services/backup_service.dart';

void main() {
  const service = BackupImportService();
  late DemoRepository repository;
  late Map<String, dynamic> base;

  setUpAll(() async {
    repository = DemoRepository();
    await repository.init();
    base = const BackupService().createDocument(
      await repository.createExportSnapshot(),
    );
  });
  tearDownAll(() => repository.dispose());

  Map<String, dynamic> copy() =>
      jsonDecode(jsonEncode(base)) as Map<String, dynamic>;
  List<Map<String, dynamic>> items(Map<String, dynamic> doc, String key) =>
      ((doc['data'] as Map<String, dynamic>)[key] as List)
          .cast<Map<String, dynamic>>();
  PickedBackupFile file(Object doc, {String name = 'backup.json'}) {
    final bytes = Uint8List.fromList(utf8.encode(jsonEncode(doc)));
    return PickedBackupFile(name: name, size: bytes.length, bytes: bytes);
  }

  void rejects(void Function(Map<String, dynamic>) change, [String? message]) {
    final doc = copy();
    change(doc);
    expect(
      () => service.inspect(file(doc)),
      throwsA(
        isA<BackupImportException>().having(
          (e) => e.message,
          'message',
          message == null ? isNotEmpty : contains(message),
        ),
      ),
    );
  }

  test(
    'valid B1 JSON v1 produces immutable full-graph preview and no write',
    () {
      final beforeRevision = repository.revision;
      final beforeWrites = repository.writesInFlight;
      final preview = service.inspect(file(copy()));
      expect(preview.isValid, true);
      expect(preview.schemaVersion, 1);
      expect(preview.recordCounts['profiles'], repository.profiles.length);
      expect(
        preview.snapshot.recordCounts.keys,
        containsAll([
          'groups',
          'profiles',
          'stages',
          'milestones',
          'tasks',
          'timelineEvents',
          'transactions',
          'collaborators',
          'collaboratorAssignments',
          'attachments',
        ]),
      );
      expect(() => preview.warnings.add('x'), throwsUnsupportedError);
      expect(preview.snapshot.profiles.first.fullName, contains('Nguyễn'));
      expect(repository.revision, beforeRevision);
      expect(repository.writesInFlight, beforeWrites);
    },
  );

  test('preview totals, archived/inactive counts and rebuilt paid amount', () {
    final preview = service.inspect(file(copy()));
    expect(
      preview.totalReceived,
      preview.snapshot.transactions
          .where((t) => t.type.value == 'RECEIVED')
          .fold<num>(0, (sum, t) => sum + t.amount),
    );
    expect(
      preview.totalExpense,
      preview.snapshot.transactions
          .where((t) => t.type.value == 'EXPENSE')
          .fold<num>(0, (sum, t) => sum + t.amount),
    );
    expect(
      preview.totalCollaboratorPayment,
      preview.snapshot.transactions
          .where((t) => t.type.value == 'COLLABORATOR_PAYMENT')
          .fold<num>(0, (sum, t) => sum + t.amount),
    );
    expect(
      preview.archivedAssignmentCount,
      preview.snapshot.collaboratorAssignments
          .where((a) => a.archivedAt != null)
          .length,
    );
    expect(
      preview.inactiveCollaboratorCount,
      preview.snapshot.collaborators.where((c) => !c.active).length,
    );
    for (final assignment in preview.snapshot.collaboratorAssignments) {
      expect(
        preview.rebuiltPaidAmounts[assignment.id] ?? 0,
        assignment.paidAmount,
      );
    }
  });

  test('file errors: empty, invalid UTF8, invalid JSON, wrong extension, oversized', () {
    expect(
      () => service.inspect(
        PickedBackupFile(name: 'x.json', size: 0, bytes: Uint8List(0)),
      ),
      throwsA(isA<BackupImportException>()),
    );
    expect(
      () => service.inspect(
        PickedBackupFile(
          name: 'x.json',
          size: 1,
          bytes: Uint8List.fromList([0xff]),
        ),
      ),
      throwsA(isA<BackupImportException>()),
    );
    expect(
      () => service.inspect(
        PickedBackupFile(
          name: 'x.json',
          size: 1,
          bytes: Uint8List.fromList([123]),
        ),
      ),
      throwsA(isA<BackupImportException>()),
    );
    expect(
      () => service.inspect(file(copy(), name: 'x.txt')),
      throwsA(isA<BackupImportException>()),
    );
    expect(
      () => service.inspect(
        PickedBackupFile(
          name: 'x.json',
          size: BackupImportService.maxFileBytes + 1,
          bytes: Uint8List.fromList([123]),
        ),
      ),
      throwsA(isA<BackupImportException>()),
    );
  });

  test('schema version missing, wrong type, future and old rejected', () {
    rejects((d) => d.remove('schemaVersion'), 'schemaVersion');
    rejects((d) => d['schemaVersion'] = '1', 'schemaVersion');
    rejects((d) => d['schemaVersion'] = 2, 'mới hơn');
    rejects((d) => d['schemaVersion'] = 0, 'cũ');
  });

  test('strict fields: missing, wrong type, empty ID, invalid timestamp', () {
    rejects((d) => items(d, 'profiles').first.remove('fullName'), 'fullName');
    rejects(
      (d) => items(d, 'profiles').first['hasDeadline'] = 'false',
      'hasDeadline',
    );
    rejects((d) => items(d, 'profiles').first['id'] = ' ', 'id');
    rejects(
      (d) => items(d, 'profiles').first['createdAt'] = '2026-02-30T12:00:00',
      'createdAt',
    );
    rejects((d) => items(d, 'collaborators').first['active'] = null, 'active');
  });

  test('unknown enums rejected without model fallback', () {
    for (final pair in [
      ('profiles', 'status'),
      ('stages', 'status'),
      ('milestones', 'status'),
      ('tasks', 'status'),
      ('tasks', 'priority'),
      ('timelineEvents', 'type'),
      ('transactions', 'type'),
      ('attachments', 'type'),
    ]) {
      rejects((d) => items(d, pair.$1).first[pair.$2] = 'unknown', pair.$2);
    }
  });

  test('duplicate IDs and broken FKs rejected', () {
    for (final key in ['groups', 'profiles', 'collaboratorAssignments']) {
      rejects(
        (d) =>
            items(d, key).add(Map<String, dynamic>.from(items(d, key).first)),
        'trùng',
      );
    }
    rejects((d) => items(d, 'profiles').first['groupId'] = 'missing-group');
    rejects((d) => items(d, 'tasks').first['profileId'] = 'missing-profile');
    rejects(
      (d) => items(d, 'collaboratorAssignments').first['collaboratorId'] =
          'missing-collaborator',
    );
    rejects((d) {
      final tx = items(
        d,
        'transactions',
      ).firstWhere((x) => x['type'] == 'COLLABORATOR_PAYMENT');
      tx['collaboratorAssignmentId'] = 'missing-assignment';
    });
    rejects((d) {
      final tx = items(
        d,
        'transactions',
      ).firstWhere((x) => x['type'] == 'COLLABORATOR_PAYMENT');
      tx['profileId'] = items(d, 'profiles').last['id'];
    });
  });

  test('money amount, cache mismatch and commission violation rejected', () {
    rejects((d) => items(d, 'transactions').first['amount'] = 0);
    rejects((d) => items(d, 'transactions').first['amount'] = -1);
    rejects((d) => items(d, 'transactions').first['amount'] = 'NaN');
    rejects((d) => items(d, 'transactions').first['amount'] = 'Infinity');
    rejects(
      (d) =>
          items(d, 'collaboratorAssignments').first['paidAmount'] = 999999999,
    );
    rejects(
      (d) => items(d, 'collaboratorAssignments').first['commissionAmount'] = -1,
    );
    rejects(
      (d) => items(d, 'collaboratorAssignments').first['commissionAmount'] = 0,
    );
  });

  test('deadline, waiting and completed invariants rejected', () {
    rejects(
      (d) => items(d, 'profiles').first['hasDeadline'] =
          !(items(d, 'profiles').first['deadline'] != null),
    );
    rejects((d) {
      final p = items(d, 'profiles').first;
      p['hasDeadline'] = true;
      p['deadline'] = '2000-01-01T00:00:00';
    });
    rejects((d) {
      final p = items(d, 'profiles').first;
      p['status'] = 'waiting';
      p['waitingSince'] = '2026-09-21T12:00:00';
      p['expectedResponseDate'] = '2026-09-20T12:00:00';
      p['completedAt'] = null;
    });
    rejects((d) {
      final p = items(d, 'profiles').first;
      p['status'] = 'new';
      p['waitingSince'] = '2026-09-21T12:00:00';
    });
    rejects((d) {
      final p = items(d, 'profiles').first;
      p['status'] = 'new';
      p['waitingReason'] = 'Đang chờ';
      p['waitingSince'] = null;
      p['expectedResponseDate'] = null;
    });
    rejects((d) {
      final p = items(d, 'profiles').first;
      p['status'] = 'completed';
      p['completedAt'] = null;
      p['waitingSince'] = null;
      p['expectedResponseDate'] = null;
    });
    rejects((d) {
      final t = items(d, 'tasks').first;
      t['status'] = 'todo';
      t['completedAt'] = '2026-09-21T12:00:00';
      t['waitingSince'] = null;
      t['expectedResponseDate'] = null;
    });
  });

  test(
    'attachments metadata only; invalid size rejected; warnings generated',
    () {
      final preview = service.inspect(file(copy()));
      expect(preview.snapshot.attachments, isNotEmpty);
      expect(preview.warnings.join(' '), contains('metadata'));
      expect(preview.warnings.join(' '), contains('Demo'));
      final nullablePath = copy();
      items(nullablePath, 'attachments').first['localPathOrUrl'] = null;
      expect(
        service
            .inspect(file(nullablePath))
            .snapshot
            .attachments
            .first
            .localPathOrUrl,
        isNull,
      );
      rejects((d) => items(d, 'attachments').first['sizeBytes'] = -1);
      rejects((d) => items(d, 'attachments').first['sizeBytes'] = '2');
      rejects(
        (d) => items(d, 'collaboratorAssignments').first['archivedAt'] = 'bad',
      );
    },
  );

  test('invalid inspection cannot mutate repository', () {
    final before = repository.revision;
    rejects((d) => items(d, 'transactions').first['amount'] = 0);
    expect(repository.revision, before);
    expect(repository.writesInFlight, 0);
  });
}
