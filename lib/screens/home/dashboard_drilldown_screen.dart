import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/responsive/responsive.dart';
import '../../core/utils/app_date_utils.dart';
import '../../models/models.dart';
import '../../repositories/app_repository.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/profile_card.dart';
import 'dashboard_bucket.dart';

class DashboardDrilldownScreen extends StatelessWidget {
  const DashboardDrilldownScreen({super.key, required this.bucket});

  final DashboardBucket bucket;

  @override
  Widget build(BuildContext context) {
    final snapshot = DashboardBuckets.fromAggregates(
      context.watch<AppRepository>().allAggregates,
    );
    final items = snapshot.items(bucket);

    return Scaffold(
      appBar: AppBar(title: Text(bucket.label)),
      body: ResponsivePage(
        child: items.isEmpty
            ? EmptyState(
                icon: Icons.inbox_outlined,
                title: bucket.emptyMessage,
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (_, index) {
                  final item = items[index];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ProfileCard(
                        aggregate: item,
                        showGroupLabel: true,
                        compact: true,
                      ),
                      if (bucket == DashboardBucket.waiting)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
                          child: Text(
                            _waitingDescription(item),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                    ],
                  );
                },
              ),
      ),
    );
  }

  String _waitingDescription(ProfileAggregate item) {
    final profile = item.profile;
    final parts = <String>[
      (profile.waitingReason?.isNotEmpty ?? false)
          ? profile.waitingReason!
          : 'Chưa rõ lý do',
      if (profile.waitingSince != null)
        'Đã chờ ${AppDateUtils.daysSince(profile.waitingSince!)} ngày',
      if (profile.expectedResponseDate != null)
        'Dự kiến ${AppDateUtils.formatDate(profile.expectedResponseDate!)}',
    ];
    return parts.join(' • ');
  }
}
