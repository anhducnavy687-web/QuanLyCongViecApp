import '../core/constants/app_constants.dart';
import '../core/utils/app_date_utils.dart';
import 'attachment.dart';
import 'collaborator_assignment.dart';
import 'milestone.dart';
import 'money_transaction.dart';
import 'profile.dart';
import 'task_item.dart';
import 'timeline_event.dart';
import 'work_group.dart';
import 'work_stage.dart';

/// Phân loại ưu tiên của hồ sơ trên Dashboard, theo đúng thứ tự spec:
/// Quá hạn > Hôm nay > Sắp đến hạn > Trì trệ/Không có deadline > Bình thường.
enum DeadlineCategory {
  overdue,
  dueToday,
  upcoming,
  stalled,
  normal,
  completed,
}

extension DeadlineCategoryX on DeadlineCategory {
  int get priority {
    switch (this) {
      case DeadlineCategory.overdue:
        return 0;
      case DeadlineCategory.dueToday:
        return 1;
      case DeadlineCategory.upcoming:
        return 2;
      case DeadlineCategory.stalled:
        return 3;
      case DeadlineCategory.normal:
        return 4;
      case DeadlineCategory.completed:
        return 5;
    }
  }

  String get label {
    switch (this) {
      case DeadlineCategory.overdue:
        return 'Quá hạn';
      case DeadlineCategory.dueToday:
        return 'Hôm nay';
      case DeadlineCategory.upcoming:
        return 'Sắp đến hạn';
      case DeadlineCategory.stalled:
        return 'Trì trệ / Không có deadline';
      case DeadlineCategory.normal:
        return 'Đang xử lý bình thường';
      case DeadlineCategory.completed:
        return 'Hoàn thành';
    }
  }
}

/// Tổng hợp tài chính của một hồ sơ, tính TỪ danh sách transaction (không
/// dùng số lưu sẵn), theo đúng yêu cầu "các số tổng phải được tính từ
/// transaction khi phù hợp".
class ProfileFinance {
  final num totalAmount;
  final num received;
  final num expense;
  final num commissionTotal;
  final num commissionPaid;

  const ProfileFinance({
    required this.totalAmount,
    required this.received,
    required this.expense,
    required this.commissionTotal,
    required this.commissionPaid,
  });

  num get remainingToReceive {
    final r = totalAmount - received;
    return r < 0 ? 0 : r;
  }

  num get commissionRemaining {
    final r = commissionTotal - commissionPaid;
    return r < 0 ? 0 : r;
  }
}

/// Gói dữ liệu đầy đủ của một hồ sơ: hồ sơ gốc + toàn bộ dữ liệu liên quan.
/// Đây là "view model" dùng chung cho Dashboard/Detail để tránh mỗi màn hình
/// tự tính toán lại business logic.
class ProfileAggregate {
  final Profile profile;
  final WorkGroup? group;
  final List<WorkStage> stages;
  final List<Milestone> milestones;
  final List<MoneyTransaction> transactions;
  final List<CollaboratorAssignment> assignments;
  final List<Attachment> attachments;
  final List<TaskItem> tasks;
  final List<TimelineEvent> timeline;

  ProfileAggregate({
    required this.profile,
    this.group,
    List<WorkStage>? stages,
    List<Milestone>? milestones,
    List<MoneyTransaction>? transactions,
    List<CollaboratorAssignment>? assignments,
    List<Attachment>? attachments,
    List<TaskItem>? tasks,
    List<TimelineEvent>? timeline,
  })  : stages = List.unmodifiable(
          [...(stages ?? const [])]..sort((a, b) => a.order.compareTo(b.order)),
        ),
        milestones = List.unmodifiable(milestones ?? const []),
        transactions = List.unmodifiable(transactions ?? const []),
        assignments = List.unmodifiable(assignments ?? const []),
        attachments = List.unmodifiable(attachments ?? const []),
        tasks = List.unmodifiable(tasks ?? const []),
        timeline = List.unmodifiable(
          [...(timeline ?? const [])]
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
        );

  ProfileFinance get finance {
    num received = 0;
    num expense = 0;
    num commissionPaid = 0;
    for (final t in transactions) {
      switch (t.type) {
        case TransactionType.received:
          received += t.amount;
          break;
        case TransactionType.expense:
          expense += t.amount;
          break;
        case TransactionType.collaboratorPayment:
          commissionPaid += t.amount;
          break;
      }
    }
    final commissionTotal =
        assignments.fold<num>(0, (sum, a) => sum + a.commissionAmount);
    return ProfileFinance(
      totalAmount: profile.totalAmount,
      received: received,
      expense: expense,
      commissionTotal: commissionTotal,
      commissionPaid: commissionPaid,
    );
  }

  /// Bước đang thực hiện: bước đầu tiên có trạng thái inProgress, nếu không
  /// có thì là bước pending gần nhất (bước tiếp theo cần làm).
  WorkStage? get currentStage {
    for (final s in stages) {
      if (s.status == StageStatus.inProgress) return s;
    }
    for (final s in stages) {
      if (s.status == StageStatus.pending) return s;
    }
    return null;
  }

  WorkStage? get nextStage {
    final current = currentStage;
    if (current == null) return null;
    final idx = stages.indexWhere((s) => s.id == current.id);
    for (var i = idx + 1; i < stages.length; i++) {
      if (stages[i].status != StageStatus.skipped) return stages[i];
    }
    return null;
  }

  List<WorkStage> get completedStages =>
      stages.where((s) => s.status == StageStatus.completed).toList();

  List<WorkStage> get upcomingStages {
    final current = currentStage;
    final idx = current == null ? -1 : stages.indexWhere((s) => s.id == current.id);
    return stages.skip(idx + 1).where((s) => s.status == StageStatus.pending).toList();
  }

  bool get isStalledByInactivity {
    if (profile.status != ProfileStatus.inProgress) return false;
    final daysSinceUpdate =
        DateTime.now().difference(profile.updatedAt).inDays;
    return daysSinceUpdate >= AppConstants.stalledThresholdDays;
  }

  DeadlineCategory get deadlineCategory {
    if (profile.status == ProfileStatus.completed ||
        profile.status == ProfileStatus.cancelled) {
      return DeadlineCategory.completed;
    }
    if (!profile.hasDeadline || profile.deadline == null) {
      return DeadlineCategory.stalled;
    }
    final deadline = profile.deadline!;
    if (AppDateUtils.isOverdue(deadline)) return DeadlineCategory.overdue;
    if (AppDateUtils.isToday(deadline)) return DeadlineCategory.dueToday;
    if (AppDateUtils.isUpcoming(deadline, AppConstants.upcomingThresholdDays)) {
      return DeadlineCategory.upcoming;
    }
    if (isStalledByInactivity) return DeadlineCategory.stalled;
    return DeadlineCategory.normal;
  }

  /// Số milestone quá hạn/hôm nay/sắp tới — hiển thị cảnh báo phụ trên card.
  int get overdueMilestoneCount => milestones
      .where((m) => m.timing() == MilestoneTiming.overdue)
      .length;

  /// Hồ sơ đang ở trạng thái "Đang chờ" phản hồi từ bên ngoài.
  bool get isWaiting => profile.status == ProfileStatus.waiting;

  /// Các việc cần làm chưa hoàn thành/hủy, sắp theo deadline (null cuối).
  List<TaskItem> get openTasks {
    final list = tasks
        .where((t) =>
            t.status != TaskStatus.completed &&
            t.status != TaskStatus.cancelled)
        .toList();
    list.sort((a, b) {
      if (a.dueDate == null && b.dueDate == null) return 0;
      if (a.dueDate == null) return 1;
      if (b.dueDate == null) return -1;
      return a.dueDate!.compareTo(b.dueDate!);
    });
    return list;
  }

  List<TaskItem> get overdueTasks => openTasks
      .where((t) => t.dueDate != null && AppDateUtils.isOverdue(t.dueDate!))
      .toList();

  List<TaskItem> get todayTasks => openTasks
      .where((t) => t.dueDate != null && AppDateUtils.isToday(t.dueDate!))
      .toList();

  int get overdueTaskCount => overdueTasks.length;
}
