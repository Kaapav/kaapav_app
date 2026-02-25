import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import '../services/api/product_api.dart';

class ProductListState {
  final List<Product> products;
  final List<String> categories;
  final bool isLoading;
  final String? error;
  final String searchQuery;
  final String? categoryFilter;
  final bool? inStockFilter;

  const ProductListState({
    this.products = const [],
    this.categories = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
    this.categoryFilter,
    this.inStockFilter,
  });

  ProductListState copyWith({
    List<Product>? products,
    List<String>? categories,
    bool? isLoading,
    String? error,
    String? searchQuery,
    String? categoryFilter,
    bool? inStockFilter,
    bool clearError = false,
    bool clearCategory = false,
    bool clearStock = false,
  }) {
    return ProductListState(
      products: products ?? this.products,
      categories: categories ?? this.categories,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      searchQuery: searchQuery ?? this.searchQuery,
      categoryFilter:
          clearCategory ? null : (categoryFilter ?? this.categoryFilter),
      inStockFilter:
          clearStock ? null : (inStockFilter ?? this.inStockFilter),
    );
  }

  // Mirrors useProductStore.getFilteredProducts
  List<Product> get filteredProducts {
    var result = products;

    if (categoryFilter != null) {
      result =
          result.where((p) => p.category == categoryFilter).toList();
    }
    if (inStockFilter == true) {
      result = result.where((p) => p.stock > 0).toList();
    }
    if (inStockFilter == false) {
      result = result.where((p) => p.stock <= 0).toList();
    }
    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      result = result.where((p) {
        return p.name.toLowerCase().contains(q) ||
            p.sku.toLowerCase().contains(q);
      }).toList();
    }

    return result;
  }

  int get totalProducts => products.length;
  int get activeProducts => products.where((p) => p.isActive).length;
  int get outOfStock => products.where((p) => p.isOutOfStock).length;
  int get lowStock => products.where((p) => p.isLowStock).length;
  int get featuredProducts => products.where((p) => p.isFeatured).length;
}

final productProvider =
    StateNotifierProvider<ProductNotifier, ProductListState>((ref) {
  return ProductNotifier();
});

class ProductNotifier extends StateNotifier<ProductListState> {
  final ProductApi _productApi = ProductApi();

  ProductNotifier() : super(const ProductListState());

  // ── Load products (mirrors setProducts + setCategories) ──
  Future<void> loadProducts({bool refresh = false}) async {
    if (state.isLoading && !refresh) return;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await _productApi.getProducts();
      final rawData = response.data;
      final List<dynamic> productList =
          rawData is List ? rawData : (rawData['products'] ?? rawData['data'] ?? []);

      final products =
          productList.map((j) => Product.fromJson(j)).toList();

      products.sort((a, b) => a.name.compareTo(b.name));

      final cats = products
          .map((p) => p.category)
          .where((c) => c != null && c.isNotEmpty)
          .cast<String>()
          .toSet()
          .toList()
        ..sort();

      state = state.copyWith(
        products: products,
        categories: cats,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<bool> createProduct(Map<String, dynamic> data) async {
    try {
      await _productApi.createProduct(data);
      await loadProducts(refresh: true);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  // Mirrors updateProduct
  Future<bool> updateProduct(String sku, Map<String, dynamic> data) async {
    try {
      await _productApi.updateProduct(sku, data);
      await loadProducts(refresh: true);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> updateStock(String sku, int stock) async {
    try {
      await _productApi.updateStock(sku, action: 'set', quantity: stock);
      final updated = state.products.map((p) {
        if (p.sku == sku) return p.copyWith(stock: stock);
        return p;
      }).toList();
      state = state.copyWith(products: updated);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteProduct(String sku) async {
    try {
      await _productApi.deleteProduct(sku);
      final updated = state.products.where((p) => p.sku != sku).toList();
      state = state.copyWith(products: updated);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Mirrors getProductBySku
  Product? getProduct(String sku) {
    try {
      return state.products.firstWhere((p) => p.sku == sku);
    } catch (_) {
      return null;
    }
  }

  void setSearch(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setCategoryFilter(String? category) {
    if (category == null || category == 'all') {
      state = state.copyWith(clearCategory: true);
    } else {
      state = state.copyWith(categoryFilter: category);
    }
  }

  void setStockFilter(bool? inStock) {
    if (inStock == null) {
      state = state.copyWith(clearStock: true);
    } else {
      state = state.copyWith(inStockFilter: inStock);
    }
  }
}