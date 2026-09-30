import '../../core/utils/repository_action.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/extensions/context_extensions.dart';
import '../../core/extensions/datetime_extensions.dart';
import '../../core/responsive/responsive.dart';
import '../../core/utils/validators.dart';
import '../../models/models.dart';
import '../../repositories/app_repository.dart';
import '../../widgets/waiting_reason_chips.dart';

/// Form Thêm/Sửa hồ sơ. Khi tạo mới, hồ sơ tự động được gán 5 bước xử lý
/// mặc định (xem AppRepository.addProfile).
class AddEditProfileScreen extends StatefulWidget {
  final Profile? profile;
  final String? initialGroupId;

  const AddEditProfileScreen({super.key, this.profile, this.initialGroupId});

  @override
  State<AddEditProfileScreen> createState() => _AddEditProfileScreenState();
}

class _AddEditProfileScreenState extends State<AddEditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _workTargetCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _amountCtrl;
  late final TextEditingController _noteCtrl;
  late final TextEditingController _waitingReasonCtrl;
  final Map<String, TextEditingController> _dynamicCtrls = {};

  String? _groupId;
  late DateTime _startDate;
  DateTime? _deadline;
  late bool _hasDeadline;
  late ProfileStatus _status;
  DateTime? _waitingSince;
  DateTime? _expectedResponseDate;
  bool _saving = false;
  String? _deadlineError;

  bool get _isEdit => widget.profile != null;

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _nameCtrl = TextEditingController(text: p?.fullName ?? '');
    _phoneCtrl = TextEditingController(text: p?.phone ?? '');
    _workTargetCtrl = TextEditingController(text: p?.workTarget ?? '');
    _descCtrl = TextEditingController(text: p?.description ?? '');
    _amountCtrl = TextEditingController(
      text: p != null && p.totalAmount > 0
          ? p.totalAmount.toStringAsFixed(0)
          : '',
    );
    _noteCtrl = TextEditingController(text: p?.note ?? '');
    _waitingReasonCtrl = TextEditingController(text: p?.waitingReason ?? '');
    _groupId = p?.groupId ?? widget.initialGroupId;
    _startDate = p?.startDate ?? DateTime.now();
    _deadline = p?.deadline;
    _hasDeadline = p?.hasDeadline ?? false;
    _status = p?.status ?? ProfileStatus.newProfile;
    _waitingSince = p?.waitingSince;
    _expectedResponseDate = p?.expectedResponseDate;
    final values = <String, Object?>{
      'dateOfBirth': p?.dateOfBirth?.toIso8601String().split('T').first,
      'citizenId': p?.citizenId,
      'rank': p?.rank,
      'position': p?.position,
      'unit': p?.unit,
      'enlistment': p?.enlistment,
      'hometown': p?.hometown,
      'currentResidence': p?.currentResidence,
      'educationLevel': p?.educationLevel,
      'specialty': p?.specialty,
      'schoolHistory': p?.schoolHistory,
      'officerRating': p?.officerRating,
      'fatherFullName': p?.fatherFullName,
      'fatherBirthYear': p?.fatherBirthYear,
      'fatherOccupation': p?.fatherOccupation,
      'fatherHometown': p?.fatherHometown,
      'fatherCurrentResidence': p?.fatherCurrentResidence,
      'motherFullName': p?.motherFullName,
      'motherBirthYear': p?.motherBirthYear,
      'motherOccupation': p?.motherOccupation,
      'motherHometown': p?.motherHometown,
      'motherCurrentResidence': p?.motherCurrentResidence,
      'aspiration1': p?.aspiration1,
      'aspiration2': p?.aspiration2,
      'aspiration3': p?.aspiration3,
      ...?p?.customFieldValues,
    };
    for (final entry in values.entries) {
      _dynamicCtrls[entry.key] = TextEditingController(
        text: entry.value?.toString() ?? '',
      );
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _workTargetCtrl.dispose();
    _descCtrl.dispose();
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    _waitingReasonCtrl.dispose();
    for (final controller in _dynamicCtrls.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _pickDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline ?? _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _deadline = picked);
  }

  Future<void> _pickDate(
    DateTime? initial,
    ValueChanged<DateTime> onPicked,
  ) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked != null) onPicked(picked);
  }

  Future<void> _save() async {
    setState(() => _deadlineError = null);
    if (!_formKey.currentState!.validate()) return;
    if (_groupId == null) {
      context.showSnackBar('Vui lòng chọn nhóm công việc', isError: true);
      return;
    }
    if (_hasDeadline) {
      if (_deadline == null) {
        setState(() => _deadlineError = 'Vui lòng chọn hạn hoàn thành');
        return;
      }
      final err = Validators.deadlineNotBeforeStart(_startDate, _deadline);
      if (err != null) {
        setState(() => _deadlineError = err);
        return;
      }
    }
    if (_status == ProfileStatus.waiting &&
        _waitingSince != null &&
        _expectedResponseDate != null &&
        _expectedResponseDate!.isBefore(_waitingSince!)) {
      context.showSnackBar(
        'Ngày dự kiến phản hồi không được trước ngày bắt đầu chờ',
        isError: true,
      );
      return;
    }

    setState(() => _saving = true);
    final repo = context.read<AppRepository>();
    final saved = await runRepositoryAction(context, () async {
      final amount =
          num.tryParse(
            _amountCtrl.text.replaceAll('.', '').replaceAll(',', ''),
          ) ??
          0;
      final now = DateTime.now();
      String? text(String id) {
        final value = _dynamicCtrls[id]?.text.trim() ?? '';
        return value.isEmpty ? null : value;
      }

      int? year(String id) => int.tryParse(text(id) ?? '');
      final dob = DateTime.tryParse(text('dateOfBirth') ?? '');
      final customValues = Map<String, dynamic>.from(
        widget.profile?.customFieldValues ?? const {},
      );
      final selectedGroup = repo.groupById(_groupId!);
      for (final definition
          in selectedGroup?.customFieldDefinitions ??
              const <CustomFieldDefinition>[]) {
        final config = selectedGroup!.effectiveFieldConfigs
            .where((c) => c.fieldId == definition.id)
            .firstOrNull;
        if (config?.enabled != true || !definition.active) continue;
        final raw = text(definition.id);
        if (raw == null) {
          customValues.remove(definition.id);
          continue;
        }
        customValues[definition.id] = switch (definition.type) {
          ProfileFieldType.number => num.tryParse(raw) ?? raw,
          ProfileFieldType.year => int.tryParse(raw) ?? raw,
          ProfileFieldType.boolean => raw == 'true',
          _ => raw,
        };
      }
      final isWaiting = _status == ProfileStatus.waiting;
      if (isWaiting) {
        _waitingSince ??= now;
      }

      if (_isEdit) {
        final base = widget.profile!.copyWith(
          groupId: _groupId!,
          fullName: _nameCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
          workTarget: _workTargetCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          startDate: _startDate,
          deadline: _hasDeadline ? _deadline : null,
          hasDeadline: _hasDeadline,
          status: _status,
          totalAmount: amount,
          note: _noteCtrl.text.trim(),
          clearDeadline: !_hasDeadline,
          completedAt: _status == ProfileStatus.completed
              ? (widget.profile!.status == ProfileStatus.completed
                    ? widget.profile!.completedAt
                    : now)
              : null,
          clearCompletedAt: _status != ProfileStatus.completed,
          waitingReason: isWaiting ? _waitingReasonCtrl.text.trim() : null,
          clearWaitingReason: !isWaiting,
          waitingSince: isWaiting ? _waitingSince : null,
          clearWaitingSince: !isWaiting,
          expectedResponseDate: isWaiting ? _expectedResponseDate : null,
          clearExpectedResponseDate: !isWaiting,
        );
        await repo.updateProfile(
          base.replaceDynamicValues(
            dateOfBirth: dob,
            citizenId: text('citizenId'),
            rank: text('rank'),
            position: text('position'),
            unit: text('unit'),
            enlistment: text('enlistment'),
            hometown: text('hometown'),
            currentResidence: text('currentResidence'),
            educationLevel: text('educationLevel'),
            specialty: text('specialty'),
            schoolHistory: text('schoolHistory'),
            officerRating: text('officerRating'),
            fatherFullName: text('fatherFullName'),
            fatherBirthYear: year('fatherBirthYear'),
            fatherOccupation: text('fatherOccupation'),
            fatherHometown: text('fatherHometown'),
            fatherCurrentResidence: text('fatherCurrentResidence'),
            motherFullName: text('motherFullName'),
            motherBirthYear: year('motherBirthYear'),
            motherOccupation: text('motherOccupation'),
            motherHometown: text('motherHometown'),
            motherCurrentResidence: text('motherCurrentResidence'),
            aspiration1: text('aspiration1'),
            aspiration2: text('aspiration2'),
            aspiration3: text('aspiration3'),
            customFieldValues: customValues,
          ),
        );
      } else {
        await repo.addProfile(
          Profile(
            id: '',
            groupId: _groupId!,
            fullName: _nameCtrl.text.trim(),
            phone: _phoneCtrl.text.trim(),
            workTarget: _workTargetCtrl.text.trim(),
            description: _descCtrl.text.trim(),
            startDate: _startDate,
            deadline: _hasDeadline ? _deadline : null,
            hasDeadline: _hasDeadline,
            status: _status,
            totalAmount: amount,
            note: _noteCtrl.text.trim(),
            createdAt: now,
            updatedAt: now,
            completedAt: _status == ProfileStatus.completed ? now : null,
            waitingReason: isWaiting ? _waitingReasonCtrl.text.trim() : null,
            waitingSince: isWaiting ? _waitingSince : null,
            expectedResponseDate: isWaiting ? _expectedResponseDate : null,
            dateOfBirth: dob,
            citizenId: text('citizenId'),
            rank: text('rank'),
            position: text('position'),
            unit: text('unit'),
            enlistment: text('enlistment'),
            hometown: text('hometown'),
            currentResidence: text('currentResidence'),
            educationLevel: text('educationLevel'),
            specialty: text('specialty'),
            schoolHistory: text('schoolHistory'),
            officerRating: text('officerRating'),
            fatherFullName: text('fatherFullName'),
            fatherBirthYear: year('fatherBirthYear'),
            fatherOccupation: text('fatherOccupation'),
            fatherHometown: text('fatherHometown'),
            fatherCurrentResidence: text('fatherCurrentResidence'),
            motherFullName: text('motherFullName'),
            motherBirthYear: year('motherBirthYear'),
            motherOccupation: text('motherOccupation'),
            motherHometown: text('motherHometown'),
            motherCurrentResidence: text('motherCurrentResidence'),
            aspiration1: text('aspiration1'),
            aspiration2: text('aspiration2'),
            aspiration3: text('aspiration3'),
            customFieldValues: customValues,
          ),
        );
      }
    });
    if (!mounted) return;
    setState(() => _saving = false);
    if (saved) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<AppRepository>();
    final groups = repo.groups;
    final selectedGroup = repo.groupById(_groupId ?? '');
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Sửa hồ sơ' : 'Thêm hồ sơ')),
      body: ResponsivePage(
        maxContentWidth: 720,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              Text('NHÓM CÔNG VIỆC', style: context.textTheme.labelLarge),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: groups.any((g) => g.id == _groupId)
                    ? _groupId
                    : null,
                decoration: const InputDecoration(
                  labelText: 'Nhóm công việc *',
                ),
                items: [
                  for (final g in groups)
                    DropdownMenuItem(value: g.id, child: Text(g.name)),
                ],
                onChanged: (v) => setState(() => _groupId = v),
                validator: (value) =>
                    value == null ? 'Vui lòng chọn nhóm công việc.' : null,
              ),
              ..._dynamicWidgets(selectedGroup, aspirationsOnly: false),
              ..._dynamicWidgets(selectedGroup, aspirationsOnly: true),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 4),
              Text('QUY TRÌNH XỬ LÝ', style: context.textTheme.labelLarge),
              if (_isEdit) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<ProfileStatus>(
                  initialValue: _status,
                  decoration: const InputDecoration(labelText: 'Trạng thái'),
                  items: [
                    for (final status in ProfileStatus.values)
                      DropdownMenuItem(
                        value: status,
                        child: Text(status.label),
                      ),
                  ],
                  onChanged: (value) =>
                      setState(() => _status = value ?? _status),
                ),
              ],
              if (_status == ProfileStatus.waiting) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 4),
                Text(
                  'Thông tin chờ phản hồi',
                  style: context.textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                WaitingReasonChips(
                  currentValue: _waitingReasonCtrl.text,
                  onSelected: (v) => setState(() {
                    _waitingReasonCtrl.text = v == 'Khác' ? '' : v;
                  }),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _waitingReasonCtrl,
                  decoration: const InputDecoration(labelText: 'Lý do chờ'),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () => _pickDate(
                    _waitingSince,
                    (d) => setState(() => _waitingSince = d),
                  ),
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Chờ từ ngày'),
                    child: Text(_waitingSince?.ddMMyyyy ?? 'Hôm nay'),
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () => _pickDate(
                    _expectedResponseDate,
                    (d) => setState(() => _expectedResponseDate = d),
                  ),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Dự kiến có phản hồi',
                      suffixIcon: _expectedResponseDate == null
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () =>
                                  setState(() => _expectedResponseDate = null),
                            ),
                    ),
                    child: Text(_expectedResponseDate?.ddMMyyyy ?? 'Chưa rõ'),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              InkWell(
                onTap: _pickStartDate,
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Ngày bắt đầu'),
                  child: Text(_startDate.ddMMyyyy),
                ),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Có hạn hoàn thành (deadline)'),
                value: _hasDeadline,
                onChanged: (v) => setState(() => _hasDeadline = v),
              ),
              if (_hasDeadline) ...[
                InkWell(
                  onTap: _pickDeadline,
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Hạn hoàn thành',
                      errorText: _deadlineError,
                    ),
                    child: Text(_deadline?.ddMMyyyy ?? 'Chọn ngày'),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 4),
              Text('TÀI CHÍNH', style: context.textTheme.labelLarge),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountCtrl,
                decoration: const InputDecoration(labelText: 'Tổng tiền (đ)'),
                keyboardType: TextInputType.number,
                validator: (v) =>
                    Validators.nonNegativeAmount(v, field: 'Tổng tiền'),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_isEdit ? 'Lưu thay đổi' : 'Tạo hồ sơ'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _dynamicWidgets(
    WorkGroup? group, {
    required bool aspirationsOnly,
  }) {
    if (group == null) return const [];
    final configs = group.effectiveFieldConfigs.where((c) {
      if (!c.enabled) return false;
      final isAspiration =
          ProfileFieldCatalog.byId(c.fieldId)?.isPinnedBottom == true;
      return aspirationsOnly == isAspiration;
    }).toList();
    configs.sort((a, b) {
      final da = ProfileFieldCatalog.byId(a.fieldId);
      final db = ProfileFieldCatalog.byId(b.fieldId);
      if (da?.isPinnedBottom == true && db?.isPinnedBottom != true) return 1;
      if (db?.isPinnedBottom == true && da?.isPinnedBottom != true) return -1;
      if (da?.isPinnedBottom == true) {
        return da!.pinnedOrder!.compareTo(db!.pinnedOrder!);
      }
      ProfileFieldSection section(ProfileFieldConfig config) =>
          ProfileFieldCatalog.byId(config.fieldId)?.section ??
          group.customFieldDefinitions
              .firstWhere((d) => d.id == config.fieldId)
              .section;
      final bySection = section(a).index.compareTo(section(b).index);
      return bySection != 0 ? bySection : a.order.compareTo(b.order);
    });
    final result = <Widget>[];
    ProfileFieldSection? section;
    for (final config in configs) {
      final built = ProfileFieldCatalog.byId(config.fieldId);
      CustomFieldDefinition? custom;
      for (final d in group.customFieldDefinitions) {
        if (d.id == config.fieldId) custom = d;
      }
      if (built == null && custom == null) continue;
      if (custom != null && !custom.active) continue;
      final currentSection = built?.section ?? custom!.section;
      if (section != currentSection) {
        section = currentSection;
        result.addAll([
          const SizedBox(height: 16),
          Text(switch (section) {
            ProfileFieldSection.subject => 'Thông tin đối tượng',
            ProfileFieldSection.family => 'Thông tin gia đình',
            ProfileFieldSection.workContent => 'Nội dung công việc',
            ProfileFieldSection.aspiration =>
              'Nguyện vọng — luôn ở cuối biểu mẫu',
          }, style: const TextStyle(fontWeight: FontWeight.bold)),
        ]);
      }
      final type = built?.type ?? custom!.type;
      final label =
          '${built?.labelVi ?? custom!.label}${config.required ? ' *' : ''}';
      final controller = _controllerFor(config.fieldId);
      String? validate(String? value) {
        if (config.required && (value == null || value.trim().isEmpty)) {
          return 'Vui lòng nhập ${built?.labelVi ?? custom!.label}.';
        }
        if (value == null || value.trim().isEmpty) return null;
        if (config.fieldId == 'fullName') return Validators.fullName(value);
        if (config.fieldId == 'phone') return Validators.phone(value);
        if (type == ProfileFieldType.number && num.tryParse(value) == null) {
          return 'Số không hợp lệ';
        }
        if (type == ProfileFieldType.year && int.tryParse(value) == null) {
          return 'Năm không hợp lệ';
        }
        if (type == ProfileFieldType.date) {
          final date = DateTime.tryParse(value);
          if (date == null) return 'Ngày không hợp lệ';
          if (config.fieldId == 'dateOfBirth' && date.isAfter(DateTime.now())) {
            return 'Ngày không được ở tương lai';
          }
        }
        return null;
      }

      Widget field;
      if (type == ProfileFieldType.boolean) {
        field = DropdownButtonFormField<String>(
          initialValue: controller.text.isEmpty ? null : controller.text,
          decoration: InputDecoration(labelText: label),
          items: const [
            DropdownMenuItem(value: 'true', child: Text('Có')),
            DropdownMenuItem(value: 'false', child: Text('Không')),
          ],
          onChanged: (value) => controller.text = value ?? '',
          validator: validate,
        );
      } else if (type == ProfileFieldType.singleSelect && custom != null) {
        final optionIds = custom.options.map((e) => e.id).toSet();
        field = DropdownButtonFormField<String>(
          initialValue: optionIds.contains(controller.text)
              ? controller.text
              : null,
          decoration: InputDecoration(labelText: label),
          items: [
            for (final option in custom.options.where(
              (o) => o.active || o.id == controller.text,
            ))
              DropdownMenuItem(
                value: option.id,
                child: Text(
                  option.active
                      ? option.label
                      : '${option.label} (Không còn sử dụng)',
                ),
              ),
          ],
          onChanged: (value) => controller.text = value ?? '',
          validator: validate,
        );
      } else if (type == ProfileFieldType.date) {
        field = TextFormField(
          controller: controller,
          readOnly: true,
          decoration: InputDecoration(
            labelText: label,
            suffixIcon: const Icon(Icons.calendar_today_outlined),
          ),
          onTap: () async {
            final initial = DateTime.tryParse(controller.text);
            await _pickDate(
              initial,
              (date) => setState(() {
                controller.text = date.toIso8601String().split('T').first;
              }),
            );
          },
          validator: validate,
        );
      } else {
        field = TextFormField(
          controller: controller,
          decoration: InputDecoration(labelText: label),
          maxLines: type == ProfileFieldType.multiline ? 3 : 1,
          keyboardType: switch (type) {
            ProfileFieldType.number ||
            ProfileFieldType.year => TextInputType.number,
            _ => TextInputType.text,
          },
          validator: validate,
        );
      }
      result.addAll([const SizedBox(height: 12), field]);
    }
    return result;
  }

  TextEditingController _controllerFor(String fieldId) => switch (fieldId) {
    'fullName' => _nameCtrl,
    'phone' => _phoneCtrl,
    'workTarget' => _workTargetCtrl,
    'description' => _descCtrl,
    'note' => _noteCtrl,
    _ => _dynamicCtrls.putIfAbsent(
      fieldId,
      () => TextEditingController(
        text: widget.profile?.customFieldValues[fieldId]?.toString() ?? '',
      ),
    ),
  };
}
