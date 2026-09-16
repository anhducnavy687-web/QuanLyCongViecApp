import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/extensions/context_extensions.dart';
import '../../core/extensions/datetime_extensions.dart';
import '../../core/responsive/responsive.dart';
import '../../core/utils/validators.dart';
import '../../models/models.dart';
import '../../repositories/app_repository.dart';
import '../../widgets/waiting_reason_chips.dart';

/// Form Thêm/Sửa việc cần làm gắn với một hồ sơ. Khi trạng thái là
/// "Đang chờ" (waiting), hiển thị thêm các trường lý do chờ / chờ từ ngày /
/// ngày dự kiến có phản hồi — cùng cấu trúc dữ liệu waiting như [Profile].
class AddEditTaskScreen extends StatefulWidget {
  final String profileId;
  final TaskItem? task;

  const AddEditTaskScreen({super.key, required this.profileId, this.task});

  @override
  State<AddEditTaskScreen> createState() => _AddEditTaskScreenState();
}

class _AddEditTaskScreenState extends State<AddEditTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _noteCtrl;
  late final TextEditingController _waitingReasonCtrl;

  late TaskStatus _status;
  late TaskPriority _priority;
  DateTime? _dueDate;
  DateTime? _waitingSince;
  DateTime? _expectedResponseDate;
  bool _saving = false;

  bool get _isEdit => widget.task != null;

  @override
  void initState() {
    super.initState();
    final t = widget.task;
    _titleCtrl = TextEditingController(text: t?.title ?? '');
    _descCtrl = TextEditingController(text: t?.description ?? '');
    _noteCtrl = TextEditingController(text: t?.note ?? '');
    _waitingReasonCtrl = TextEditingController(text: t?.waitingReason ?? '');
    _status = t?.status ?? TaskStatus.todo;
    _priority = t?.priority ?? TaskPriority.normal;
    _dueDate = t?.dueDate;
    _waitingSince = t?.waitingSince;
    _expectedResponseDate = t?.expectedResponseDate;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _noteCtrl.dispose();
    _waitingReasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(
    DateTime? initial,
    ValueChanged<DateTime> onPicked,
  ) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) onPicked(picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final repo = context.read<AppRepository>();
    final now = DateTime.now();

    if (_status == TaskStatus.waiting) {
      _waitingSince ??= now;
    }

    if (_isEdit) {
      await repo.updateTask(
        widget.task!.copyWith(
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          status: _status,
          priority: _priority,
          dueDate: _dueDate,
          clearDueDate: _dueDate == null,
          waitingReason: _status == TaskStatus.waiting
              ? _waitingReasonCtrl.text.trim()
              : null,
          clearWaitingReason: _status != TaskStatus.waiting,
          waitingSince: _status == TaskStatus.waiting ? _waitingSince : null,
          clearWaitingSince: _status != TaskStatus.waiting,
          expectedResponseDate: _status == TaskStatus.waiting
              ? _expectedResponseDate
              : null,
          clearExpectedResponseDate: _status != TaskStatus.waiting,
          completedAt: _status == TaskStatus.completed ? now : null,
          clearCompletedAt: _status != TaskStatus.completed,
          note: _noteCtrl.text.trim(),
        ),
      );
    } else {
      await repo.addTask(
        TaskItem(
          id: '',
          profileId: widget.profileId,
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          status: _status,
          priority: _priority,
          dueDate: _dueDate,
          waitingReason: _status == TaskStatus.waiting
              ? _waitingReasonCtrl.text.trim()
              : null,
          waitingSince: _status == TaskStatus.waiting
              ? (_waitingSince ?? now)
              : null,
          expectedResponseDate: _status == TaskStatus.waiting
              ? _expectedResponseDate
              : null,
          createdAt: now,
          updatedAt: now,
          note: _noteCtrl.text.trim(),
        ),
      );
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Sửa việc cần làm' : 'Thêm việc cần làm'),
      ),
      body: ResponsivePage(
        maxContentWidth: 720,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(labelText: 'Tên việc *'),
                validator: (v) => Validators.required(v, field: 'Tên việc'),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(labelText: 'Mô tả'),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<TaskStatus>(
                initialValue: _status,
                decoration: const InputDecoration(labelText: 'Trạng thái'),
                items: [
                  for (final s in TaskStatus.values)
                    DropdownMenuItem(value: s, child: Text(s.label)),
                ],
                onChanged: (v) => setState(() => _status = v ?? _status),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<TaskPriority>(
                initialValue: _priority,
                decoration: const InputDecoration(labelText: 'Độ ưu tiên'),
                items: [
                  for (final p in TaskPriority.values)
                    DropdownMenuItem(value: p, child: Text(p.label)),
                ],
                onChanged: (v) => setState(() => _priority = v ?? _priority),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () =>
                    _pickDate(_dueDate, (d) => setState(() => _dueDate = d)),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Hạn xử lý',
                    suffixIcon: _dueDate == null
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () => setState(() => _dueDate = null),
                          ),
                  ),
                  child: Text(_dueDate?.ddMMyyyy ?? 'Không có hạn'),
                ),
              ),
              if (_status == TaskStatus.waiting) ...[
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
              const SizedBox(height: 12),
              TextFormField(
                controller: _noteCtrl,
                decoration: const InputDecoration(labelText: 'Ghi chú'),
                maxLines: 3,
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
                    : Text(_isEdit ? 'Lưu thay đổi' : 'Tạo việc'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
