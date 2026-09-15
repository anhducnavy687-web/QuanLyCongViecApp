import 'package:uuid/uuid.dart';

import '../models/models.dart';
import 'app_repository.dart';
import 'demo_seed_data.dart';

/// Repository chạy hoàn toàn trong bộ nhớ (không cần Firebase, không cần
/// mạng). Đây là DEMO MODE bắt buộc của ứng dụng — cho phép mở app và dùng
/// ngay dù chưa cấu hình Firebase.
///
/// Toàn bộ CRUD thao tác trên các List trong bộ nhớ rồi gọi [notifyListeners]
/// để UI cập nhật ngay lập tức, mô phỏng đúng hành vi mà FirebaseRepository
/// sẽ có (Firestore snapshot -> cập nhật cache -> notifyListeners).
class DemoRepository extends AppRepository {
  final _uuid = const Uuid();
  bool _ready = false;
  bool _online = true;

  final List<WorkGroup> _groups = [];
  final List<Profile> _profiles = [];
  final List<WorkStage> _stages = [];
  final List<Milestone> _milestones = [];
  final List<MoneyTransaction> _transactions = [];
  final List<Collaborator> _collaborators = [];
  final List<CollaboratorAssignment> _assignments = [];
  final List<Attachment> _attachments = [];
  final List<TaskItem> _tasks = [];
  final List<TimelineEvent> _timelineEvents = [];

  @override
  bool get isReady => _ready;

  @override
  bool get isDemoMode => true;

  @override
  bool get isOnline => _online;

  /// Cho phép Settings bật/tắt để xem thử giao diện Offline.
  void setSimulatedOnline(bool value) {
    _online = value;
    notifyListeners();
  }

  @override
  Future<void> init() async {
    if (_ready) return;
    final seed = buildDemoSeed();
    _groups.addAll(seed.groups);
    _profiles.addAll(seed.profiles);
    _stages.addAll(seed.stages);
    _milestones.addAll(seed.milestones);
    _transactions.addAll(seed.transactions);
    _collaborators.addAll(seed.collaborators);
    _assignments.addAll(seed.assignments);
    _attachments.addAll(seed.attachments);
    _tasks.addAll(seed.tasks);
    _timelineEvents.addAll(seed.timelineEvents);
    _ready = true;
    notifyListeners();
  }

  DateTime get _now => DateTime.now();

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
      _stages.where((s) => s.profileId == profileId).toList()
        ..sort((a, b) => a.order.compareTo(b.order));

  @override
  List<Milestone> milestonesOf(String profileId) =>
      _milestones.where((m) => m.profileId == profileId).toList()
        ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

  @override
  List<MoneyTransaction> transactionsOf(String profileId) =>
      _transactions.where((t) => t.profileId == profileId).toList()
        ..sort((a, b) => b.date.compareTo(a.date));

  @override
  List<CollaboratorAssignment> assignmentsOf(String profileId) =>
      _assignments.where((a) => a.profileId == profileId).toList();

  @override
  List<CollaboratorAssignment> assignmentsOfCollaborator(String collaboratorId) =>
      _assignments.where((a) => a.collaboratorId == collaboratorId).toList();

  @override
  List<Attachment> attachmentsOf(String profileId) =>
      _attachments.where((a) => a.profileId == profileId).toList();

  @override
  List<TaskItem> tasksOf(String profileId) =>
      _tasks.where((t) => t.profileId == profileId).toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  @override
  List<TimelineEvent> timelineOf(String profileId) =>
      _timelineEvents.where((e) => e.profileId == profileId).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  @override
  List<TaskItem> get allOpenTasks => _tasks
      .where((t) =>
          t.status != TaskStatus.completed && t.status != TaskStatus.cancelled)
      .toList();

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
  Future<WorkGroup> addGroup({required String name, String description = ''}) async {
    final group = WorkGroup(
      id: _uuid.v4(),
      name: name,
      description: description,
      createdAt: _now,
      updatedAt: _now,
    );
    _groups.add(group);
    notifyListeners();
    return group;
  }

  @override
  Future<void> updateGroup(WorkGroup group) async {
    final idx = _groups.indexWhere((g) => g.id == group.id);
    if (idx == -1) return;
    _groups[idx] = group.copyWith(updatedAt: _now);
    notifyListeners();
  }

  @override
  Future<void> deleteGroup(String id) async {
    _groups.removeWhere((g) => g.id == id);
    final profileIds = _profiles.where((p) => p.groupId == id).map((p) => p.id).toList();
    for (final pid in profileIds) {
      await deleteProfile(pid);
    }
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // Profile
  // ---------------------------------------------------------------------

  @override
  Future<Profile> addProfile(Profile profile, {bool withDefaultStages = true}) async {
    final id = profile.id.isEmpty ? _uuid.v4() : profile.id;
    final newProfile = profile.copyWith(
      id: id,
      createdAt: _now,
      updatedAt: _now,
    );
    _profiles.add(newProfile);
    if (withDefaultStages) {
      final names = _defaultStageNames;
      for (var i = 0; i < names.length; i++) {
        _stages.add(WorkStage(
          id: _uuid.v4(),
          profileId: id,
          name: names[i],
          order: i,
          status: i == 0 ? StageStatus.inProgress : StageStatus.pending,
        ));
      }
    }
    _logEvent(id, TimelineEventType.profileCreated, 'Tạo hồ sơ "${newProfile.fullName}"');
    notifyListeners();
    return newProfile;
  }

  static const _defaultStageNames = [
    'Nhận hồ sơ',
    'Chuẩn bị',
    'Làm việc với bên liên quan',
    'Hoàn thiện',
    'Bàn giao',
  ];

  @override
  Future<void> updateProfile(Profile profile) async {
    final idx = _profiles.indexWhere((p) => p.id == profile.id);
    if (idx == -1) return;
    final old = _profiles[idx];
    final updated = profile.copyWith(updatedAt: _now);
    _profiles[idx] = updated;
    if (old.status != updated.status) {
      _logEvent(
        updated.id,
        TimelineEventType.statusChanged,
        'Đổi trạng thái: ${old.status.label} → ${updated.status.label}',
      );
      if (updated.status == ProfileStatus.waiting) {
        _logEvent(
          updated.id,
          TimelineEventType.waitingStarted,
          updated.waitingReason?.isNotEmpty == true
              ? 'Bắt đầu chờ: ${updated.waitingReason}'
              : 'Bắt đầu chờ phản hồi',
        );
      } else if (old.status == ProfileStatus.waiting) {
        _logEvent(updated.id, TimelineEventType.waitingResolved, 'Kết thúc chờ');
      }
    }
    notifyListeners();
  }

  @override
  Future<void> deleteProfile(String id) async {
    _profiles.removeWhere((p) => p.id == id);
    _stages.removeWhere((s) => s.profileId == id);
    _milestones.removeWhere((m) => m.profileId == id);
    _transactions.removeWhere((t) => t.profileId == id);
    _assignments.removeWhere((a) => a.profileId == id);
    _attachments.removeWhere((a) => a.profileId == id);
    _tasks.removeWhere((t) => t.profileId == id);
    _timelineEvents.removeWhere((e) => e.profileId == id);
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // WorkStage
  // ---------------------------------------------------------------------

  @override
  Future<WorkStage> addStage(WorkStage stage) async {
    final newStage = stage.id.isEmpty ? stage.copyWith(id: _uuid.v4()) : stage;
    _stages.add(newStage);
    notifyListeners();
    return newStage;
  }

  @override
  Future<void> updateStage(WorkStage stage) async {
    final idx = _stages.indexWhere((s) => s.id == stage.id);
    if (idx == -1) return;
    _stages[idx] = stage;
    _touchProfile(stage.profileId);
  }

  @override
  Future<void> deleteStage(String id) async {
    _stages.removeWhere((s) => s.id == id);
    notifyListeners();
  }

  @override
  Future<void> reorderStages(String profileId, List<String> orderedStageIds) async {
    for (var i = 0; i < orderedStageIds.length; i++) {
      final idx = _stages.indexWhere((s) => s.id == orderedStageIds[i]);
      if (idx != -1) {
        _stages[idx] = _stages[idx].copyWith(order: i);
      }
    }
    _touchProfile(profileId);
  }

  @override
  Future<void> markStageCompleted(String stageId) async {
    final idx = _stages.indexWhere((s) => s.id == stageId);
    if (idx == -1) return;
    final stage = _stages[idx];
    _stages[idx] = stage.copyWith(
      status: StageStatus.completed,
      completedAt: _now,
      startDate: stage.startDate ?? _now,
    );
    // Tự động chuyển bước tiếp theo (nếu có) sang "đang thực hiện".
    final siblings = stagesOf(stage.profileId);
    final nextPendingIdx = siblings.indexWhere(
      (s) => s.order > stage.order && s.status == StageStatus.pending,
    );
    if (nextPendingIdx != -1) {
      final next = siblings[nextPendingIdx];
      final gIdx = _stages.indexWhere((s) => s.id == next.id);
      _stages[gIdx] = next.copyWith(status: StageStatus.inProgress, startDate: _now);
    }
    _logEvent(
      stage.profileId,
      TimelineEventType.stageCompleted,
      'Hoàn thành bước "${stage.name}"',
    );
    _touchProfile(stage.profileId);
  }

  @override
  Future<void> setStageInProgress(String stageId) async {
    final idx = _stages.indexWhere((s) => s.id == stageId);
    if (idx == -1) return;
    final stage = _stages[idx];
    _stages[idx] = stage.copyWith(
      status: StageStatus.inProgress,
      startDate: stage.startDate ?? _now,
    );
    _touchProfile(stage.profileId);
  }

  void _touchProfile(String profileId) {
    final idx = _profiles.indexWhere((p) => p.id == profileId);
    if (idx != -1) {
      _profiles[idx] = _profiles[idx].copyWith(updatedAt: _now);
    }
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // Milestone
  // ---------------------------------------------------------------------

  @override
  Future<Milestone> addMilestone(Milestone milestone) async {
    final m = milestone.id.isEmpty ? milestone.copyWith(id: _uuid.v4()) : milestone;
    _milestones.add(m);
    notifyListeners();
    return m;
  }

  @override
  Future<void> updateMilestone(Milestone milestone) async {
    final idx = _milestones.indexWhere((m) => m.id == milestone.id);
    if (idx == -1) return;
    _milestones[idx] = milestone;
    notifyListeners();
  }

  @override
  Future<void> deleteMilestone(String id) async {
    _milestones.removeWhere((m) => m.id == id);
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // MoneyTransaction
  // ---------------------------------------------------------------------

  @override
  Future<MoneyTransaction> addTransaction(MoneyTransaction transaction) async {
    final t = transaction.id.isEmpty
        ? transaction.copyWith(id: _uuid.v4(), createdAt: _now)
        : transaction;
    _transactions.add(t);

    // Nếu là trả hoa hồng, cập nhật cache paidAmount trên assignment.
    if (t.type == TransactionType.collaboratorPayment &&
        t.collaboratorAssignmentId != null) {
      final idx = _assignments.indexWhere((a) => a.id == t.collaboratorAssignmentId);
      if (idx != -1) {
        final current = _assignments[idx];
        _assignments[idx] = current.copyWith(
          paidAmount: current.paidAmount + t.amount,
          updatedAt: _now,
        );
      }
    }
    _logEvent(
      t.profileId,
      TimelineEventType.transaction,
      '${t.type.label}: ${t.amount}${t.note.isNotEmpty ? ' — ${t.note}' : ''}',
    );
    _touchProfile(t.profileId);
    return t;
  }

  @override
  Future<void> deleteTransaction(String id) async {
    final tx = _transactions.where((t) => t.id == id).toList();
    if (tx.isEmpty) return;
    final t = tx.first;
    _transactions.removeWhere((tr) => tr.id == id);
    if (t.type == TransactionType.collaboratorPayment &&
        t.collaboratorAssignmentId != null) {
      final idx = _assignments.indexWhere((a) => a.id == t.collaboratorAssignmentId);
      if (idx != -1) {
        final current = _assignments[idx];
        final newPaid = current.paidAmount - t.amount;
        _assignments[idx] = current.copyWith(
          paidAmount: newPaid < 0 ? 0 : newPaid,
          updatedAt: _now,
        );
      }
    }
    _touchProfile(t.profileId);
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
    final c = Collaborator(
      id: _uuid.v4(),
      name: name,
      phone: phone,
      note: note,
      createdAt: _now,
      updatedAt: _now,
    );
    _collaborators.add(c);
    notifyListeners();
    return c;
  }

  @override
  Future<void> updateCollaborator(Collaborator collaborator) async {
    final idx = _collaborators.indexWhere((c) => c.id == collaborator.id);
    if (idx == -1) return;
    _collaborators[idx] = collaborator.copyWith(updatedAt: _now);
    notifyListeners();
  }

  @override
  Future<void> deleteCollaborator(String id) async {
    _collaborators.removeWhere((c) => c.id == id);
    _assignments.removeWhere((a) => a.collaboratorId == id);
    notifyListeners();
  }

  @override
  Future<CollaboratorAssignment> addAssignment(CollaboratorAssignment assignment) async {
    final a = assignment.id.isEmpty
        ? assignment.copyWith(id: _uuid.v4(), createdAt: _now, updatedAt: _now)
        : assignment;
    _assignments.add(a);
    notifyListeners();
    return a;
  }

  @override
  Future<void> updateAssignment(CollaboratorAssignment assignment) async {
    final idx = _assignments.indexWhere((a) => a.id == assignment.id);
    if (idx == -1) return;
    _assignments[idx] = assignment.copyWith(updatedAt: _now);
    notifyListeners();
  }

  @override
  Future<void> deleteAssignment(String id) async {
    _assignments.removeWhere((a) => a.id == id);
    _transactions.removeWhere((t) => t.collaboratorAssignmentId == id);
    notifyListeners();
  }

  @override
  Future<void> payCommission({
    required String assignmentId,
    required num amount,
    required DateTime date,
    String note = '',
  }) async {
    final idx = _assignments.indexWhere((a) => a.id == assignmentId);
    if (idx == -1) return;
    final assignment = _assignments[idx];
    await addTransaction(MoneyTransaction(
      id: '',
      profileId: assignment.profileId,
      type: TransactionType.collaboratorPayment,
      amount: amount,
      date: date,
      note: note,
      createdAt: _now,
      collaboratorAssignmentId: assignmentId,
    ));
  }

  // ---------------------------------------------------------------------
  // Attachment
  // ---------------------------------------------------------------------

  @override
  Future<Attachment> addAttachment(Attachment attachment) async {
    final a = attachment.id.isEmpty ? attachment.copyWith(id: _uuid.v4()) : attachment;
    _attachments.add(a);
    notifyListeners();
    return a;
  }

  @override
  Future<void> renameAttachment(String id, String newFileName) async {
    final idx = _attachments.indexWhere((a) => a.id == id);
    if (idx == -1) return;
    _attachments[idx] = _attachments[idx].copyWith(
      fileName: newFileName,
      updatedAt: _now,
    );
    notifyListeners();
  }

  @override
  Future<void> deleteAttachment(String id) async {
    _attachments.removeWhere((a) => a.id == id);
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // Task
  // ---------------------------------------------------------------------

  @override
  Future<TaskItem> addTask(TaskItem task) async {
    final t = task.id.isEmpty
        ? TaskItem(
            id: _uuid.v4(),
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
            createdAt: _now,
            updatedAt: _now,
            note: task.note,
          )
        : task;
    _tasks.add(t);
    _logEvent(t.profileId, TimelineEventType.taskCreated, 'Tạo việc "${t.title}"');
    _touchProfile(t.profileId);
    return t;
  }

  @override
  Future<void> updateTask(TaskItem task) async {
    final idx = _tasks.indexWhere((t) => t.id == task.id);
    if (idx == -1) return;
    final old = _tasks[idx];
    final updated = task.copyWith(updatedAt: _now);
    _tasks[idx] = updated;
    if (old.status != updated.status &&
        updated.status == TaskStatus.completed) {
      _logEvent(
        updated.profileId,
        TimelineEventType.taskCompleted,
        'Hoàn thành việc "${updated.title}"',
      );
    }
    _touchProfile(updated.profileId);
  }

  @override
  Future<void> deleteTask(String id) async {
    _tasks.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  @override
  Future<void> markTaskCompleted(String id) async {
    final idx = _tasks.indexWhere((t) => t.id == id);
    if (idx == -1) return;
    final task = _tasks[idx];
    _tasks[idx] = task.copyWith(
      status: TaskStatus.completed,
      completedAt: _now,
      updatedAt: _now,
    );
    _logEvent(
      task.profileId,
      TimelineEventType.taskCompleted,
      'Hoàn thành việc "${task.title}"',
    );
    _touchProfile(task.profileId);
  }

  // ---------------------------------------------------------------------
  // Timeline
  // ---------------------------------------------------------------------

  @override
  Future<void> addTimelineNote(String profileId, String message) async {
    _logEvent(profileId, TimelineEventType.note, message);
    notifyListeners();
  }

  void _logEvent(String profileId, TimelineEventType type, String message) {
    _timelineEvents.add(TimelineEvent(
      id: _uuid.v4(),
      profileId: profileId,
      type: type,
      message: message,
      createdAt: _now,
    ));
  }
}
