// lib/screens/products/products_screen.dart
// KAAPAV Catalogue Manager — v2
// Wired to: productProvider → ProductApi → wa.kaapav.com/api/products

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart'; 
import 'package:kaapav_app/config/theme.dart';
import '../../models/product.dart';
import '../../providers/product_provider.dart';
import '../../services/api/product_api.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/api/api_client.dart';

// ─────────────────────────────────────────────
// CATEGORY CONFIG
// ─────────────────────────────────────────────
const _catConfig = {
  'bracelet':     {'emoji': '📿', 'label': 'Bracelets',    'mrp': 999.0,  'price': 499.0},
  'necklace':     {'emoji': '✨', 'label': 'Necklaces',    'mrp': 999.0,  'price': 499.0},
  'earrings':     {'emoji': '👂', 'label': 'Earrings',     'mrp': 499.0,  'price': 249.0},
  'pendant':      {'emoji': '💎', 'label': 'Pendants',     'mrp': 999.0,  'price': 499.0},
  'rings':        {'emoji': '💍', 'label': 'Rings',        'mrp': 499.0,  'price': 249.0},
  'pendant_sets': {'emoji': '🎁', 'label': 'Pendant Sets', 'mrp': 1499.0, 'price': 699.0},
};

const _kTags = {
  'Fast Moving':  {'color': 0xFFEF4444, 'bg': 0xFFFEE2E2, 'emoji': '🔥'},
  'New Arrival':  {'color': 0xFF3B82F6, 'bg': 0xFFDBEAFE, 'emoji': '✨'},
  'Bestseller':   {'color': 0xFFF59E0B, 'bg': 0xFFFEF3C7, 'emoji': '⭐'},
  'On Offer':     {'color': 0xFF10B981, 'bg': 0xFFD1FAE5, 'emoji': '🎁'},
  'Limited':      {'color': 0xFF8B5CF6, 'bg': 0xFFEDE9FE, 'emoji': '⏳'},
  'Trending':     {'color': 0xFFEC4899, 'bg': 0xFFFCE7F3, 'emoji': '📈'},
  'Clearance':    {'color': 0xFF6B7280, 'bg': 0xFFF3F4F6, 'emoji': '🏷️'},
};

String _catEmoji(String? cat) =>
    (_catConfig[cat?.toLowerCase()]?['emoji'] as String?) ?? '💎';
String _catLabel(String? cat) =>
    (_catConfig[cat?.toLowerCase()]?['label'] as String?) ?? (cat ?? 'Other');

// ─────────────────────────────────────────────
// MAIN SCREEN
// ─────────────────────────────────────────────
class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key});

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen>
    with SingleTickerProviderStateMixin {
  final _searchCtrl = TextEditingController();
  String _selectedCat = 'all';
  Product? _selectedProduct;
  String _sortBy = 'name';
  Set<String> _selectedSkus = {};
  bool _bulkMode = false;

  // NEW: status + stock filters
  String _filterStatus = 'all'; // all / active / inactive
  String _filterStock  = 'all'; // all / low / out

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(productProvider.notifier).loadProducts());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // Matches name + SKU + description + tags, plus status/stock filters
  List<Product> _filtered(List<Product> all) {
    final q = _searchCtrl.text.toLowerCase();
    final list = all.where((p) {
      final catOk = _selectedCat == 'all' || p.category == _selectedCat;
      final searchOk = q.isEmpty ||
          p.name.toLowerCase().contains(q) ||
          p.sku.toLowerCase().contains(q) ||
          (p.description?.toLowerCase().contains(q) ?? false) ||
          p.tags.any((t) => t.toLowerCase().contains(q));
      final statusOk = _filterStatus == 'all' ||
          (_filterStatus == 'active' && p.isActive) ||
          (_filterStatus == 'inactive' && !p.isActive);
      final stockOk = _filterStock == 'all' ||
          (_filterStock == 'low' && p.isLowStock) ||
          (_filterStock == 'out' && p.isOutOfStock);
      return catOk && searchOk && statusOk && stockOk;
    }).toList();

    switch (_sortBy) {
      case 'price_asc':  list.sort((a, b) => a.price.compareTo(b.price)); break;
      case 'price_desc': list.sort((a, b) => b.price.compareTo(a.price)); break;
      case 'stock':      list.sort((a, b) => a.stock.compareTo(b.stock)); break;
      case 'newest':     list.sort((a, b) => b.sku.compareTo(a.sku)); break;
      default:           list.sort((a, b) => a.name.compareTo(b.name)); break;
    }
    return list;
  }

  // Share single product as WhatsApp-style card
  void _shareProduct(Product p) {
    final discountPct = p.hasDiscount
        ? ((p.comparePrice! - p.price) / p.comparePrice! * 100).round()
        : 0;
    final priceStr = p.hasDiscount
        ? '₹${p.price.toStringAsFixed(0)}/₹${p.comparePrice!.toStringAsFixed(0)} ($discountPct% Off)'
        : '₹${p.price.toStringAsFixed(0)}';
    final tagsLine = p.tags.isNotEmpty ? '\n🏷️ ${p.tags.join(' · ')}' : '';
    // Use product's own URL if available, else construct from SKU
    final productUrl = (p.websiteLink != null && p.websiteLink!.isNotEmpty)
        ? p.websiteLink!
        : 'https://www.kaapav.com/products/${p.sku.toLowerCase()}';

    Share.share(
      '💎 *${p.name}*\n'
      '💰 $priceStr\n'
      '${_catEmoji(p.category)} ${_catLabel(p.category)}$tagsLine\n'
      '🛍️ $productUrl',
      subject: p.name,
    );
  }

  // Share bulk selection as a list — each item gets its own URL
  void _bulkShare(List<Product> selected) {
    if (selected.isEmpty) return;
    final lines = selected.map((p) {
      final discountPct = p.hasDiscount
          ? ((p.comparePrice! - p.price) / p.comparePrice! * 100).round()
          : 0;
      final priceStr = p.hasDiscount
          ? '₹${p.price.toStringAsFixed(0)}/₹${p.comparePrice!.toStringAsFixed(0)} ($discountPct% Off)'
          : '₹${p.price.toStringAsFixed(0)}';
      final productUrl = (p.websiteLink != null && p.websiteLink!.isNotEmpty)
          ? p.websiteLink!
          : 'https://www.kaapav.com/products/${p.sku.toLowerCase()}';
      return '• *${p.name}* — $priceStr\n  $productUrl';
    }).join('\n\n');
    Share.share(
      '💎 *KAAPAV Products*\n\n$lines',
      subject: 'KAAPAV Products',
    );
  }

  @override
  Widget build(BuildContext context) {
    final state    = ref.watch(productProvider);
    final isDark   = Theme.of(context).brightness == Brightness.dark;
    final screenW  = MediaQuery.of(context).size.width;
    final isWide   = screenW > 700;
    final filtered = _filtered(state.products);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0805) : const Color(0xFFFBF8F1),
      body: Column(
        children: [
          _TopBar(totalCount: state.products.length, isDark: isDark, onAdd: () => _openAddSheet(context)),
          _SearchBar(controller: _searchCtrl, isDark: isDark, onChanged: (_) => setState(() {})),
          _CategoryTabs(
            selected: _selectedCat,
            categories: state.categories,
            onSelect: (c) => setState(() {
              _selectedCat = c;
              if (!isWide) _selectedProduct = null;
            }),
            isDark: isDark,
          ),
          _StatsBar(products: state.products, filtered: filtered, isDark: isDark),
          _SortBulkBar(
            sortBy: _sortBy,
            bulkMode: _bulkMode,
            selectedCount: _selectedSkus.length,
            totalCount: filtered.length,
            filterStatus: _filterStatus,
            filterStock: _filterStock,
            isDark: isDark,
            onSortChanged: (v) => setState(() => _sortBy = v),
            onBulkToggle: () => setState(() { _bulkMode = !_bulkMode; _selectedSkus.clear(); }),
            onSelectAll: () => setState(() { _selectedSkus = filtered.map((p) => p.sku).toSet(); }),
            onBulkActivate: () => _bulkAction(context, state, true),
            onBulkDeactivate: () => _bulkAction(context, state, false),
            onBulkDelete: () => _bulkDelete(context, state),
            onBulkShare: () => _bulkShare(filtered.where((p) => _selectedSkus.contains(p.sku)).toList()),
            onFilterStatus: (v) => setState(() => _filterStatus = v),
            onFilterStock:  (v) => setState(() => _filterStock = v),
          ),
          Expanded(
            child: state.isLoading
                ? _buildShimmer(isDark)
                : isWide
                    ? _WideLayout(
                        products: filtered,
                        selected: _selectedProduct,
                        onSelect: (p) => setState(() => _selectedProduct = p),
                        onEdit: (p) => _openEditSheet(context, p),
                        onDelete: (p) => _confirmDelete(context, p),
                        onCopy: (p) => _copyProduct(context, p),
                        onToggleActive: (p) => _toggleActive(context, p),
                        onShare: _shareProduct,
                        onLongPress: (p) => setState(() { _bulkMode = true; _selectedSkus.add(p.sku); }),
                        onStockEdit: (p, stock) => _quickStock(context, p, stock),
                        bulkMode: _bulkMode,
                        selectedSkus: _selectedSkus,
                        isDark: isDark,
                      )
                    : _NarrowLayout(
                        products: filtered,
                        onTap: (p) => _bulkMode
                            ? setState(() {
                                _selectedSkus.contains(p.sku)
                                    ? _selectedSkus.remove(p.sku)
                                    : _selectedSkus.add(p.sku);
                              })
                            : _openEditSheet(context, p),
                        onEdit: (p) => _openEditSheet(context, p),
                        onDelete: (p) => _confirmDelete(context, p),
                        onCopy: (p) => _copyProduct(context, p),
                        onStockEdit: (p, stock) => _quickStock(context, p, stock),
                        onToggleActive: (p) => _toggleActive(context, p),
                        onShare: _shareProduct,
                        onLongPress: (p) => setState(() { _bulkMode = true; _selectedSkus.add(p.sku); }),
                        onRefresh: () => ref.read(productProvider.notifier).loadProducts(refresh: true),
                        bulkMode: _bulkMode,
                        selectedSkus: _selectedSkus,
                        isDark: isDark,
                      ),
          ),
        ],
      ),
      floatingActionButton: isWide
          ? null
          : FloatingActionButton(
              backgroundColor: KaapavTheme.gold,
              onPressed: () => _openAddSheet(context),
              child: const Icon(Icons.add, color: Colors.white),
            ),
    );
  }

  Widget _buildShimmer(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: 8,
      itemBuilder: (_, __) => Container(
        height: 72,
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1509) : const Color(0xFFF0EDE6),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Future<void> _toggleActive(BuildContext context, Product p) async {
    final ok = await ref.read(productProvider.notifier)
        .updateProduct(p.sku, {'is_active': p.isActive ? 0 : 1});
    if (context.mounted) {
      _showToast(context,
          ok ? '${p.isActive ? '⏸ Deactivated' : '✅ Activated'} ${p.name}' : '❌ Failed', ok);
    }
  }

  Future<void> _bulkAction(BuildContext context, dynamic state, bool activate) async {
    int ok = 0;
    for (final sku in List<String>.from(_selectedSkus)) {
      Product? p;
      try { p = state.products.firstWhere((x) => x.sku == sku); } catch (_) {}
      if (p != null) {
        final success = await ref.read(productProvider.notifier)
            .updateProduct(sku, {'is_active': activate ? 1 : 0});
        if (success) ok++;
      }
    }
    if (context.mounted) {
      setState(() { _bulkMode = false; _selectedSkus.clear(); });
      _showToast(context, '✅ $ok products ${activate ? 'activated' : 'deactivated'}', true);
    }
  }

  Future<void> _bulkDelete(BuildContext context, dynamic state) async {
    final count = _selectedSkus.length;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1A1509) : Colors.white,
        title: const Text('Delete Selected?'),
        content: Text('Delete $count products? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Color(0xFFEF4444))),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    int ok = 0;
    for (final sku in List.from(_selectedSkus)) {
      final success = await ref.read(productProvider.notifier).deleteProduct(sku);
      if (success) ok++;
    }
    if (context.mounted) {
      setState(() { _bulkMode = false; _selectedSkus.clear(); });
      _showToast(context, '🗑 $ok products deleted', true);
    }
  }

  void _openAddSheet(BuildContext context, {Product? prefill}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProductFormSheet(
        product: prefill,
        isDark: Theme.of(context).brightness == Brightness.dark,
        isCopy: prefill != null,
        onSave: (data) async {
          final ok = await ref.read(productProvider.notifier).createProduct(data);
          if (context.mounted) {
            Navigator.pop(context);
            _showToast(context, ok ? '✅ Product added' : '❌ Failed to add', ok);
          }
        },
      ),
    );
  }

  void _openEditSheet(BuildContext context, Product p) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProductFormSheet(
        product: p,
        isDark: Theme.of(context).brightness == Brightness.dark,
                onSave: (data) async {
          final ok = await ref.read(productProvider.notifier).updateProduct(p.sku, data);
          if (context.mounted) {
            Navigator.pop(context);
            _showToast(context, ok ? '✅ Saved' : '❌ Failed to save', ok);
            if (ok) {
              final updated = ref.read(productProvider.notifier).getProduct(p.sku);
              setState(() => _selectedProduct = updated);
            }
          }
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, Product p) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1A1509) : Colors.white,
        title: const Text('Delete Product?'),
        content: Text('Delete "${p.name}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final ok = await ref.read(productProvider.notifier).deleteProduct(p.sku);
              if (context.mounted) {
                _showToast(context, ok ? '🗑 Deleted' : '❌ Failed', ok);
                setState(() => _selectedProduct = null);
              }
            },
            child: const Text('Delete', style: TextStyle(color: Color(0xFFEF4444))),
          ),
        ],
      ),
    );
  }

  void _copyProduct(BuildContext context, Product p) => _openAddSheet(context, prefill: p);

  Future<void> _quickStock(BuildContext context, Product p, int stock) async {
    final ok = await ref.read(productProvider.notifier).updateStock(p.sku, stock);
    if (context.mounted) {
      _showToast(context, ok ? '✅ Stock updated to $stock' : '❌ Failed', ok);
    }
  }

  void _showToast(BuildContext context, String msg, bool success) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: success ? const Color(0xFF10B981) : const Color(0xFFEF4444),
      duration: const Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
    ));
  }
}

// ─────────────────────────────────────────────
// TOP BAR
// ─────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final int totalCount;
  final bool isDark;
  final VoidCallback onAdd;
  const _TopBar({required this.totalCount, required this.isDark, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F0C07) : Colors.white,
        border: Border(bottom: BorderSide(color: isDark ? const Color(0xFF251D0A) : const Color(0xFFE5E7EB))),
      ),
      child: Row(
        children: [
          Text('Catalogue', style: TextStyle(fontFamily: 'serif', fontSize: 20,
              fontWeight: FontWeight.w400, color: KaapavTheme.gold, letterSpacing: 0.5)),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF251D0A) : const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('$totalCount',
                style: TextStyle(fontSize: 11, color: KaapavTheme.gold, fontWeight: FontWeight.w600)),
          ),
          const Spacer(),
          _OutlineBtn(label: '⬆ CSV', isDark: isDark, onTap: () => _showCsvInfo(context)),
          const SizedBox(width: 8),
          _GoldBtn(label: '+ Add', onTap: onAdd),
        ],
      ),
    );
  }

  void _showCsvInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1A1509) : Colors.white,
        title: Text('CSV Import', style: TextStyle(color: KaapavTheme.gold)),
        content: const Text(
          'To import products:\n\n'
          '1. Prepare CSV: name, sku, category, price, sale_price, description, stock\n\n'
          '2. Run: node import-products.js in your Kaapav-Whatsapp folder\n\n'
          '3. Paste generated SQL in D1 console\n\n'
          'Your import-products.js script is already set up ✅',
          style: TextStyle(fontSize: 13, height: 1.6),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
              child: Text('Got it', style: TextStyle(color: KaapavTheme.gold))),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// SEARCH BAR
// ─────────────────────────────────────────────
class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isDark;
  final ValueChanged<String> onChanged;
  const _SearchBar({required this.controller, required this.isDark, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      color: isDark ? const Color(0xFF0F0C07) : Colors.white,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: TextStyle(fontSize: 13, color: isDark ? const Color(0xFFF2E8D0) : const Color(0xFF1A1A1A)),
        decoration: InputDecoration(
          hintText: 'Search name, SKU, tags, description...',
          hintStyle: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF7A6A42) : const Color(0xFF9CA3AF)),
          prefixIcon: Icon(Icons.search, size: 18, color: isDark ? const Color(0xFF7A6A42) : const Color(0xFF9CA3AF)),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(icon: const Icon(Icons.close, size: 16),
                  onPressed: () { controller.clear(); onChanged(''); })
              : null,
          filled: true,
          fillColor: isDark ? const Color(0xFF1A1208) : const Color(0xFFF9F6EF),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: isDark ? const Color(0xFF251D0A) : const Color(0xFFE5E7EB))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: isDark ? const Color(0xFF251D0A) : const Color(0xFFE5E7EB))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: KaapavTheme.goldDark)),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// CATEGORY TABS
// ─────────────────────────────────────────────
class _CategoryTabs extends StatelessWidget {
  final String selected;
  final List<String> categories;
  final ValueChanged<String> onSelect;
  final bool isDark;
  const _CategoryTabs({required this.selected, required this.categories,
      required this.onSelect, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final all = ['all', ...categories];
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F0C07) : Colors.white,
        border: Border(bottom: BorderSide(color: isDark ? const Color(0xFF251D0A) : const Color(0xFFE5E7EB))),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: all.length,
        itemBuilder: (_, i) {
          final cat = all[i];
          final isActive = cat == selected;
          final label = cat == 'all' ? 'All' : '${_catEmoji(cat)} ${_catLabel(cat)}';
          return GestureDetector(
            onTap: () => onSelect(cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: isActive ? (isDark ? const Color(0xFF3A2C10) : const Color(0xFFFEF3C7)) : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: isActive ? KaapavTheme.gold : Colors.transparent),
              ),
              child: Text(label, style: TextStyle(fontSize: 11,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  color: isActive ? KaapavTheme.gold
                      : (isDark ? const Color(0xFF7A6A42) : const Color(0xFF6B7280)),
                  letterSpacing: 0.3)),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
// STATS BAR — inventory value + OOS count
// ─────────────────────────────────────────────
class _StatsBar extends StatelessWidget {
  final List<Product> products;
  final List<Product> filtered;
  final bool isDark;
  const _StatsBar({required this.products, required this.filtered, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final active   = filtered.where((p) => p.isActive).length;
    final lowStock = filtered.where((p) => p.isLowStock).length;
    final outStock = filtered.where((p) => p.isOutOfStock).length;
    final invValue = filtered.fold<double>(0, (s, p) => s + (p.price * p.stock));
    final invLabel = invValue >= 100000
        ? '₹${(invValue / 100000).toStringAsFixed(1)}L'
        : invValue >= 1000
            ? '₹${(invValue / 1000).toStringAsFixed(1)}K'
            : '₹${invValue.toStringAsFixed(0)}';

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F0C07) : Colors.white,
        border: Border(bottom: BorderSide(color: isDark ? const Color(0xFF251D0A) : const Color(0xFFE5E7EB))),
      ),
      child: Row(children: [
        _StatChip(n: '${filtered.length}', label: 'Total',    isDark: isDark),
        _StatChip(n: '$active',            label: 'Active',   isDark: isDark),
        _StatChip(n: invLabel,             label: 'Inv. Val', isDark: isDark),
        if (lowStock > 0) _StatChip(n: '$lowStock', label: 'Low', isDark: isDark, warn: true),
        if (outStock > 0) _StatChip(n: '$outStock', label: 'OOS', isDark: isDark, warn: true),
      ]),
    );
  }
}

// ─────────────────────────────────────────────
// SORT + BULK BAR — filter chips + bulk share
// ─────────────────────────────────────────────
class _SortBulkBar extends StatelessWidget {
  final String sortBy, filterStatus, filterStock;
  final bool bulkMode;
  final int selectedCount, totalCount;
  final bool isDark;
  final ValueChanged<String> onSortChanged;
  final VoidCallback onBulkToggle, onSelectAll, onBulkActivate, onBulkDeactivate, onBulkDelete, onBulkShare;
  final ValueChanged<String> onFilterStatus, onFilterStock;

  const _SortBulkBar({
    required this.sortBy, required this.filterStatus, required this.filterStock,
    required this.bulkMode, required this.selectedCount, required this.totalCount,
    required this.isDark, required this.onSortChanged, required this.onBulkToggle,
    required this.onSelectAll, required this.onBulkActivate, required this.onBulkDeactivate,
    required this.onBulkDelete, required this.onBulkShare,
    required this.onFilterStatus, required this.onFilterStock,
  });

  @override
  Widget build(BuildContext context) {
    final border  = isDark ? const Color(0xFF251D0A) : const Color(0xFFE5E7EB);
    final subText = isDark ? const Color(0xFF7A6A42) : const Color(0xFF9CA3AF);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F0C07) : Colors.white,
        border: Border(bottom: BorderSide(color: border)),
      ),
      child: bulkMode
          ? SizedBox(height: 38, child: Row(children: [
              GestureDetector(onTap: onBulkToggle, child: Icon(Icons.close, size: 18, color: subText)),
              const SizedBox(width: 8),
              Text('$selectedCount selected', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFFF2E8D0) : const Color(0xFF1A1A1A))),
              const SizedBox(width: 8),
              GestureDetector(onTap: onSelectAll,
                  child: Text('All', style: TextStyle(fontSize: 11, color: KaapavTheme.gold))),
              const Spacer(),
              _BulkBtn(label: '✓',  color: const Color(0xFF10B981), onTap: onBulkActivate),
              const SizedBox(width: 5),
              _BulkBtn(label: '○',  color: subText,                 onTap: onBulkDeactivate),
              const SizedBox(width: 5),
              _BulkBtn(label: '📤', color: const Color(0xFF8B5CF6), onTap: onBulkShare),
              const SizedBox(width: 5),
              _BulkBtn(label: '🗑', color: const Color(0xFFEF4444), onTap: onBulkDelete),
            ]))
          : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Row 1: sort chips
              SizedBox(height: 36, child: Row(children: [
                Text('Sort:', style: TextStyle(fontSize: 11, color: subText)),
                const SizedBox(width: 6),
                _SortChip(label: 'Name',   value: 'name',       current: sortBy, isDark: isDark, onTap: onSortChanged),
                _SortChip(label: '₹ Low',  value: 'price_asc',  current: sortBy, isDark: isDark, onTap: onSortChanged),
                _SortChip(label: '₹ High', value: 'price_desc', current: sortBy, isDark: isDark, onTap: onSortChanged),
                _SortChip(label: 'Stock',  value: 'stock',      current: sortBy, isDark: isDark, onTap: onSortChanged),
                _SortChip(label: 'New',    value: 'newest',     current: sortBy, isDark: isDark, onTap: onSortChanged),
                const Spacer(),
                GestureDetector(onTap: onBulkToggle,
                    child: Row(children: [
                      Icon(Icons.checklist, size: 16, color: subText),
                      const SizedBox(width: 4),
                      Text('Select', style: TextStyle(fontSize: 11, color: subText)),
                    ])),
              ])),
              // Row 2: status + stock filter chips
              SizedBox(height: 30, child: ListView(scrollDirection: Axis.horizontal, children: [
                _FilterChip(label: 'All',     value: 'all',      current: filterStatus, isDark: isDark, onTap: onFilterStatus),
                _FilterChip(label: '● Active', value: 'active',  current: filterStatus, isDark: isDark, onTap: onFilterStatus, activeColor: const Color(0xFF10B981)),
                _FilterChip(label: '○ Off',    value: 'inactive', current: filterStatus, isDark: isDark, onTap: onFilterStatus, activeColor: const Color(0xFF6B7280)),
                Container(width: 1, height: 16, margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
                    color: isDark ? const Color(0xFF251D0A) : const Color(0xFFE5E7EB)),
                _FilterChip(label: '⚠ Low',  value: 'low', current: filterStock, isDark: isDark, onTap: onFilterStock, activeColor: const Color(0xFFF59E0B)),
                _FilterChip(label: '✕ OOS',  value: 'out', current: filterStock, isDark: isDark, onTap: onFilterStock, activeColor: const Color(0xFFEF4444)),
              ])),
            ]),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label, value, current;
  final bool isDark;
  final ValueChanged<String> onTap;
  final Color? activeColor;
  const _FilterChip({required this.label, required this.value, required this.current,
      required this.isDark, required this.onTap, this.activeColor});

  @override
  Widget build(BuildContext context) {
    final isOn = value == current;
    final ac   = activeColor ?? KaapavTheme.gold;
    return GestureDetector(
      onTap: () => onTap(isOn ? 'all' : value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(right: 4, bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isOn ? ac.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: isOn ? ac : Colors.transparent),
        ),
        child: Text(label, style: TextStyle(fontSize: 10,
            fontWeight: isOn ? FontWeight.w700 : FontWeight.w400,
            color: isOn ? ac : (isDark ? const Color(0xFF7A6A42) : const Color(0xFF9CA3AF)))),
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  final String label, value, current;
  final bool isDark;
  final ValueChanged<String> onTap;
  const _SortChip({required this.label, required this.value, required this.current,
      required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isOn = value == current;
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        margin: const EdgeInsets.only(right: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isOn ? (isDark ? const Color(0xFF3A2C10) : const Color(0xFFFEF3C7)) : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: isOn ? KaapavTheme.gold : Colors.transparent),
        ),
        child: Text(label, style: TextStyle(fontSize: 10,
            fontWeight: isOn ? FontWeight.w700 : FontWeight.w400,
            color: isOn ? KaapavTheme.gold : (isDark ? const Color(0xFF7A6A42) : const Color(0xFF9CA3AF)))),
      ),
    );
  }
}

class _BulkBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _BulkBtn({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
        child: Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String n, label;
  final bool isDark, warn;
  const _StatChip({required this.n, required this.label, required this.isDark, this.warn = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          border: Border(right: BorderSide(color: isDark ? const Color(0xFF251D0A) : const Color(0xFFE5E7EB))),
        ),
        child: Column(children: [
          Text(n, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
              color: warn ? const Color(0xFFF59E0B) : KaapavTheme.gold)),
          Text(label, style: TextStyle(fontSize: 9, letterSpacing: 0.3,
              color: isDark ? const Color(0xFF7A6A42) : const Color(0xFF9CA3AF))),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// NARROW LAYOUT — Dismissible + fixed refresh + share
// ─────────────────────────────────────────────
class _NarrowLayout extends StatelessWidget {
  final List<Product> products;
  final ValueChanged<Product> onTap, onEdit, onDelete, onCopy, onLongPress, onToggleActive, onShare;
  final void Function(Product, int) onStockEdit;
  final Future<void> Function() onRefresh;
  final bool isDark, bulkMode;
  final Set<String> selectedSkus;

  const _NarrowLayout({
    required this.products, required this.onTap, required this.onEdit,
    required this.onDelete, required this.onCopy, required this.onLongPress,
    required this.onShare, required this.onStockEdit, required this.onRefresh,
    required this.isDark, required this.onToggleActive,
    this.bulkMode = false, this.selectedSkus = const {},
  });

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('💎', style: TextStyle(fontSize: 48)),
        const SizedBox(height: 12),
        Text('No products found', style: TextStyle(fontSize: 16,
            color: isDark ? const Color(0xFF7A6A42) : const Color(0xFF9CA3AF))),
      ]));
    }
    return RefreshIndicator(
      color: KaapavTheme.gold,
      onRefresh: onRefresh, // FIXED
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 80),
        itemCount: products.length,
        itemBuilder: (ctx, i) {
          final p = products[i];
          return Dismissible(
            key: Key('product_${p.sku}'),
            direction: DismissDirection.endToStart,
            confirmDismiss: (_) async => await showDialog<bool>(
              context: ctx,
              builder: (_) => AlertDialog(
                backgroundColor: isDark ? const Color(0xFF1A1509) : Colors.white,
                title: const Text('Delete?'),
                content: Text('Delete "${p.name}"?'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                  TextButton(onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Delete', style: TextStyle(color: Color(0xFFEF4444)))),
                ],
              ),
            ) ?? false,
            onDismissed: (_) => onDelete(p),
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(color: const Color(0xFFEF4444), borderRadius: BorderRadius.circular(8)),
              child: const Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.delete_outline, color: Colors.white, size: 22),
                Text('Delete', style: TextStyle(color: Colors.white, fontSize: 10)),
              ]),
            ),
            child: _ProductTile(
              product: p,
              isDark: isDark,
              onTap: () => onTap(p),
              onEdit: () => onEdit(p),
              onDelete: () => onDelete(p),
              onCopy: () => onCopy(p),
              onToggleActive: () => onToggleActive(p),
              onShare: () => onShare(p),
              onStockEdit: (v) => onStockEdit(p, v), // FIXED: no double dialog
              onLongPress: () => onLongPress(p),
              bulkMode: bulkMode,
              isSelected: selectedSkus.contains(p.sku),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
// WIDE LAYOUT
// ─────────────────────────────────────────────
class _WideLayout extends StatelessWidget {
  final List<Product> products;
  final Product? selected;
  final ValueChanged<Product> onSelect, onEdit, onDelete, onCopy, onToggleActive, onShare, onLongPress;
  final void Function(Product, int) onStockEdit;
  final bool isDark, bulkMode;
  final Set<String> selectedSkus;

  const _WideLayout({
    required this.products, required this.selected, required this.onSelect,
    required this.onEdit, required this.onDelete, required this.onCopy,
    required this.onToggleActive, required this.onShare, required this.onStockEdit,
    required this.isDark, required this.onLongPress,
    this.bulkMode = false, this.selectedSkus = const {},
  });

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      SizedBox(
        width: 360,
        child: _NarrowLayout(
          products: products, isDark: isDark, onTap: onSelect,
          onEdit: onEdit, onDelete: onDelete, onCopy: onCopy,
          onLongPress: onLongPress, onShare: onShare,
          onStockEdit: onStockEdit, onToggleActive: onToggleActive,
          onRefresh: () async {},
          bulkMode: bulkMode, selectedSkus: selectedSkus,
        ),
      ),
      VerticalDivider(width: 1, color: isDark ? const Color(0xFF251D0A) : const Color(0xFFE5E7EB)),
      Expanded(
        child: selected == null
            ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text('💎', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 12),
                Text('Select a product', style: TextStyle(fontSize: 18,
                    color: isDark ? const Color(0xFF7A6A42) : const Color(0xFF9CA3AF))),
              ]))
            : _DetailPane(
                product: selected!, isDark: isDark,
                onEdit: () => onEdit(selected!),
                onDelete: () => onDelete(selected!),
                onShare: () => onShare(selected!),
              ),
      ),
    ]);
  }
}

// ─────────────────────────────────────────────
// PRODUCT TILE — share + tag chips + SKU copy
// ─────────────────────────────────────────────
class _ProductTile extends StatelessWidget {
  final Product product;
  final bool isDark;
  final VoidCallback onTap, onEdit, onDelete, onCopy, onShare, onLongPress, onToggleActive;
  final ValueChanged<int> onStockEdit;
  final bool bulkMode, isSelected;

  const _ProductTile({
    required this.product, required this.isDark, required this.onTap,
    required this.onEdit, required this.onDelete, required this.onCopy,
    required this.onShare, required this.onStockEdit, required this.onToggleActive,
    required this.onLongPress, this.bulkMode = false, this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final discount = product.hasDiscount
        ? ((product.comparePrice! - product.price) / product.comparePrice! * 100).round() : 0;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F0C07) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? KaapavTheme.gold
                : (isDark ? const Color(0xFF251D0A) : const Color(0xFFE5E7EB)),
          ),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Main row
          Row(children: [
            if (bulkMode)
              Padding(padding: const EdgeInsets.only(right: 8),
                  child: Icon(isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                      color: isSelected ? KaapavTheme.gold : const Color(0xFF9CA3AF), size: 20)),
            _ProductThumb(imageUrl: product.imageUrl, emoji: _catEmoji(product.category), isDark: isDark),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
                      color: isDark ? const Color(0xFFF2E8D0) : const Color(0xFF1A1A1A))),
              const SizedBox(height: 3),
              Row(children: [
                Text('₹${product.price.toStringAsFixed(0)}',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: KaapavTheme.gold)),
                if (product.hasDiscount) ...[
                  const SizedBox(width: 6),
                  Text('₹${product.comparePrice!.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF),
                          decoration: TextDecoration.lineThrough)),
                  const SizedBox(width: 4),
                  Text('$discount% off', style: const TextStyle(fontSize: 10,
                      color: Color(0xFF10B981), fontWeight: FontWeight.w600)),
                ],
                const Spacer(),
                // SKU tap to copy
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: product.sku));
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Copied ${product.sku}'),
                      duration: const Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: KaapavTheme.goldDark,
                    ));
                  },
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(product.sku, style: TextStyle(fontSize: 9, letterSpacing: 0.1,
                        color: isDark ? const Color(0xFF3A3020) : const Color(0xFFD1D5DB))),
                    const SizedBox(width: 2),
                    Icon(Icons.copy, size: 8,
                        color: isDark ? const Color(0xFF3A3020) : const Color(0xFFD1D5DB)),
                  ]),
                ),
              ]),
              const SizedBox(height: 3),
              Row(children: [
                _StockBadge(product: product),
                const SizedBox(width: 6),
                Text(_catLabel(product.category), style: TextStyle(fontSize: 9,
                    color: isDark ? const Color(0xFF7A6A42) : const Color(0xFF9CA3AF))),
                const Spacer(),
                if (product.isFeatured) const Text('⭐', style: TextStyle(fontSize: 10)),
              ]),
            ])),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: onToggleActive,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: product.isActive ? const Color(0xFFD1FAE5) : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(product.isActive ? 'ON' : 'OFF', style: TextStyle(fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: product.isActive ? const Color(0xFF059669) : const Color(0xFF6B7280))),
              ),
            ),
          ]),

          // Action row + tag chips
          if (!bulkMode) ...[
            Container(
              margin: const EdgeInsets.only(top: 6),
              padding: const EdgeInsets.only(top: 6),
              decoration: BoxDecoration(border: Border(top: BorderSide(
                  color: isDark ? const Color(0xFF1A1208) : const Color(0xFFF0EDE6)))),
              child: Row(children: [
                GestureDetector(
                  onTap: () => showQuickStockDialog(context, product, onStockEdit, isDark),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1A1208) : const Color(0xFFF9F6EF),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: isDark ? const Color(0xFF251D0A) : const Color(0xFFE5E7EB)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.inventory_2_outlined, size: 11,
                          color: isDark ? const Color(0xFF7A6A42) : const Color(0xFF9CA3AF)),
                      const SizedBox(width: 4),
                      Text('Stock: ${product.stock}', style: TextStyle(fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isDark ? const Color(0xFF7A6A42) : const Color(0xFF6B7280))),
                      const SizedBox(width: 3),
                      Icon(Icons.edit, size: 9,
                          color: isDark ? const Color(0xFF7A6A42) : const Color(0xFF9CA3AF)),
                    ]),
                  ),
                ),
                const Spacer(),
                _TileAction(icon: Icons.share_outlined, color: const Color(0xFF8B5CF6), onTap: onShare),
                const SizedBox(width: 6),
                _TileAction(icon: Icons.copy_outlined,  color: const Color(0xFF3B82F6), onTap: onCopy),
                const SizedBox(width: 6),
                _TileAction(icon: Icons.edit_outlined,  color: KaapavTheme.gold,        onTap: onEdit),
                const SizedBox(width: 6),
                _TileAction(icon: Icons.delete_outline, color: const Color(0xFFEF4444), onTap: onDelete),
              ]),
            ),
            // Tag chips
            if (product.tags.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Wrap(spacing: 4, runSpacing: 4,
                  children: product.tags.map((tag) {
                    final cfg   = _kTags[tag];
                    final bg    = cfg != null ? Color(cfg['bg'] as int)
                        : (isDark ? const Color(0xFF1A1208) : const Color(0xFFF3F4F6));
                    final color = cfg != null ? Color(cfg['color'] as int) : const Color(0xFF6B7280);
                    final emoji = cfg?['emoji'] as String? ?? '🏷️';
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
                      child: Text('$emoji $tag',
                          style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w600)),
                    );
                  }).toList(),
                ),
              ),
          ],
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// PRODUCT THUMB
// ─────────────────────────────────────────────
class _ProductThumb extends StatelessWidget {
  final String? imageUrl;
  final String emoji;
  final bool isDark;
  const _ProductThumb({required this.imageUrl, required this.emoji, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48, height: 48,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1208) : const Color(0xFFF9F6EF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? const Color(0xFF251D0A) : const Color(0xFFE5E7EB)),
      ),
      child: imageUrl != null && imageUrl!.isNotEmpty
          ? ClipRRect(borderRadius: BorderRadius.circular(7),
              child: CachedNetworkImage(imageUrl: imageUrl!, fit: BoxFit.cover,
                  placeholder: (_, __) => Center(child: Text(emoji)),
                  errorWidget: (_, __, ___) => Center(child: Text(emoji, style: const TextStyle(fontSize: 22)))))
          : Center(child: Text(emoji, style: const TextStyle(fontSize: 22))),
    );
  }
}

// ─────────────────────────────────────────────
// STOCK BADGE
// ─────────────────────────────────────────────
class _StockBadge extends StatelessWidget {
  final Product product;
  const _StockBadge({required this.product});

  @override
  Widget build(BuildContext context) {
    Color bg, fg; String label;
    if (product.isOutOfStock) {
      bg = const Color(0xFFFEE2E2); fg = const Color(0xFFDC2626); label = 'Out of stock';
    } else if (product.isLowStock) {
      bg = const Color(0xFFFEF3C7); fg = const Color(0xFFD97706); label = 'Low: ${product.stock}';
    } else {
      bg = const Color(0xFFD1FAE5); fg = const Color(0xFF059669); label = '${product.stock} pcs';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: TextStyle(fontSize: 9, color: fg, fontWeight: FontWeight.w600)),
    );
  }
}

class _TileAction extends StatelessWidget {
  final IconData icon; final Color color; final VoidCallback onTap;
  const _TileAction({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: onTap,
      child: Container(padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
          child: Icon(icon, size: 14, color: color)));
  }
}

// ─────────────────────────────────────────────
// DETAIL PANE — tags section + share button
// ─────────────────────────────────────────────
class _DetailPane extends ConsumerWidget {
  final Product product;
  final bool isDark;
  final VoidCallback onEdit, onDelete, onShare;

  const _DetailPane({required this.product, required this.isDark,
      required this.onEdit, required this.onDelete, required this.onShare});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final discount = product.hasDiscount
        ? ((product.comparePrice! - product.price) / product.comparePrice! * 100).round() : 0;

    return Column(children: [
      Expanded(child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(_catEmoji(product.category), style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(product.name, style: TextStyle(fontSize: 20,
                  fontWeight: FontWeight.w600, color: KaapavTheme.gold)),
              Text('SKU: ${product.sku} · ${_catLabel(product.category)}',
                  style: TextStyle(fontSize: 12,
                      color: isDark ? const Color(0xFF7A6A42) : const Color(0xFF9CA3AF))),
            ])),
          ]),
          const SizedBox(height: 20),
          if (product.images.isNotEmpty || (product.imageUrl != null && product.imageUrl!.isNotEmpty)) ...[
            _ImageGallery(
              images: product.images.isNotEmpty
                  ? product.images
                  : [if ((product.imageUrl ?? '').isNotEmpty) product.imageUrl!],
              isDark: isDark,
            ),
            const SizedBox(height: 20),
          ],
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1208) : const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isDark ? const Color(0xFF3A2C10) : const Color(0xFFF59E0B), width: 0.5),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              _PriceChip(label: 'Sale', value: '₹${product.price.toStringAsFixed(0)}', valueColor: KaapavTheme.gold),
              if (product.hasDiscount) ...[
                Container(width: 1, height: 32, color: isDark ? const Color(0xFF251D0A) : const Color(0xFFE5E7EB)),
                _PriceChip(label: 'MRP', value: '₹${product.comparePrice!.toStringAsFixed(0)}', strikethrough: true),
                Container(width: 1, height: 32, color: isDark ? const Color(0xFF251D0A) : const Color(0xFFE5E7EB)),
                _PriceChip(label: 'Discount', value: '$discount% OFF', valueColor: const Color(0xFF10B981)),
                Container(width: 1, height: 32, color: isDark ? const Color(0xFF251D0A) : const Color(0xFFE5E7EB)),
                _PriceChip(label: 'You Save', value: '₹${(product.comparePrice! - product.price).toStringAsFixed(0)}'),
              ],
            ]),
          ),
          const SizedBox(height: 20),
          if (product.description != null && product.description!.isNotEmpty) ...[
            _SectionLabel('Description', isDark: isDark),
            const SizedBox(height: 8),
            Text(product.description!, style: TextStyle(fontSize: 13, height: 1.6,
                color: isDark ? const Color(0xFFD4C4A0) : const Color(0xFF374151))),
            const SizedBox(height: 20),
          ],
          _SectionLabel('Inventory', isDark: isDark),
          const SizedBox(height: 8),
          _InfoRow('Stock', '${product.stock} units', isDark: isDark),
          _InfoRow('Status', product.isActive ? '● Active' : '○ Inactive', isDark: isDark,
              valueColor: product.isActive ? const Color(0xFF10B981) : const Color(0xFF6B7280)),
          _InfoRow('Featured', product.isFeatured ? '⭐ Yes' : 'No', isDark: isDark),
          if (product.category != null)
            _InfoRow('Category', _catLabel(product.category), isDark: isDark),
          // Tags section
          if (product.tags.isNotEmpty) ...[
            const SizedBox(height: 20),
            _SectionLabel('Tags', isDark: isDark),
            const SizedBox(height: 10),
            Wrap(spacing: 6, runSpacing: 6,
              children: product.tags.map((tag) {
                final cfg   = _kTags[tag];
                final bg    = cfg != null ? Color(cfg['bg'] as int)
                    : (isDark ? const Color(0xFF1A1208) : const Color(0xFFF3F4F6));
                final color = cfg != null ? Color(cfg['color'] as int) : const Color(0xFF6B7280);
                final emoji = cfg?['emoji'] as String? ?? '🏷️';
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
                  child: Text('$emoji $tag', style: TextStyle(fontSize: 12,
                      color: color, fontWeight: FontWeight.w600)),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 8),
        ]),
      )),
      Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F0C07) : Colors.white,
          border: Border(top: BorderSide(color: isDark ? const Color(0xFF251D0A) : const Color(0xFFE5E7EB))),
        ),
        child: Row(children: [
          _OutlineBtn(label: '🗑 Delete', isDark: isDark, onTap: onDelete,
              textColor: const Color(0xFFEF4444), borderColor: const Color(0xFFEF4444)),
          const SizedBox(width: 8),
          _OutlineBtn(label: '📤 Share', isDark: isDark, onTap: onShare,
              textColor: const Color(0xFF8B5CF6), borderColor: const Color(0xFF8B5CF6)),
          const Spacer(),
          _OutlineBtn(label: 'Cancel', isDark: isDark, onTap: () {}),
          const SizedBox(width: 8),
          _GoldBtn(label: '✏️ Edit', onTap: onEdit),
        ]),
      ),
    ]);
  }
}

// ─────────────────────────────────────────────
// IMAGE GALLERY — horizontal scroll + fullscreen + download
// ─────────────────────────────────────────────
class _ImageGallery extends StatefulWidget {
  final List<String> images;
  final bool isDark;
  const _ImageGallery({required this.images, required this.isDark});

  @override
  State<_ImageGallery> createState() => _ImageGalleryState();
}

class _ImageGalleryState extends State<_ImageGallery> {
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    final images = widget.images;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Main image
      GestureDetector(
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => _FullscreenImage(url: images[_selected]))),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: CachedNetworkImage(
            imageUrl: images[_selected],
            height: 220,
            width: double.infinity,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(height: 220,
                color: widget.isDark ? const Color(0xFF1A1208) : const Color(0xFFF0EDE6),
                child: const Center(child: CircularProgressIndicator())),
            errorWidget: (_, __, ___) => Container(height: 220,
                color: widget.isDark ? const Color(0xFF1A1208) : const Color(0xFFF0EDE6),
                child: const Center(child: Icon(Icons.broken_image_outlined, color: Color(0xFF9CA3AF), size: 40))),
          ),
        ),
      ),
      if (images.length > 1) ...[
        const SizedBox(height: 8),
        SizedBox(
          height: 64,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: images.length,
            itemBuilder: (_, i) => GestureDetector(
              onTap: () => setState(() => _selected = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.only(right: 8),
                width: 64, height: 64,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: i == _selected ? KaapavTheme.gold : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: CachedNetworkImage(
                    imageUrl: images[i],
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => const Icon(Icons.broken_image_outlined),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ]);
  }
}

class _FullscreenImage extends StatelessWidget {
  final String url;
  const _FullscreenImage({required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_outlined, color: Colors.white),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: url));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Image URL copied — open in browser to download'),
                duration: Duration(seconds: 3),
              ));
            },
          ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          child: CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.contain,
            placeholder: (_, __) => const CircularProgressIndicator(color: Colors.white),
            errorWidget: (_, __, ___) => const Icon(Icons.broken_image_outlined,
                color: Colors.white, size: 60),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// SHARE OPTIONS SHEET
// ─────────────────────────────────────────────
// ignore: unused_element
class _ShareOptionsSheet extends StatelessWidget {
  final Product product;
  final bool isDark;
  const _ShareOptionsSheet({required this.product, required this.isDark});

  String _buildCaption() {
    final discountPct = product.hasDiscount
        ? ((product.comparePrice! - product.price) / product.comparePrice! * 100).round() : 0;
    final priceStr = product.hasDiscount
        ? '₹${product.price.toStringAsFixed(0)}/₹${product.comparePrice!.toStringAsFixed(0)} ($discountPct% Off)'
        : '₹${product.price.toStringAsFixed(0)}';
    final tagsLine = product.tags.isNotEmpty ? '\n🏷️ ${product.tags.join(' · ')}' : '';
    final url = (product.websiteLink != null && product.websiteLink!.isNotEmpty)
        ? product.websiteLink!
        : 'https://www.kaapav.com/products/${product.sku.toLowerCase()}';
    return '💎 *${product.name}*\n💰 $priceStr\n${_catEmoji(product.category)} ${_catLabel(product.category)}$tagsLine\n🛍️ $url';
  }

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF0F0C07) : Colors.white;
    final border = isDark ? const Color(0xFF251D0A) : const Color(0xFFE5E7EB);
    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: KaapavTheme.gold)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 36, height: 4,
            decoration: BoxDecoration(color: border, borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 16),
        Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: KaapavTheme.gold)),
        const SizedBox(height: 16),
        _ShareTile(
          icon: Icons.send_outlined,
          color: const Color(0xFF10B981),
          title: 'Send to Customer',
          sub: 'Pick from your chats',
          onTap: () {
            Navigator.pop(context);
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => _CustomerPickerSheet(product: product, isDark: isDark),
            );
          },
        ),
        const SizedBox(height: 8),
        _ShareTile(
          icon: Icons.share_outlined,
          color: const Color(0xFF8B5CF6),
          title: 'Share via Apps',
          sub: 'WhatsApp, Instagram, etc.',
          onTap: () {
            Navigator.pop(context);
            Share.share(_buildCaption(), subject: product.name);
          },
        ),
        if (product.websiteLink != null && product.websiteLink!.isNotEmpty) ...[
          const SizedBox(height: 8),
          _ShareTile(
            icon: Icons.link_outlined,
            color: KaapavTheme.gold,
            title: 'Copy Product Link',
            sub: product.websiteLink!,
            onTap: () {
              Navigator.pop(context);
              Clipboard.setData(ClipboardData(text: product.websiteLink!));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Link copied!'),
                duration: Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ));
            },
          ),
        ],
      ]),
    );
  }
}

class _ShareTile extends StatelessWidget {
  final IconData icon; final Color color;
  final String title, sub; final VoidCallback onTap;
  const _ShareTile({required this.icon, required this.color,
      required this.title, required this.sub, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(children: [
          Container(padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: color, size: 20)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
          ])),
          Icon(Icons.chevron_right, color: color, size: 18),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// CUSTOMER PICKER — search chats + send product
// ─────────────────────────────────────────────
class _CustomerPickerSheet extends StatefulWidget {
  final Product product;
  final bool isDark;
  const _CustomerPickerSheet({required this.product, required this.isDark});

  @override
  State<_CustomerPickerSheet> createState() => _CustomerPickerSheetState();
}

class _CustomerPickerSheetState extends State<_CustomerPickerSheet> {
  final _searchCtrl = TextEditingController();
  List<dynamic> _chats = [];
  List<dynamic> _filtered = [];
  bool _loading = true;
  String? _sending;

  @override
  void initState() {
    super.initState();
    _loadChats();
    _searchCtrl.addListener(() {
      final q = _searchCtrl.text.toLowerCase();
      setState(() {
        _filtered = q.isEmpty ? _chats : _chats.where((c) =>
            (c['customer_name'] ?? '').toLowerCase().contains(q) ||
            (c['phone'] ?? '').contains(q)).toList();
      });
    });
  }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _loadChats() async {
    try {
      final api = ApiClient.instance;
      final res = await api.get('/api/chats', queryParameters: {'limit': '100'});
      final chats = (res.data['chats'] as List? ?? []);
      setState(() { _chats = chats; _filtered = chats; _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _sendProduct(String phone, String name) async {
    setState(() => _sending = phone);
    try {
      final api = ApiClient.instance;
      await api.post('/api/products/send', data: {'sku': widget.product.sku, 'phone': phone});
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('✅ Sent to $name'),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ));
      }
    } catch (e) {
      setState(() => _sending = null);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('❌ Failed: $e'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.isDark ? const Color(0xFF0F0C07) : Colors.white;
    final border = widget.isDark ? const Color(0xFF251D0A) : const Color(0xFFE5E7EB);
    return DraggableScrollableSheet(
      initialChildSize: 0.75, maxChildSize: 0.95, minChildSize: 0.4,
      builder: (_, ctrl) => Container(
        decoration: BoxDecoration(color: bg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border(top: BorderSide(color: KaapavTheme.gold))),
        child: Column(children: [
          Center(child: Container(margin: const EdgeInsets.only(top: 10),
              width: 36, height: 4,
              decoration: BoxDecoration(color: border, borderRadius: BorderRadius.circular(2)))),
          Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(children: [
              Text('Send to Customer', style: TextStyle(fontSize: 16,
                  fontWeight: FontWeight.w600, color: KaapavTheme.gold)),
              const Spacer(),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ]),
          ),
          Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              style: TextStyle(fontSize: 13, color: widget.isDark ? const Color(0xFFF2E8D0) : const Color(0xFF1A1A1A)),
              decoration: InputDecoration(
                hintText: 'Search customers...',
                hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF9CA3AF)),
                filled: true,
                fillColor: widget.isDark ? const Color(0xFF1A1208) : const Color(0xFFF9F6EF),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: border)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: KaapavTheme.goldDark)),
              ),
            ),
          ),
          Expanded(child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _filtered.isEmpty
                  ? const Center(child: Text('No customers found'))
                  : ListView.builder(
                      controller: ctrl,
                      itemCount: _filtered.length,
                      itemBuilder: (_, i) {
                        final chat = _filtered[i];
                        final phone = chat['phone'] as String? ?? '';
                        final name = chat['customer_name'] as String? ?? phone;
                        final isSending = _sending == phone;
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: KaapavTheme.gold.withValues(alpha: 0.15),
                            child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                                style: TextStyle(color: KaapavTheme.gold, fontWeight: FontWeight.w700)),
                          ),
                          title: Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                          subtitle: Text(phone, style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
                          trailing: isSending
                              ? const SizedBox(width: 20, height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2))
                              : Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(color: KaapavTheme.gold,
                                      borderRadius: BorderRadius.circular(6)),
                                  child: const Text('Send', style: TextStyle(fontSize: 12,
                                      fontWeight: FontWeight.w600, color: Color(0xFF0A0804))),
                                ),
                          onTap: isSending ? null : () => _sendProduct(phone, name),
                        );
                      },
                    )),
        ]),
      ),
    );
  }
}


class _PriceChip extends StatelessWidget {
  final String label, value;
  final Color? valueColor;
  final bool strikethrough;
  const _PriceChip({required this.label, required this.value, this.valueColor, this.strikethrough = false});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(label, style: const TextStyle(fontSize: 9, color: Color(0xFF9CA3AF), letterSpacing: 0.2)),
      const SizedBox(height: 3),
      Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
          color: valueColor ?? const Color(0xFF9CA3AF),
          decoration: strikethrough ? TextDecoration.lineThrough : null)),
    ]);
  }
}

class _SectionLabel extends StatelessWidget {
  final String text; final bool isDark;
  const _SectionLabel(this.text, {required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Text(text.toUpperCase(), style: TextStyle(fontSize: 10, letterSpacing: 0.25,
          fontWeight: FontWeight.w600, color: KaapavTheme.gold)),
      const SizedBox(width: 8),
      Expanded(child: Container(height: 1,
          color: isDark ? const Color(0xFF251D0A) : const Color(0xFFE5E7EB))),
    ]);
  }
}

class _InfoRow extends StatelessWidget {
  final String label, value; final bool isDark; final Color? valueColor;
  const _InfoRow(this.label, this.value, {required this.isDark, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(children: [
        SizedBox(width: 90, child: Text(label, style: TextStyle(fontSize: 11,
            color: isDark ? const Color(0xFF7A6A42) : const Color(0xFF9CA3AF)))),
        Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
            color: valueColor ?? (isDark ? const Color(0xFFF2E8D0) : const Color(0xFF1A1A1A)))),
      ]),
    );
  }
}

// ─────────────────────────────────────────────
// PRODUCT FORM SHEET — image URL fixed
// ─────────────────────────────────────────────

class _ProductFormSheet extends StatefulWidget {
  final Product? product;
  final bool isDark, isCopy;
  final Future<void> Function(Map<String, dynamic>) onSave;

  const _ProductFormSheet({
    this.product,
    required this.isDark,
    this.isCopy = false,
    required this.onSave,
  });

  @override
  State<_ProductFormSheet> createState() => _ProductFormSheetState();
}

class _ProductFormSheetState extends State<_ProductFormSheet> {
  late final TextEditingController _name,
      _sku,
      _desc,
      _price,
      _mrp,
      _stock,
      _websiteUrl;

  String _category = 'bracelet';
  bool _active = true, _featured = false, _saving = false;
  List<String> _tags = [];
  List<String> _images = [];
  final _productApi = ProductApi();

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _name = TextEditingController(text: p?.name ?? '');
    _sku = TextEditingController(text: p?.sku ?? '');
    _desc = TextEditingController(text: p?.description ?? '');
    _price = TextEditingController(
      text: p != null ? p.price.toStringAsFixed(0) : '',
    );
    _mrp = TextEditingController(
      text: p?.comparePrice != null ? p!.comparePrice!.toStringAsFixed(0) : '',
    );
    _stock = TextEditingController(text: p != null ? '${p.stock}' : '0');
    _websiteUrl = TextEditingController(text: p?.websiteLink ?? '');
    _category = p?.category ?? 'bracelet';
    _active = p?.isActive ?? true;
    _featured = p?.isFeatured ?? false;
    _tags = List<String>.from(p?.tags ?? []);

_images = {
      if ((p?.imageUrl ?? '').isNotEmpty) p!.imageUrl!,
      ...(p?.images ?? <String>[]),
    }.toList();
  }

  @override
  void dispose() {
    for (final c in [_name, _sku, _desc, _price, _mrp, _stock, _websiteUrl]) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _isEdit => widget.product != null && !widget.isCopy;

  void _save() async {
    if (_name.text.trim().isEmpty) {
      _toast('Product name is required');
      return;
    }
    if (_sku.text.trim().isEmpty) {
      _toast('SKU is required');
      return;
    }
    if (_price.text.trim().isEmpty) {
      _toast('Price is required');
      return;
    }

    setState(() => _saving = true);

    await widget.onSave({
      'name': _name.text.trim(),
      'sku': _sku.text.trim(),
      'category': _category,
      'description': _desc.text.trim(),
      'price': double.tryParse(_price.text) ?? 0,
      'compare_price': double.tryParse(_mrp.text) ?? 0,
      'stock': int.tryParse(_stock.text) ?? 0,
      'image_url': _images.isNotEmpty ? _images.first : '',
      'images': _images,
      'website_link': _websiteUrl.text.trim(),
      'is_active': _active ? 1 : 0,
      'is_featured': _featured ? 1 : 0,
      'tags': _tags,
    });

    if (mounted) setState(() => _saving = false);
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFFEF4444),
      ),
    );
  }

  Future<void> _pickAndUploadImage() async {
  final picker = ImagePicker();
  final files = await picker.pickMultiImage(imageQuality: 85);
  if (files.isEmpty) return;

  setState(() => _saving = true);

  var addedCount = 0;
  final failures = <String>[];

  try {
    for (final file in files) {
      try {
        final res = await _productApi.uploadImage(file.path, file.name);
        final rawUrl = res.data['url'] ?? res.data['mediaUrl'];
        final url = rawUrl?.toString().trim();

        if (url != null && url.isNotEmpty && !_images.contains(url)) {
          _images.add(url);
          addedCount++;
        }
      } catch (_) {
        failures.add(file.name);
      }
    }

    if (mounted) {
      setState(() {});
      if (addedCount > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$addedCount image${addedCount == 1 ? '' : 's'} added'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
      if (failures.isNotEmpty) {
        _toast('Some uploads failed: ${failures.join(', ')}');
      }
    }
  } finally {
    if (mounted) setState(() => _saving = false);
  }
}


  @override
  Widget build(BuildContext context) {
    final bg = widget.isDark ? const Color(0xFF0F0C07) : Colors.white;
    final borderColor =
        widget.isDark ? const Color(0xFF251D0A) : const Color(0xFFE5E7EB);

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      maxChildSize: 0.97,
      minChildSize: 0.5,
      builder: (_, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border(top: BorderSide(color: KaapavTheme.gold, width: 1)),
        ),
        child: Column(
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Row(
                children: [
                  Text(
                    _isEdit ? 'Edit Product' : 'Add New Product',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: KaapavTheme.gold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  _FormSection('Basic Information', isDark: widget.isDark),
                  _FormField(
                    'Product Name *',
                    child: _input(_name, 'e.g. Crystal Lotus Ring'),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _FormField(
                          'SKU *',
                          child: _input(_sku, 'e.g. 701015'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _FormField('Category', child: _catDropdown()),
                      ),
                    ],
                  ),
                  _FormField('Description', child: _textArea(_desc)),

                  _FormSection('Pricing', isDark: widget.isDark),
                  Row(
                    children: [
                      Expanded(
                        child: _FormField(
                          'Sale Price (₹) *',
                          child: _numInput(_price, '249'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _FormField(
                          'MRP (₹)',
                          child: _numInput(_mrp, '499'),
                        ),
                      ),
                    ],
                  ),
                  _PricePreview(
                    priceCtrl: _price,
                    mrpCtrl: _mrp,
                    isDark: widget.isDark,
                  ),

                  _FormSection('Inventory', isDark: widget.isDark),
                  Row(
                    children: [
                      Expanded(
                        child: _FormField('Stock', child: _numInput(_stock, '0')),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _FormField(
                          'Website URL',
                          child: _input(
                            _websiteUrl,
                            'https://www.kaapav.com/shop/...',
                          ),
                        ),
                      ),
                    ],
                  ),

                  _FormSection('Images', isDark: widget.isDark),
                  _MultiImageManager(
                    images: _images,
                    isDark: widget.isDark,
                    onAdd: (url) => setState(() {
                      if (!_images.contains(url)) _images.add(url);
                    }),
                    onDelete: (i) => setState(() => _images.removeAt(i)),
                    onSetMain: (i) {
                      if (i <= 0 || i >= _images.length) return;
                      setState(() {
                        final item = _images.removeAt(i);
                        _images.insert(0, item);
                      });
                    },
                    onPickAndUpload: _pickAndUploadImage,
                  ),

                  const SizedBox(height: 8),
                  _FormSection('Tags', isDark: widget.isDark),
                  _TagSelector(
                    selected: _tags,
                    isDark: widget.isDark,
                    onChanged: (v) => setState(() => _tags = v),
                  ),

                  const SizedBox(height: 16),
                  _FormSection('Settings', isDark: widget.isDark),
                  _ToggleRow(
                    label: 'Show in WhatsApp Bot',
                    sub: 'Display in order flow',
                    value: _active,
                    onChanged: (v) => setState(() => _active = v),
                    isDark: widget.isDark,
                  ),
                  _ToggleRow(
                    label: 'Featured Product',
                    sub: 'Show in bestsellers',
                    value: _featured,
                    onChanged: (v) => setState(() => _featured = v),
                    isDark: widget.isDark,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
              decoration: BoxDecoration(
                color: bg,
                border: Border(top: BorderSide(color: borderColor)),
              ),
              child: Row(
                children: [
                  _OutlineBtn(
                    label: 'Cancel',
                    isDark: widget.isDark,
                    onTap: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  _GoldBtn(
                    label: _saving ? 'Saving...' : '💾 Save',
                    onTap: _saving ? null : _save,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _input(TextEditingController c, String hint) =>
      _BaseInput(controller: c, hint: hint, isDark: widget.isDark);

  Widget _numInput(TextEditingController c, String hint) => _BaseInput(
        controller: c,
        hint: hint,
        isDark: widget.isDark,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      );

  Widget _textArea(TextEditingController c) => _BaseInput(
        controller: c,
        hint: 'Short product description...',
        isDark: widget.isDark,
        maxLines: 3,
      );

  Widget _catDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: widget.isDark ? const Color(0xFF1A1208) : const Color(0xFFF9F6EF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: widget.isDark ? const Color(0xFF251D0A) : const Color(0xFFE5E7EB),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _category,
          isExpanded: true,
          style: TextStyle(
            fontSize: 12,
            color: widget.isDark ? const Color(0xFFF2E8D0) : const Color(0xFF1A1A1A),
          ),
          dropdownColor: widget.isDark ? const Color(0xFF1A1208) : Colors.white,
          onChanged: (v) => setState(() => _category = v!),
          items: _catConfig.entries.map((e) {
            return DropdownMenuItem(
              value: e.key,
              child: Text(
                '${e.value['emoji']} ${e.value['label']}',
                style: const TextStyle(fontSize: 12),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// PRICE PREVIEW
// ─────────────────────────────────────────────
class _PricePreview extends StatefulWidget {
  final TextEditingController priceCtrl, mrpCtrl;
  final bool isDark;
  const _PricePreview({required this.priceCtrl, required this.mrpCtrl, required this.isDark});

  @override
  State<_PricePreview> createState() => _PricePreviewState();
}

class _PricePreviewState extends State<_PricePreview> {
  @override
  void initState() {
    super.initState();
    widget.priceCtrl.addListener(() => setState(() {}));
    widget.mrpCtrl.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    final price    = double.tryParse(widget.priceCtrl.text) ?? 0;
    final mrp      = double.tryParse(widget.mrpCtrl.text) ?? 0;
    final discount = mrp > 0 ? ((mrp - price) / mrp * 100).round() : 0;
    final save     = mrp - price;
    if (price <= 0) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: widget.isDark ? const Color(0xFF1A1208) : const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: widget.isDark ? const Color(0xFF3A2C10) : const Color(0xFFF59E0B), width: 0.5),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _PriceChip(label: 'Sale', value: '₹${price.toStringAsFixed(0)}', valueColor: KaapavTheme.gold),
        if (mrp > 0) ...[
          _PriceChip(label: 'MRP', value: '₹${mrp.toStringAsFixed(0)}', strikethrough: true),
          _PriceChip(label: 'Off', value: '$discount%', valueColor: const Color(0xFF10B981)),
          _PriceChip(label: 'Save', value: '₹${save.toStringAsFixed(0)}'),
        ],
      ]),
    );
  }
}

// ─────────────────────────────────────────────
// FORM HELPERS
// ─────────────────────────────────────────────
class _FormSection extends StatelessWidget {
  final String label; final bool isDark;
  const _FormSection(this.label, {required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 10),
      child: Row(children: [
        Text(label.toUpperCase(), style: TextStyle(fontSize: 10, letterSpacing: 0.25,
            fontWeight: FontWeight.w600, color: KaapavTheme.gold)),
        const SizedBox(width: 8),
        Expanded(child: Container(height: 1,
            color: isDark ? const Color(0xFF251D0A) : const Color(0xFFE5E7EB))),
      ]),
    );
  }
}

class _FormField extends StatelessWidget {
  final String label; final Widget child;
  const _FormField(this.label, {required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label.toUpperCase(), style: const TextStyle(fontSize: 10, letterSpacing: 0.1, color: Color(0xFF9CA3AF))),
        const SizedBox(height: 5),
        child,
      ]),
    );
  }
}

class _BaseInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint; final bool isDark; final int maxLines;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  const _BaseInput({required this.controller, required this.hint, required this.isDark,
      this.maxLines = 1, this.keyboardType, this.inputFormatters});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller, maxLines: maxLines, keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFFF2E8D0) : const Color(0xFF1A1A1A)),
      decoration: InputDecoration(
        hintText: hint, hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
        filled: true, fillColor: isDark ? const Color(0xFF1A1208) : const Color(0xFFF9F6EF),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: isDark ? const Color(0xFF251D0A) : const Color(0xFFE5E7EB))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: isDark ? const Color(0xFF251D0A) : const Color(0xFFE5E7EB))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: KaapavTheme.goldDark)),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String label, sub; final bool value, isDark;
  final ValueChanged<bool> onChanged;
  const _ToggleRow({required this.label, required this.sub, required this.value,
      required this.onChanged, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(
          color: isDark ? const Color(0xFF1A1208) : const Color(0xFFF0EDE6)))),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 13,
              color: isDark ? const Color(0xFFF2E8D0) : const Color(0xFF1A1A1A))),
          Text(sub, style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
        ])),
        Switch(value: value, onChanged: onChanged, activeThumbColor: KaapavTheme.gold,
            activeTrackColor: KaapavTheme.gold.withValues(alpha: 0.4)),
      ]),
    );
  }
}
// ignore: unused_element
class _FormImagePreview extends StatelessWidget {
  final String imageUrl;
  final bool isDark;
  const _FormImagePreview({required this.imageUrl, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showFullscreen(context, imageUrl),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          height: 120,
          width: double.infinity,
          fit: BoxFit.cover,
          placeholder: (_, __) => Container(height: 120,
              color: isDark ? const Color(0xFF1A1208) : const Color(0xFFF0EDE6),
              child: const Center(child: CircularProgressIndicator())),
          errorWidget: (_, __, ___) => Container(height: 120,
              color: isDark ? const Color(0xFF1A1208) : const Color(0xFFF0EDE6),
              child: const Center(child: Icon(Icons.broken_image_outlined, color: Color(0xFF9CA3AF)))),
        ),
      ),
    );
  }

  void _showFullscreen(BuildContext context, String url) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => _FullscreenImage(url: url)));
  }
}

// ─────────────────────────────────────────────
// SHARED BUTTONS
// ─────────────────────────────────────────────
class _GoldBtn extends StatelessWidget {
  final String label; final VoidCallback? onTap;
  const _GoldBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: onTap,
      child: AnimatedContainer(duration: const Duration(milliseconds: 100),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
              color: onTap == null ? const Color(0xFF9CA3AF) : KaapavTheme.gold,
              borderRadius: BorderRadius.circular(8)),
          child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
              color: Color(0xFF0A0804), letterSpacing: 0.3))));
  }
}

class _OutlineBtn extends StatelessWidget {
  final String label; final bool isDark; final VoidCallback? onTap;
  final Color? textColor, borderColor;
  const _OutlineBtn({required this.label, required this.isDark, required this.onTap,
      this.textColor, this.borderColor});

  @override
  Widget build(BuildContext context) {
    final tc = textColor ?? (isDark ? const Color(0xFF7A6A42) : const Color(0xFF6B7280));
    final bc = borderColor ?? (isDark ? const Color(0xFF251D0A) : const Color(0xFFE5E7EB));
    return GestureDetector(onTap: onTap,
      child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: bc)),
          child: Text(label, style: TextStyle(fontSize: 12, color: tc, letterSpacing: 0.2))));
  }
}

// ─────────────────────────────────────────────
// QUICK STOCK DIALOG
// ─────────────────────────────────────────────
Future<void> showQuickStockDialog(
    BuildContext context, Product product, ValueChanged<int> onSave, bool isDark) async {
  final ctrl = TextEditingController(text: '${product.stock}');
  await showDialog(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: isDark ? const Color(0xFF1A1509) : Colors.white,
      title: Text('Update Stock', style: TextStyle(color: KaapavTheme.gold, fontSize: 16)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(product.name, style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
        const SizedBox(height: 12),
        TextField(controller: ctrl, autofocus: true, keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(labelText: 'Stock quantity',
                labelStyle: TextStyle(color: KaapavTheme.gold),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: KaapavTheme.gold)))),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        TextButton(
          onPressed: () { final v = int.tryParse(ctrl.text) ?? product.stock; onSave(v); Navigator.pop(context); },
          child: Text('Save', style: TextStyle(color: KaapavTheme.gold, fontWeight: FontWeight.w700)),
        ),
      ],
    ),
  );
  ctrl.dispose();
}

// ─────────────────────────────────────────────
// TAG SELECTOR
// ─────────────────────────────────────────────
class _TagSelector extends StatelessWidget {
  final List<String> selected; final bool isDark; final ValueChanged<List<String>> onChanged;
  const _TagSelector({required this.selected, required this.isDark, required this.onChanged});

  @override
  Widget build(BuildContext context) =>
      _TagSelectorInner(selected: selected, isDark: isDark, onChanged: onChanged);
}

class _TagSelectorInner extends StatefulWidget {
  final List<String> selected; final bool isDark; final ValueChanged<List<String>> onChanged;
  const _TagSelectorInner({required this.selected, required this.isDark, required this.onChanged});

  @override
  State<_TagSelectorInner> createState() => _TagSelectorInnerState();
}

class _TagSelectorInnerState extends State<_TagSelectorInner> {
  final _ctrl = TextEditingController();

  void _add(String tag) {
    final t = tag.trim();
    if (t.isEmpty || widget.selected.contains(t)) return;
    widget.onChanged([...widget.selected, t]);
    _ctrl.clear();
  }

  void _remove(String tag) =>
      widget.onChanged(widget.selected.where((t) => t != tag).toList());

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final bord = widget.isDark ? const Color(0xFF251D0A) : const Color(0xFFE5E7EB);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Wrap(spacing: 6, runSpacing: 6,
        children: _kTags.entries.map((e) {
          final isOn  = widget.selected.contains(e.key);
          final bg    = isOn ? Color(e.value['bg'] as int)
              : (widget.isDark ? const Color(0xFF1A1208) : const Color(0xFFF9F6EF));
          final color = isOn ? Color(e.value['color'] as int)
              : (widget.isDark ? const Color(0xFF7A6A42) : const Color(0xFF9CA3AF));
          final border = isOn ? Color(e.value['color'] as int).withValues(alpha: 0.4) : bord;
          return GestureDetector(
            onTap: () => isOn ? _remove(e.key) : _add(e.key),
            child: AnimatedContainer(duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: border)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(e.value['emoji'] as String, style: const TextStyle(fontSize: 12)),
                const SizedBox(width: 4),
                Text(e.key, style: TextStyle(fontSize: 11,
                    fontWeight: isOn ? FontWeight.w700 : FontWeight.w400, color: color)),
                if (isOn) ...[
                  const SizedBox(width: 4),
                  Icon(Icons.check_circle, size: 12, color: Color(e.value['color'] as int)),
                ],
              ]),
            ),
          );
        }).toList(),
      ),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: TextField(controller: _ctrl,
          style: TextStyle(fontSize: 12, color: widget.isDark ? const Color(0xFFF2E8D0) : const Color(0xFF1A1A1A)),
          decoration: InputDecoration(hintText: 'Type custom tag, press Enter…',
              hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
              filled: true, fillColor: widget.isDark ? const Color(0xFF1A1208) : const Color(0xFFF9F6EF),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: bord)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: bord)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: KaapavTheme.goldDark))),
          onSubmitted: _add, textInputAction: TextInputAction.done)),
        const SizedBox(width: 8),
        GestureDetector(onTap: () => _add(_ctrl.text),
            child: Container(padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: KaapavTheme.gold, borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.add, color: Colors.white, size: 18))),
      ]),
      if (widget.selected.isNotEmpty) ...[
        const SizedBox(height: 10),
        Wrap(spacing: 6, runSpacing: 6,
          children: widget.selected.map((tag) {
            final cfg   = _kTags[tag];
            final bg    = cfg != null ? Color(cfg['bg'] as int) : const Color(0xFFF3F4F6);
            final color = cfg != null ? Color(cfg['color'] as int) : const Color(0xFF6B7280);
            final emoji = cfg?['emoji'] as String? ?? '🏷️';
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text('$emoji $tag', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
                const SizedBox(width: 4),
                GestureDetector(onTap: () => _remove(tag),
                    child: Icon(Icons.close, size: 12, color: color)),
              ]),
            );
          }).toList(),
        ),
      ],
    ]);
  }
}
// ─────────────────────────────────────────────
// MULTI IMAGE MANAGER
// ─────────────────────────────────────────────
class _MultiImageManager extends StatefulWidget {
  final List<String> images;
  final bool isDark;
  final ValueChanged<String> onAdd;
  final ValueChanged<int> onDelete;
  final ValueChanged<int> onSetMain;
  final VoidCallback onPickAndUpload;

  const _MultiImageManager({
    required this.images,
    required this.isDark,
    required this.onAdd,
    required this.onDelete,
    required this.onSetMain,
    required this.onPickAndUpload,
  });

  @override
  State<_MultiImageManager> createState() => _MultiImageManagerState();
}

class _MultiImageManagerState extends State<_MultiImageManager> {
  late final TextEditingController _urlCtrl;

  @override
  void initState() {
    super.initState();
    _urlCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.images;
    final isDark = widget.isDark;
    final borderColor =
        isDark ? const Color(0xFF251D0A) : const Color(0xFFE5E7EB);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (images.isNotEmpty) ...[
          SizedBox(
            height: 160,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                final isMain = i == 0;
                return SizedBox(
                  width: 140,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Stack(
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      _FullscreenImage(url: images[i]),
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: CachedNetworkImage(
                                  imageUrl: images[i],
                                  width: 140,
                                  height: double.infinity,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) => Container(
                                    color: isDark
                                        ? const Color(0xFF1A1208)
                                        : const Color(0xFFF0EDE6),
                                    child: const Center(
                                      child: Icon(
                                        Icons.broken_image_outlined,
                                        color: Color(0xFF9CA3AF),
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 6,
                              left: 6,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isMain
                                      ? KaapavTheme.gold
                                      : Colors.black.withValues(alpha: 0.55),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  isMain ? 'Main' : '#${i + 1}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: isMain
                                        ? const Color(0xFF0A0804)
                                        : Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 6,
                              right: 6,
                              child: GestureDetector(
                                onTap: () => widget.onDelete(i),
                                child: Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFEF4444),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: isMain ? null : () => widget.onSetMain(i),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: KaapavTheme.gold,
                                side: const BorderSide(color: KaapavTheme.gold),
                                padding: const EdgeInsets.symmetric(vertical: 8),
                              ),
                              child: const Text(
                                'Set Main',
                                style: TextStyle(fontSize: 11),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
        ],

        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _urlCtrl,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? const Color(0xFFF2E8D0)
                      : const Color(0xFF1A1A1A),
                ),
                decoration: InputDecoration(
                  hintText: 'Paste image URL and tap +',
                  hintStyle: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF9CA3AF),
                  ),
                  filled: true,
                  fillColor:
                      isDark ? const Color(0xFF1A1208) : const Color(0xFFF9F6EF),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: KaapavTheme.goldDark),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: () {
                final url = _urlCtrl.text.trim();
                if (url.isNotEmpty && !images.contains(url)) {
                  widget.onAdd(url);
                  _urlCtrl.clear();
                }
              },
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: KaapavTheme.gold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: KaapavTheme.gold.withValues(alpha: 0.3),
                  ),
                ),
                child: const Icon(
                  Icons.link,
                  size: 18,
                  color: KaapavTheme.gold,
                ),
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: widget.onPickAndUpload,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: KaapavTheme.gold,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.photo_library_outlined,
                  size: 18,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),

        if (images.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '${images.length} image${images.length == 1 ? '' : 's'} added. First image is the main catalogue image.',
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF9CA3AF),
              ),
            ),
          ),
      ],
    );
  }
}