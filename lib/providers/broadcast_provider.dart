import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/broadcast.dart';
import '../services/api/broadcast_api.dart';

class BroadcastListState {
  final List<Broadcast> broadcasts;
  final bool isLoading;
  final String? error;
  final String? statusFilter;

  const BroadcastListState({
    this.broadcasts = const [],
    this.isLoading = false,
    this.error,
    this.statusFilter,
  });

  BroadcastListState copyWith({
    List<Broadcast>? broadcasts,
    bool? isLoading,
    String? error,
    String? statusFilter,
    bool clearError = false,
    bool clearFilter = false,
  }) {
    return BroadcastListState(
      broadcasts: broadcasts ?? this.broadcasts,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      statusFilter:
          clearFilter ? null : (statusFilter ?? this.statusFilter),
    );
  }

  List<Broadcast> get filteredBroadcasts {
    if (statusFilter == null) return broadcasts;
    return broadcasts.where((b) => b.status == statusFilter).toList();
  }

  int get draftCount => broadcasts.where((b) => b.isDraft).length;
  int get scheduledCount => broadcasts.where((b) => b.isScheduled).length;
  int get sendingCount => broadcasts.where((b) => b.isSending).length;
  int get completedCount => broadcasts.where((b) => b.isCompleted).length;
}

final broadcastProvider =
    StateNotifierProvider<BroadcastNotifier, BroadcastListState>((ref) {
  return BroadcastNotifier();
});

class BroadcastNotifier extends StateNotifier<BroadcastListState> {
  final BroadcastApi _broadcastApi = BroadcastApi();

  BroadcastNotifier() : super(const BroadcastListState());

  Future<void> loadBroadcasts({bool refresh = false}) async {
    if (state.isLoading && !refresh) return;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await _broadcastApi.getBroadcasts();
      final rawData = response.data;
      final List<dynamic> list = rawData is List
          ? rawData
          : (rawData['broadcasts'] ?? rawData['data'] ?? []);

      final broadcasts =
          list.map((j) => Broadcast.fromJson(j)).toList();

      broadcasts.sort(
          (a, b) => (b.createdAt ?? '').compareTo(a.createdAt ?? ''));

      state = state.copyWith(
        broadcasts: broadcasts,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<String?> createBroadcast(Map<String, dynamic> data) async {
    try {
      final response = await _broadcastApi.createBroadcast(data);
      final respData = response.data as Map<String, dynamic>;
      await loadBroadcasts(refresh: true);
      return respData['broadcast_id'] as String?;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  Future<bool> startBroadcast(String id) async {
    try {
      await _broadcastApi.startBroadcast(id);
      final updated = state.broadcasts.map((b) {
        if (b.broadcastId == id) return b.copyWith(status: 'sending');
        return b;
      }).toList();
      state = state.copyWith(broadcasts: updated);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> cancelBroadcast(String id) async {
    try {
      await _broadcastApi.cancelBroadcast(id);
      final updated = state.broadcasts.map((b) {
        if (b.broadcastId == id) return b.copyWith(status: 'cancelled');
        return b;
      }).toList();
      state = state.copyWith(broadcasts: updated);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<Broadcast?> getBroadcastDetails(String id) async {
    try {
      final response = await _broadcastApi.getBroadcast(id);
      final data = response.data as Map<String, dynamic>;
      return Broadcast.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  void setStatusFilter(String? status) {
    if (status == null) {
      state = state.copyWith(clearFilter: true);
    } else {
      state = state.copyWith(statusFilter: status);
    }
  }
}