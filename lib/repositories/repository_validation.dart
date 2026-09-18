import '../models/models.dart';
import 'app_repository.dart';

void validatePositiveAmount(num amount) {
  if (amount <= 0) {
    throw const RepositoryException('Số tiền phải lớn hơn 0.');
  }
}

void validateProfileDates(Profile profile) {
  if (profile.hasDeadline && profile.deadline == null) {
    throw const RepositoryException(
      'Vui lòng chọn hạn hoàn thành hoặc tắt tùy chọn có deadline.',
    );
  }
  if (!profile.hasDeadline && profile.deadline != null) {
    throw const RepositoryException(
      'Hồ sơ không deadline không được có ngày hạn.',
    );
  }
  if (profile.deadline != null &&
      profile.deadline!.isBefore(profile.startDate)) {
    throw const RepositoryException(
      'Hạn hoàn thành không được trước ngày bắt đầu.',
    );
  }
  _validateWaitingDates(
    statusIsWaiting: profile.status == ProfileStatus.waiting,
    waitingSince: profile.waitingSince,
    expectedResponseDate: profile.expectedResponseDate,
  );
}

void validateTaskDates(TaskItem task) {
  _validateWaitingDates(
    statusIsWaiting: task.status == TaskStatus.waiting,
    waitingSince: task.waitingSince,
    expectedResponseDate: task.expectedResponseDate,
  );
}

void _validateWaitingDates({
  required bool statusIsWaiting,
  required DateTime? waitingSince,
  required DateTime? expectedResponseDate,
}) {
  if (!statusIsWaiting &&
      (waitingSince != null || expectedResponseDate != null)) {
    throw const RepositoryException(
      'Thông tin chờ chỉ được lưu khi trạng thái là Đang chờ.',
    );
  }
  if (statusIsWaiting &&
      waitingSince != null &&
      expectedResponseDate != null &&
      expectedResponseDate.isBefore(waitingSince)) {
    throw const RepositoryException(
      'Ngày dự kiến phản hồi không được trước ngày bắt đầu chờ.',
    );
  }
}

Profile normalizeProfileCompletion(Profile profile, Profile? previous) {
  final wasCompleted = previous?.status == ProfileStatus.completed;
  final isCompleted = profile.status == ProfileStatus.completed;
  if (!isCompleted) return profile.copyWith(clearCompletedAt: true);
  if (wasCompleted) {
    return profile.copyWith(
      completedAt:
          previous!.completedAt ?? profile.completedAt ?? DateTime.now(),
    );
  }
  return profile.copyWith(completedAt: profile.completedAt ?? DateTime.now());
}

TaskItem normalizeTaskCompletion(TaskItem task, TaskItem? previous) {
  final wasCompleted = previous?.status == TaskStatus.completed;
  final isCompleted = task.status == TaskStatus.completed;
  if (!isCompleted) return task.copyWith(clearCompletedAt: true);
  if (wasCompleted) {
    return task.copyWith(
      completedAt: previous!.completedAt ?? task.completedAt ?? DateTime.now(),
    );
  }
  return task.copyWith(completedAt: task.completedAt ?? DateTime.now());
}
