import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/models.dart';
import 'profile_smart_paste_parser.dart';

class ProfileSmartPasteSheet extends StatefulWidget {
  const ProfileSmartPasteSheet({super.key, required this.group});
  final WorkGroup group;

  @override
  State<ProfileSmartPasteSheet> createState() => _ProfileSmartPasteSheetState();
}

class _ProfileSmartPasteSheetState extends State<ProfileSmartPasteSheet> {
  final _controller = TextEditingController();
  SmartPasteResult? _result;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pasteClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (!mounted || data?.text == null) return;
    setState(() {
      _controller.text = data!.text!;
      _controller.selection = TextSelection.collapsed(
        offset: _controller.text.length,
      );
      _result = null;
    });
  }

  void _analyze() {
    FocusScope.of(context).unfocus();
    setState(() {
      _result = ProfileSmartPasteParser().parse(_controller.text, widget.group);
    });
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 10,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Dán thông tin hồ sơ',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
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
                  'Nhóm: ${widget.group.name}. Mỗi dòng nên có dạng “Tên trường: Giá trị”.',
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('smart-paste-input'),
                  controller: _controller,
                  minLines: 7,
                  maxLines: 12,
                  decoration: const InputDecoration(
                    hintText: 'Họ và tên: Nguyễn Văn A\nNgày sinh: 15/08/1990\nĐơn vị: ...',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) {
                    setState(() => _result = null);
                  },
                ),
                const SizedBox(height: 10),
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _pasteClipboard,
                      icon: const Icon(Icons.content_paste_rounded),
                      label: const Text('Dán từ Clipboard'),
                    ),
                    FilledButton.icon(
                      onPressed: _analyze,
                      icon: const Icon(Icons.manage_search_rounded),
                      label: const Text('Phân tích'),
                    ),
                  ],
                ),
                if (result != null) ...[
                  const SizedBox(height: 18),
                  Text(
                    'Kết quả xem trước',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  if (result.items.isEmpty)
                    const Text('Không tìm thấy dòng thông tin nào.'),
                  for (final item in result.items) _ResultTile(item: item),
                  const SizedBox(height: 12),
                  Text(
                    'Chỉ các dòng “Đã nhận diện” sẽ được điền. Dòng cần xem lại và chưa nhận diện được giữ nguyên ở đây.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    key: const Key('smart-paste-apply'),
                    onPressed: result.applicableValues.isEmpty
                        ? null
                        : () => Navigator.pop(context, result.applicableValues),
                    child: const Text('Áp dụng vào biểu mẫu'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultTile extends StatelessWidget {
  const _ResultTile({required this.item});
  final SmartPasteField item;

  @override
  Widget build(BuildContext context) {
    final (icon, color, status) = switch (item.status) {
      SmartPasteStatus.recognized => (
        Icons.check_circle_outline_rounded,
        Colors.green,
        'Đã nhận diện',
      ),
      SmartPasteStatus.review => (
        Icons.error_outline_rounded,
        Colors.orange,
        'Cần xem lại',
      ),
      SmartPasteStatus.unresolved => (
        Icons.help_outline_rounded,
        Colors.grey,
        'Chưa nhận diện',
      ),
    };
    return Card(
      margin: const EdgeInsets.only(top: 8),
      child: ListTile(
        dense: true,
        leading: Icon(icon, color: color),
        title: Text(
          item.fieldLabel == null
              ? item.sourceLabel
              : '${item.sourceLabel} → ${item.fieldLabel}',
        ),
        subtitle: Text(
          [
            '$status: ${item.rawValue.isEmpty ? '(trống)' : item.rawValue}',
            if (item.message != null) item.message!,
          ].join('\n'),
        ),
      ),
    );
  }
}
