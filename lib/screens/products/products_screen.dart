// lib/screens/products/products_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../providers/product_provider.dart';
import '../../widgets/product_card.dart';
import '../../widgets/common/custom_search_bar.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/shimmer_loading.dart';

class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key});

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _categoryFilter = 'all';
  bool _gridView = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(productProvider.notifier).loadProducts());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productState = ref.watch(productProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        foregroundColor: isDark ? Colors.white : const Color(0xFF1A1A1A),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_gridView ? Icons.view_list : Icons.grid_view),
            onPressed: () => setState(() => _gridView = !_gridView),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) => setState(() => _categoryFilter = value),
            itemBuilder: (context) {
              final categories = <String>['all'];
              for (final p in productState.products) {
                if (p.category != null && !categories.contains(p.category)) {
                  categories.add(p.category!);
                }
              }
              return categories.map((c) => PopupMenuItem(
                value: c,
                child: Text(c == 'all' ? 'All Categories' : c),
              )).toList();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          CustomSearchBar(
            controller: _searchController,
            hintText: 'Search products...',
            onChanged: (value) {
              setState(() => _searchQuery = value.toLowerCase());
            },
            onClear: () {
              _searchController.clear();
              setState(() => _searchQuery = '');
            },
          ),
          Expanded(
            child: productState.isLoading
                ? const ShimmerLoading(type: ShimmerType.productGrid, itemCount: 6)
                : _buildProductList(productState),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: KaapavTheme.gold,
        onPressed: () {
          // TODO: Add product screen
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildProductList(ProductListState productState) {
    var products = productState.products;

    if (_categoryFilter != 'all') {
      products = products.where((p) => p.category == _categoryFilter).toList();
    }

    if (_searchQuery.isNotEmpty) {
      products = products.where((p) {
        final name = p.name.toLowerCase();
        final sku = p.sku.toLowerCase();
        final category = (p.category ?? '').toLowerCase();
        return name.contains(_searchQuery) ||
            sku.contains(_searchQuery) ||
            category.contains(_searchQuery);
      }).toList();
    }

    if (products.isEmpty) {
      return EmptyState(
        icon: Icons.inventory_2_outlined,
        title: _searchQuery.isNotEmpty ? 'No products found' : 'No products yet',
        subtitle: _searchQuery.isNotEmpty
            ? 'Try a different search term'
            : 'Add products to your catalog',
      );
    }

    return RefreshIndicator(
      color: KaapavTheme.gold,
      onRefresh: () => ref.read(productProvider.notifier).loadProducts(),
      child: _gridView ? _buildGrid(products) : _buildList(products),
    );
  }

  Widget _buildGrid(List products) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.72,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return ProductCard(
          product: product,
          onTap: () {
            Navigator.pushNamed(
              context,
              AppRoutes.productDetail,
              arguments: product.sku,
            );
          },
        );
      },
    );
  }

  Widget _buildList(List products) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return ProductCard(
          product: product,
          onTap: () {
            Navigator.pushNamed(
              context,
              AppRoutes.productDetail,
              arguments: product.sku,
            );
          },
        );
      },
    );
  }
}