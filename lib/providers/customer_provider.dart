import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/customer.dart';
import '../services/api/chat_api.dart';

// ── Single customer detail (family by phone) ──
class CustomerState {
  final Customer? customer;
  final bool isLoading;
  final String? error;

  const CustomerState({this.customer, this.isLoading = false, this.error});

  CustomerState copyWith({
    Customer? customer,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return CustomerState(
      customer: customer ?? this.customer,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

final customerProvider = StateNotifierProvider.family<CustomerNotifier,
    CustomerState, String>((ref, phone) {
  return CustomerNotifier(phone);
});

class CustomerNotifier extends StateNotifier<CustomerState> {
  final String _phone;
  final ChatApi _chatApi = ChatApi();

  CustomerNotifier(this._phone) : super(const CustomerState());

  Future<void> loadCustomer() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await _chatApi.getCustomer(_phone);
      final data = response.data as Map<String, dynamic>;
      final customerData = data['customer'] as Map<String, dynamic>? ?? data;
      final customer = Customer.fromJson(customerData);

      state = state.copyWith(
        customer: customer,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
}

// ── Customers list (for Customers screen) ──
class CustomersListState {
  final List<Customer> customers;
  final bool isLoading;
  final String? error;
  final String searchQuery;
  final String? segmentFilter;
  final String? tierFilter;

  const CustomersListState({
    this.customers = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
    this.segmentFilter,
    this.tierFilter,
  });

  CustomersListState copyWith({
    List<Customer>? customers,
    bool? isLoading,
    String? error,
    String? searchQuery,
    String? segmentFilter,
    String? tierFilter,
    bool clearError = false,
    bool clearSegment = false,
    bool clearTier = false,
  }) {
    return CustomersListState(
      customers: customers ?? this.customers,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      searchQuery: searchQuery ?? this.searchQuery,
      segmentFilter:
          clearSegment ? null : (segmentFilter ?? this.segmentFilter),
      tierFilter: clearTier ? null : (tierFilter ?? this.tierFilter),
    );
  }

  List<Customer> get filteredCustomers {
    var result = customers;

    if (segmentFilter != null) {
      result = result.where((c) => c.segment == segmentFilter).toList();
    }
    if (tierFilter != null) {
      result = result.where((c) => c.tier == tierFilter).toList();
    }
    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      result = result.where((c) {
        return c.name.toLowerCase().contains(q) ||
            c.phone.contains(q) ||
            (c.email?.toLowerCase().contains(q) ?? false);
      }).toList();
    }

    return result;
  }
}

final customersListProvider =
    StateNotifierProvider<CustomersListNotifier, CustomersListState>((ref) {
  return CustomersListNotifier();
});

class CustomersListNotifier extends StateNotifier<CustomersListState> {
  final ChatApi _chatApi = ChatApi();

  CustomersListNotifier() : super(const CustomersListState());

  Future<void> loadCustomers() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await _chatApi.getChats();
      final rawData = response.data;
      final List<dynamic> chatList =
          rawData is List ? rawData : (rawData['chats'] ?? rawData['data'] ?? []);

      final customers = chatList.map((j) {
        return Customer(
          phone: j['phone'] as String? ?? '',
          name: j['customer_name'] as String? ?? '',
          segment: j['segment'] as String? ?? 'new',
          tier: j['tier'] as String? ?? 'bronze',
          labels: _parseLabels(j['labels']),
          messageCount: _toInt(j['total_messages']),
          lastSeen: j['last_timestamp'] as String?,
        );
      }).toList();

      state = state.copyWith(
        customers: customers,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  static int _toInt(dynamic val) {
    if (val is int) return val;
    if (val is double) return val.toInt();
    if (val is String) return int.tryParse(val) ?? 0;
    return 0;
  }

  static List<String> _parseLabels(dynamic val) {
    if (val == null) return [];
    if (val is List) return val.map((e) => e.toString()).toList();
    if (val is String) {
      if (val.isEmpty || val == '[]') return [];
      return val
          .replaceAll('[', '')
          .replaceAll(']', '')
          .replaceAll('"', '')
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return [];
  }

  void setSearch(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setSegmentFilter(String? segment) {
    if (segment == null) {
      state = state.copyWith(clearSegment: true);
    } else {
      state = state.copyWith(segmentFilter: segment);
    }
  }

  void setTierFilter(String? tier) {
    if (tier == null) {
      state = state.copyWith(clearTier: true);
    } else {
      state = state.copyWith(tierFilter: tier);
    }
  }
}