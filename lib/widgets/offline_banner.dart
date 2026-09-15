import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/connectivity_service.dart';

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final isOnline = context.watch<ConnectivityService>().isOnline;
    if (isOnline) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      color: Colors.orange.shade700,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: const Row(
        children: [
          Icon(Icons.cloud_off_rounded, size: 16, color: Colors.white),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Đang ngoại tuyến — dữ liệu sẽ tự đồng bộ khi có mạng trở lại.',
              style: TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
