import 'dart:convert';

class Product {
  final int? id;
  final String sku;
  final String name;
  final String? description;
  final double price;
  final double? comparePrice;
  final double? costPrice;
  final String? category;
  final String? subcategory;
  final List<String> tags;
  final int stock;
  final bool trackInventory;
  final String? imageUrl;
  final List<String> images;
  final String? videoUrl;
  final bool hasVariants;
  final List<dynamic> variants;
  final String? waProductId;
  final int viewCount;
  final int orderCount;
  final bool isActive;
  final bool isFeatured;
  final String? createdAt;
  final String? updatedAt;
  final String? websiteLink;
  final String? material;

  const Product({
    this.id,
    this.sku = '',
    this.name = '',
    this.description,
    this.price = 0.0,
    this.comparePrice,
    this.costPrice,
    this.category,
    this.subcategory,
    this.tags = const [],
    this.stock = 0,
    this.trackInventory = true,
    this.imageUrl,
    this.images = const [],
    this.videoUrl,
    this.hasVariants = false,
    this.variants = const [],
    this.waProductId,
    this.viewCount = 0,
    this.orderCount = 0,
    this.isActive = true,
    this.isFeatured = false,
    this.createdAt,
    this.updatedAt,
    this.websiteLink,
    this.material,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int?,
      sku: json['sku'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      price: _toDouble(json['price']),
      comparePrice: json['compare_price'] != null
          ? _toDouble(json['compare_price'])
          : null,
      costPrice: json['cost_price'] != null
          ? _toDouble(json['cost_price'])
          : null,
      category: json['category'] as String?,
      subcategory: json['subcategory'] as String?,
      tags: _parseStringList(json['tags']),
      stock: _toInt(json['stock']),
      trackInventory: json['track_inventory'] == 1 ||
          json['track_inventory'] == true ||
          json['track_inventory'] == null,
      imageUrl: json['image_url'] as String?,
      images: _parseStringList(json['images']),
      videoUrl: json['video_url'] as String?,
      hasVariants: json['has_variants'] == 1 || json['has_variants'] == true,
      variants: _parseDynamicList(json['variants']),
      waProductId: json['wa_product_id'] as String?,
      viewCount: _toInt(json['view_count']),
      orderCount: _toInt(json['order_count']),
      isActive: json['is_active'] == 1 ||
          json['is_active'] == true ||
          json['is_active'] == null,
      isFeatured: json['is_featured'] == 1 || json['is_featured'] == true,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      websiteLink: json['website_link'] as String?,
      material: json['material'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'sku': sku,
        'name': name,
        'description': description,
        'price': price,
        'compare_price': comparePrice,
        'cost_price': costPrice,
        'category': category,
        'subcategory': subcategory,
        'tags': tags,
        'stock': stock,
        'track_inventory': trackInventory ? 1 : 0,
        'image_url': imageUrl,
        'images': images,
        'video_url': videoUrl,
        'has_variants': hasVariants ? 1 : 0,
        'variants': variants,
        'wa_product_id': waProductId,
        'view_count': viewCount,
        'order_count': orderCount,
        'is_active': isActive ? 1 : 0,
        'is_featured': isFeatured ? 1 : 0,
        'created_at': createdAt,
        'updated_at': updatedAt,
        'website_link': websiteLink,
        'material': material,
      };

  static const _unset = Object();

  Product copyWith({
    int? id,
    String? sku,
    String? name,
    Object? description = _unset,
    double? price,
    Object? comparePrice = _unset,
    Object? costPrice = _unset,
    Object? category = _unset,
    Object? subcategory = _unset,
    List<String>? tags,
    int? stock,
    bool? trackInventory,
    Object? imageUrl = _unset,
    List<String>? images,
    Object? videoUrl = _unset,
    bool? hasVariants,
    List<dynamic>? variants,
    Object? waProductId = _unset,
    int? viewCount,
    int? orderCount,
    bool? isActive,
    bool? isFeatured,
    Object? createdAt = _unset,
    Object? updatedAt = _unset,
    Object? websiteLink = _unset,
    Object? material = _unset,
  }) {
    return Product(
      id: id ?? this.id,
      sku: sku ?? this.sku,
      name: name ?? this.name,
      description: identical(description, _unset)
          ? this.description
          : description as String?,
      price: price ?? this.price,
      comparePrice: identical(comparePrice, _unset)
          ? this.comparePrice
          : comparePrice as double?,
      costPrice: identical(costPrice, _unset)
          ? this.costPrice
          : costPrice as double?,
      category: identical(category, _unset)
          ? this.category
          : category as String?,
      subcategory: identical(subcategory, _unset)
          ? this.subcategory
          : subcategory as String?,
      tags: tags ?? this.tags,
      stock: stock ?? this.stock,
      trackInventory: trackInventory ?? this.trackInventory,
      imageUrl: identical(imageUrl, _unset)
          ? this.imageUrl
          : imageUrl as String?,
      images: images ?? this.images,
      videoUrl: identical(videoUrl, _unset)
          ? this.videoUrl
          : videoUrl as String?,
      hasVariants: hasVariants ?? this.hasVariants,
      variants: variants ?? this.variants,
      waProductId: identical(waProductId, _unset)
          ? this.waProductId
          : waProductId as String?,
      viewCount: viewCount ?? this.viewCount,
      orderCount: orderCount ?? this.orderCount,
      isActive: isActive ?? this.isActive,
      isFeatured: isFeatured ?? this.isFeatured,
      createdAt: identical(createdAt, _unset)
          ? this.createdAt
          : createdAt as String?,
      updatedAt: identical(updatedAt, _unset)
          ? this.updatedAt
          : updatedAt as String?,
      websiteLink: identical(websiteLink, _unset)
          ? this.websiteLink
          : websiteLink as String?,
      material: identical(material, _unset)
          ? this.material
          : material as String?,
    );
  }

  bool get inStock => !trackInventory || stock > 0;
  bool get isLowStock => trackInventory && stock > 0 && stock <= 5;
  bool get isOutOfStock => trackInventory && stock <= 0;
  bool get hasDiscount => comparePrice != null && comparePrice! > price;

  double get discountPercent {
    if (!hasDiscount) return 0;
    return ((comparePrice! - price) / comparePrice! * 100).roundToDouble();
  }

  double get profit {
    if (costPrice == null) return 0;
    return price - costPrice!;
  }

  double get profitMargin {
    if (costPrice == null || price == 0) return 0;
    return ((price - costPrice!) / price * 100).roundToDouble();
  }

  static int _toInt(dynamic val) {
    if (val is int) return val;
    if (val is double) return val.toInt();
    if (val is String) return int.tryParse(val) ?? 0;
    return 0;
  }

  static double _toDouble(dynamic val) {
    if (val is double) return val;
    if (val is int) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? 0.0;
    return 0.0;
  }

  static List<String> _parseStringList(dynamic val) {
    if (val == null) return [];

    if (val is List) {
      return val.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    }

    if (val is String) {
      if (val.trim().isEmpty || val.trim() == '[]') return [];

      try {
        final decoded = jsonDecode(val);
        if (decoded is List) {
          return decoded
              .map((e) => e.toString())
              .where((e) => e.isNotEmpty)
              .toList();
        }
      } catch (_) {
        return val
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }
    }

    return [];
  }

  static List<dynamic> _parseDynamicList(dynamic val) {
    if (val == null) return [];
    if (val is List) return val;

    if (val is String && val.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(val);
        if (decoded is List) return decoded;
      } catch (_) {}
    }

    return [];
  }
}