import 'package:flutter_test/flutter_test.dart';
import 'package:quanlycongviecapp/models/models.dart';

Profile _profile({
  ProfileStatus status = ProfileStatus.inProgress,
  bool hasDeadline = true,
  DateTime? deadline,
  DateTime? startDate,
  DateTime? updatedAt,
  num totalAmount = 20000000,
}) {
  final now = DateTime.now();
  return Profile(
    id: 'p1',
    groupId: 'g1',
    fullName: 'Nguyễn Văn A',
    workTarget: 'Test',
    startDate: startDate ?? now.subtract(const Duration(days: 10)),
    deadline: deadline,
    hasDeadline: hasDeadline,
    status: status,
    totalAmount: totalAmount,
    createdAt: now,
    updatedAt: updatedAt ?? now,
  );
}

void main() {
  group('ProfileAggregate.finance — tính từ transaction', () {
    test('tổng hợp đúng RECEIVED / EXPENSE / COLLABORATOR_PAYMENT', () {
      final profile = _profile(totalAmount: 20000000);
      final agg = ProfileAggregate(
        profile: profile,
        transactions: [
          MoneyTransaction(
            id: 't1',
            profileId: 'p1',
            type: TransactionType.received,
            amount: 8000000,
            date: DateTime.now(),
            createdAt: DateTime.now(),
          ),
          MoneyTransaction(
            id: 't2',
            profileId: 'p1',
            type: TransactionType.received,
            amount: 4000000,
            date: DateTime.now(),
            createdAt: DateTime.now(),
          ),
          MoneyTransaction(
            id: 't3',
            profileId: 'p1',
            type: TransactionType.expense,
            amount: 500000,
            date: DateTime.now(),
            createdAt: DateTime.now(),
          ),
          MoneyTransaction(
            id: 't4',
            profileId: 'p1',
            type: TransactionType.collaboratorPayment,
            amount: 1000000,
            date: DateTime.now(),
            createdAt: DateTime.now(),
            collaboratorAssignmentId: 'as1',
          ),
        ],
        assignments: [
          CollaboratorAssignment(
            id: 'as1',
            profileId: 'p1',
            collaboratorId: 'ctv1',
            commissionAmount: 1500000,
            paidAmount: 1000000,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ],
      );

      final finance = agg.finance;
      expect(finance.totalAmount, 20000000);
      expect(finance.received, 12000000);
      expect(finance.remainingToReceive, 8000000);
      expect(finance.expense, 500000);
      expect(finance.commissionTotal, 1500000);
      expect(finance.commissionPaid, 1000000);
      expect(finance.commissionRemaining, 500000);
    });

    test('remainingToReceive không âm khi đã nhận vượt tổng tiền', () {
      final profile = _profile(totalAmount: 1000000);
      final agg = ProfileAggregate(
        profile: profile,
        transactions: [
          MoneyTransaction(
            id: 't1',
            profileId: 'p1',
            type: TransactionType.received,
            amount: 3000000,
            date: DateTime.now(),
            createdAt: DateTime.now(),
          ),
        ],
      );
      expect(agg.finance.remainingToReceive, 0);
    });
  });

  group('ProfileAggregate.deadlineCategory', () {
    test('quá hạn khi deadline đã qua', () {
      final agg = ProfileAggregate(
        profile: _profile(deadline: DateTime.now().subtract(const Duration(days: 3))),
      );
      expect(agg.deadlineCategory, DeadlineCategory.overdue);
    });

    test('hôm nay khi deadline là hôm nay', () {
      final now = DateTime.now();
      final agg = ProfileAggregate(
        profile: _profile(deadline: DateTime(now.year, now.month, now.day)),
      );
      expect(agg.deadlineCategory, DeadlineCategory.dueToday);
    });

    test('sắp đến hạn khi còn trong ngưỡng cảnh báo', () {
      final agg = ProfileAggregate(
        profile: _profile(deadline: DateTime.now().add(const Duration(days: 2))),
      );
      expect(agg.deadlineCategory, DeadlineCategory.upcoming);
    });

    test('trì trệ khi hồ sơ không có deadline', () {
      final agg = ProfileAggregate(profile: _profile(hasDeadline: false, deadline: null));
      expect(agg.deadlineCategory, DeadlineCategory.stalled);
    });

    test('hoàn thành khi trạng thái là completed dù deadline thế nào', () {
      final agg = ProfileAggregate(
        profile: _profile(
          status: ProfileStatus.completed,
          deadline: DateTime.now().subtract(const Duration(days: 10)),
        ),
      );
      expect(agg.deadlineCategory, DeadlineCategory.completed);
    });
  });

  group('ProfileAggregate — bước hiện tại (currentStage)', () {
    test('bước hiện tại là bước inProgress đầu tiên', () {
      final agg = ProfileAggregate(
        profile: _profile(),
        stages: [
          WorkStage(id: 's1', profileId: 'p1', name: 'Nhận hồ sơ', order: 0, status: StageStatus.completed),
          WorkStage(id: 's2', profileId: 'p1', name: 'Chuẩn bị', order: 1, status: StageStatus.inProgress),
          WorkStage(id: 's3', profileId: 'p1', name: 'Bàn giao', order: 2, status: StageStatus.pending),
        ],
      );
      expect(agg.currentStage?.name, 'Chuẩn bị');
      expect(agg.completedStages.length, 1);
      expect(agg.nextStage?.name, 'Bàn giao');
    });

    test('currentStage null khi tất cả các bước đã hoàn thành', () {
      final agg = ProfileAggregate(
        profile: _profile(),
        stages: [
          WorkStage(id: 's1', profileId: 'p1', name: 'A', order: 0, status: StageStatus.completed),
          WorkStage(id: 's2', profileId: 'p1', name: 'B', order: 1, status: StageStatus.completed),
        ],
      );
      expect(agg.currentStage, isNull);
    });
  });

  group('Milestone.timing', () {
    test('phân loại đúng quá hạn/hôm nay/sắp tới/hoàn thành', () {
      final now = DateTime.now();
      final overdue = Milestone(
        id: 'm1',
        profileId: 'p1',
        title: 'A',
        dueDate: now.subtract(const Duration(days: 2)),
      );
      final today = Milestone(
        id: 'm2',
        profileId: 'p1',
        title: 'B',
        dueDate: DateTime(now.year, now.month, now.day),
      );
      final upcoming = Milestone(
        id: 'm3',
        profileId: 'p1',
        title: 'C',
        dueDate: now.add(const Duration(days: 1)),
      );
      final completed = Milestone(
        id: 'm4',
        profileId: 'p1',
        title: 'D',
        dueDate: now.subtract(const Duration(days: 5)),
        status: MilestoneStatus.completed,
      );

      expect(overdue.timing(), MilestoneTiming.overdue);
      expect(today.timing(), MilestoneTiming.today);
      expect(upcoming.timing(upcomingThresholdDays: 3), MilestoneTiming.upcoming);
      expect(completed.timing(), MilestoneTiming.completed);
    });
  });
}
