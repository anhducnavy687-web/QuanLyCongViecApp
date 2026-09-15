import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/extensions/context_extensions.dart';
import '../../core/extensions/datetime_extensions.dart';
import '../../core/utils/validators.dart';
import '../../models/models.dart';
import '../../repositories/app_repository.dart';

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
    _amountCtrl = TextEditingController(text: p != null && p.totalAmount > 0 ? p.totalAmount.toStringAsFixed(0) : '');
    _noteCtrl = TextEditingController(text: p?.note ?? '');
    _waitingReasonCtrl = TextEditingController(text: p?.waitingReason ?? '');
    _groupId = p?.groupId ?? widget.initialGroupId;
    _startDate = p?.startDate ?? DateTime.now();
    _deadline = p?.deadline;
    _hasDeadline = p?.hasDeadline ?? false;
    _status = p?.status ?? ProfileStatus.newProfile;
    _waitingSince = p?.waitingSince;
    _expectedResponseDate = p?.expectedResponseDate;
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
    super.dispose();
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
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

  Future<void> _pickDate(DateTime? initial, ValueChanged<DateTime> onPicked) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime(2000),
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
      final err = Validators.deadlineNotBeforeStart(_startDate, _deadline);
      if (err != null) {
        setState(() => _deadlineError = err);
        return;
      }
    }

    setState(() => _saving = true);
    final repo = context.read<AppRepository>();
    final amount = num.tryParse(_amountCtrl.text.replaceAll('.', '').replaceAll(',', '')) ?? 0;
    final now = DateTime.now();
    final isWaiting = _status == ProfileStatus.waiting;
    if (isWaiting) {
      _waitingSince ??= now;
    }

    if (_isEdit) {
      await repo.updateProfile(widget.profile!.copyWith(
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
        completedAt: _status == ProfileStatus.completed ? now : null,
        clearCompletedAt: _status != ProfileStatus.completed,
        waitingReason: isWaiting ? _waitingReasonCtrl.text.trim() : null,
        clearWaitingReason: !isWaiting,
        waitingSince: isWaiting ? _waitingSince : null,
        clearWaitingSince: !isWaiting,
        expectedResponseDate: isWaiting ? _expectedResponseDate : null,
        clearExpectedResponseDate: !isWaiting,
      ));
    } else {
      await repo.addProfile(Profile(
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
        waitingReason: isWaiting ? _waitingReasonCtrl.text.trim() : null,
        waitingSince: isWaiting ? _waitingSince : null,
        expectedResponseDate: isWaiting ? _expectedResponseDate : null,
      ));
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<AppRepository>();
    final groups = repo.groups;

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Sửa hồ sơ' : 'Thêm hồ sơ')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Họ tên *'),
              validator: Validators.fullName,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneCtrl,
              decoration: const InputDecoration(labelText: 'Số điện thoại'),
              keyboardType: TextInputType.phone,
              validator: Validators.phone,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _workTargetCtrl,
              decoration: const InputDecoration(labelText: 'Đích công việc *'),
              validator: Validators.workTarget,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descCtrl,
              decoration: const InputDecoration(labelText: 'Mô tả'),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: groups.any((g) => g.id == _groupId) ? _groupId : null,
              decoration: const InputDecoration(labelText: 'Nhóm công việc *'),
              items: [for (final g in groups) DropdownMenuItem(value: g.id, child: Text(g.name))],
              onChanged: (v) => setState(() => _groupId = v),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<ProfileStatus>(
              initialValue: _status,
              decoration: const InputDecoration(labelText: 'Trạng thái'),
              items: [
                for (final s in ProfileStatus.values)
                  DropdownMenuItem(value: s, child: Text(s.label)),
              ],
              onChanged: (v) => setState(() => _status = v ?? _status),
            ),
            if (_status == ProfileStatus.waiting) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 4),
              Text('Thông tin chờ phản hồi', style: context.textTheme.labelLarge),
              const SizedBox(height: 12),
              TextFormField(
                controller: _waitingReasonCtrl,
                decoration: const InputDecoration(labelText: 'Lý do chờ'),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () => _pickDate(_waitingSince, (d) => setState(() => _waitingSince = d)),
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Chờ từ ngày'),
                  child: Text(_waitingSince?.ddMMyyyy ?? 'Hôm nay'),
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () =>
                    _pickDate(_expectedResponseDate, (d) => setState(() => _expectedResponseDate = d)),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Dự kiến có phản hồi',
                    suffixIcon: _expectedResponseDate == null
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () => setState(() => _expectedResponseDate = null),
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
            const SizedBox(height: 12),
            TextFormField(
              controller: _amountCtrl,
              decoration: const InputDecoration(labelText: 'Tổng tiền (đ)'),
              keyboardType: TextInputType.number,
              validator: (v) => Validators.nonNegativeAmount(v, field: 'Tổng tiền'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _noteCtrl,
              decoration: const InputDecoration(labelText: 'Ghi chú'),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
              child: _saving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(_isEdit ? 'Lưu thay đổi' : 'Tạo hồ sơ'),
            ),
          ],
        ),
      ),
    );
  }
}
