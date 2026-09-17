import '../../core/utils/repository_action.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/extensions/context_extensions.dart';
import '../../core/utils/validators.dart';
import '../../models/models.dart';
import '../../repositories/app_repository.dart';

/// Form thêm/sửa Nhóm công việc, hiển thị dạng bottom sheet.
class AddEditGroupSheet extends StatefulWidget {
  final WorkGroup? group;
  const AddEditGroupSheet({super.key, this.group});

  @override
  State<AddEditGroupSheet> createState() => _AddEditGroupSheetState();
}

class _AddEditGroupSheetState extends State<AddEditGroupSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.group?.name ?? '');
    _descCtrl = TextEditingController(text: widget.group?.description ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final repo = context.read<AppRepository>();
    final saved = await runRepositoryAction(context, () async {
      if (widget.group == null) {
        await repo.addGroup(
          name: _nameCtrl.text.trim(),
          description: _descCtrl.text.trim(),
        );
      } else {
        await repo.updateGroup(
          widget.group!.copyWith(
            name: _nameCtrl.text.trim(),
            description: _descCtrl.text.trim(),
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
    final isEdit = widget.group != null;
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
                  isEdit ? 'Sửa nhóm công việc' : 'Thêm nhóm công việc',
                  style: context.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'Tên nhóm'),
                  validator: Validators.required,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Mô tả (không bắt buộc)',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 20),
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
