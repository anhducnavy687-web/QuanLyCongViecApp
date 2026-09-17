import '../../core/utils/repository_action.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/extensions/context_extensions.dart';
import '../../core/utils/validators.dart';
import '../../models/models.dart';
import '../../repositories/app_repository.dart';

class AddEditCollaboratorSheet extends StatefulWidget {
  final Collaborator? collaborator;
  const AddEditCollaboratorSheet({super.key, this.collaborator});

  @override
  State<AddEditCollaboratorSheet> createState() =>
      _AddEditCollaboratorSheetState();
}

class _AddEditCollaboratorSheetState extends State<AddEditCollaboratorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _noteCtrl;
  late bool _active;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.collaborator?.name ?? '');
    _phoneCtrl = TextEditingController(text: widget.collaborator?.phone ?? '');
    _noteCtrl = TextEditingController(text: widget.collaborator?.note ?? '');
    _active = widget.collaborator?.active ?? true;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final repo = context.read<AppRepository>();
    final saved = await runRepositoryAction(context, () async {
      if (widget.collaborator == null) {
        await repo.addCollaborator(
          name: _nameCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
          note: _noteCtrl.text.trim(),
        );
      } else {
        await repo.updateCollaborator(
          widget.collaborator!.copyWith(
            name: _nameCtrl.text.trim(),
            phone: _phoneCtrl.text.trim(),
            note: _noteCtrl.text.trim(),
            active: _active,
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
    final isEdit = widget.collaborator != null;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  isEdit ? 'Sửa cộng tác viên' : 'Thêm cộng tác viên',
                  style: context.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'Họ tên'),
                  validator: (v) => Validators.required(v, field: 'Họ tên'),
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
                  controller: _noteCtrl,
                  decoration: const InputDecoration(labelText: 'Ghi chú'),
                  maxLines: 2,
                ),
                if (isEdit) ...[
                  const SizedBox(height: 4),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Đang hoạt động'),
                    value: _active,
                    onChanged: (v) => setState(() => _active = v),
                  ),
                ],
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Lưu'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
