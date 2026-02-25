// lib/screens/customers/customers_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';
import '../../providers/customer_provider.dart';
import '../../widgets/common/custom_search_bar.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/shimmer_loading.dart';

class CustomersScreen extends ConsumerStatefulWidget {
  const CustomersScreen({super.key});

  @override
  ConsumerState<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends ConsumerState<CustomersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _segmentFilter = 'all';

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(customersListProvider.notifier).loadCustomers());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customerState = ref.watch(customersListProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers'),
        backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        foregroundColor: isDark ? Colors.white : const Color(0xFF1A1A1A),
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) => setState(() => _segmentFilter = value),
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'all', child: Text('All')),
              PopupMenuItem(value: 'new', child: Text('New')),
              PopupMenuItem(value: 'returning', child: Text('Returning')),
              PopupMenuItem(value: 'vip', child: Text('VIP')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          CustomSearchBar(
            controller: _searchController,
            hintText: 'Search customers...',
            onChanged: (value) {
              setState(() => _searchQuery = value.toLowerCase());
            },
            onClear: () {
              _searchController.clear();
              setState(() => _searchQuery = '');
            },
          ),
          Expanded(
            child: customerState.isLoading
                ? const ShimmerLoading(type: ShimmerType.chatList, itemCount: 8)
                : _buildCustomerList(customerState),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerList(CustomersListState customerState) {
    var customers = customerState.customers;

    if (_searchQuery.isNotEmpty) {
      customers = customers.where((c) {
        final name = c.name.toLowerCase();
        final phone = c.phone.toLowerCase();
        final email = (c.email ?? '').toLowerCase();
        return name.contains(_searchQuery) ||
            phone.contains(_searchQuery) ||
            email.contains(_searchQuery);
      }).toList();
    }

    if (_segmentFilter != 'all') {
      customers = customers.where((c) => c.segment == _segmentFilter).toList();
    }

    if (customers.isEmpty) {
      return EmptyState(
        icon: Icons.people_outline,
        title: _searchQuery.isNotEmpty ? 'No customers found' : 'No customers yet',
        subtitle: _searchQuery.isNotEmpty
            ? 'Try a different search term'
            : 'Customers will appear when they message you',
      );
    }

    return RefreshIndicator(
      color: KaapavTheme.gold,
      onRefresh: () => ref.read(customersListProvider.notifier).loadCustomers(),
      child: ListView.builder(
        itemCount: customers.length,
        itemBuilder: (context, index) {
          final customer = customers[index];
          return _CustomerTile(customer: customer);
        },
      ),
    );
  }
}

class _CustomerTile extends StatelessWidget {
  final dynamic customer;
  const _CustomerTile({required this.customer});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _getSegmentColor(customer.segment),
        child: Text(
          (customer.name.isNotEmpty ? customer.name : customer.phone)
              .substring(0, 1)
              .toUpperCase(),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
      title: Text(
        customer.name.isNotEmpty ? customer.name : customer.phone,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : const Color(0xFF1A1A1A),
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(customer.phone,
              style: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF))),
          const SizedBox(height: 2),
          Row(
            children: [
              if (customer.segment != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: _getSegmentColor(customer.segment).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    (customer.segment ?? '').toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: _getSegmentColor(customer.segment),
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              Text('${customer.messageCount ?? 0} msgs',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
            ],
          ),
        ],
      ),
      isThreeLine: true,
      trailing: const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF)),
      onTap: () {
        Navigator.pushNamed(context, '/chat-window', arguments: customer.phone);
      },
    );
  }

  Color _getSegmentColor(String? segment) {
    switch (segment) {
      case 'vip':
        return const Color(0xFFFFD700);
      case 'returning':
        return const Color(0xFF45B7D1);
      case 'new':
        return const Color(0xFF4ECDC4);
      default:
        return const Color(0xFF9CA3AF);
    }
  }
}