// lib/providers/connectivity_provider.dart
// ═══════════════════════════════════════════════════════════
// CONNECTIVITY STATE — Drives offline banner + auto-sync
// ═══════════════════════════════════════════════════════════

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api/api_client.dart';

final connectivityProvider =
    StateNotifierProvider<ConnectivityNotifier, bool>((ref) {
  return ConnectivityNotifier();
});

class ConnectivityNotifier extends StateNotifier<bool> {
  StreamSubscription? _sub;

  /// State = true means online, false means offline
  ConnectivityNotifier() : super(true) {
    state = ApiClient.instance.isOnline;
    _sub = ApiClient.instance.onlineStream.listen((online) {
      state = online;
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

/// Quick read — no provider needed, just a simple getter
final isOnlineProvider = Provider<bool>((ref) {
  return ref.watch(connectivityProvider);
});

/// Offline queue count
final offlineQueueCountProvider = Provider<int>((ref) {
  ref.watch(connectivityProvider); // rebuild when connectivity changes
  return ApiClient.instance.offlineQueue.count;
});