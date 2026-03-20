import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:kaapav_app/config/theme.dart';
import '../../providers/product_provider.dart';

class ProductDetailScreen extends ConsumerWidget {
  final String sku;

  const ProductDetailScreen({
    super.key,
    required this.sku,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(productProvider).products;
    final product = products.any((p) => p.sku == sku)
        ? products.firstWhere((p) => p.sku == sku)
        : null;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (product == null) {
      return Scaffold(
        appBar: AppBar(title: Text(sku)),
        body: const Center(child: Text('Product not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(product.name),
        backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        foregroundColor: isDark ? Colors.white : const Color(0xFF1A1A1A),
        elevation: 0,
      ),
      body: ListView(
        children: [
          if ((product.imageUrl ?? '').isNotEmpty || product.images.isNotEmpty) ...[
            _ProductDetailGallery(
              images: product.images.isNotEmpty
                  ? product.images
                  : [if ((product.imageUrl ?? '').isNotEmpty) product.imageUrl!],
            ),
          ],
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  product.sku,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      '₹${product.price.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: KaapavTheme.gold,
                      ),
                    ),
                    if (product.hasDiscount) ...[
                      const SizedBox(width: 12),
                      Text(
                        '₹${product.comparePrice!.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 18,
                          color: Color(0xFF9CA3AF),
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '-${product.discountPercent.toStringAsFixed(0)}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                if ((product.description ?? '').isNotEmpty)
                  Text(
                    product.description!,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: isDark ? Colors.white70 : const Color(0xFF374151),
                    ),
                  ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text(
                      'Stock: ',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                    Text(
                      product.inStock
                          ? '${product.stock} available'
                          : 'Out of stock',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: product.inStock
                            ? const Color(0xFF10B981)
                            : const Color(0xFFEF4444),
                      ),
                    ),
                  ],
                ),
                if (product.category != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text(
                        'Category: ',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                      Text(
                        product.category!,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white : const Color(0xFF374151),
                        ),
                      ),
                    ],
                  ),
                ],
                if (product.tags.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Tags',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF9CA3AF),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: product.tags.map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: KaapavTheme.gold.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          tag,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: KaapavTheme.gold,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductDetailGallery extends StatefulWidget {
  final List<String> images;

  const _ProductDetailGallery({
    required this.images,
  });

  @override
  State<_ProductDetailGallery> createState() => _ProductDetailGalleryState();
}

class _ProductDetailGalleryState extends State<_ProductDetailGallery> {
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    final images = widget.images;

    return Column(
      children: [
        CachedNetworkImage(
          imageUrl: images[_selected],
          height: 300,
          width: double.infinity,
          fit: BoxFit.cover,
          placeholder: (_, __) => Container(
            height: 300,
            color: const Color(0xFFFBF8F1),
          ),
          errorWidget: (_, __, ___) => Container(
            height: 300,
            color: const Color(0xFFFBF8F1),
            child: const Center(
              child: Icon(Icons.broken_image, size: 48),
            ),
          ),
        ),
        if (images.length > 1)
          SizedBox(
            height: 78,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(8),
              itemCount: images.length,
              itemBuilder: (_, i) => GestureDetector(
                onTap: () => setState(() => _selected = i),
                child: Container(
                  width: 62,
                  height: 62,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: i == _selected
                          ? KaapavTheme.gold
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: CachedNetworkImage(
                      imageUrl: images[i],
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) =>
                          const Icon(Icons.broken_image_outlined),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}