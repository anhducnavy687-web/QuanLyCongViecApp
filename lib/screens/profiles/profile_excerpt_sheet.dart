import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/models.dart';
import '../groups/group_profile_template_builder.dart';
import '../../core/utils/profile_information_text_builder.dart';

class ProfileExcerptSheet extends StatefulWidget {
  const ProfileExcerptSheet({
    super.key,
    required this.profile,
    required this.group,
  });

  final Profile profile;
  final WorkGroup group;

  @override
  State<ProfileExcerptSheet> createState() => _ProfileExcerptSheetState();
}

class _ProfileExcerptSheetState extends State<ProfileExcerptSheet> {
  static const _builder = ProfileInformationTextBuilder();
  var _mode = GroupProfileTemplateMode.allEnabled;
  var _copying = false;

  String get _text => _builder.build(widget.group, widget.profile, mode: _mode);

  Future<void> _copy() async {
    final value = _text;
    if (value.isEmpty || _copying) return;
    setState(() => _copying = true);
    try {
      await Clipboard.setData(ClipboardData(text: value));
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã sao chép trích ngang')));
    } finally {
      if (mounted) setState(() => _copying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final text = _text;
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
                      'Trích ngang',
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
              Text(
                'Tạo nội dung để gửi qua tin nhắn',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
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
                  child: text.isEmpty
                      ? Center(
                          child: Text(
                            'Không có trường thông tin để xuất.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        )
                      : SingleChildScrollView(
                          child: SelectableText(
                            text,
                            key: const ValueKey('profile-excerpt-preview'),
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
                      onPressed: text.isEmpty || _copying ? null : _copy,
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
