import '../models/models.dart';

class ExportValidationException implements Exception {
  const ExportValidationException(this.message);
  final String message;
  @override
  String toString() => message;
}

class ExportSnapshotValidator {
  const ExportSnapshotValidator();

  void validate(ExportSnapshot snapshot) {
    _unique('nhóm', snapshot.groups.map((e) => e.id));
    _unique('hồ sơ', snapshot.profiles.map((e) => e.id));
    _unique('bước xử lý', snapshot.stages.map((e) => e.id));
    _unique('mốc thời gian', snapshot.milestones.map((e) => e.id));
    _unique('việc cần làm', snapshot.tasks.map((e) => e.id));
    _unique('dòng lịch sử', snapshot.timelineEvents.map((e) => e.id));
    _unique('giao dịch', snapshot.transactions.map((e) => e.id));
    _unique('cộng tác viên', snapshot.collaborators.map((e) => e.id));
    _unique(
      'phân công cộng tác viên',
      snapshot.collaboratorAssignments.map((e) => e.id),
    );
    _unique('tài liệu', snapshot.attachments.map((e) => e.id));

    final groupIds = snapshot.groups.map((e) => e.id).toSet();
    final profileIds = snapshot.profiles.map((e) => e.id).toSet();
    final collaboratorIds = snapshot.collaborators.map((e) => e.id).toSet();
    final assignments = {
      for (final assignment in snapshot.collaboratorAssignments)
        assignment.id: assignment,
    };

    for (final profile in snapshot.profiles) {
      _require(
        groupIds.contains(profile.groupId),
        'Profile ${profile.id} tham chiếu group ${profile.groupId} không tồn tại.',
      );
      _finite(profile.totalAmount, 'Tổng tiền hồ sơ không hợp lệ.');
      _require(
        profile.hasDeadline == (profile.deadline != null),
        'Thông tin deadline của hồ sơ không nhất quán.',
      );
      if (profile.deadline != null) {
        _require(
          !profile.deadline!.isBefore(profile.startDate),
          'Deadline hồ sơ không được trước ngày bắt đầu.',
        );
      }
      _waiting(
        profile.status == ProfileStatus.waiting,
        profile.waitingSince,
        profile.expectedResponseDate,
      );
      _completed(
        profile.status == ProfileStatus.completed,
        profile.completedAt,
        'hồ sơ',
      );
    }

    void requireProfile(String profileId, String entity, String id) => _require(
      profileIds.contains(profileId),
      '$entity $id tham chiếu profile $profileId không tồn tại.',
    );
    for (final stage in snapshot.stages) {
      requireProfile(stage.profileId, 'Stage', stage.id);
    }
    for (final milestone in snapshot.milestones) {
      requireProfile(milestone.profileId, 'Milestone', milestone.id);
    }
    for (final task in snapshot.tasks) {
      requireProfile(task.profileId, 'Task', task.id);
      _waiting(
        task.status == TaskStatus.waiting,
        task.waitingSince,
        task.expectedResponseDate,
      );
      _completed(
        task.status == TaskStatus.completed,
        task.completedAt,
        'việc cần làm',
      );
    }
    for (final event in snapshot.timelineEvents) {
      requireProfile(event.profileId, 'TimelineEvent', event.id);
    }
    for (final attachment in snapshot.attachments) {
      requireProfile(attachment.profileId, 'Attachment', attachment.id);
      _require(attachment.sizeBytes >= 0, 'Kích thước tài liệu không hợp lệ.');
    }
    for (final assignment in snapshot.collaboratorAssignments) {
      requireProfile(assignment.profileId, 'Assignment', assignment.id);
      _require(
        collaboratorIds.contains(assignment.collaboratorId),
        'Assignment ${assignment.id} tham chiếu collaborator ${assignment.collaboratorId} không tồn tại.',
      );
      _finite(assignment.commissionAmount, 'Hoa hồng không hợp lệ.');
      _finite(assignment.paidAmount, 'Số tiền đã trả không hợp lệ.');
      _require(assignment.commissionAmount >= 0, 'Hoa hồng không được âm.');
    }

    final rebuiltPaid = <String, num>{};
    for (final transaction in snapshot.transactions) {
      requireProfile(transaction.profileId, 'Transaction', transaction.id);
      _finite(
        transaction.amount,
        'Transaction ${transaction.id} có số tiền không hợp lệ.',
      );
      _require(
        transaction.amount > 0,
        'Transaction ${transaction.id} có số tiền không hợp lệ.',
      );
      if (transaction.type == TransactionType.collaboratorPayment) {
        final assignmentId = transaction.collaboratorAssignmentId;
        _require(
          assignmentId != null && assignmentId.isNotEmpty,
          'Transaction ${transaction.id} thiếu assignment.',
        );
        final assignment = assignments[assignmentId];
        _require(
          assignment != null,
          'Transaction ${transaction.id} tham chiếu assignment $assignmentId không tồn tại.',
        );
        _require(
          assignment!.profileId == transaction.profileId,
          'Transaction ${transaction.id} và assignment $assignmentId thuộc hai profile khác nhau.',
        );
        rebuiltPaid[assignmentId!] =
            (rebuiltPaid[assignmentId] ?? 0) + transaction.amount;
      } else {
        _require(
          transaction.collaboratorAssignmentId == null,
          'Giao dịch thường không được gắn với phân công cộng tác viên.',
        );
      }
    }

    for (final assignment in snapshot.collaboratorAssignments) {
      final rebuilt = rebuiltPaid[assignment.id] ?? 0;
      _require(
        rebuilt <= assignment.commissionAmount,
        'Assignment ${assignment.id} có số tiền đã trả lớn hơn hoa hồng.',
      );
      _require(
        assignment.paidAmount == rebuilt,
        'Assignment ${assignment.id} có paidAmount không khớp lịch sử giao dịch.',
      );
    }
  }

  void _unique(String label, Iterable<String> ids) {
    final seen = <String>{};
    for (final id in ids) {
      _require(id.isNotEmpty, 'ID $label không được để trống.');
      _require(seen.add(id), 'Phát hiện ID $label bị trùng.');
    }
  }

  void _waiting(bool waiting, DateTime? since, DateTime? expected) {
    _require(
      waiting || (since == null && expected == null),
      'Thông tin chờ chỉ được lưu khi trạng thái là Đang chờ.',
    );
    if (since != null && expected != null) {
      _require(
        !expected.isBefore(since),
        'Ngày dự kiến phản hồi không được trước ngày bắt đầu chờ.',
      );
    }
  }

  void _completed(bool completed, DateTime? completedAt, String label) {
    _require(
      completed == (completedAt != null),
      'Trạng thái hoàn thành và completedAt của $label không nhất quán.',
    );
  }

  void _finite(num value, String message) => _require(value.isFinite, message);

  void _require(bool condition, String message) {
    if (!condition) throw ExportValidationException(message);
  }
}
