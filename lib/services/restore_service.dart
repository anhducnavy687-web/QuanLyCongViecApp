import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/models.dart';
import '../repositories/app_repository.dart';
import '../repositories/firebase_repository.dart';
import 'export_snapshot_validator.dart';

class RestoreException implements Exception {
  const RestoreException(this.message);
  final String message;
  @override
  String toString() => message;
}

class RestoreService {
  const RestoreService({this.safeWriteLimit = 450});
  final int safeWriteLimit;

  Future<RestorePlan> createPlan({
    required FirebaseRepository repository,
    required RestorePreview preview,
  }) async {
    _validateSnapshot(preview.snapshot);
    final currentPaths = await _readServerPaths(
      repository.firestore,
      repository.uid,
    );
    return plan(
      uid: repository.uid,
      preview: preview,
      currentDocumentPaths: currentPaths,
    );
  }

  RestorePlan plan({
    required String uid,
    required RestorePreview preview,
    required Set<String> currentDocumentPaths,
  }) {
    _validateUid(uid);
    _validateSnapshot(preview.snapshot);
    final snapshot = preview.snapshot;
    final rebuiltAssignments = [
      for (final assignment in snapshot.collaboratorAssignments)
        assignment.copyWith(
          paidAmount: preview.rebuiltPaidAmounts[assignment.id] ?? 0,
        ),
    ];
    for (final assignment in rebuiltAssignments) {
      if (assignment.paidAmount > assignment.commissionAmount) {
        throw RestoreException(
          'Assignment ${assignment.id} có số tiền đã trả lớn hơn hoa hồng.',
        );
      }
    }

    final root = 'users/$uid';
    final documents = <RestoreDocument>[
      for (final value in snapshot.groups)
        RestoreDocument(path: '$root/groups/${value.id}', data: value.toJson()),
      for (final value in snapshot.collaborators)
        RestoreDocument(
          path: '$root/collaborators/${value.id}',
          data: value.toJson(),
        ),
      for (final value in snapshot.profiles)
        RestoreDocument(
          path: '$root/profiles/${value.id}',
          data: value.toJson(),
        ),
      for (final value in snapshot.stages)
        RestoreDocument(
          path: '$root/profiles/${value.profileId}/stages/${value.id}',
          data: value.toJson(),
        ),
      for (final value in snapshot.milestones)
        RestoreDocument(
          path: '$root/profiles/${value.profileId}/milestones/${value.id}',
          data: value.toJson(),
        ),
      for (final value in snapshot.tasks)
        RestoreDocument(
          path: '$root/profiles/${value.profileId}/tasks/${value.id}',
          data: value.toJson(),
        ),
      for (final value in snapshot.timelineEvents)
        RestoreDocument(
          path: '$root/profiles/${value.profileId}/timelineEvents/${value.id}',
          data: value.toJson(),
        ),
      for (final value in snapshot.transactions)
        RestoreDocument(
          path: '$root/profiles/${value.profileId}/transactions/${value.id}',
          data: value.toJson(),
        ),
      for (final value in rebuiltAssignments)
        RestoreDocument(
          path:
              '$root/profiles/${value.profileId}/collaboratorAssignments/${value.id}',
          data: value.toJson(),
        ),
      for (final value in snapshot.attachments)
        RestoreDocument(
          path: '$root/profiles/${value.profileId}/attachments/${value.id}',
          data: value.toJson(),
        ),
    ];
    final incomingPaths = documents.map((document) => document.path).toSet();
    final result = RestorePlan(
      uid: uid,
      incomingSnapshot: snapshot,
      currentDocumentPaths: currentDocumentPaths,
      documentsToSet: documents,
      documentsToDelete: currentDocumentPaths.difference(incomingPaths),
    );
    if (result.totalWrites > safeWriteLimit) {
      throw const RestoreException(
        'Bản sao lưu này quá lớn để khôi phục an toàn trong phiên bản hiện tại.',
      );
    }
    return result;
  }

  Future<void> commit({
    required FirebaseRepository repository,
    required RestorePreview preview,
    required RestorePlan plan,
    required String? Function() currentUid,
  }) async {
    final token = repository.beginRestore();
    try {
      await _commitLocked(
        repository: repository,
        preview: preview,
        plan: plan,
        currentUid: currentUid,
      );
    } on RestoreException {
      rethrow;
    } catch (_) {
      throw const RestoreException(
        'Không thể khôi phục dữ liệu. Dữ liệu hiện tại được giữ nguyên.',
      );
    } finally {
      repository.endRestore(token);
    }
  }

  Future<RestorePlan> restore({
    required FirebaseRepository repository,
    required RestorePreview preview,
    required String? Function() currentUid,
  }) async {
    final token = repository.beginRestore();
    try {
      if (currentUid() != repository.uid) {
        throw const RestoreException(
          'Phiên đăng nhập đã thay đổi. Dữ liệu chưa được khôi phục.',
        );
      }
      _validateSnapshot(preview.snapshot);
      final paths = await _readServerPaths(
        repository.firestore,
        repository.uid,
      );
      final restorePlan = plan(
        uid: repository.uid,
        preview: preview,
        currentDocumentPaths: paths,
      );
      await _commitLocked(
        repository: repository,
        preview: preview,
        plan: restorePlan,
        currentUid: currentUid,
      );
      return restorePlan;
    } on RestoreException {
      rethrow;
    } catch (_) {
      throw const RestoreException(
        'Không thể khôi phục dữ liệu. Dữ liệu hiện tại được giữ nguyên.',
      );
    } finally {
      repository.endRestore(token);
    }
  }

  Future<void> _commitLocked({
    required FirebaseRepository repository,
    required RestorePreview preview,
    required RestorePlan plan,
    required String? Function() currentUid,
  }) async {
    _validateSnapshot(preview.snapshot);
    if (!identical(plan.incomingSnapshot, preview.snapshot) ||
        plan.uid != repository.uid ||
        currentUid() != plan.uid ||
        !repository.isRestoreInProgress) {
      throw const RestoreException(
        'Phiên đăng nhập đã thay đổi. Dữ liệu chưa được khôi phục.',
      );
    }
    if (plan.totalWrites > safeWriteLimit) {
      throw const RestoreException(
        'Bản sao lưu này quá lớn để khôi phục an toàn trong phiên bản hiện tại.',
      );
    }
    final batch = repository.firestore.batch();
    for (final document in plan.documentsToSet) {
      batch.set(repository.firestore.doc(document.path), document.data);
    }
    for (final path in plan.documentsToDelete) {
      batch.delete(repository.firestore.doc(path));
    }
    if (currentUid() != plan.uid || !repository.isRestoreInProgress) {
      throw const RestoreException(
        'Phiên đăng nhập đã thay đổi. Dữ liệu chưa được khôi phục.',
      );
    }
    await batch.commit();
  }

  void verify(AppRepository repository, RestorePreview preview) {
    if (!repository.isReady || repository.syncError != null) {
      throw const RestoreException('Repository chưa đồng bộ thành công.');
    }
    final expected = preview.snapshot;
    Set<String> ids<T>(Iterable<T> values, String Function(T) id) =>
        values.map(id).toSet();
    void same(Set<String> actual, Set<String> wanted) {
      if (actual.length != wanted.length || !actual.containsAll(wanted)) {
        throw const RestoreException('Dữ liệu máy chủ chưa khớp bản sao lưu.');
      }
    }

    same(
      ids(repository.groups, (e) => e.id),
      ids(expected.groups, (e) => e.id),
    );
    for (final wanted in expected.groups) {
      final actual = repository.groupById(wanted.id)!;
      if (actual.profileFieldSchemaVersion !=
              wanted.profileFieldSchemaVersion ||
          actual.effectiveFieldConfigs
                  .map((e) => e.toJson().toString())
                  .join() !=
              wanted.effectiveFieldConfigs
                  .map((e) => e.toJson().toString())
                  .join() ||
          actual.customFieldDefinitions
                  .map((e) => e.toJson().toString())
                  .join() !=
              wanted.customFieldDefinitions
                  .map((e) => e.toJson().toString())
                  .join()) {
        throw const RestoreException(
          'Cấu hình trường hồ sơ chưa khớp bản sao lưu.',
        );
      }
    }
    same(
      ids(repository.profiles, (e) => e.id),
      ids(expected.profiles, (e) => e.id),
    );
    same(
      ids(repository.collaborators, (e) => e.id),
      ids(expected.collaborators, (e) => e.id),
    );
    for (final profile in expected.profiles) {
      final restoredProfile = repository.profileById(profile.id)!;
      if (restoredProfile.customFieldValues.toString() !=
          profile.customFieldValues.toString()) {
        throw const RestoreException(
          'Giá trị trường tùy chỉnh chưa khớp bản sao lưu.',
        );
      }
      same(
        ids(repository.stagesOf(profile.id), (e) => e.id),
        ids(
          expected.stages.where((e) => e.profileId == profile.id),
          (e) => e.id,
        ),
      );
      same(
        ids(repository.milestonesOf(profile.id), (e) => e.id),
        ids(
          expected.milestones.where((e) => e.profileId == profile.id),
          (e) => e.id,
        ),
      );
      same(
        ids(repository.tasksOf(profile.id), (e) => e.id),
        ids(
          expected.tasks.where((e) => e.profileId == profile.id),
          (e) => e.id,
        ),
      );
      same(
        ids(repository.timelineOf(profile.id), (e) => e.id),
        ids(
          expected.timelineEvents.where((e) => e.profileId == profile.id),
          (e) => e.id,
        ),
      );
      same(
        ids(repository.transactionsOf(profile.id), (e) => e.id),
        ids(
          expected.transactions.where((e) => e.profileId == profile.id),
          (e) => e.id,
        ),
      );
      same(
        ids(repository.attachmentsOf(profile.id), (e) => e.id),
        ids(
          expected.attachments.where((e) => e.profileId == profile.id),
          (e) => e.id,
        ),
      );
      final assignments = repository.assignmentsOf(profile.id);
      same(
        ids(assignments, (e) => e.id),
        ids(
          expected.collaboratorAssignments.where(
            (e) => e.profileId == profile.id,
          ),
          (e) => e.id,
        ),
      );
      for (final assignment in assignments) {
        if (assignment.paidAmount !=
            (preview.rebuiltPaidAmounts[assignment.id] ?? 0)) {
          throw const RestoreException(
            'paidAmount chưa khớp lịch sử giao dịch.',
          );
        }
      }
    }
  }

  Future<Set<String>> _readServerPaths(
    FirebaseFirestore firestore,
    String uid,
  ) async {
    _validateUid(uid);
    final root = firestore.collection('users').doc(uid);
    final paths = <String>{};
    Future<QuerySnapshot<Map<String, dynamic>>> server(
      CollectionReference<Map<String, dynamic>> ref,
    ) => ref.get(const GetOptions(source: Source.server));
    try {
      for (final name in ['groups', 'collaborators']) {
        final result = await server(root.collection(name));
        paths.addAll(result.docs.map((document) => document.reference.path));
      }
      final profiles = await server(root.collection('profiles'));
      for (final profile in profiles.docs) {
        paths.add(profile.reference.path);
        for (final name in [
          'stages',
          'milestones',
          'tasks',
          'timelineEvents',
          'transactions',
          'collaboratorAssignments',
          'attachments',
        ]) {
          final nested = await server(profile.reference.collection(name));
          paths.addAll(nested.docs.map((document) => document.reference.path));
        }
      }
      return paths;
    } catch (_) {
      throw const RestoreException(
        'Không thể đọc đầy đủ dữ liệu hiện tại từ máy chủ. Dữ liệu chưa được khôi phục.',
      );
    }
  }

  void _validateSnapshot(ExportSnapshot snapshot) {
    try {
      const ExportSnapshotValidator().validate(snapshot);
    } on ExportValidationException catch (error) {
      throw RestoreException(error.message);
    }
    final values = <String>[
      ...snapshot.groups.map((e) => e.id),
      ...snapshot.profiles.expand((e) => [e.id, e.groupId]),
      ...snapshot.stages.expand((e) => [e.id, e.profileId]),
      ...snapshot.milestones.expand((e) => [e.id, e.profileId]),
      ...snapshot.tasks.expand((e) => [e.id, e.profileId]),
      ...snapshot.timelineEvents.expand((e) => [e.id, e.profileId]),
      ...snapshot.transactions.expand(
        (e) => [
          e.id,
          e.profileId,
          if (e.collaboratorAssignmentId != null) e.collaboratorAssignmentId!,
        ],
      ),
      ...snapshot.collaborators.map((e) => e.id),
      ...snapshot.collaboratorAssignments.expand(
        (e) => [e.id, e.profileId, e.collaboratorId],
      ),
      ...snapshot.attachments.expand((e) => [e.id, e.profileId]),
    ];
    for (final value in values) {
      _validateId(value);
    }
  }

  void _validateUid(String uid) => _validateId(uid);

  void _validateId(String id) {
    if (id.isEmpty ||
        id.length > 256 ||
        id == '.' ||
        id == '..' ||
        id.contains('/') ||
        id.contains('\\') ||
        id.contains('../') ||
        id.contains('..\\')) {
      throw const RestoreException(
        'Bản sao lưu chứa ID không an toàn và không thể khôi phục.',
      );
    }
  }
}
