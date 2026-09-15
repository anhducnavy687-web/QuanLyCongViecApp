import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Theo dõi trạng thái kết nối mạng để hiển thị banner Offline và quyết
/// định khi nào đồng bộ lại dữ liệu với Firebase.
class ConnectivityService extends ChangeNotifier {
  bool _isOnline = true;
  StreamSubscription<List<ConnectivityResult>>? _sub;

  bool get isOnline => _isOnline;

  Future<void> init() async {
    try {
      final result = await Connectivity().checkConnectivity();
      _isOnline = _fromResults(result);
      _sub = Connectivity().onConnectivityChanged.listen((results) {
        final online = _fromResults(results);
        if (online != _isOnline) {
          _isOnline = online;
          notifyListeners();
        }
      });
    } catch (_) {
      // Nếu plugin không khả dụng (VD: môi trường test), coi như online để
      // không chặn luồng sử dụng chính của app.
      _isOnline = true;
    }
  }

  bool _fromResults(List<ConnectivityResult> results) {
    if (results.isEmpty) return false;
    return results.any((r) => r != ConnectivityResult.none);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
