import 'package:flutter/material.dart';

import '../../models/models.dart';

class ProfileFieldConfigResult {
  const ProfileFieldConfigResult(this.configs, this.customDefinitions);
  final List<ProfileFieldConfig> configs;
  final List<CustomFieldDefinition> customDefinitions;
}

class ProfileFieldConfigScreen extends StatefulWidget {
  const ProfileFieldConfigScreen({
    super.key,
    required this.initialConfigs,
    required this.initialCustomDefinitions,
  });
  final List<ProfileFieldConfig> initialConfigs;
  final List<CustomFieldDefinition> initialCustomDefinitions;

  @override
  State<ProfileFieldConfigScreen> createState() =>
      _ProfileFieldConfigScreenState();
}

class _ProfileFieldConfigScreenState extends State<ProfileFieldConfigScreen> {
  late List<ProfileFieldConfig> _configs;
  late List<CustomFieldDefinition> _definitions;
  final _ids = CustomFieldIdGenerator();

  @override
  void initState() {
    super.initState();
    _configs = List.of(widget.initialConfigs);
    _definitions = List.of(widget.initialCustomDefinitions);
  }

  ProfileFieldSection? _sectionOf(String id) {
    final builtIn = ProfileFieldCatalog.byId(id);
    if (builtIn != null) return builtIn.section;
    return _definitions.where((d) => d.id == id).firstOrNull?.section;
  }

  String _labelOf(String id) =>
      ProfileFieldCatalog.byId(id)?.labelVi ??
      _definitions.firstWhere((d) => d.id == id).label;

  List<ProfileFieldConfig> _active(ProfileFieldSection section) =>
      _configs
          .where(
            (c) =>
                c.enabled &&
                _sectionOf(c.fieldId) == section &&
                (_definitions
                        .where((d) => d.id == c.fieldId)
                        .firstOrNull
                        ?.active ??
                    true),
          )
          .toList()
        ..sort((a, b) => a.order.compareTo(b.order));

  void _replace(ProfileFieldConfig value) {
    final i = _configs.indexWhere((c) => c.fieldId == value.fieldId);
    if (i < 0) {
      _configs.add(value);
    } else {
      _configs[i] = value;
    }
  }

  void _normalize(ProfileFieldSection section) {
    final active = _active(section);
    for (var i = 0; i < active.length; i++) {
      _replace(active[i].copyWith(order: i));
    }
  }

  void _hide(ProfileFieldConfig config) {
    if (config.fieldId == 'fullName') return;
    setState(() {
      _replace(config.copyWith(enabled: false, required: false));
      final di = _definitions.indexWhere((d) => d.id == config.fieldId);
      if (di >= 0) {
        _definitions[di] = _definitions[di].copyWith(active: false);
      }
      _normalize(_sectionOf(config.fieldId)!);
    });
  }

  void _reorder(ProfileFieldSection section, int oldIndex, int newIndex) {
    setState(() {
      final fields = _active(section);
      fields.insert(newIndex, fields.removeAt(oldIndex));
      for (var i = 0; i < fields.length; i++) {
        _replace(fields[i].copyWith(order: i));
      }
    });
  }

  Future<void> _addFields() async {
    final inactive = ProfileFieldCatalog.definitions
        .where(
          (d) =>
              !d.isPinnedBottom &&
              !_configs.any((c) => c.fieldId == d.id && c.enabled),
        )
        .toList();
    final inactiveCustom = _definitions
        .where(
          (d) =>
              !d.active || !_configs.any((c) => c.fieldId == d.id && c.enabled),
        )
        .toList();
    final selected = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final picked = <String>[];
        return StatefulBuilder(
          builder: (context, update) => SafeArea(
            child: FractionallySizedBox(
              heightFactor: .85,
              child: Column(
                children: [
                  const ListTile(
                    title: Text('Thêm trường'),
                    subtitle: Text('Trường có sẵn chưa được sử dụng'),
                  ),
                  Expanded(
                    child: ListView(
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('TRƯỜNG CÓ SẴN'),
                        ),
                        for (final field in inactive)
                          CheckboxListTile(
                            title: Text(field.labelVi),
                            subtitle: Text(_sectionLabel(field.section)),
                            value: picked.contains(field.id),
                            onChanged: (value) => update(() {
                              if (value == true) {
                                picked.add(field.id);
                              } else {
                                picked.remove(field.id);
                              }
                            }),
                          ),
                        if (inactiveCustom.isNotEmpty) ...[
                          const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text('TRƯỜNG TÙY CHỈNH ĐÃ ẨN'),
                          ),
                          for (final field in inactiveCustom)
                            CheckboxListTile(
                              title: Text(field.label),
                              subtitle: Text(_sectionLabel(field.section)),
                              value: picked.contains(field.id),
                              onChanged: (value) => update(() {
                                if (value == true) {
                                  picked.add(field.id);
                                } else {
                                  picked.remove(field.id);
                                }
                              }),
                            ),
                        ],
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.add_circle_outline),
                          title: const Text('TẠO TRƯỜNG MỚI'),
                          subtitle: const Text(
                            'Tạo trường thông tin tùy chỉnh',
                          ),
                          onTap: () =>
                              Navigator.pop(context, const ['__custom__']),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: picked.isEmpty
                            ? null
                            : () => Navigator.pop(context, List.of(picked)),
                        child: const Text('Thêm trường đã chọn'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    if (!mounted || selected == null) return;
    if (selected.contains('__custom__')) {
      await _editCustom();
      return;
    }
    setState(() {
      for (final id in selected) {
        final section = _sectionOf(id)!;
        final nextOrder = _active(section).length;
        final old = _configs.where((c) => c.fieldId == id).firstOrNull;
        _replace(
          ProfileFieldConfig(
            fieldId: id,
            enabled: true,
            required: old?.required ?? false,
            order: nextOrder,
          ),
        );
        final definitionIndex = _definitions.indexWhere((d) => d.id == id);
        if (definitionIndex >= 0) {
          _definitions[definitionIndex] = _definitions[definitionIndex]
              .copyWith(active: true);
        }
      }
    });
  }

  Future<void> _editCustom([CustomFieldDefinition? existing]) async {
    final label = TextEditingController(text: existing?.label ?? '');
    var section = existing?.section ?? ProfileFieldSection.subject;
    var type = existing?.type ?? ProfileFieldType.text;
    var required = existing == null
        ? false
        : _configs.firstWhere((c) => c.fieldId == existing.id).required;
    var options = List<CustomFieldOption>.of(existing?.options ?? const []);
    String? error;
    final result = await showDialog<CustomFieldDefinition>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          title: Text(existing == null ? 'Tạo trường mới' : 'Chỉnh sửa trường'),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: label,
                    decoration: const InputDecoration(
                      labelText: 'Tên trường *',
                    ),
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
                    onChanged: existing == null
                        ? (v) => update(() => section = v!)
                        : null,
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
                    onChanged: existing == null
                        ? (v) => update(() => type = v!)
                        : null,
                  ),
                  if (existing != null)
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Text(
                        'Loại dữ liệu không thể thay đổi sau khi trường đã được tạo.',
                      ),
                    ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Bắt buộc'),
                    value: required,
                    onChanged: (v) => update(() => required = v),
                  ),
                  if (type == ProfileFieldType.singleSelect) ...[
                    const Divider(),
                    Row(
                      children: [
                        const Expanded(child: Text('Các lựa chọn')),
                        TextButton.icon(
                          onPressed: () async {
                            final value = await _optionLabelDialog(context);
                            if (value == null) return;
                            update(() {
                              options.add(
                                CustomFieldOption(
                                  id: _ids.nextOptionId(),
                                  label: value,
                                  order: options.length,
                                ),
                              );
                            });
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Thêm lựa chọn'),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: options.isEmpty ? 56 : 220,
                      child: options.isEmpty
                          ? const Center(child: Text('Chưa có lựa chọn'))
                          : ReorderableListView.builder(
                              itemCount: options.length,
                              onReorderItem: (oldIndex, newIndex) => update(() {
                                options.insert(
                                  newIndex,
                                  options.removeAt(oldIndex),
                                );
                                options = [
                                  for (var i = 0; i < options.length; i++)
                                    CustomFieldOption(
                                      id: options[i].id,
                                      label: options[i].label,
                                      active: options[i].active,
                                      order: i,
                                    ),
                                ];
                              }),
                              itemBuilder: (context, index) {
                                final option = options[index];
                                return ListTile(
                                  key: ValueKey(option.id),
                                  leading: const Icon(
                                    Icons.drag_handle,
                                    semanticLabel: 'Kéo để đổi thứ tự',
                                  ),
                                  title: Text(option.label),
                                  subtitle: option.active
                                      ? null
                                      : const Text('Không còn sử dụng'),
                                  onTap: () async {
                                    final value = await _optionLabelDialog(
                                      context,
                                      initial: option.label,
                                    );
                                    if (value == null) return;
                                    update(() {
                                      options[index] = CustomFieldOption(
                                        id: option.id,
                                        label: value,
                                        active: option.active,
                                        order: option.order,
                                      );
                                    });
                                  },
                                  trailing: Switch(
                                    value: option.active,
                                    onChanged: (value) => update(() {
                                      options[index] = CustomFieldOption(
                                        id: option.id,
                                        label: option.label,
                                        active: value,
                                        order: option.order,
                                      );
                                    }),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                  if (error != null)
                    Text(
                      error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                ],
              ),
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
                final activeLabels = options
                    .where((o) => o.active)
                    .map((o) => o.label.trim().toLowerCase())
                    .toList();
                if (name.isEmpty ||
                    (type == ProfileFieldType.singleSelect &&
                        (activeLabels.isEmpty ||
                            activeLabels.any((label) => label.isEmpty) ||
                            activeLabels.toSet().length !=
                                activeLabels.length))) {
                  update(
                    () => error = name.isEmpty ? 'Vui lòng nhập tên trường.' : 'Lựa chọn đang sử dụng không được trống hoặc trùng nhau.',
                  );
                  return;
                }
                Navigator.pop(
                  context,
                  CustomFieldDefinition(
                    id: existing?.id ?? _ids.nextFieldId(),
                    label: name,
                    section: section,
                    type: type,
                    options: options,
                    createdAt: existing?.createdAt ?? DateTime.now(),
                    active: true,
                  ),
                );
              },
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
    label.dispose();
    if (result == null || !mounted) return;
    setState(() {
      final i = _definitions.indexWhere((d) => d.id == result.id);
      if (i < 0) {
        _definitions.add(result);
        _configs.add(
          ProfileFieldConfig(
            fieldId: result.id,
            enabled: true,
            required: required,
            order: _active(result.section).length,
          ),
        );
      } else {
        _definitions[i] = result;
        final config = _configs.firstWhere((c) => c.fieldId == result.id);
        _replace(config.copyWith(enabled: true, required: required));
      }
    });
  }

  Future<void> _reset() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Khôi phục cấu hình mặc định?'),
        content: const Text(
          'Trường tùy chỉnh và dữ liệu hồ sơ vẫn được giữ lại nhưng sẽ bị ẩn.',
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
      _definitions = [for (final d in _definitions) d.copyWith(active: false)];
      _configs = [
        ...ProfileFieldCatalog.defaultConfigs(),
        for (var i = 0; i < _definitions.length; i++)
          ProfileFieldConfig(
            fieldId: _definitions[i].id,
            enabled: false,
            required: false,
            order: i,
          ),
      ];
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Cấu hình trường hồ sơ'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(
            context,
            ProfileFieldConfigResult(_configs, _definitions),
          ),
          child: const Text('Xong'),
        ),
      ],
    ),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        const Text('Chọn thông tin cần sử dụng cho hồ sơ thuộc nhóm này.'),
        const SizedBox(height: 4),
        const Text('Ấn giữ và kéo để thay đổi thứ tự.'),
        const SizedBox(height: 16),
        _section(ProfileFieldSection.subject, 'THÔNG TIN ĐỐI TƯỢNG'),
        _section(ProfileFieldSection.family, 'THÔNG TIN GIA ĐÌNH'),
        _section(ProfileFieldSection.workContent, 'NỘI DUNG CÔNG VIỆC'),
        _aspirations(),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _addFields,
          icon: const Icon(Icons.add),
          label: const Text('Thêm trường'),
        ),
        TextButton.icon(
          onPressed: _reset,
          icon: const Icon(Icons.restart_alt),
          label: const Text('Khôi phục cấu hình mặc định'),
        ),
      ],
    ),
  );

  Widget _section(ProfileFieldSection section, String title) {
    final fields = _active(section);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            if (fields.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Chưa có trường đang sử dụng.'),
              ),
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: fields.length,
              onReorderItem: (oldIndex, newIndex) =>
                  _reorder(section, oldIndex, newIndex),
              itemBuilder: (context, index) {
                final config = fields[index];
                final custom = _definitions
                    .where((d) => d.id == config.fieldId)
                    .firstOrNull;
                final locked = config.fieldId == 'fullName';
                return ListTile(
                  key: ValueKey(config.fieldId),
                  leading: const Tooltip(
                    message: 'Ấn giữ và kéo để đổi thứ tự',
                    child: Icon(Icons.drag_handle),
                  ),
                  title: Text(_labelOf(config.fieldId)),
                  subtitle: locked
                      ? const Text('Bắt buộc · Trường cốt lõi')
                      : CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          title: const Text('Bắt buộc'),
                          value: config.required,
                          onChanged: (value) => setState(
                            () => _replace(
                              config.copyWith(required: value ?? false),
                            ),
                          ),
                        ),
                  trailing: locked
                      ? const Icon(Icons.lock_outline)
                      : PopupMenuButton<String>(
                          tooltip: 'Tùy chọn trường',
                          onSelected: (value) {
                            if (value == 'hide') _hide(config);
                            if (value == 'edit' && custom != null) {
                              _editCustom(custom);
                            }
                          },
                          itemBuilder: (context) => [
                            if (custom != null)
                              const PopupMenuItem(
                                value: 'edit',
                                child: Text('Chỉnh sửa trường'),
                              ),
                            const PopupMenuItem(
                              value: 'hide',
                              child: Text('Ẩn trường'),
                            ),
                          ],
                        ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _aspirations() {
    final fields = ProfileFieldCatalog.definitions
        .where((d) => d.isPinnedBottom)
        .toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'NGUYỆN VỌNG',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Text('Nguyện vọng luôn được hiển thị ở cuối biểu mẫu.'),
            for (final field in fields)
              Builder(
                builder: (context) {
                  final config = _configs.firstWhere(
                    (c) => c.fieldId == field.id,
                  );
                  return SwitchListTile(
                    title: Text(field.labelVi),
                    subtitle: CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      title: const Text('Bắt buộc'),
                      value: config.required,
                      onChanged: config.enabled
                          ? (value) => setState(
                              () => _replace(
                                config.copyWith(required: value ?? false),
                              ),
                            )
                          : null,
                    ),
                    value: config.enabled,
                    onChanged: (value) => setState(
                      () => _replace(
                        config.copyWith(
                          enabled: value,
                          required: value ? config.required : false,
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  static Future<String?> _optionLabelDialog(
    BuildContext context, {
    String initial = '',
  }) async {
    final controller = TextEditingController(text: initial);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(initial.isEmpty ? 'Thêm lựa chọn' : 'Đổi tên lựa chọn'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Tên lựa chọn *'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isNotEmpty) Navigator.pop(context, value);
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  static String _sectionLabel(ProfileFieldSection section) => switch (section) {
    ProfileFieldSection.subject => 'Thông tin đối tượng',
    ProfileFieldSection.family => 'Thông tin gia đình',
    ProfileFieldSection.workContent => 'Nội dung công việc',
    ProfileFieldSection.aspiration => 'Nguyện vọng',
  };

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
