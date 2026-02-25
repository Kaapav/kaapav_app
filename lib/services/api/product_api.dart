// lib/services/api/product_api.dart
// ═══════════════════════════════════════════════════════════
// PRODUCT API
// Matches: worker/handlers/product.js
// ═══════════════════════════════════════════════════════════

import 'package:dio/dio.dart';
import '../../config/constants.dart';
import 'api_client.dart';

class ProductApi {
  final ApiClient _client = ApiClient.instance;

  // ═══════════════════════════════════════════════════════════
  // LIST PRODUCTS
  // GET /api/products?category=&search=&in_stock=true&featured=true&sort=&order=&limit=&offset=
  // Response: { products[], total, limit, offset }
  // ═══════════════════════════════════════════════════════════

  Future<Response> getProducts({
    String? category,
    String? subcategory,
    String? search,
    bool? inStock,
    bool? featured,
    String sortBy = 'created_at',
    String sortOrder = 'desc',
    int limit = 50,
    int offset = 0,
    CancelToken? cancelToken,
  }) {
    final params = <String, dynamic>{
      'limit': limit,
      'offset': offset,
      'sort': sortBy,
      'order': sortOrder,
    };
    if (category != null) params['category'] = category;
    if (subcategory != null) params['subcategory'] = subcategory;
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (inStock == true) params['in_stock'] = 'true';
    if (featured == true) params['featured'] = 'true';

    return _client.get(
      ApiEndpoints.products,
      queryParameters: params,
      cacheTTL: const Duration(minutes: 1),
      cancelToken: cancelToken,
    );
  }

  // ═══════════════════════════════════════════════════════════
  // GET CATEGORIES (hierarchical)
  // GET /api/products/categories
  // Response: { categories: [{ name, productCount, totalStock, subcategories[] }] }
  // ═══════════════════════════════════════════════════════════

  Future<Response> getCategories() {
    return _client.get(
      ApiEndpoints.productCategories,
      cacheTTL: const Duration(minutes: 5),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // LOW STOCK PRODUCTS
  // GET /api/products/low-stock?threshold=10
  // Response: { products[], threshold }
  // ═══════════════════════════════════════════════════════════

  Future<Response> getLowStock({int threshold = 10}) {
    return _client.get(
      '/api/products/low-stock',
      queryParameters: {'threshold': threshold},
      cacheTTL: const Duration(minutes: 2),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // GET SINGLE PRODUCT (with order stats)
  // GET /api/products/:sku
  // Response: { product: {}, stats: { totalOrders, totalSold } }
  // ═══════════════════════════════════════════════════════════

  Future<Response> getProduct(String sku) {
    return _client.get(
      ApiEndpoints.product(sku),
      cacheTTL: const Duration(minutes: 1),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // CREATE PRODUCT
  // POST /api/products
  // Body: { sku, name, price, description, category, subcategory, tags[], stock,
  //         trackInventory, imageUrl, images[], videoUrl, variants[], isFeatured }
  // Response: { success, sku }
  // ═══════════════════════════════════════════════════════════

  Future<Response> createProduct(Map<String, dynamic> data) {
    return _client.post(ApiEndpoints.products, data: data);
  }

  // ═══════════════════════════════════════════════════════════
  // UPDATE PRODUCT
  // PUT /api/products/:sku
  // Body: { name, price, stock, category, tags[], images[], variants[], isFeatured, isActive, ... }
  // ═══════════════════════════════════════════════════════════

  Future<Response> updateProduct(String sku, Map<String, dynamic> data) {
    return _client.put(ApiEndpoints.product(sku), data: data);
  }

  // ═══════════════════════════════════════════════════════════
  // DELETE PRODUCT (soft delete — sets is_active = 0)
  // DELETE /api/products/:sku
  // ═══════════════════════════════════════════════════════════

  Future<Response> deleteProduct(String sku) {
    return _client.delete(ApiEndpoints.product(sku));
  }

  // ═══════════════════════════════════════════════════════════
  // UPDATE STOCK
  // POST /api/products/:sku/stock
  // Body: { action: "set"|"add"|"subtract", quantity, reason? }
  // Response: { success, newStock }
  // ═══════════════════════════════════════════════════════════

  Future<Response> updateStock(
    String sku, {
    required String action,
    required int quantity,
    String? reason,
  }) {
    return _client.post(
      ApiEndpoints.productStock(sku),
      data: {
        'action': action,
        'quantity': quantity,
        if (reason != null) 'reason': reason,
      },
    );
  }

  // ═══════════════════════════════════════════════════════════
  // BULK IMPORT (max 500 products, background processing)
  // POST /api/products/bulk-import
  // Body: { products: [{ sku, name, price, stock, category, imageUrl }] }
  // Response: { success, message }
  // ═══════════════════════════════════════════════════════════

  Future<Response> bulkImport(List<Map<String, dynamic>> products) {
    return _client.post(
      '/api/products/bulk-import',
      data: {'products': products},
    );
  }

  // ═══════════════════════════════════════════════════════════
  // UPLOAD IMAGE (to R2)
  // POST /api/products/upload-image
  // Body: FormData with 'file' field
  // Response: { success, url, filename }
  // ═══════════════════════════════════════════════════════════

  Future<Response> uploadImage(String filePath, String fileName) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
    });

    return _client.dio.post(
      '/api/products/upload-image',
      data: formData,
      options: Options(
        headers: {
          'Content-Type': 'multipart/form-data',
        },
      ),
    );
  }
}