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
        'Hồ sơ tham chiếu nhóm không tồn tại.',
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

    void requireProfile(String profileId, String entity) => _require(
      profileIds.contains(profileId),
      '$entity tham chiếu hồ sơ không tồn tại.',
    );
    for (final stage in snapshot.stages) {
      requireProfile(stage.profileId, 'Bước xử lý');
    }
    for (final milestone in snapshot.milestones) {
      requireProfile(milestone.profileId, 'Mốc thời gian');
    }
    for (final task in snapshot.tasks) {
      requireProfile(task.profileId, 'Việc cần làm');
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
      requireProfile(event.profileId, 'Lịch sử');
    }
    for (final attachment in snapshot.attachments) {
      requireProfile(attachment.profileId, 'Tài liệu');
      _require(attachment.sizeBytes >= 0, 'Kích thước tài liệu không hợp lệ.');
    }
    for (final assignment in snapshot.collaboratorAssignments) {
      requireProfile(assignment.profileId, 'Phân công');
      _require(
        collaboratorIds.contains(assignment.collaboratorId),
        'Phân công tham chiếu cộng tác viên không tồn tại.',
      );
      _finite(assignment.commissionAmount, 'Hoa hồng không hợp lệ.');
      _finite(assignment.paidAmount, 'Số tiền đã trả không hợp lệ.');
      _require(assignment.commissionAmount >= 0, 'Hoa hồng không được âm.');
    }

    final rebuiltPaid = <String, num>{};
    for (final transaction in snapshot.transactions) {
      requireProfile(transaction.profileId, 'Giao dịch');
      _finite(transaction.amount, 'Số tiền giao dịch không hợp lệ.');
      _require(transaction.amount > 0, 'Số tiền giao dịch phải lớn hơn 0.');
      if (transaction.type == TransactionType.collaboratorPayment) {
        final assignmentId = transaction.collaboratorAssignmentId;
        _require(
          assignmentId != null && assignmentId.isNotEmpty,
          'Thanh toán cộng tác viên thiếu phân công.',
        );
        final assignment = assignments[assignmentId];
        _require(
          assignment != null,
          'Thanh toán tham chiếu phân công không tồn tại.',
        );
        _require(
          assignment!.profileId == transaction.profileId,
          'Thanh toán và phân công thuộc hai hồ sơ khác nhau.',
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
        'Số tiền đã trả vượt quá hoa hồng của phân công.',
      );
      _require(
        assignment.paidAmount == rebuilt,
        'Dữ liệu paidAmount không khớp lịch sử giao dịch. Vui lòng đồng bộ lại trước khi xuất.',
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
