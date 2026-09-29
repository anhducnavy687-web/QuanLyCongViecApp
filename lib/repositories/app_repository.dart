import 'package:flutter/foundation.dart';

import '../core/constants/app_constants.dart';
import '../models/models.dart';
import '../services/export_snapshot_validator.dart';

class RepositoryException implements Exception {
  const RepositoryException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Interface chung cho tầng dữ liệu của ứng dụng.
///
/// Mọi màn hình UI chỉ được làm việc thông qua [AppRepository] — không bao
/// giờ gọi thẳng Firestore hay dữ liệu Demo. Nhờ vậy sau này có thể chuyển
/// từ [DemoRepository] (bộ nhớ trong) sang FirebaseRepository (Firestore +
/// Storage) mà không cần sửa lại UI, chỉ cần đổi implementation được
/// provide ở gốc app (xem `navigation/app_providers.dart`).
///
/// [AppRepository] là một [ChangeNotifier]: khi dữ liệu thay đổi (do người
/// dùng thao tác hoặc do đồng bộ từ server), repository gọi [notifyListeners]
/// để toàn bộ UI đang lắng nghe tự cập nhật lại — đây là nền tảng để sau
/// này Firestore snapshot listener có thể cập nhật UI theo thời gian thực
/// giống hệt cách Demo Mode hoạt động.
abstract class AppRepository extends ChangeNotifier {
  int _revision = 0;
  int _writesInFlight = 0;
  Object? _restoreLock;

  int get revision => _revision;
  int get writesInFlight => _writesInFlight;
  bool get isRestoreInProgress => _restoreLock != null;

  Object beginRestore() {
    if (_restoreLock != null || _writesInFlight != 0) {
      throw const RepositoryException(
        'Đang có thao tác dữ liệu khác. Vui lòng thử lại sau.',
      );
    }
    final token = Object();
    _restoreLock = token;
    notifyListeners();
    return token;
  }

  void endRestore(Object token) {
    if (identical(_restoreLock, token)) {
      _restoreLock = null;
      notifyListeners();
    }
  }

  @override
  void notifyListeners() {
    _revision++;
    super.notifyListeners();
  }

  @protected
  Future<T> runTrackedWrite<T>(Future<T> Function() action) async {
    if (_restoreLock != null) {
      throw const RepositoryException(
        'Đang khôi phục dữ liệu. Vui lòng chờ hoàn tất.',
      );
    }
    _writesInFlight++;
    try {
      return await action();
    } finally {
      _writesInFlight--;
    }
  }

  Future<ExportSnapshot> createExportSnapshot() async {
    if (_restoreLock != null) {
      throw const RepositoryException(
        'Đang khôi phục dữ liệu. Vui lòng chờ hoàn tất.',
      );
    }
    if (!isReady || syncError != null) {
      throw const RepositoryException(
        'Dữ liệu chưa đồng bộ đầy đủ. Vui lòng thử lại sau.',
      );
    }
    if (_writesInFlight != 0) {
      throw const RepositoryException(
        'Đang lưu dữ liệu. Vui lòng chờ hoàn tất rồi thử lại.',
      );
    }
    final startRevision = _revision;
    final profileCopy = List<Profile>.of(profiles);
    final snapshot = ExportSnapshot(
      exportedAt: DateTime.now(),
      appVersion: AppConstants.appVersion,
      sourceMode: isDemoMode ? 'demo' : 'firebase',
      repositoryRevision: startRevision,
      groups: List<WorkGroup>.of(groups),
      profiles: profileCopy,
      stages: [for (final p in profileCopy) ...stagesOf(p.id)],
      milestones: [for (final p in profileCopy) ...milestonesOf(p.id)],
      tasks: [for (final p in profileCopy) ...tasksOf(p.id)],
      timelineEvents: [for (final p in profileCopy) ...timelineOf(p.id)],
      transactions: [for (final p in profileCopy) ...transactionsOf(p.id)],
      collaborators: List<Collaborator>.of(collaborators),
      collaboratorAssignments: [
        for (final p in profileCopy) ...assignmentsOf(p.id),
      ],
      attachments: [for (final p in profileCopy) ...attachmentsOf(p.id)],
    );
    const ExportSnapshotValidator().validate(snapshot);
    await Future<void>.delayed(Duration.zero);
    if (_revision != startRevision || _writesInFlight != 0) {
      throw const RepositoryException(
        'Dữ liệu vừa thay đổi trong lúc tạo bản xuất. Vui lòng thử lại.',
      );
    }
    return snapshot;
  }

  /// Khởi tạo repository (nạp dữ liệu demo, hoặc đăng ký các Firestore
  /// listener). Phải gọi trước khi dùng các getter bên dưới.
  Future<void> init();

  bool get isReady;

  String? get syncError => null;

  /// true nếu đây là repository chạy ở Demo Mode (không cần đăng nhập).
  bool get isDemoMode;

  /// Trạng thái kết nối mạng gần nhất mà repository biết được.
  bool get isOnline;

  // ---------------------------------------------------------------------
  // Đọc dữ liệu (đồng bộ, từ cache trong bộ nhớ — luôn sẵn sàng kể cả khi
  // offline).
  // ---------------------------------------------------------------------

  List<WorkGroup> get groups;
  WorkGroup? groupById(String id);

  List<Profile> get profiles;
  Profile? profileById(String id);
  List<Profile> profilesByGroup(String groupId);

  List<Collaborator> get collaborators;
  Collaborator? collaboratorById(String id);

  List<WorkStage> stagesOf(String profileId);
  List<Milestone> milestonesOf(String profileId);
  List<MoneyTransaction> transactionsOf(String profileId);
  List<CollaboratorAssignment> assignmentsOf(String profileId);
  List<CollaboratorAssignment> assignmentsOfCollaborator(String collaboratorId);
  List<Attachment> attachmentsOf(String profileId);
  List<TaskItem> tasksOf(String profileId);
  List<TimelineEvent> timelineOf(String profileId);

  /// Toàn bộ task chưa hoàn thành/hủy trên mọi hồ sơ — dùng cho Dashboard
  /// (mục "Việc hôm nay") mà không cần duyệt qua allAggregates.
  List<TaskItem> get allOpenTasks;

  ProfileAggregate aggregateOf(String profileId);
  List<ProfileAggregate> get allAggregates;

  // ---------------------------------------------------------------------
  // WorkGroup
  // ---------------------------------------------------------------------
  Future<WorkGroup> addGroup({required String name, String description = ''}) =>
      runTrackedWrite(() => addGroupImpl(name: name, description: description));
  @protected
  Future<WorkGroup> addGroupImpl({required String name, String description});
  Future<void> updateGroup(WorkGroup group) =>
      runTrackedWrite(() => updateGroupImpl(group));
  @protected
  Future<void> updateGroupImpl(WorkGroup group);
  Future<void> deleteGroup(String id) =>
      runTrackedWrite(() => deleteGroupImpl(id));
  @protected
  Future<void> deleteGroupImpl(String id);

  // ---------------------------------------------------------------------
  // Profile
  // ---------------------------------------------------------------------
  Future<Profile> addProfile(
    Profile profile, {
    bool withDefaultStages = true,
  }) => runTrackedWrite(
    () => addProfileImpl(profile, withDefaultStages: withDefaultStages),
  );
  @protected
  Future<Profile> addProfileImpl(
    Profile profile, {
    bool withDefaultStages = true,
  });
  Future<void> updateProfile(Profile profile) =>
      runTrackedWrite(() => updateProfileImpl(profile));
  @protected
  Future<void> updateProfileImpl(Profile profile);
  Future<void> deleteProfile(String id) =>
      runTrackedWrite(() => deleteProfileImpl(id));
  @protected
  Future<void> deleteProfileImpl(String id);

  // ---------------------------------------------------------------------
  // WorkStage
  // ---------------------------------------------------------------------
  Future<WorkStage> addStage(WorkStage stage) =>
      runTrackedWrite(() => addStageImpl(stage));
  @protected
  Future<WorkStage> addStageImpl(WorkStage stage);
  Future<void> updateStage(WorkStage stage) =>
      runTrackedWrite(() => updateStageImpl(stage));
  @protected
  Future<void> updateStageImpl(WorkStage stage);
  Future<void> deleteStage(String id) =>
      runTrackedWrite(() => deleteStageImpl(id));
  @protected
  Future<void> deleteStageImpl(String id);
  Future<void> reorderStages(String profileId, List<String> orderedStageIds) =>
      runTrackedWrite(() => reorderStagesImpl(profileId, orderedStageIds));
  @protected
  Future<void> reorderStagesImpl(
    String profileId,
    List<String> orderedStageIds,
  );
  Future<void> markStageCompleted(String stageId) =>
      runTrackedWrite(() => markStageCompletedImpl(stageId));
  @protected
  Future<void> markStageCompletedImpl(String stageId);
  Future<void> setStageInProgress(String stageId) =>
      runTrackedWrite(() => setStageInProgressImpl(stageId));
  @protected
  Future<void> setStageInProgressImpl(String stageId);

  // ---------------------------------------------------------------------
  // Milestone
  // ---------------------------------------------------------------------
  Future<Milestone> addMilestone(Milestone milestone) =>
      runTrackedWrite(() => addMilestoneImpl(milestone));
  @protected
  Future<Milestone> addMilestoneImpl(Milestone milestone);
  Future<void> updateMilestone(Milestone milestone) =>
      runTrackedWrite(() => updateMilestoneImpl(milestone));
  @protected
  Future<void> updateMilestoneImpl(Milestone milestone);
  Future<void> deleteMilestone(String id) =>
      runTrackedWrite(() => deleteMilestoneImpl(id));
  @protected
  Future<void> deleteMilestoneImpl(String id);

  // ---------------------------------------------------------------------
  // MoneyTransaction
  // ---------------------------------------------------------------------
  Future<MoneyTransaction> addTransaction(MoneyTransaction transaction) =>
      runTrackedWrite(() => addTransactionImpl(transaction));
  @protected
  Future<MoneyTransaction> addTransactionImpl(MoneyTransaction transaction);
  Future<void> deleteTransaction(String id) =>
      runTrackedWrite(() => deleteTransactionImpl(id));
  @protected
  Future<void> deleteTransactionImpl(String id);

  // ---------------------------------------------------------------------
  // Collaborator & CollaboratorAssignment
  // ---------------------------------------------------------------------
  Future<Collaborator> addCollaborator({
    required String name,
    String phone = '',
    String note = '',
  }) => runTrackedWrite(
    () => addCollaboratorImpl(name: name, phone: phone, note: note),
  );
  @protected
  Future<Collaborator> addCollaboratorImpl({
    required String name,
    String phone,
    String note,
  });
  Future<void> updateCollaborator(Collaborator collaborator) =>
      runTrackedWrite(() => updateCollaboratorImpl(collaborator));
  @protected
  Future<void> updateCollaboratorImpl(Collaborator collaborator);
  Future<void> deleteCollaborator(String id) =>
      runTrackedWrite(() => deleteCollaboratorImpl(id));
  @protected
  Future<void> deleteCollaboratorImpl(String id);

  Future<CollaboratorAssignment> addAssignment(
    CollaboratorAssignment assignment,
  ) => runTrackedWrite(() => addAssignmentImpl(assignment));
  @protected
  Future<CollaboratorAssignment> addAssignmentImpl(
    CollaboratorAssignment assignment,
  );
  Future<void> updateAssignment(CollaboratorAssignment assignment) =>
      runTrackedWrite(() => updateAssignmentImpl(assignment));
  @protected
  Future<void> updateAssignmentImpl(CollaboratorAssignment assignment);
  Future<void> deleteAssignment(String id) =>
      runTrackedWrite(() => deleteAssignmentImpl(id));
  @protected
  Future<void> deleteAssignmentImpl(String id);

  /// Trả hoa hồng cho một assignment: tạo transaction COLLABORATOR_PAYMENT
  /// và cập nhật cache paidAmount tương ứng.
  Future<void> payCommission({
    required String assignmentId,
    required num amount,
    required DateTime date,
    String note = '',
  }) => runTrackedWrite(
    () => payCommissionImpl(
      assignmentId: assignmentId,
      amount: amount,
      date: date,
      note: note,
    ),
  );
  @protected
  Future<void> payCommissionImpl({
    required String assignmentId,
    required num amount,
    required DateTime date,
    String note,
  });

  // ---------------------------------------------------------------------
  // Attachment
  // ---------------------------------------------------------------------
  Future<Attachment> addAttachment(Attachment attachment) =>
      runTrackedWrite(() => addAttachmentImpl(attachment));
  @protected
  Future<Attachment> addAttachmentImpl(Attachment attachment);
  Future<void> renameAttachment(String id, String newFileName) =>
      runTrackedWrite(() => renameAttachmentImpl(id, newFileName));
  @protected
  Future<void> renameAttachmentImpl(String id, String newFileName);
  Future<void> deleteAttachment(String id) =>
      runTrackedWrite(() => deleteAttachmentImpl(id));
  @protected
  Future<void> deleteAttachmentImpl(String id);

  // ---------------------------------------------------------------------
  // Task (việc cần làm)
  // ---------------------------------------------------------------------
  Future<TaskItem> addTask(TaskItem task) =>
      runTrackedWrite(() => addTaskImpl(task));
  @protected
  Future<TaskItem> addTaskImpl(TaskItem task);
  Future<void> updateTask(TaskItem task) =>
      runTrackedWrite(() => updateTaskImpl(task));
  @protected
  Future<void> updateTaskImpl(TaskItem task);
  Future<void> deleteTask(String id) =>
      runTrackedWrite(() => deleteTaskImpl(id));
  @protected
  Future<void> deleteTaskImpl(String id);
  Future<void> markTaskCompleted(String id) =>
      runTrackedWrite(() => markTaskCompletedImpl(id));
  @protected
  Future<void> markTaskCompletedImpl(String id);

  // ---------------------------------------------------------------------
  // Timeline (lịch sử sự kiện của hồ sơ)
  // ---------------------------------------------------------------------
  Future<void> addTimelineNote(String profileId, String message) =>
      runTrackedWrite(() => addTimelineNoteImpl(profileId, message));
  @protected
  Future<void> addTimelineNoteImpl(String profileId, String message);
}
