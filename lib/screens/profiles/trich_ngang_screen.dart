import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/extensions/context_extensions.dart';
import '../../core/utils/excerpt_builder.dart';
import '../../repositories/app_repository.dart';
import '../../services/file_service.dart';

/// Màn hình Trích ngang hồ sơ — sinh văn bản sạch để Sao chép / Chia sẻ.
class TrichNgangScreen extends StatefulWidget {
  final String profileId;
  const TrichNgangScreen({super.key, required this.profileId});

  @override
  State<TrichNgangScreen> createState() => _TrichNgangScreenState();
}

class _TrichNgangScreenState extends State<TrichNgangScreen> {
  bool _includeFinance = false;
  final _fileService = FileService();

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<AppRepository>();
    final aggregate = repo.aggregateOf(widget.profileId);
    final text = ExcerptBuilder.build(aggregate, includeFinance: _includeFinance);

    return Scaffold(
      appBar: AppBar(title: const Text('Trích ngang hồ sơ')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('Cơ bản')),
                ButtonSegment(value: true, label: Text('Đầy đủ (có tiền)')),
              ],
              selected: {_includeFinance},
              onSelectionChanged: (s) => setState(() => _includeFinance = s.first),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.colors.surfaceContainerHighest.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SelectableText(text, style: const TextStyle(fontSize: 13.5, height: 1.5)),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.copy_rounded),
                      label: const Text('Sao chép'),
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: text));
                        if (context.mounted) context.showSnackBar('Đã sao chép trích ngang');
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      icon: const Icon(Icons.share_rounded),
                      label: const Text('Chia sẻ'),
                      onPressed: () async {
                        try {
                          await _fileService.shareText(text);
                        } on FileServiceException catch (e) {
                          if (context.mounted) context.showSnackBar(e.message, isError: true);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
