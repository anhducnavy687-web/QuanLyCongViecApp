import 'dart:convert';

import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quanlycongviecapp/models/models.dart';
import 'package:quanlycongviecapp/repositories/app_repository.dart';
import 'package:quanlycongviecapp/repositories/demo_repository.dart';
import 'package:quanlycongviecapp/services/backup_service.dart';
import 'package:quanlycongviecapp/services/excel_export_service.dart';
import 'package:quanlycongviecapp/services/export_snapshot_validator.dart';

class SnapshotTestRepository extends DemoRepository {
  bool forceNotReady = false;
  String? forcedError;

  @override
  bool get isReady => !forceNotReady && super.isReady;

  @override
  String? get syncError => forcedError;

  Future<void> holdWrite(Future<void> Function() action) =>
      runTrackedWrite(action);

  void changeRevision() => notifyListeners();
}

class EmptySnapshotRepository extends SnapshotTestRepository {
  @override
  List<WorkGroup> get groups => const [];
  @override
  List<Profile> get profiles => const [];
  @override
  List<Collaborator> get collaborators => const [];
}

void main() {
  group('repository export snapshot', () {
    test('copies the full graph into immutable lists', () async {
      final repo = SnapshotTestRepository();
      await repo.init();
      final snapshot = await repo.createExportSnapshot();
      expect(snapshot.groups.length, repo.groups.length);
      expect(snapshot.profiles.length, repo.profiles.length);
      expect(
        snapshot.transactions.length,
        repo.profiles.fold<int>(
          0,
          (n, p) => n + repo.transactionsOf(p.id).length,
        ),
      );
      expect(
        () => snapshot.groups.add(repo.groups.first),
        throwsUnsupportedError,
      );
      repo.dispose();
    });

    test('rejects not-ready, sync-error and write-in-flight states', () async {
      final repo = SnapshotTestRepository();
      await repo.init();
      repo.forceNotReady = true;
      await expectLater(
        repo.createExportSnapshot(),
        throwsA(isA<RepositoryException>()),
      );
      repo.forceNotReady = false;
      repo.forcedError = 'sync failed';
      await expectLater(
        repo.createExportSnapshot(),
        throwsA(isA<RepositoryException>()),
      );
      repo.forcedError = null;
      final blocker = Future<void>.delayed(const Duration(milliseconds: 50));
      final write = repo.holdWrite(() => blocker);
      await expectLater(
        repo.createExportSnapshot(),
        throwsA(isA<RepositoryException>()),
      );
      await write;
      repo.dispose();
    });

    test('revision change prevents a stale snapshot', () async {
      final repo = SnapshotTestRepository();
      await repo.init();
      final future = repo.createExportSnapshot();
      repo.changeRevision();
      await expectLater(future, throwsA(isA<RepositoryException>()));
      repo.dispose();
    });

    test('empty dataset is valid', () async {
      final repo = EmptySnapshotRepository();
      await repo.init();
      final snapshot = await repo.createExportSnapshot();
      expect(snapshot.recordCounts.values.every((count) => count == 0), true);
      repo.dispose();
    });
  });

  group('JSON backup v2', () {
    test('serializes full graph, Unicode, nulls, enums and metadata', () async {
      final repo = SnapshotTestRepository();
      await repo.init();
      final snapshot = await repo.createExportSnapshot();
      final file = const BackupService().createJsonBackup(snapshot);
      final json = jsonDecode(utf8.decode(file.bytes)) as Map<String, dynamic>;
      expect(json['schemaVersion'], 2);
      expect(json['exportedAt'], snapshot.exportedAt.toIso8601String());
      expect(
        file.fileName,
        matches(RegExp(r'^QuanLyCongViec_Backup_.*\.json$')),
      );
      expect(utf8.decode(file.bytes), contains('Nguyễn'));
      expect(
        (json['data'] as Map)['profiles'],
        hasLength(snapshot.profiles.length),
      );
      expect(
        (json['data'] as Map)['attachments'].toString(),
        isNot(contains('binary')),
      );
      expect(((json['source'] as Map)['attachmentBinaryIncluded']), false);
      repo.dispose();
    });

    test('strict document validation rejects unknown enum', () async {
      final repo = SnapshotTestRepository();
      await repo.init();
      final service = const BackupService();
      final document = service.createDocument(
        await repo.createExportSnapshot(),
      );
      final profiles = (document['data'] as Map)['profiles'] as List;
      (profiles.first as Map<String, dynamic>)['status'] = 'unknown';
      expect(
        () => service.validateDocument(document),
        throwsA(isA<ExportValidationException>()),
      );
      repo.dispose();
    });

    test(
      'rejects duplicates, broken FK, invalid money and paid mismatch',
      () async {
        final repo = SnapshotTestRepository();
        await repo.init();
        final base = await repo.createExportSnapshot();
        ExportSnapshot copy({
          List<WorkGroup>? groups,
          List<Profile>? profiles,
          List<MoneyTransaction>? transactions,
          List<CollaboratorAssignment>? assignments,
        }) => ExportSnapshot(
          exportedAt: base.exportedAt,
          appVersion: base.appVersion,
          sourceMode: base.sourceMode,
          repositoryRevision: base.repositoryRevision,
          groups: groups ?? base.groups,
          profiles: profiles ?? base.profiles,
          stages: base.stages,
          milestones: base.milestones,
          tasks: base.tasks,
          timelineEvents: base.timelineEvents,
          transactions: transactions ?? base.transactions,
          collaborators: base.collaborators,
          collaboratorAssignments: assignments ?? base.collaboratorAssignments,
          attachments: base.attachments,
        );
        const validator = ExportSnapshotValidator();
        expect(
          () => validator.validate(
            copy(groups: [...base.groups, base.groups.first]),
          ),
          throwsA(isA<ExportValidationException>()),
        );
        expect(
          () => validator.validate(
            copy(
              profiles: [
                base.profiles.first.copyWith(groupId: 'missing'),
                ...base.profiles.skip(1),
              ],
            ),
          ),
          throwsA(isA<ExportValidationException>()),
        );
        final transaction = base.transactions.first;
        expect(
          () => validator.validate(
            copy(
              transactions: [
                transaction.copyWith(amount: 0),
                ...base.transactions.skip(1),
              ],
            ),
          ),
          throwsA(isA<ExportValidationException>()),
        );
        final assignment = base.collaboratorAssignments.first;
        expect(
          () => validator.validate(
            copy(
              assignments: [
                assignment.copyWith(paidAmount: assignment.paidAmount + 1),
                ...base.collaboratorAssignments.skip(1),
              ],
            ),
          ),
          throwsA(isA<ExportValidationException>()),
        );
        repo.dispose();
      },
    );

    test(
      'rejects invalid deadline, waiting, completedAt and commission',
      () async {
        final repo = SnapshotTestRepository();
        await repo.init();
        final base = await repo.createExportSnapshot();
        ExportSnapshot copy({
          List<Profile>? profiles,
          List<TaskItem>? tasks,
          List<CollaboratorAssignment>? assignments,
        }) => ExportSnapshot(
          exportedAt: base.exportedAt,
          appVersion: base.appVersion,
          sourceMode: base.sourceMode,
          repositoryRevision: base.repositoryRevision,
          groups: base.groups,
          profiles: profiles ?? base.profiles,
          stages: base.stages,
          milestones: base.milestones,
          tasks: tasks ?? base.tasks,
          timelineEvents: base.timelineEvents,
          transactions: base.transactions,
          collaborators: base.collaborators,
          collaboratorAssignments: assignments ?? base.collaboratorAssignments,
          attachments: base.attachments,
        );
        const validator = ExportSnapshotValidator();
        final profile = base.profiles.first;
        expect(
          () => validator.validate(
            copy(
              profiles: [
                profile.copyWith(hasDeadline: true, clearDeadline: true),
                ...base.profiles.skip(1),
              ],
            ),
          ),
          throwsA(isA<ExportValidationException>()),
        );
        final task = base.tasks.first;
        expect(
          () => validator.validate(
            copy(
              tasks: [
                task.copyWith(
                  status: TaskStatus.waiting,
                  waitingSince: DateTime(2026, 2, 2),
                  expectedResponseDate: DateTime(2026, 2, 1),
                ),
                ...base.tasks.skip(1),
              ],
            ),
          ),
          throwsA(isA<ExportValidationException>()),
        );
        expect(
          () => validator.validate(
            copy(
              profiles: [
                profile.copyWith(
                  status: ProfileStatus.completed,
                  clearCompletedAt: true,
                ),
                ...base.profiles.skip(1),
              ],
            ),
          ),
          throwsA(isA<ExportValidationException>()),
        );
        final assignment = base.collaboratorAssignments.firstWhere(
          (a) => a.paidAmount > 0,
        );
        expect(
          () => validator.validate(
            copy(
              assignments: [
                for (final a in base.collaboratorAssignments)
                  if (a.id == assignment.id)
                    a.copyWith(commissionAmount: assignment.paidAmount - 1)
                  else
                    a,
              ],
            ),
          ),
          throwsA(isA<ExportValidationException>()),
        );
        repo.dispose();
      },
    );

    test(
      'preserves archived and inactive states without attachment binary',
      () async {
        final repo = SnapshotTestRepository();
        await repo.init();
        final base = await repo.createExportSnapshot();
        final snapshot = ExportSnapshot(
          exportedAt: base.exportedAt,
          appVersion: base.appVersion,
          sourceMode: base.sourceMode,
          repositoryRevision: base.repositoryRevision,
          groups: base.groups,
          profiles: base.profiles,
          stages: base.stages,
          milestones: base.milestones,
          tasks: base.tasks,
          timelineEvents: base.timelineEvents,
          transactions: base.transactions,
          collaborators: [
            base.collaborators.first.copyWith(active: false),
            ...base.collaborators.skip(1),
          ],
          collaboratorAssignments: [
            base.collaboratorAssignments.first.copyWith(
              archivedAt: DateTime(2026, 1, 1),
            ),
            ...base.collaboratorAssignments.skip(1),
          ],
          attachments: base.attachments,
        );
        final document = const BackupService().createDocument(snapshot);
        final data = document['data'] as Map;
        expect((data['collaborators'] as List).first['active'], false);
        expect(
          (data['collaboratorAssignments'] as List).first['archivedAt'],
          isNotNull,
        );
        expect(data['attachments'].toString(), isNot(contains('binary')));
        repo.dispose();
      },
    );
  });

  group('XLSX export', () {
    test('creates expected sheets, rows, Unicode and numeric money', () async {
      final repo = SnapshotTestRepository();
      await repo.init();
      final snapshot = await repo.createExportSnapshot();
      final file = const ExcelExportService().createWorkbook(snapshot);
      final workbook = Excel.decodeBytes(file.bytes);
      expect(workbook.tables.keys.toSet(), {
        'Metadata',
        'Groups',
        'Profiles',
        'Stages',
        'Milestones',
        'Tasks',
        'TimelineEvents',
        'Transactions',
        'Collaborators',
        'CollaboratorAssignments',
        'Attachments',
        'FieldDefinitions',
        'CustomFieldValues',
      });
      expect(workbook['Profiles'].maxRows, snapshot.profiles.length + 1);
      expect(
        workbook['Profiles'].rows
            .expand((e) => e)
            .any((cell) => cell?.value.toString().contains('Nguyễn') ?? false),
        true,
      );
      final amount = workbook['Transactions']
          .cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: 1))
          .value;
      expect(amount, anyOf(isA<IntCellValue>(), isA<DoubleCellValue>()));
      expect(
        workbook['Attachments'].rows.first.last?.value.toString(),
        'Binary included',
      );
      repo.dispose();
    });

    test('empty dataset still creates all sheets with headers', () async {
      final repo = EmptySnapshotRepository();
      await repo.init();
      final file = const ExcelExportService().createWorkbook(
        await repo.createExportSnapshot(),
      );
      final workbook = Excel.decodeBytes(file.bytes);
      expect(workbook.tables, hasLength(13));
      expect(workbook['Groups'].maxRows, 1);
      repo.dispose();
    });
  });
}
