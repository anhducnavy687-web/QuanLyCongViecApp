import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/extensions/context_extensions.dart';
import '../core/extensions/datetime_extensions.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/money_utils.dart';
import '../models/models.dart';
import '../repositories/app_repository.dart';
import 'money_bar.dart';
import 'section_card.dart';

/// Khu vực tiền bạc trong trang chi tiết hồ sơ: tổng hợp tài chính + lịch
/// sử giao dịch. Toàn bộ số liệu tổng được TÍNH TỪ transaction, không dùng
/// số lưu sẵn nào khác — KHÔNG hiển thị phần trăm, KHÔNG gọi là "lợi nhuận".
class MoneySection extends StatelessWidget {
  final String profileId;
  const MoneySection({super.key, required this.profileId});

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<AppRepository>();
    final aggregate = repo.aggregateOf(profileId);
    final finance = aggregate.finance;
    final transactions = aggregate.transactions;

    return SectionCard(
      title: 'Tiền bạc',
      trailing: IconButton(
        icon: const Icon(Icons.add_rounded),
        onPressed: () => _showAddTransactionDialog(context, repo),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MoneyBar(received: finance.received, total: finance.totalAmount),
          const SizedBox(height: 14),
          _row('Tổng tiền', finance.totalAmount, Colors.grey.shade700),
          _row('Đã nhận', finance.received, AppColors.completed),
          _row('Còn phải nhận', finance.remainingToReceive, AppColors.overdue),
          const Divider(height: 20),
          _row('Chi phí', finance.expense, AppColors.stalled),
          _row('Hoa hồng cộng tác viên', finance.commissionTotal, AppColors.waiting),
          _row('Đã trả hoa hồng', finance.commissionPaid, AppColors.inProgress),
          _row('Còn phải trả hoa hồng', finance.commissionRemaining, AppColors.overdue),
          const SizedBox(height: 12),
          if (transactions.isNotEmpty) ...[
            Text('Lịch sử giao dịch', style: context.textTheme.labelLarge),
            const SizedBox(height: 4),
            ...transactions.map((t) => _TransactionTile(transaction: t)),
          ],
        ],
      ),
    );
  }

  Widget _row(String label, num value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13)),
          Text(
            MoneyUtils.format(value),
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }

  void _showAddTransactionDialog(BuildContext context, AppRepository repo) {
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    TransactionType type = TransactionType.received;
    DateTime date = DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Thêm giao dịch'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SegmentedButton<TransactionType>(
                  segments: const [
                    ButtonSegment(value: TransactionType.received, label: Text('Đã nhận')),
                    ButtonSegment(value: TransactionType.expense, label: Text('Chi phí')),
                  ],
                  selected: {type},
                  onSelectionChanged: (s) => setState(() => type = s.first),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Số tiền (đ)'),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: date,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) setState(() => date = picked);
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Ngày giao dịch'),
                    child: Text(date.ddMMyyyy),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteCtrl,
                  decoration: const InputDecoration(labelText: 'Ghi chú (không bắt buộc)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
            FilledButton(
              onPressed: () {
                final amount = num.tryParse(amountCtrl.text.replaceAll('.', '').replaceAll(',', ''));
                if (amount == null || amount < 0) {
                  context.showSnackBar('Số tiền không hợp lệ', isError: true);
                  return;
                }
                repo.addTransaction(MoneyTransaction(
                  id: '',
                  profileId: profileId,
                  type: type,
                  amount: amount,
                  date: date,
                  note: noteCtrl.text.trim(),
                  createdAt: DateTime.now(),
                ));
                Navigator.pop(ctx);
              },
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final MoneyTransaction transaction;
  const _TransactionTile({required this.transaction});

  (Color, IconData) get _style {
    switch (transaction.type) {
      case TransactionType.received:
        return (AppColors.completed, Icons.arrow_downward_rounded);
      case TransactionType.expense:
        return (AppColors.overdue, Icons.arrow_upward_rounded);
      case TransactionType.collaboratorPayment:
        return (AppColors.waiting, Icons.handshake_rounded);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (color, icon) = _style;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(transaction.type.label, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                if (transaction.note.isNotEmpty)
                  Text(
                    transaction.note,
                    style: TextStyle(fontSize: 11.5, color: context.colors.onSurfaceVariant),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                MoneyUtils.format(transaction.amount),
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: color),
              ),
              Text(transaction.date.ddMMyyyy, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
          PopupMenuButton<String>(
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.more_vert_rounded, size: 18),
            onSelected: (v) {
              if (v == 'delete') {
                context.read<AppRepository>().deleteTransaction(transaction.id);
              }
            },
            itemBuilder: (ctx) => const [
              PopupMenuItem(value: 'delete', child: Text('Xóa')),
            ],
          ),
        ],
      ),
    );
  }
}
