import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/models.dart';
import 'group_profile_template_builder.dart';

class GroupInformationTemplateSheet extends StatefulWidget {
  const GroupInformationTemplateSheet({super.key, required this.group});

  final WorkGroup group;

  @override
  State<GroupInformationTemplateSheet> createState() =>
      _GroupInformationTemplateSheetState();
}

class _GroupInformationTemplateSheetState
    extends State<GroupInformationTemplateSheet> {
  static const _builder = GroupProfileTemplateBuilder();
  var _mode = GroupProfileTemplateMode.allEnabled;

  String get _template => _builder.build(widget.group, mode: _mode);

  Future<void> _copy() async {
    final template = _template;
    if (template.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: template));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Đã sao chép mẫu thông tin')));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final template = _template;
    final height = (MediaQuery.sizeOf(context).height * .88)
        .clamp(360.0, 680.0)
        .toDouble();

    return SafeArea(
      child: SizedBox(
        height: height,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Mẫu thu thập thông tin',
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Đóng',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              RadioGroup<GroupProfileTemplateMode>(
                groupValue: _mode,
                onChanged: (value) {
                  if (value != null) setState(() => _mode = value);
                },
                child: const Column(
                  children: [
                    RadioListTile<GroupProfileTemplateMode>(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      title: Text('Tất cả trường đang bật'),
                      value: GroupProfileTemplateMode.allEnabled,
                    ),
                    RadioListTile<GroupProfileTemplateMode>(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      title: Text('Chỉ trường bắt buộc'),
                      value: GroupProfileTemplateMode.requiredOnly,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text('Xem trước', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colors.outlineVariant),
                  ),
                  child: template.isEmpty
                      ? Center(
                          child: Text(
                            'Không có trường thông tin để tạo mẫu.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        )
                      : SingleChildScrollView(
                          child: SelectableText(
                            template,
                            key: const ValueKey('group-template-preview'),
                            style: theme.textTheme.bodyLarge?.copyWith(
                              height: 1.5,
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Đóng'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: template.isEmpty ? null : _copy,
                      icon: const Icon(Icons.content_copy_rounded),
                      label: const Text('Sao chép'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
