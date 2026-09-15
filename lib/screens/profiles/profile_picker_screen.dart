import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../repositories/app_repository.dart';
import '../../widgets/empty_state.dart';

/// Màn hình chọn nhanh một hồ sơ — dùng khi thao tác (ví dụ tạo việc cần
/// làm, thêm giao dịch) được bắt đầu từ Quick Action mà chưa có sẵn hồ sơ
/// đang xem. Trả về `profileId` đã chọn qua [Navigator.pop].
class ProfilePickerScreen extends StatefulWidget {
  const ProfilePickerScreen({super.key});

  @override
  State<ProfilePickerScreen> createState() => _ProfilePickerScreenState();
}

class _ProfilePickerScreenState extends State<ProfilePickerScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<AppRepository>();
    final profiles = repo.profiles.where((p) {
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return p.fullName.toLowerCase().contains(q) ||
          p.phone.toLowerCase().contains(q) ||
          p.workTarget.toLowerCase().contains(q);
    }).toList()
      ..sort((a, b) => a.fullName.compareTo(b.fullName));

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Tìm hồ sơ...',
            border: InputBorder.none,
          ),
          onChanged: (v) => setState(() => _query = v),
        ),
      ),
      body: profiles.isEmpty
          ? const EmptyState(icon: Icons.person_search_rounded, title: 'Không tìm thấy hồ sơ phù hợp')
          : ListView.builder(
              itemCount: profiles.length,
              itemBuilder: (context, i) {
                final p = profiles[i];
                return ListTile(
                  title: Text(p.fullName),
                  subtitle: Text(p.workTarget, maxLines: 1, overflow: TextOverflow.ellipsis),
                  onTap: () => Navigator.pop(context, p.id),
                );
              },
            ),
    );
  }
}
