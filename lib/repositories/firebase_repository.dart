import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/utils/app_date_utils.dart';
import '../models/models.dart';
import '../services/firebase_error_message.dart';
import 'app_repository.dart';

/// Triển khai [AppRepository] thật bằng Cloud Firestore.
///
/// Cấu trúc Firestore (xem thêm docs/firestore-schema.md):
///   users/{uid}/groups/{groupId}
///   users/{uid}/profiles/{profileId}
///   users/{uid}/profiles/{profileId}/stages/{stageId}
///   users/{uid}/profiles/{profileId}/milestones/{milestoneId}
///   users/{uid}/profiles/{profileId}/transactions/{transactionId}
///   users/{uid}/profiles/{profileId}/attachments/{attachmentId}
///   users/{uid}/profiles/{profileId}/collaboratorAssignments/{assignmentId}
///   users/{uid}/collaborators/{collaboratorId}
///
/// Repository giữ một bản cache trong bộ nhớ được đồng bộ bằng các
/// snapshot listener của Firestore, rồi gọi [notifyListeners] — do đó UI
/// (vốn chỉ biết tới [AppRepository]) hoạt động giống hệt như với
/// [DemoRepository], chỉ khác là dữ liệu tới từ server và có thể có độ trễ.
class FirebaseRepository extends AppRepository {
  FirebaseRepository({required this.uid, FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final String uid;
  final FirebaseFirestore _db;

  bool _ready = false;
  bool _online = true;
  bool _disposed = false;
  String? _syncError;
  Future<void>? _initializing;
  final _initialData = Completer<void>();
  final Set<String> _pendingInitial = {};

  @override
  String? get syncError => _syncError;

  final List<WorkGroup> _groups = [];
  final List<Profile> _profiles = [];
  final List<Collaborator> _collaborators = [];
  final Map<String, List<WorkStage>> _stages = {};
  final Map<String, List<Milestone>> _milestones = {};
  final Map<String, List<MoneyTransaction>> _transactions = {};
  final Map<String, List<CollaboratorAssignment>> _assignments = {};
  final Map<String, List<Attachment>> _attachments = {};
  final Map<String, List<TaskItem>> _tasks = {};
  final Map<String, List<TimelineEvent>> _timelineEvents = {};

  final List<StreamSubscription> _topLevelSubs = [];
  final Map<String, List<StreamSubscription>> _profileSubs = {};

  @override
  bool get isReady => _ready;

  @override
  bool get isDemoMode => false;

  @override
  bool get isOnline => _online;

  CollectionReference<Map<String, dynamic>> get _userDoc =>
      _db.collection('users');

  DocumentReference<Map<String, dynamic>> get _root => _userDoc.doc(uid);

  CollectionReference<Map<String, dynamic>> get _groupsRef =>
      _root.collection('groups');

  CollectionReference<Map<String, dynamic>> get _profilesRef =>
      _root.collection('profiles');

  CollectionReference<Map<String, dynamic>> get _collaboratorsRef =>
      _root.collection('collaborators');

  DocumentReference<Map<String, dynamic>> _profileDoc(String id) =>
      _profilesRef.doc(id);

  @override
  Future<void> init() => _initializing ??= _startListeners();

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>> _listen(
    CollectionReference<Map<String, dynamic>> ref,
    void Function(QuerySnapshot<Map<String, dynamic>>) onData,
  ) {
    _pendingInitial.add(ref.path);
    return ref.snapshots(includeMetadataChanges: true).listen((snapshot) {
      if (_disposed || _syncError != null) return;
      try {
        onData(snapshot);
        // Do not treat an empty offline cache as an empty server database.
        if (!snapshot.metadata.isFromCache) {
          _pendingInitial.remove(ref.path);
          if (_pendingInitial.isEmpty && !_initialData.isCompleted) {
            _ready = true;
            _initialData.complete();
          }
        }
        notifyListeners();
      } catch (e) {
        _listenerError(e);
      }
    }, onError: _listenerError);
  }

  void _listenerError(Object error) {
    if (_disposed || _syncError != null) return;
    _ready = false;
    _online = false;
    _syncError = firebaseErrorMessage(error);
    if (!_initialData.isCompleted) {
      _initialData.completeError(RepositoryException(_syncError!));
    }
    notifyListeners();
  }

  Future<void> _startListeners() async {
    if (_ready) return;
    try {
      _topLevelSubs.add(
        _listen(_groupsRef, (snap) {
          _groups
            ..clear()
            ..addAll(snap.docs.map((d) => WorkGroup.fromJson(d.data())));
          notifyListeners();
        }),
      );

      _topLevelSubs.add(
        _listen(_collaboratorsRef, (snap) {
          _collaborators
            ..clear()
            ..addAll(snap.docs.map((d) => Collaborator.fromJson(d.data())));
          notifyListeners();
        }),
      );

      _topLevelSubs.add(
        _listen(_profilesRef, (snap) {
          final newIds = snap.docs.map((d) => d.id).toSet();
          final oldIds = _profiles.map((p) => p.id).toSet();

          _profiles
            ..clear()
            ..addAll(snap.docs.map((d) => Profile.fromJson(d.data())));

          for (final removedId in oldIds.difference(newIds)) {
            _detachProfileListeners(removedId);
          }
          for (final addedId in newIds.difference(oldIds)) {
            _attachProfileListeners(addedId);
          }
          notifyListeners();
        }),
      );

      await _initialData.future.timeout(const Duration(seconds: 15));
      notifyListeners();
    } catch (e) {
      _ready = false;
      _syncError = e is RepositoryException
          ? e.message
          : firebaseErrorMessage(e);
      throw RepositoryException(_syncError!);
    }
  }

  void _attachProfileListeners(String profileId) {
    final subs = <StreamSubscription>[];
    final doc = _profileDoc(profileId);

    subs.add(
      _listen(doc.collection('stages'), (snap) {
        _stages[profileId] =
            snap.docs.map((d) => WorkStage.fromJson(d.data())).toList()
              ..sort((a, b) => a.order.compareTo(b.order));
        notifyListeners();
      }),
    );
    subs.add(
      _listen(doc.collection('milestones'), (snap) {
        _milestones[profileId] = snap.docs
            .map((d) => Milestone.fromJson(d.data()))
            .toList();
        notifyListeners();
      }),
    );
    subs.add(
      _listen(doc.collection('transactions'), (snap) {
        _transactions[profileId] =
            snap.docs.map((d) => MoneyTransaction.fromJson(d.data())).toList()
              ..sort((a, b) => b.date.compareTo(a.date));
        notifyListeners();
      }),
    );
    subs.add(
      _listen(doc.collection('collaboratorAssignments'), (snap) {
        _assignments[profileId] = snap.docs
            .map((d) => CollaboratorAssignment.fromJson(d.data()))
            .toList();
        notifyListeners();
      }),
    );
    subs.add(
      _listen(doc.collection('attachments'), (snap) {
        _attachments[profileId] = snap.docs
            .map((d) => Attachment.fromJson(d.data()))
            .toList();
        notifyListeners();
      }),
    );
    subs.add(
      _listen(doc.collection('tasks'), (snap) {
        _tasks[profileId] =
            snap.docs.map((d) => TaskItem.fromJson(d.data())).toList()
              ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
        notifyListeners();
      }),
    );
    subs.add(
      _listen(doc.collection('timelineEvents'), (snap) {
        _timelineEvents[profileId] =
            snap.docs.map((d) => TimelineEvent.fromJson(d.data())).toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        notifyListeners();
      }),
    );

    _profileSubs[profileId] = subs;
  }

  void _detachProfileListeners(String profileId) {
    for (final s in _profileSubs[profileId] ?? const <StreamSubscription>[]) {
      s.cancel();
    }
    _profileSubs.remove(profileId);
    _pendingInitial.removeWhere(
      (path) => path.startsWith('${_profileDoc(profileId).path}/'),
    );
    _stages.remove(profileId);
    _milestones.remove(profileId);
    _transactions.remove(profileId);
    _assignments.remove(profileId);
    _attachments.remove(profileId);
    _tasks.remove(profileId);
    _timelineEvents.remove(profileId);
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _ready = false;
    if (!_initialData.isCompleted && _initializing != null) {
      _initialData.completeError(
        const RepositoryException('Phiên dữ liệu đã kết thúc.'),
      );
    }
    for (final s in _topLevelSubs) {
      s.cancel();
    }
    for (final id in _profileSubs.keys.toList()) {
      _detachProfileListeners(id);
    }
    super.dispose();
  }

  // ---------------------------------------------------------------------
  // Đọc dữ liệu
  // ---------------------------------------------------------------------

  @override
  List<WorkGroup> get groups => List.unmodifiable(_groups);

  @override
  WorkGroup? groupById(String id) {
    for (final g in _groups) {
      if (g.id == id) return g;
    }
    return null;
  }

  @override
  List<Profile> get profiles => List.unmodifiable(_profiles);

  @override
  Profile? profileById(String id) {
    for (final p in _profiles) {
      if (p.id == id) return p;
    }
    return null;
  }

  @override
  List<Profile> profilesByGroup(String groupId) =>
      _profiles.where((p) => p.groupId == groupId).toList();

  @override
  List<Collaborator> get collaborators => List.unmodifiable(_collaborators);

  @override
  Collaborator? collaboratorById(String id) {
    for (final c in _collaborators) {
      if (c.id == id) return c;
    }
    return null;
  }

  @override
  List<WorkStage> stagesOf(String profileId) =>
      List.unmodifiable(_stages[profileId] ?? const []);

  @override
  List<Milestone> milestonesOf(String profileId) =>
      List.unmodifiable(_milestones[profileId] ?? const []);

  @override
  List<MoneyTransaction> transactionsOf(String profileId) =>
      List.unmodifiable(_transactions[profileId] ?? const []);

  @override
  List<CollaboratorAssignment> assignmentsOf(String profileId) =>
      List.unmodifiable(_assignments[profileId] ?? const []);

  @override
  List<CollaboratorAssignment> assignmentsOfCollaborator(
    String collaboratorId,
  ) {
    final result = <CollaboratorAssignment>[];
    for (final list in _assignments.values) {
      result.addAll(list.where((a) => a.collaboratorId == collaboratorId));
    }
    return result;
  }

  @override
  List<Attachment> attachmentsOf(String profileId) =>
      List.unmodifiable(_attachments[profileId] ?? const []);

  @override
  List<TaskItem> tasksOf(String profileId) =>
      List.unmodifiable(_tasks[profileId] ?? const []);

  @override
  List<TimelineEvent> timelineOf(String profileId) =>
      List.unmodifiable(_timelineEvents[profileId] ?? const []);

  @override
  List<TaskItem> get allOpenTasks {
    final result = <TaskItem>[];
    for (final list in _tasks.values) {
      result.addAll(
        list.where(
          (t) =>
              t.status != TaskStatus.completed &&
              t.status != TaskStatus.cancelled,
        ),
      );
    }
    return result;
  }

  @override
  ProfileAggregate aggregateOf(String profileId) {
    final profile = profileById(profileId);
    if (profile == null) {
      throw StateError('Không tìm thấy hồ sơ với id=$profileId');
    }
    return ProfileAggregate(
      profile: profile,
      group: groupById(profile.groupId),
      stages: stagesOf(profileId),
      milestones: milestonesOf(profileId),
      transactions: transactionsOf(profileId),
      assignments: assignmentsOf(profileId),
      attachments: attachmentsOf(profileId),
      tasks: tasksOf(profileId),
      timeline: timelineOf(profileId),
    );
  }

  @override
  List<ProfileAggregate> get allAggregates =>
      _profiles.map((p) => aggregateOf(p.id)).toList();

  // ---------------------------------------------------------------------
  // WorkGroup
  // ---------------------------------------------------------------------

  @override
  Future<WorkGroup> addGroup({
    required String name,
    String description = '',
  }) async {
    final doc = _groupsRef.doc();
    final now = DateTime.now();
    final group = WorkGroup(
      id: doc.id,
      name: name,
      description: description,
      createdAt: now,
      updatedAt: now,
    );
    await doc.set(group.toJson());
    return group;
  }

  @override
  Future<void> updateGroup(WorkGroup group) async {
    final updated = group.copyWith(updatedAt: DateTime.now());
    await _groupsRef.doc(group.id).set(updated.toJson());
  }

  @override
  Future<void> deleteGroup(String id) async {
    final profileIds = _profiles
        .where((p) => p.groupId == id)
        .map((p) => p.id)
        .toList();
    for (final pid in profileIds) {
      await deleteProfile(pid);
    }
    await _groupsRef.doc(id).delete();
  }

  // ---------------------------------------------------------------------
  // Profile
  // ---------------------------------------------------------------------

  @override
  Future<Profile> addProfile(
    Profile profile, {
    bool withDefaultStages = true,
  }) async {
    final doc = profile.id.isEmpty
        ? _profilesRef.doc()
        : _profilesRef.doc(profile.id);
    final now = DateTime.now();
    final newProfile = profile.copyWith(
      id: doc.id,
      createdAt: now,
      updatedAt: now,
    );
    await doc.set(newProfile.toJson());
    await _logEvent(
      doc.id,
      TimelineEventType.profileCreated,
      'Tạo hồ sơ "${newProfile.fullName}"',
    );

    if (withDefaultStages) {
      const names = [
        'Nhận hồ sơ',
        'Chuẩn bị',
        'Làm việc với bên liên quan',
        'Hoàn thiện',
        'Bàn giao',
      ];
      final batch = _db.batch();
      for (var i = 0; i < names.length; i++) {
        final stageDoc = doc.collection('stages').doc();
        final stage = WorkStage(
          id: stageDoc.id,
          profileId: doc.id,
          name: names[i],
          order: i,
          status: i == 0 ? StageStatus.inProgress : StageStatus.pending,
        );
        batch.set(stageDoc, stage.toJson());
      }
      await batch.commit();
    }
    return newProfile;
  }

  @override
  Future<void> updateProfile(Profile profile) async {
    final old = profileById(profile.id);
    final updated = profile.copyWith(updatedAt: DateTime.now());
    await _profileDoc(profile.id).set(updated.toJson());
    if (old != null && old.status != updated.status) {
      await _logEvent(
        updated.id,
        TimelineEventType.statusChanged,
        'Đổi trạng thái: ${old.status.label} → ${updated.status.label}',
      );
      if (updated.status == ProfileStatus.waiting) {
        await _logEvent(
          updated.id,
          TimelineEventType.waitingStarted,
          updated.waitingReason?.isNotEmpty == true
              ? 'Bắt đầu chờ: ${updated.waitingReason}'
              : 'Bắt đầu chờ phản hồi',
        );
      } else if (old.status == ProfileStatus.waiting) {
        await _logEvent(
          updated.id,
          TimelineEventType.waitingResolved,
          'Kết thúc chờ',
        );
      }
    }
    if (old != null && old.deadline != updated.deadline) {
      await _logEvent(
        updated.id,
        TimelineEventType.profileUpdated,
        _describeDeadlineChange(old, updated),
      );
    }
  }

  /// Diễn giải thay đổi hạn hoàn thành để ghi vào Timeline — chỉ gọi khi
  /// `old.deadline != updated.deadline`.
  static String _describeDeadlineChange(Profile old, Profile updated) {
    if (updated.deadline == null) return 'Bỏ hạn hoàn thành';
    if (old.deadline == null) {
      return 'Đặt hạn hoàn thành: ${AppDateUtils.formatDate(updated.deadline)}';
    }
    return 'Đổi hạn hoàn thành: ${AppDateUtils.formatDate(old.deadline)} → '
        '${AppDateUtils.formatDate(updated.deadline)}';
  }

  @override
  Future<void> deleteProfile(String id) async {
    final doc = _profileDoc(id);
    for (final sub in [
      'stages',
      'milestones',
      'transactions',
      'attachments',
      'collaboratorAssignments',
      'tasks',
      'timelineEvents',
    ]) {
      final snap = await doc.collection(sub).get();
      final batch = _db.batch();
      for (final d in snap.docs) {
        batch.delete(d.reference);
      }
      await batch.commit();
    }
    await doc.delete();
  }

  // ---------------------------------------------------------------------
  // WorkStage
  // ---------------------------------------------------------------------

  @override
  Future<WorkStage> addStage(WorkStage stage) async {
    final ref = _profileDoc(stage.profileId).collection('stages');
    final doc = stage.id.isEmpty ? ref.doc() : ref.doc(stage.id);
    final newStage = stage.copyWith(id: doc.id);
    await doc.set(newStage.toJson());
    return newStage;
  }

  @override
  Future<void> updateStage(WorkStage stage) async {
    await _profileDoc(stage.profileId)
        .collection('stages')
        .doc(stage.id)
        .set(stage.toJson());
    await _touchProfile(stage.profileId);
  }

  @override
  Future<void> deleteStage(String id) async {
    for (final entry in _stages.entries) {
      if (entry.value.any((s) => s.id == id)) {
        await _profileDoc(entry.key).collection('stages').doc(id).delete();
        return;
      }
    }
  }

  @override
  Future<void> reorderStages(
    String profileId,
    List<String> orderedStageIds,
  ) async {
    final ref = _profileDoc(profileId).collection('stages');
    final batch = _db.batch();
    for (var i = 0; i < orderedStageIds.length; i++) {
      batch.update(ref.doc(orderedStageIds[i]), {'order': i});
    }
    await batch.commit();
    await _touchProfile(profileId);
  }

  @override
  Future<void> markStageCompleted(String stageId) async {
    final stage = _findStage(stageId);
    if (stage == null) return;
    final now = DateTime.now();
    await updateStage(
      stage.copyWith(
        status: StageStatus.completed,
        completedAt: now,
        startDate: stage.startDate ?? now,
      ),
    );
    await _logEvent(
      stage.profileId,
      TimelineEventType.stageCompleted,
      'Hoàn thành bước "${stage.name}"',
    );
    final siblings = stagesOf(stage.profileId);
    final nextIdx = siblings.indexWhere(
      (s) => s.order > stage.order && s.status == StageStatus.pending,
    );
    if (nextIdx != -1) {
      await updateStage(
        siblings[nextIdx].copyWith(
          status: StageStatus.inProgress,
          startDate: now,
        ),
      );
    }
  }

  @override
  Future<void> setStageInProgress(String stageId) async {
    final stage = _findStage(stageId);
    if (stage == null) return;
    await updateStage(
      stage.copyWith(
        status: StageStatus.inProgress,
        startDate: stage.startDate ?? DateTime.now(),
      ),
    );
  }

  WorkStage? _findStage(String stageId) {
    for (final list in _stages.values) {
      for (final s in list) {
        if (s.id == stageId) return s;
      }
    }
    return null;
  }

  Future<void> _touchProfile(String profileId) async {
    final profile = profileById(profileId);
    if (profile == null) return;
    await _profileDoc(profileId)
        .update({'updatedAt': DateTime.now().toIso8601String()});
  }

  // ---------------------------------------------------------------------
  // Milestone
  // ---------------------------------------------------------------------

  @override
  Future<Milestone> addMilestone(Milestone milestone) async {
    final ref = _profileDoc(milestone.profileId).collection('milestones');
    final doc = milestone.id.isEmpty ? ref.doc() : ref.doc(milestone.id);
    final m = milestone.copyWith(id: doc.id);
    await doc.set(m.toJson());
    return m;
  }

  @override
  Future<void> updateMilestone(Milestone milestone) async {
    await _profileDoc(milestone.profileId)
        .collection('milestones')
        .doc(milestone.id)
        .set(milestone.toJson());
  }

  @override
  Future<void> deleteMilestone(String id) async {
    for (final entry in _milestones.entries) {
      if (entry.value.any((m) => m.id == id)) {
        await _profileDoc(entry.key).collection('milestones').doc(id).delete();
        return;
      }
    }
  }

  // ---------------------------------------------------------------------
  // MoneyTransaction
  // ---------------------------------------------------------------------

  @override
  Future<MoneyTransaction> addTransaction(MoneyTransaction transaction) async {
    final profile = _profileDoc(transaction.profileId);
    final ref = profile.collection('transactions');
    final doc = transaction.id.isEmpty ? ref.doc() : ref.doc(transaction.id);
    final t = transaction.copyWith(id: doc.id, createdAt: DateTime.now());
    final eventDoc = profile.collection('timelineEvents').doc();
    final event = TimelineEvent(
      id: eventDoc.id,
      profileId: t.profileId,
      type: TimelineEventType.transaction,
      message:
          '${t.type.label}: ${t.amount}${t.note.isNotEmpty ? ' — ${t.note}' : ''}',
      createdAt: t.createdAt,
    );
    await _db.runTransaction((tx) async {
      // Stable document IDs across retries: never apply a payment twice.
      final existing = await tx.get(doc);
      if (existing.exists) {
        throw const RepositoryException(
          'Giao dịch này đã tồn tại. Vui lòng tải lại dữ liệu.',
        );
      }
      DocumentReference<Map<String, dynamic>>? assignment;
      if (t.type == TransactionType.collaboratorPayment &&
          t.collaboratorAssignmentId != null) {
        assignment = profile
            .collection('collaboratorAssignments')
            .doc(t.collaboratorAssignmentId);
        final current = await tx.get(assignment);
        if (!current.exists) {
          throw const RepositoryException(
            'Phân công cộng tác viên không còn tồn tại. Vui lòng tải lại dữ liệu.',
          );
        }
      }
      tx.set(doc, t.toJson());
      if (assignment != null) {
        tx.update(assignment, {
          'paidAmount': FieldValue.increment(t.amount),
          'updatedAt': t.createdAt.toIso8601String(),
        });
      }
      tx.set(eventDoc, event.toJson());
      tx.update(profile, {'updatedAt': t.createdAt.toIso8601String()});
    });
    return t;
  }

  @override
  Future<void> deleteTransaction(String id) async {
    for (final entry in _transactions.entries) {
      if (!entry.value.any((t) => t.id == id)) continue;
      final profile = _profileDoc(entry.key);
      final doc = profile.collection('transactions').doc(id);
      await _db.runTransaction((tx) async {
        // Read server state: a second device deleting the same payment is a no-op.
        final existing = await tx.get(doc);
        if (!existing.exists) return;
        final t = MoneyTransaction.fromJson(existing.data()!);
        DocumentReference<Map<String, dynamic>>? assignment;
        num? newPaid;
        if (t.type == TransactionType.collaboratorPayment &&
            t.collaboratorAssignmentId != null) {
          assignment = profile
              .collection('collaboratorAssignments')
              .doc(t.collaboratorAssignmentId);
          final current = await tx.get(assignment);
          if (current.exists) {
            final remaining =
                (current.data()!['paidAmount'] as num? ?? 0) - t.amount;
            newPaid = remaining < 0 ? 0 : remaining;
          }
        }
        tx.delete(doc);
        if (assignment != null && newPaid != null) {
          tx.update(assignment, {
            'paidAmount': newPaid,
            'updatedAt': DateTime.now().toIso8601String(),
          });
        }
      });
      return;
    }
  }
  // ---------------------------------------------------------------------
  // Collaborator & Assignment
  // ---------------------------------------------------------------------

  @override
  Future<Collaborator> addCollaborator({
    required String name,
    String phone = '',
    String note = '',
  }) async {
    final doc = _collaboratorsRef.doc();
    final now = DateTime.now();
    final c = Collaborator(
      id: doc.id,
      name: name,
      phone: phone,
      note: note,
      createdAt: now,
      updatedAt: now,
    );
    await doc.set(c.toJson());
    return c;
  }

  @override
  Future<void> updateCollaborator(Collaborator collaborator) async {
    final updated = collaborator.copyWith(updatedAt: DateTime.now());
    await _collaboratorsRef.doc(collaborator.id).set(updated.toJson());
  }

  @override
  Future<void> deleteCollaborator(String id) async {
    await _collaboratorsRef.doc(id).delete();
  }

  @override
  Future<CollaboratorAssignment> addAssignment(
    CollaboratorAssignment assignment,
  ) async {
    final ref = _profileDoc(assignment.profileId)
        .collection('collaboratorAssignments');
    final doc = assignment.id.isEmpty ? ref.doc() : ref.doc(assignment.id);
    final now = DateTime.now();
    final a = assignment.copyWith(id: doc.id, createdAt: now, updatedAt: now);
    await doc.set(a.toJson());
    return a;
  }

  @override
  Future<void> updateAssignment(CollaboratorAssignment assignment) async {
    final updated = assignment.copyWith(updatedAt: DateTime.now());
    final fields = updated.toJson()..remove('paidAmount');
    await _profileDoc(assignment.profileId)
        .collection('collaboratorAssignments')
        .doc(assignment.id)
        .update(fields);
  }

  @override
  Future<void> deleteAssignment(String id) async {
    for (final entry in _assignments.entries) {
      if (entry.value.any((a) => a.id == id)) {
        await _profileDoc(entry.key)
            .collection('collaboratorAssignments')
            .doc(id)
            .delete();
        return;
      }
    }
  }

  @override
  Future<void> payCommission({
    required String assignmentId,
    required num amount,
    required DateTime date,
    String note = '',
  }) async {
    CollaboratorAssignment? assignment;
    for (final list in _assignments.values) {
      final match = list.where((a) => a.id == assignmentId);
      if (match.isNotEmpty) {
        assignment = match.first;
        break;
      }
    }
    if (assignment == null) return;
    await addTransaction(
      MoneyTransaction(
        id: '',
        profileId: assignment.profileId,
        type: TransactionType.collaboratorPayment,
        amount: amount,
        date: date,
        note: note,
        createdAt: DateTime.now(),
        collaboratorAssignmentId: assignmentId,
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Attachment
  // ---------------------------------------------------------------------

  @override
  Future<Attachment> addAttachment(Attachment attachment) async {
    final ref = _profileDoc(attachment.profileId).collection('attachments');
    final doc = attachment.id.isEmpty ? ref.doc() : ref.doc(attachment.id);
    final a = attachment.copyWith(id: doc.id);
    await doc.set(a.toJson());
    return a;
  }

  @override
  Future<void> renameAttachment(String id, String newFileName) async {
    for (final entry in _attachments.entries) {
      if (entry.value.any((a) => a.id == id)) {
        await _profileDoc(entry.key).collection('attachments').doc(id).update({
          'fileName': newFileName,
          'updatedAt': DateTime.now().toIso8601String(),
        });
        return;
      }
    }
  }

  @override
  Future<void> deleteAttachment(String id) async {
    for (final entry in _attachments.entries) {
      if (entry.value.any((a) => a.id == id)) {
        await _profileDoc(entry.key).collection('attachments').doc(id).delete();
        return;
      }
    }
  }

  // ---------------------------------------------------------------------
  // Task (việc cần làm)
  // ---------------------------------------------------------------------

  @override
  Future<TaskItem> addTask(TaskItem task) async {
    final ref = _profileDoc(task.profileId).collection('tasks');
    final doc = task.id.isEmpty ? ref.doc() : ref.doc(task.id);
    final now = DateTime.now();
    final t = TaskItem(
      id: doc.id,
      profileId: task.profileId,
      title: task.title,
      description: task.description,
      status: task.status,
      priority: task.priority,
      dueDate: task.dueDate,
      waitingReason: task.waitingReason,
      waitingSince: task.waitingSince,
      expectedResponseDate: task.expectedResponseDate,
      completedAt: task.completedAt,
      createdAt: now,
      updatedAt: now,
      note: task.note,
    );
    await doc.set(t.toJson());
    await _logEvent(
      t.profileId,
      TimelineEventType.taskCreated,
      'Tạo việc "${t.title}"',
    );
    await _touchProfile(t.profileId);
    return t;
  }

  @override
  Future<void> updateTask(TaskItem task) async {
    final old = _findTask(task.id);
    final updated = task.copyWith(updatedAt: DateTime.now());
    await _profileDoc(task.profileId)
        .collection('tasks')
        .doc(task.id)
        .set(updated.toJson());
    if (old != null &&
        old.status != updated.status &&
        updated.status == TaskStatus.completed) {
      await _logEvent(
        updated.profileId,
        TimelineEventType.taskCompleted,
        'Hoàn thành việc "${updated.title}"',
      );
    }
    await _touchProfile(updated.profileId);
  }

  @override
  Future<void> deleteTask(String id) async {
    for (final entry in _tasks.entries) {
      if (entry.value.any((t) => t.id == id)) {
        await _profileDoc(entry.key).collection('tasks').doc(id).delete();
        return;
      }
    }
  }

  @override
  Future<void> markTaskCompleted(String id) async {
    final task = _findTask(id);
    if (task == null) return;
    final now = DateTime.now();
    await _profileDoc(task.profileId)
        .collection('tasks')
        .doc(id)
        .set(
          task
              .copyWith(
                status: TaskStatus.completed,
                completedAt: now,
                updatedAt: now,
              )
              .toJson(),
        );
    await _logEvent(
      task.profileId,
      TimelineEventType.taskCompleted,
      'Hoàn thành việc "${task.title}"',
    );
    await _touchProfile(task.profileId);
  }

  TaskItem? _findTask(String taskId) {
    for (final list in _tasks.values) {
      for (final t in list) {
        if (t.id == taskId) return t;
      }
    }
    return null;
  }

  // ---------------------------------------------------------------------
  // Timeline (lịch sử sự kiện của hồ sơ)
  // ---------------------------------------------------------------------

  @override
  Future<void> addTimelineNote(String profileId, String message) async {
    await _logEvent(profileId, TimelineEventType.note, message);
  }

  Future<void> _logEvent(
    String profileId,
    TimelineEventType type,
    String message,
  ) async {
    final ref = _profileDoc(profileId).collection('timelineEvents').doc();
    final event = TimelineEvent(
      id: ref.id,
      profileId: profileId,
      type: type,
      message: message,
      createdAt: DateTime.now(),
    );
    await ref.set(event.toJson());
  }
}
