import 'package:flutter/foundation.dart';

import '../models/models.dart';

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
  Future<WorkGroup> addGroup({required String name, String description});
  Future<void> updateGroup(WorkGroup group);
  Future<void> deleteGroup(String id);

  // ---------------------------------------------------------------------
  // Profile
  // ---------------------------------------------------------------------
  Future<Profile> addProfile(Profile profile, {bool withDefaultStages = true});
  Future<void> updateProfile(Profile profile);
  Future<void> deleteProfile(String id);

  // ---------------------------------------------------------------------
  // WorkStage
  // ---------------------------------------------------------------------
  Future<WorkStage> addStage(WorkStage stage);
  Future<void> updateStage(WorkStage stage);
  Future<void> deleteStage(String id);
  Future<void> reorderStages(String profileId, List<String> orderedStageIds);
  Future<void> markStageCompleted(String stageId);
  Future<void> setStageInProgress(String stageId);

  // ---------------------------------------------------------------------
  // Milestone
  // ---------------------------------------------------------------------
  Future<Milestone> addMilestone(Milestone milestone);
  Future<void> updateMilestone(Milestone milestone);
  Future<void> deleteMilestone(String id);

  // ---------------------------------------------------------------------
  // MoneyTransaction
  // ---------------------------------------------------------------------
  Future<MoneyTransaction> addTransaction(MoneyTransaction transaction);
  Future<void> deleteTransaction(String id);

  // ---------------------------------------------------------------------
  // Collaborator & CollaboratorAssignment
  // ---------------------------------------------------------------------
  Future<Collaborator> addCollaborator({
    required String name,
    String phone,
    String note,
  });
  Future<void> updateCollaborator(Collaborator collaborator);
  Future<void> deleteCollaborator(String id);

  Future<CollaboratorAssignment> addAssignment(
    CollaboratorAssignment assignment,
  );
  Future<void> updateAssignment(CollaboratorAssignment assignment);
  Future<void> deleteAssignment(String id);

  /// Trả hoa hồng cho một assignment: tạo transaction COLLABORATOR_PAYMENT
  /// và cập nhật cache paidAmount tương ứng.
  Future<void> payCommission({
    required String assignmentId,
    required num amount,
    required DateTime date,
    String note,
  });

  // ---------------------------------------------------------------------
  // Attachment
  // ---------------------------------------------------------------------
  Future<Attachment> addAttachment(Attachment attachment);
  Future<void> renameAttachment(String id, String newFileName);
  Future<void> deleteAttachment(String id);

  // ---------------------------------------------------------------------
  // Task (việc cần làm)
  // ---------------------------------------------------------------------
  Future<TaskItem> addTask(TaskItem task);
  Future<void> updateTask(TaskItem task);
  Future<void> deleteTask(String id);
  Future<void> markTaskCompleted(String id);

  // ---------------------------------------------------------------------
  // Timeline (lịch sử sự kiện của hồ sơ)
  // ---------------------------------------------------------------------
  Future<void> addTimelineNote(String profileId, String message);
}
