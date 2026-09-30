import 'dart:typed_data';

import 'package:excel/excel.dart';

import '../models/models.dart';
import 'backup_service.dart';
import 'export_snapshot_validator.dart';

class ExcelExportService {
  const ExcelExportService({this.validator = const ExportSnapshotValidator()});
  final ExportSnapshotValidator validator;

  GeneratedExportFile createWorkbook(ExportSnapshot snapshot) {
    validator.validate(snapshot);
    final book = Excel.createExcel();
    final profileNames = {for (final p in snapshot.profiles) p.id: p.fullName};
    final groupNames = {for (final g in snapshot.groups) g.id: g.name};
    final groupsById = {for (final g in snapshot.groups) g.id: g};
    String customDisplay(Profile profile, String fieldId, Object? value) {
      final definition = groupsById[profile.groupId]?.customFieldDefinitions
          .where((d) => d.id == fieldId)
          .firstOrNull;
      if (definition?.type != ProfileFieldType.singleSelect) {
        return value?.toString() ?? '';
      }
      return definition!.options
              .where((option) => option.id == value)
              .map((option) => option.label)
              .firstOrNull ??
          value?.toString() ??
          '';
    }

    final collaboratorNames = {
      for (final c in snapshot.collaborators) c.id: c.name,
    };

    _sheet(
      book,
      'Metadata',
      ['Trường', 'Giá trị'],
      [
        ['Schema Version', 2],
        ['Exported At', snapshot.exportedAt],
        ['App Version', snapshot.appVersion],
        ['Source Mode', snapshot.sourceMode],
        for (final entry in snapshot.recordCounts.entries)
          ['Record Count: ${entry.key}', entry.value],
        ['Attachment Binary Included', false],
        [
          'Attachment Warning',
          'localPathOrUrl có thể không sử dụng được trên thiết bị khác.',
        ],
      ],
    );
    _sheet(
      book,
      'Groups',
      ['ID', 'Tên', 'Mô tả', 'Created', 'Updated'],
      [
        for (final g in snapshot.groups)
          [g.id, g.name, g.description, g.createdAt, g.updatedAt],
      ],
    );
    _sheet(
      book,
      'Profiles',
      [
        'ID',
        'Group ID',
        'Tên nhóm',
        'Họ tên',
        'Điện thoại',
        'Mục tiêu',
        'Mô tả',
        'Start date',
        'Has deadline',
        'Deadline',
        'Status raw',
        'Trạng thái',
        'Tổng tiền',
        'Ghi chú',
        'Created',
        'Updated',
        'Completed',
        'Lý do chờ',
        'Bắt đầu chờ',
        'Dự kiến phản hồi',
        'Ngày sinh',
        'CCCD',
        'Cấp bậc',
        'Chức vụ',
        'Đơn vị',
        'Nhập ngũ',
        'Quê quán',
        'Nơi ở hiện nay',
        'Trình độ',
        'Chuyên ngành',
        'Qua trường',
        'Xếp loại cán bộ',
        'Họ tên bố',
        'Năm sinh bố',
        'Nghề nghiệp bố',
        'Quê quán bố',
        'Nơi ở bố',
        'Họ tên mẹ',
        'Năm sinh mẹ',
        'Nghề nghiệp mẹ',
        'Quê quán mẹ',
        'Nơi ở mẹ',
        'Nguyện vọng 1',
        'Nguyện vọng 2',
        'Nguyện vọng 3',
      ],
      [
        for (final p in snapshot.profiles)
          [
            p.id,
            p.groupId,
            groupNames[p.groupId] ?? '',
            p.fullName,
            p.phone,
            p.workTarget,
            p.description,
            p.startDate,
            p.hasDeadline,
            p.deadline,
            p.status.value,
            p.status.label,
            p.totalAmount,
            p.note,
            p.createdAt,
            p.updatedAt,
            p.completedAt,
            p.waitingReason,
            p.waitingSince,
            p.expectedResponseDate,
            p.dateOfBirth,
            p.citizenId,
            p.rank,
            p.position,
            p.unit,
            p.enlistment,
            p.hometown,
            p.currentResidence,
            p.educationLevel,
            p.specialty,
            p.schoolHistory,
            p.officerRating,
            p.fatherFullName,
            p.fatherBirthYear,
            p.fatherOccupation,
            p.fatherHometown,
            p.fatherCurrentResidence,
            p.motherFullName,
            p.motherBirthYear,
            p.motherOccupation,
            p.motherHometown,
            p.motherCurrentResidence,
            p.aspiration1,
            p.aspiration2,
            p.aspiration3,
          ],
      ],
    );
    _sheet(
      book,
      'Stages',
      [
        'ID',
        'Profile ID',
        'Hồ sơ',
        'Tên bước',
        'Thứ tự',
        'Status raw',
        'Trạng thái',
        'Bắt đầu',
        'Hoàn thành',
        'Deadline',
        'Ghi chú',
      ],
      [
        for (final s in snapshot.stages)
          [
            s.id,
            s.profileId,
            profileNames[s.profileId] ?? '',
            s.name,
            s.order,
            s.status.value,
            s.status.label,
            s.startDate,
            s.completedAt,
            s.deadline,
            s.note,
          ],
      ],
    );
    _sheet(
      book,
      'Milestones',
      [
        'ID',
        'Profile ID',
        'Hồ sơ',
        'Tiêu đề',
        'Due date',
        'Status raw',
        'Trạng thái',
        'Completed',
        'Ghi chú',
      ],
      [
        for (final m in snapshot.milestones)
          [
            m.id,
            m.profileId,
            profileNames[m.profileId] ?? '',
            m.title,
            m.dueDate,
            m.status.value,
            m.status.label,
            m.completedAt,
            m.note,
          ],
      ],
    );
    _sheet(
      book,
      'Tasks',
      [
        'ID',
        'Profile ID',
        'Hồ sơ',
        'Tiêu đề',
        'Mô tả',
        'Status raw',
        'Trạng thái',
        'Priority raw',
        'Ưu tiên',
        'Due date',
        'Lý do chờ',
        'Bắt đầu chờ',
        'Dự kiến phản hồi',
        'Completed',
        'Created',
        'Updated',
        'Ghi chú',
      ],
      [
        for (final t in snapshot.tasks)
          [
            t.id,
            t.profileId,
            profileNames[t.profileId] ?? '',
            t.title,
            t.description,
            t.status.value,
            t.status.label,
            t.priority.value,
            t.priority.label,
            t.dueDate,
            t.waitingReason,
            t.waitingSince,
            t.expectedResponseDate,
            t.completedAt,
            t.createdAt,
            t.updatedAt,
            t.note,
          ],
      ],
    );
    _sheet(
      book,
      'TimelineEvents',
      ['ID', 'Profile ID', 'Hồ sơ', 'Type raw', 'Loại', 'Message', 'Created'],
      [
        for (final e in snapshot.timelineEvents)
          [
            e.id,
            e.profileId,
            profileNames[e.profileId] ?? '',
            e.type.value,
            e.type.label,
            e.message,
            e.createdAt,
          ],
      ],
    );
    _sheet(
      book,
      'Transactions',
      [
        'ID',
        'Profile ID',
        'Hồ sơ',
        'Type raw',
        'Loại',
        'Amount',
        'Date',
        'Ghi chú',
        'Created',
        'Assignment ID',
      ],
      [
        for (final t in snapshot.transactions)
          [
            t.id,
            t.profileId,
            profileNames[t.profileId] ?? '',
            t.type.value,
            t.type.label,
            t.amount,
            t.date,
            t.note,
            t.createdAt,
            t.collaboratorAssignmentId,
          ],
      ],
    );
    _sheet(
      book,
      'Collaborators',
      ['ID', 'Tên', 'Điện thoại', 'Ghi chú', 'Active', 'Created', 'Updated'],
      [
        for (final c in snapshot.collaborators)
          [c.id, c.name, c.phone, c.note, c.active, c.createdAt, c.updatedAt],
      ],
    );
    final rebuiltPaid = _rebuiltPaid(snapshot.transactions);
    _sheet(
      book,
      'CollaboratorAssignments',
      [
        'ID',
        'Profile ID',
        'Collaborator ID',
        'Hồ sơ',
        'Cộng tác viên',
        'Vai trò',
        'Commission amount',
        'Paid amount rebuilt',
        'Paid amount stored',
        'Difference',
        'Ghi chú',
        'Archived at',
        'Created',
        'Updated',
      ],
      [
        for (final a in snapshot.collaboratorAssignments)
          [
            a.id,
            a.profileId,
            a.collaboratorId,
            profileNames[a.profileId] ?? '',
            collaboratorNames[a.collaboratorId] ?? '',
            a.role,
            a.commissionAmount,
            rebuiltPaid[a.id] ?? 0,
            a.paidAmount,
            a.paidAmount - (rebuiltPaid[a.id] ?? 0),
            a.note,
            a.archivedAt,
            a.createdAt,
            a.updatedAt,
          ],
      ],
    );
    _sheet(
      book,
      'Attachments',
      [
        'ID',
        'Profile ID',
        'Hồ sơ',
        'File name',
        'Type raw',
        'Size bytes',
        'Local path/URL',
        'Storage path',
        'Created',
        'Updated',
        'Binary included',
      ],
      [
        for (final a in snapshot.attachments)
          [
            a.id,
            a.profileId,
            profileNames[a.profileId] ?? '',
            a.fileName,
            a.type.name,
            a.sizeBytes,
            a.localPathOrUrl,
            a.storagePath,
            a.createdAt,
            a.updatedAt,
            false,
          ],
      ],
    );
    _sheet(
      book,
      'FieldDefinitions',
      [
        'Group ID',
        'Group Name',
        'Field ID',
        'Built-in/Custom',
        'Label',
        'Section',
        'Type',
        'Enabled',
        'Required',
        'Order',
        'Pinned',
        'Active',
        'Options',
      ],
      [
        for (final group in snapshot.groups)
          for (final config in group.effectiveFieldConfigs)
            [
              group.id,
              group.name,
              config.fieldId,
              ProfileFieldCatalog.byId(config.fieldId) != null
                  ? 'Built-in'
                  : 'Custom',
              ProfileFieldCatalog.byId(config.fieldId)?.labelVi ??
                  group.customFieldDefinitions
                      .where((e) => e.id == config.fieldId)
                      .map((e) => e.label)
                      .join(),
              ProfileFieldCatalog.byId(config.fieldId)?.section.name ??
                  group.customFieldDefinitions
                      .where((e) => e.id == config.fieldId)
                      .map((e) => e.section.name)
                      .join(),
              ProfileFieldCatalog.byId(config.fieldId)?.type.name ??
                  group.customFieldDefinitions
                      .where((e) => e.id == config.fieldId)
                      .map((e) => e.type.name)
                      .join(),
              config.enabled,
              config.required,
              config.order,
              ProfileFieldCatalog.byId(config.fieldId)?.isPinnedBottom ?? false,
              group.customFieldDefinitions
                  .where((e) => e.id == config.fieldId)
                  .map((e) => e.active)
                  .fold<bool>(true, (_, value) => value),
              group.customFieldDefinitions
                  .where((e) => e.id == config.fieldId)
                  .expand((e) => e.options)
                  .map(
                    (e) =>
                        '${e.id}:${e.label}:active=${e.active}:order=${e.order}',
                  )
                  .join('|'),
            ],
      ],
    );
    _sheet(
      book,
      'CustomFieldValues',
      [
        'Profile ID',
        'Profile Name',
        'Group ID',
        'Field ID',
        'Field Label',
        'Field Type',
        'Raw Value',
        'Display Value',
      ],
      [
        for (final profile in snapshot.profiles)
          for (final entry in profile.customFieldValues.entries)
            [
              profile.id,
              profile.fullName,
              profile.groupId,
              entry.key,
              snapshot.groups
                  .where((g) => g.id == profile.groupId)
                  .expand((g) => g.customFieldDefinitions)
                  .where((d) => d.id == entry.key)
                  .map((d) => d.label)
                  .join(),
              snapshot.groups
                  .where((g) => g.id == profile.groupId)
                  .expand((g) => g.customFieldDefinitions)
                  .where((d) => d.id == entry.key)
                  .map((d) => d.type.name)
                  .join(),
              entry.value,
              customDisplay(profile, entry.key, entry.value),
            ],
      ],
    );
    book.delete('Sheet1');
    final encoded = book.encode();
    if (encoded == null || encoded.isEmpty) {
      throw const ExportValidationException('Không thể tạo workbook Excel.');
    }
    return GeneratedExportFile(
      fileName: 'QuanLyCongViec_Export_${_stamp(snapshot.exportedAt)}.xlsx',
      mimeType:
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      bytes: Uint8List.fromList(encoded),
    );
  }

  void _sheet(
    Excel book,
    String name,
    List<String> headers,
    List<List<Object?>> rows,
  ) {
    final sheet = book[name];
    sheet.appendRow(headers.map(TextCellValue.new).toList());
    for (final row in rows) {
      sheet.appendRow(row.map(_cell).toList());
    }
    final headerStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.blue100,
      verticalAlign: VerticalAlign.Center,
    );
    for (final cell in sheet.row(0)) {
      cell?.cellStyle = headerStyle;
    }
    for (var i = 0; i < headers.length; i++) {
      sheet.setColumnWidth(i, i < 3 ? 22 : 18);
    }
  }

  CellValue? _cell(Object? value) {
    if (value == null) return null;
    if (value is String) return TextCellValue(value);
    if (value is bool) return BoolCellValue(value);
    if (value is int) return IntCellValue(value);
    if (value is num) return DoubleCellValue(value.toDouble());
    if (value is DateTime) return DateTimeCellValue.fromDateTime(value);
    return TextCellValue(value.toString());
  }

  Map<String, num> _rebuiltPaid(List<MoneyTransaction> transactions) {
    final result = <String, num>{};
    for (final transaction in transactions) {
      if (transaction.type != TransactionType.collaboratorPayment) continue;
      final id = transaction.collaboratorAssignmentId!;
      result[id] = (result[id] ?? 0) + transaction.amount;
    }
    return result;
  }

  String _stamp(DateTime value) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${value.year}-${two(value.month)}-${two(value.day)}_'
        '${two(value.hour)}${two(value.minute)}';
  }
}
