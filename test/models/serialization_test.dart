import 'package:flutter_test/flutter_test.dart';
import 'package:quanlycongviecapp/models/models.dart';

void main() {
  final now = DateTime(2026, 9, 15, 10, 30);

  group('Serialization round-trip (toJson -> fromJson)', () {
    test('WorkGroup', () {
      final g = WorkGroup(
        id: 'g1',
        name: 'Đất đai',
        description: 'Mô tả',
        createdAt: now,
        updatedAt: now,
      );
      final decoded = WorkGroup.fromJson(g.toJson());
      expect(decoded.id, g.id);
      expect(decoded.name, g.name);
      expect(decoded.description, g.description);
      expect(decoded.createdAt, g.createdAt);
    });

    test('Profile', () {
      final p = Profile(
        id: 'p1',
        groupId: 'g1',
        fullName: 'Nguyễn Văn Minh',
        phone: '0987111222',
        workTarget: 'Chuyển nhượng đất',
        description: 'Mô tả',
        startDate: now,
        deadline: now.add(const Duration(days: 5)),
        hasDeadline: true,
        status: ProfileStatus.inProgress,
        totalAmount: 20000000,
        note: 'Ghi chú',
        createdAt: now,
        updatedAt: now,
      );
      final decoded = Profile.fromJson(p.toJson());
      expect(decoded.fullName, p.fullName);
      expect(decoded.status, ProfileStatus.inProgress);
      expect(decoded.hasDeadline, isTrue);
      expect(decoded.deadline, p.deadline);
      expect(decoded.totalAmount, 20000000);
    });

    test('WorkStage', () {
      final s = WorkStage(
        id: 's1',
        profileId: 'p1',
        name: 'Chuẩn bị',
        order: 1,
        status: StageStatus.inProgress,
        startDate: now,
        note: 'ghi chú',
      );
      final decoded = WorkStage.fromJson(s.toJson());
      expect(decoded.name, s.name);
      expect(decoded.status, StageStatus.inProgress);
      expect(decoded.order, 1);
    });

    test('Milestone', () {
      final m = Milestone(
        id: 'm1',
        profileId: 'p1',
        title: 'Nộp hồ sơ',
        dueDate: now,
        status: MilestoneStatus.completed,
        completedAt: now,
      );
      final decoded = Milestone.fromJson(m.toJson());
      expect(decoded.title, m.title);
      expect(decoded.status, MilestoneStatus.completed);
      expect(decoded.completedAt, m.completedAt);
    });

    test('MoneyTransaction', () {
      final t = MoneyTransaction(
        id: 't1',
        profileId: 'p1',
        type: TransactionType.collaboratorPayment,
        amount: 1000000,
        date: now,
        note: 'note',
        createdAt: now,
        collaboratorAssignmentId: 'as1',
      );
      final decoded = MoneyTransaction.fromJson(t.toJson());
      expect(decoded.type, TransactionType.collaboratorPayment);
      expect(decoded.amount, 1000000);
      expect(decoded.collaboratorAssignmentId, 'as1');
    });

    test('Collaborator', () {
      final c = Collaborator(
        id: 'ctv1',
        name: 'Nguyễn Thị Hoa',
        phone: '0901234567',
        active: false,
        createdAt: now,
        updatedAt: now,
      );
      final decoded = Collaborator.fromJson(c.toJson());
      expect(decoded.name, c.name);
      expect(decoded.active, isFalse);
    });

    test('CollaboratorAssignment', () {
      final a = CollaboratorAssignment(
        id: 'as1',
        profileId: 'p1',
        collaboratorId: 'ctv1',
        role: 'Đo đạc',
        commissionAmount: 1500000,
        paidAmount: 1000000,
        createdAt: now,
        updatedAt: now,
      );
      final decoded = CollaboratorAssignment.fromJson(a.toJson());
      expect(decoded.commissionAmount, 1500000);
      expect(decoded.paidAmount, 1000000);
      expect(decoded.remainingAmount, 500000);
      expect(decoded.isArchived, false);
      final archived = CollaboratorAssignment.fromJson({
        ...a.toJson(),
        'archivedAt': now.toIso8601String(),
      });
      expect(archived.isArchived, true);
    });

    test('Attachment', () {
      final att = Attachment(
        id: 'att1',
        profileId: 'p1',
        fileName: 'ho_so.pdf',
        type: AttachmentType.pdf,
        localPathOrUrl: '/tmp/ho_so.pdf',
        sizeBytes: 12345,
        createdAt: now,
        updatedAt: now,
      );
      final decoded = Attachment.fromJson(att.toJson());
      expect(decoded.fileName, att.fileName);
      expect(decoded.type, AttachmentType.pdf);
      expect(decoded.sizeBytes, 12345);
    });

    test('Profile với trạng thái Đang chờ (waiting fields)', () {
      final p = Profile(
        id: 'p1',
        groupId: 'g1',
        fullName: 'Trần Thị B',
        workTarget: 'Xin cấp sổ đỏ',
        startDate: now,
        status: ProfileStatus.waiting,
        createdAt: now,
        updatedAt: now,
        waitingReason: 'Chờ phòng công chứng xác nhận',
        waitingSince: now,
        expectedResponseDate: now.add(const Duration(days: 3)),
      );
      final decoded = Profile.fromJson(p.toJson());
      expect(decoded.status, ProfileStatus.waiting);
      expect(decoded.waitingReason, p.waitingReason);
      expect(decoded.waitingSince, p.waitingSince);
      expect(decoded.expectedResponseDate, p.expectedResponseDate);
    });

    test('TaskItem', () {
      final t = TaskItem(
        id: 'tk1',
        profileId: 'p1',
        title: 'Gọi điện xác nhận lịch hẹn',
        description: 'Gọi trước 9h sáng',
        status: TaskStatus.waiting,
        priority: TaskPriority.urgent,
        dueDate: now.add(const Duration(days: 1)),
        waitingReason: 'Chờ khách xác nhận',
        waitingSince: now,
        expectedResponseDate: now.add(const Duration(days: 2)),
        createdAt: now,
        updatedAt: now,
        note: 'Ghi chú task',
      );
      final decoded = TaskItem.fromJson(t.toJson());
      expect(decoded.title, t.title);
      expect(decoded.status, TaskStatus.waiting);
      expect(decoded.priority, TaskPriority.urgent);
      expect(decoded.dueDate, t.dueDate);
      expect(decoded.waitingReason, t.waitingReason);
      expect(decoded.waitingSince, t.waitingSince);
      expect(decoded.expectedResponseDate, t.expectedResponseDate);
      expect(decoded.note, t.note);
    });

    test('TimelineEvent', () {
      final e = TimelineEvent(
        id: 'e1',
        profileId: 'p1',
        type: TimelineEventType.taskCompleted,
        message: 'Đã hoàn thành việc "Gọi điện xác nhận lịch hẹn"',
        createdAt: now,
      );
      final decoded = TimelineEvent.fromJson(e.toJson());
      expect(decoded.type, TimelineEventType.taskCompleted);
      expect(decoded.message, e.message);
      expect(decoded.createdAt, e.createdAt);
    });
  });
}
