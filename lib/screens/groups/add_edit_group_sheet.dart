import '../../core/utils/repository_action.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/extensions/context_extensions.dart';
import '../../core/utils/validators.dart';
import '../../models/models.dart';
import '../../repositories/app_repository.dart';
import 'profile_field_config_screen.dart';

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
  late List<ProfileFieldConfig> _configs;
  late List<CustomFieldDefinition> _customDefinitions;
  bool get _showLegacyInlineEditor => false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.group?.name ?? '');
    _descCtrl = TextEditingController(text: widget.group?.description ?? '');
    _configs = List.of(
      widget.group?.effectiveFieldConfigs ??
          ProfileFieldCatalog.defaultConfigs(),
    );
    _customDefinitions = List.of(
      widget.group?.customFieldDefinitions ?? const [],
    );
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
        final unchangedDefaults =
            _customDefinitions.isEmpty &&
            _configs.map((e) => e.toJson().toString()).join() ==
                ProfileFieldCatalog.defaultConfigs()
                    .map((e) => e.toJson().toString())
                    .join();
        if (unchangedDefaults) {
          await repo.addGroup(
            name: _nameCtrl.text.trim(),
            description: _descCtrl.text.trim(),
          );
        } else {
          await repo.addGroupConfigured(
            name: _nameCtrl.text.trim(),
            description: _descCtrl.text.trim(),
            profileFieldConfigs: _configs,
            customFieldDefinitions: _customDefinitions,
          );
        }
      } else {
        await repo.updateGroup(
          widget.group!.copyWith(
            name: _nameCtrl.text.trim(),
            description: _descCtrl.text.trim(),
            profileFieldSchemaVersion: 2,
            profileFieldConfigs: _configs,
            customFieldDefinitions: _customDefinitions,
          ),
        );
      }
    });
    if (!mounted) return;
    setState(() => _saving = false);
    if (saved) Navigator.pop(context);
  }

  Future<void> _openFieldConfiguration() async {
    final result = await Navigator.of(context).push<ProfileFieldConfigResult>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => ProfileFieldConfigScreen(
          initialConfigs: _configs,
          initialCustomDefinitions: _customDefinitions,
        ),
      ),
    );
    if (!mounted || result == null) return;
    setState(() {
      _configs = List.of(result.configs);
      _customDefinitions = List.of(result.customDefinitions);
    });
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
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CẤU HÌNH THÔNG TIN HỒ SƠ',
                          style: context.textTheme.labelLarge,
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Cấu hình các trường sẽ xuất hiện khi tạo hồ sơ thuộc nhóm này.',
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${_configs.where((c) => c.enabled).length} trường đang sử dụng · '
                          '${_configs.where((c) => c.enabled && c.required).length} trường bắt buộc',
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: _openFieldConfiguration,
                          icon: const Icon(Icons.tune),
                          label: const Text('Cấu hình trường thông tin'),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_showLegacyInlineEditor)
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: const Text('Cấu hình biểu mẫu hồ sơ'),
                    subtitle: const Text(
                      'Bật, đặt bắt buộc và kéo để đổi thứ tự',
                    ),
                    children: [
                      SizedBox(
                        height: 300,
                        child: ReorderableListView.builder(
                          itemCount: _normalConfigs.length,
                          onReorderItem: _reorder,
                          itemBuilder: (context, index) {
                            final config = _normalConfigs[index];
                            final definition = ProfileFieldCatalog.byId(
                              config.fieldId,
                            );
                            final custom = _customDefinitions
                                .where((d) => d.id == config.fieldId)
                                .firstOrNull;
                            return ListTile(
                              key: ValueKey(config.fieldId),
                              title: Text(definition?.labelVi ?? custom!.label),
                              leading: const Icon(Icons.drag_handle),
                              trailing: Switch(
                                value: config.enabled,
                                onChanged: config.fieldId == 'fullName'
                                    ? null
                                    : (value) => _update(
                                        config,
                                        enabled: value,
                                        required: value
                                            ? config.required
                                            : false,
                                      ),
                              ),
                              subtitle: CheckboxListTile(
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                                title: const Text('Bắt buộc'),
                                value: config.required,
                                onChanged:
                                    !config.enabled ||
                                        config.fieldId == 'fullName'
                                    ? null
                                    : (value) => _update(
                                        config,
                                        required: value ?? false,
                                      ),
                              ),
                            );
                          },
                        ),
                      ),
                      const ListTile(
                        leading: Icon(Icons.push_pin_outlined),
                        title: Text('Nguyện vọng — luôn ở cuối biểu mẫu'),
                      ),
                      for (final config in _aspirationConfigs)
                        SwitchListTile(
                          title: Text(
                            ProfileFieldCatalog.byId(config.fieldId)!.labelVi,
                          ),
                          subtitle: CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            title: const Text('Bắt buộc'),
                            value: config.required,
                            onChanged: config.enabled
                                ? (value) =>
                                      _update(config, required: value ?? false)
                                : null,
                          ),
                          value: config.enabled,
                          onChanged: (value) => _update(
                            config,
                            enabled: value,
                            required: value ? config.required : false,
                          ),
                        ),
                      const Divider(),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: _showAddCustomField,
                          icon: const Icon(Icons.add),
                          label: const Text('Thêm trường thông tin'),
                        ),
                      ),
                      if (_customDefinitions.isNotEmpty)
                        for (final definition in _customDefinitions)
                          SwitchListTile(
                            title: Text(definition.label),
                            subtitle: Text(
                              '${_typeLabel(definition.type)} · ID cố định: ${definition.id}',
                            ),
                            value: definition.active,
                            onChanged: (value) => setState(() {
                              final i = _customDefinitions.indexOf(definition);
                              _customDefinitions[i] = definition.copyWith(
                                active: value,
                              );
                              final ci = _configs.indexWhere(
                                (c) => c.fieldId == definition.id,
                              );
                              if (ci >= 0) {
                                _configs[ci] = _configs[ci].copyWith(
                                  enabled: value,
                                  required: value
                                      ? _configs[ci].required
                                      : false,
                                );
                              }
                            }),
                          ),
                      TextButton.icon(
                        onPressed: _confirmReset,
                        icon: const Icon(Icons.restart_alt),
                        label: const Text('Khôi phục cấu hình mặc định'),
                      ),
                    ],
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

  List<ProfileFieldConfig> get _normalConfigs =>
      _configs
          .where(
            (c) => ProfileFieldCatalog.byId(c.fieldId)?.isPinnedBottom != true,
          )
          .toList()
        ..sort((a, b) => a.order.compareTo(b.order));

  List<ProfileFieldConfig> get _aspirationConfigs =>
      _configs
          .where(
            (c) => ProfileFieldCatalog.byId(c.fieldId)?.isPinnedBottom == true,
          )
          .toList()
        ..sort(
          (a, b) =>
              ProfileFieldCatalog.byId(a.fieldId)!.pinnedOrder!
                  .compareTo(ProfileFieldCatalog.byId(b.fieldId)!.pinnedOrder!),
        );

  void _update(ProfileFieldConfig current, {bool? enabled, bool? required}) {
    setState(() {
      final index = _configs.indexWhere((e) => e.fieldId == current.fieldId);
      _configs[index] = current.copyWith(enabled: enabled, required: required);
    });
  }

  void _reorder(int oldIndex, int newIndex) {
    setState(() {
      final ordered = _normalConfigs;
      if (newIndex > oldIndex) newIndex--;
      ordered.insert(newIndex, ordered.removeAt(oldIndex));
      for (var i = 0; i < ordered.length; i++) {
        final index = _configs.indexWhere(
          (e) => e.fieldId == ordered[i].fieldId,
        );
        _configs[index] = ordered[i].copyWith(order: i);
      }
    });
  }

  Future<void> _confirmReset() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Khôi phục cấu hình mặc định?'),
        content: const Text(
          'Các trường có sẵn sẽ trở về cấu hình mặc định. Trường tùy chỉnh và dữ liệu hồ sơ vẫn được giữ lại.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Khôi phục'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _configs = [
        ...ProfileFieldCatalog.defaultConfigs(),
        for (final definition in _customDefinitions)
          ProfileFieldConfig(
            fieldId: definition.id,
            enabled: false,
            required: false,
            order: 1000 + _customDefinitions.indexOf(definition),
          ),
      ];
    });
  }

  Future<void> _showAddCustomField() async {
    final label = TextEditingController();
    final options = TextEditingController();
    var section = ProfileFieldSection.subject;
    var type = ProfileFieldType.text;
    var required = false;
    final created = await showDialog<CustomFieldDefinition>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, updateDialog) => AlertDialog(
          title: const Text('Thêm trường thông tin'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: label,
                  decoration: const InputDecoration(labelText: 'Tên trường *'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<ProfileFieldSection>(
                  initialValue: section,
                  decoration: const InputDecoration(labelText: 'Nhóm *'),
                  items: const [
                    DropdownMenuItem(
                      value: ProfileFieldSection.subject,
                      child: Text('Thông tin đối tượng'),
                    ),
                    DropdownMenuItem(
                      value: ProfileFieldSection.workContent,
                      child: Text('Nội dung công việc'),
                    ),
                  ],
                  onChanged: (v) => updateDialog(() => section = v!),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<ProfileFieldType>(
                  initialValue: type,
                  decoration: const InputDecoration(
                    labelText: 'Loại dữ liệu *',
                  ),
                  items: [
                    for (final value in ProfileFieldType.values)
                      DropdownMenuItem(
                        value: value,
                        child: Text(_typeLabel(value)),
                      ),
                  ],
                  onChanged: (v) => updateDialog(() => type = v!),
                ),
                if (type == ProfileFieldType.singleSelect) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: options,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Các lựa chọn *',
                      helperText: 'Mỗi dòng là một lựa chọn',
                    ),
                  ),
                ],
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Bắt buộc'),
                  value: required,
                  onChanged: (v) => updateDialog(() => required = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () {
                final name = label.text.trim();
                final labels = options.text
                    .split(RegExp(r'[\r\n]+'))
                    .map((e) => e.trim())
                    .where((e) => e.isNotEmpty)
                    .toList();
                final normalized = labels.map((e) => e.toLowerCase()).toSet();
                if (name.isEmpty ||
                    (type == ProfileFieldType.singleSelect &&
                        (labels.isEmpty ||
                            normalized.length != labels.length))) {
                  return;
                }
                final stamp = DateTime.now().microsecondsSinceEpoch;
                Navigator.pop(
                  context,
                  CustomFieldDefinition(
                    id: 'custom_$stamp',
                    label: name,
                    section: section,
                    type: type,
                    options: [
                      for (var i = 0; i < labels.length; i++)
                        CustomFieldOption(
                          id: 'option_${stamp}_$i',
                          label: labels[i],
                          order: i,
                        ),
                    ],
                    createdAt: DateTime.now(),
                  ),
                );
              },
              child: const Text('Thêm'),
            ),
          ],
        ),
      ),
    );
    label.dispose();
    options.dispose();
    if (created == null || !mounted) return;
    setState(() {
      _customDefinitions.add(created);
      final sectionOrders = _configs
          .where((c) {
            final b = ProfileFieldCatalog.byId(c.fieldId);
            final d = _customDefinitions
                .where((e) => e.id == c.fieldId)
                .firstOrNull;
            return (b?.section ?? d?.section) == created.section;
          })
          .map((e) => e.order);
      final order = sectionOrders.isEmpty
          ? 0
          : sectionOrders.reduce((a, b) => a > b ? a : b) + 1;
      _configs.add(
        ProfileFieldConfig(
          fieldId: created.id,
          enabled: true,
          required: required,
          order: order,
        ),
      );
    });
  }

  static String _typeLabel(ProfileFieldType type) => switch (type) {
    ProfileFieldType.text => 'Văn bản',
    ProfileFieldType.multiline => 'Văn bản nhiều dòng',
    ProfileFieldType.number => 'Số',
    ProfileFieldType.date => 'Ngày tháng',
    ProfileFieldType.year => 'Năm',
    ProfileFieldType.boolean => 'Có / Không',
    ProfileFieldType.singleSelect => 'Danh sách lựa chọn',
  };
}
