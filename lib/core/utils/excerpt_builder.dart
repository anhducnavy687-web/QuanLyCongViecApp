import '../../models/models.dart';
import 'app_date_utils.dart';
import 'money_utils.dart';

/// Sinh nội dung "Trích ngang hồ sơ" dạng văn bản sạch, dễ gửi qua
/// Zalo/email/chat. Có 2 chế độ: cơ bản (không có tiền) và đầy đủ.
class ExcerptBuilder {
  ExcerptBuilder._();

  static String build(ProfileAggregate aggregate, {required bool includeFinance}) {
    final p = aggregate.profile;
    final buffer = StringBuffer();

    buffer.writeln('TRÍCH NGANG HỒ SƠ');
    buffer.writeln('———————————————');
    buffer.writeln('Họ tên: ${p.fullName}');
    if (p.phone.isNotEmpty) buffer.writeln('Số điện thoại: ${p.phone}');
    buffer.writeln('Đích công việc: ${p.workTarget}');
    if (aggregate.group != null) buffer.writeln('Nhóm: ${aggregate.group!.name}');
    buffer.writeln('Trạng thái: ${p.status.label}');
    buffer.writeln('Ngày bắt đầu: ${AppDateUtils.formatDate(p.startDate)}');
    if (p.hasDeadline && p.deadline != null) {
      buffer.writeln('Hạn hoàn thành: ${AppDateUtils.formatDate(p.deadline)}'
          ' (${AppDateUtils.describeDeadline(p.deadline!)})');
    } else {
      buffer.writeln('Hạn hoàn thành: Không có '
          '(${AppDateUtils.describeStartedWithoutDeadline(p.startDate)})');
    }

    buffer.writeln();
    buffer.writeln('Tiến độ các bước:');
    for (final s in aggregate.stages) {
      final marker = switch (s.status) {
        StageStatus.completed => '[x]',
        StageStatus.inProgress => '[>]',
        StageStatus.skipped => '[-]',
        StageStatus.pending => '[ ]',
      };
      buffer.writeln('  $marker ${s.name}');
    }

    if (p.note.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('Ghi chú: ${p.note}');
    }

    if (includeFinance) {
      final finance = aggregate.finance;
      buffer.writeln();
      buffer.writeln('THÔNG TIN TÀI CHÍNH');
      buffer.writeln('———————————————');
      buffer.writeln('Tổng tiền: ${MoneyUtils.format(finance.totalAmount)}');
      buffer.writeln('Đã nhận: ${MoneyUtils.format(finance.received)}');
      buffer.writeln('Còn phải nhận: ${MoneyUtils.format(finance.remainingToReceive)}');
      buffer.writeln('Chi phí: ${MoneyUtils.format(finance.expense)}');

      if (aggregate.assignments.isNotEmpty) {
        buffer.writeln();
        buffer.writeln('Cộng tác viên:');
        for (final a in aggregate.assignments) {
          buffer.writeln('  - ${a.role.isEmpty ? "CTV" : a.role}: '
              '${MoneyUtils.format(a.paidAmount)} / ${MoneyUtils.format(a.commissionAmount)}'
              ' (còn ${MoneyUtils.format(a.remainingAmount)})');
        }
      }
      buffer.writeln('Tổng hoa hồng: ${MoneyUtils.format(finance.commissionTotal)}');
      buffer.writeln('Đã trả hoa hồng: ${MoneyUtils.format(finance.commissionPaid)}');
      buffer.writeln('Còn phải trả hoa hồng: ${MoneyUtils.format(finance.commissionRemaining)}');
    }

    return buffer.toString().trimRight();
  }
}
