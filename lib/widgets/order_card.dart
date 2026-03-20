import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:kaapav_app/config/theme.dart';
import '../models/order.dart';

class OrderCard extends StatelessWidget {
  final Order order;
  final VoidCallback? onTap;

  const OrderCard({
    super.key,
    required this.order,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final preview = _buildItemPreview(order.items, order.itemCount);

    final bool isAttention = order.status == 'pending' && order.paymentStatus == 'unpaid';
    final bool isReadyToShip = order.status == 'confirmed' && order.paymentStatus == 'paid';
    final bool isPaidConfirmed = order.paymentStatus == 'paid' && order.status == 'confirmed';

    final Color priorityColor = isAttention
        ? const Color(0xFFEF4444)
        : isReadyToShip
            ? const Color(0xFF7C3AED)
            : isPaidConfirmed
                ? const Color(0xFF3B82F6)
                : const Color(0xFFE5E7EB);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : const Color(0xFFE5E7EB),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 138,
                  decoration: BoxDecoration(
                    color: priorityColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(14),
                      bottomLeft: Radius.circular(14),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                order.orderId,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: KaapavTheme.gold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _StatusChip(status: order.status),
                          ],
                        ),

                        const SizedBox(height: 10),

                        // Customer
                        Row(
                          children: [
                            const Icon(
                              Icons.person_outline,
                              size: 16,
                              color: Color(0xFF9CA3AF),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                order.customerName ?? order.phone,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark
                                      ? Colors.white70
                                      : const Color(0xFF374151),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // Item preview + total
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _OrderThumb(
                              imageUrl: preview.imageUrl,
                              isDark: isDark,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    preview.title,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF1F2937),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (preview.subtitle.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      preview.subtitle,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF9CA3AF),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '\u20B9${order.total.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color:
                                    isDark ? Colors.white : const Color(0xFF1A1A1A),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        // Chips row
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            _PaymentChip(status: order.paymentStatus),
                            _SourceChip(source: order.source),
                            if (isReadyToShip) const _ReadyToShipChip(),
                            if ((order.shiprocketOrderId ?? '').isNotEmpty)
                              _MiniInfoChip(
                                label: 'SR Booked',
                                bg: const Color(0xFFEDE9FE),
                                fg: const Color(0xFF7C3AED),
                                icon: Icons.inventory_2_outlined,
                              ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // Bottom row
                        Row(
                          children: [
                            if (order.hasTracking)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0891B2)
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.local_shipping_outlined,
                                      size: 14,
                                      color: Color(0xFF0891B2),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'AWB: ${order.awbNumber}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF0891B2),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            const Spacer(),
                            Text(
                              _formatDate(order.createdAt),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF9CA3AF),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _ItemPreview _buildItemPreview(List<dynamic> items, int itemCount) {
    if (items.isEmpty) {
      return _ItemPreview(
        title: '$itemCount item${itemCount == 1 ? '' : 's'}',
        subtitle: '',
        imageUrl: null,
      );
    }

    final normalized = items
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    if (normalized.isEmpty) {
      return _ItemPreview(
        title: '$itemCount item${itemCount == 1 ? '' : 's'}',
        subtitle: '',
        imageUrl: null,
      );
    }

    final first = normalized.first;
    final firstName = (first['name'] ?? 'Item').toString().trim();
    final imageUrl =
        (first['image_url'] ?? first['image'] ?? '').toString().trim();

    final skus = <String>[];
    final categories = <String>[];

    for (final item in normalized) {
      final sku = (item['sku'] ?? '').toString().trim();
      final explicitCategory = (item['category'] ?? '').toString().trim();
      final itemName = (item['name'] ?? '').toString().trim();

      if (sku.isNotEmpty && sku != 'MANUAL' && !skus.contains(sku)) {
        skus.add(sku);
      }

      final category = explicitCategory.isNotEmpty
          ? explicitCategory
          : _extractCategoryFromName(itemName);

      if (category.isNotEmpty && !categories.contains(category)) {
        categories.add(category);
      }
    }

    final itemLabel = '$itemCount item${itemCount == 1 ? '' : 's'}';
    final skuText = skus.isNotEmpty ? skus.join(', ') : '';
    final categoryText = categories.isNotEmpty ? categories.join(', ') : '';

    final parts = <String>[
      if (skuText.isNotEmpty) skuText,
      itemLabel,
      if (categoryText.isNotEmpty) categoryText,
    ];

    return _ItemPreview(
      title: firstName,
      subtitle: parts.join(' • '),
      imageUrl: imageUrl.isNotEmpty ? imageUrl : null,
    );
  }

  String _extractCategoryFromName(String name) {
    final lower = name.toLowerCase();

    if (lower.contains('bracelet')) return 'Bracelet';
    if (lower.contains('ring')) return 'Ring';
    if (lower.contains('earring')) return 'Earring';
    if (lower.contains('pendant set')) return 'Pendant Set';
    if (lower.contains('pendant')) return 'Pendant';
    if (lower.contains('necklace')) return 'Necklace';
    if (lower.contains('bangle')) return 'Bangle';
    if (lower.contains('jhumka')) return 'Earring';
    if (lower.contains('stud')) return 'Earring';

    return '';
  }

  String _formatDate(String? date) {
    if (date == null) return '';
    try {
      final dt = DateTime.parse(date);
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inDays == 0) return 'Today';
      if (diff.inDays == 1) return 'Yesterday';
      return '${dt.day}/${dt.month}/${dt.year.toString().substring(2)}';
    } catch (_) {
      return '';
    }
  }
}

class _ItemPreview {
  final String title;
  final String subtitle;
  final String? imageUrl;

  const _ItemPreview({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
  });
}

class _OrderThumb extends StatelessWidget {
  final String? imageUrl;
  final bool isDark;

  const _OrderThumb({
    required this.imageUrl,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: isDark ? const Color(0xFF1F1F1F) : const Color(0xFFF5F0E8),
      ),
      clipBehavior: Clip.antiAlias,
      child: imageUrl != null && imageUrl!.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: imageUrl!,
              fit: BoxFit.cover,
              placeholder: (_, __) => const Center(
                child: Icon(
                  Icons.diamond_outlined,
                  size: 18,
                  color: Color(0xFFC49432),
                ),
              ),
              errorWidget: (_, __, ___) => const Center(
                child: Icon(
                  Icons.diamond_outlined,
                  size: 18,
                  color: Color(0xFFC49432),
                ),
              ),
            )
          : const Center(
              child: Icon(
                Icons.diamond_outlined,
                size: 18,
                color: Color(0xFFC49432),
              ),
            ),
    );
  }
}

class _MiniInfoChip extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  final IconData icon;

  const _MiniInfoChip({
    required this.label,
    required this.bg,
    required this.fg,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: fg,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadyToShipChip extends StatelessWidget {
  const _ReadyToShipChip();

  @override
  Widget build(BuildContext context) {
    return const _MiniInfoChip(
      label: 'Ready for Shiprocket',
      bg: Color(0xFFEDE9FE),
      fg: Color(0xFF7C3AED),
      icon: Icons.local_shipping_rounded,
    );
  }
}

class _SourceChip extends StatelessWidget {
  final String source;
  const _SourceChip({required this.source});

  @override
  Widget build(BuildContext context) {
    final value = source.trim().isEmpty ? 'unknown' : source.trim().toLowerCase();

    Color bg;
    Color fg;

    switch (value) {
      case 'whatsapp':
        bg = const Color(0xFFDCFCE7);
        fg = const Color(0xFF15803D);
        break;
      case 'catalogue':
        bg = const Color(0xFFDBEAFE);
        fg = const Color(0xFF2563EB);
        break;
      case 'manual':
        bg = const Color(0xFFFFEDD5);
        fg = const Color(0xFFC2410C);
        break;
      case 'website':
        bg = const Color(0xFFFCE7F3);
        fg = const Color(0xFFBE185D);
        break;
      default:
        bg = const Color(0xFFF3F4F6);
        fg = const Color(0xFF6B7280);
    }

    return _MiniInfoChip(
      label: value[0].toUpperCase() + value.substring(1),
      bg: bg,
      fg: fg,
      icon: Icons.label_outline_rounded,
    );
  }
}

// ── Status chip ────────────────────────────────────────────────
class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final cfg = _config();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: cfg.bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(cfg.icon, size: 11, color: cfg.fg),
          const SizedBox(width: 4),
          Text(
            status[0].toUpperCase() + status.substring(1),
            style: TextStyle(
              fontSize: 11,
              color: cfg.fg,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  _ChipCfg _config() {
    switch (status) {
      case 'pending':
        return _ChipCfg(
          const Color(0xFFFEF3C7),
          const Color(0xFFD97706),
          Icons.hourglass_empty_rounded,
        );
      case 'confirmed':
        return _ChipCfg(
          const Color(0xFFDBEAFE),
          const Color(0xFF2563EB),
          Icons.check_circle_outline_rounded,
        );
      case 'processing':
        return _ChipCfg(
          const Color(0xFFEDE9FE),
          const Color(0xFF7C3AED),
          Icons.settings_outlined,
        );
      case 'shipped':
        return _ChipCfg(
          const Color(0xFFCFFAFE),
          const Color(0xFF0891B2),
          Icons.local_shipping_outlined,
        );
      case 'delivered':
        return _ChipCfg(
          const Color(0xFFD1FAE5),
          const Color(0xFF059669),
          Icons.done_all_rounded,
        );
      case 'cancelled':
        return _ChipCfg(
          const Color(0xFFFEE2E2),
          const Color(0xFFDC2626),
          Icons.cancel_outlined,
        );
      default:
        return _ChipCfg(
          const Color(0xFFF3F4F6),
          const Color(0xFF6B7280),
          Icons.help_outline_rounded,
        );
    }
  }
}

class _ChipCfg {
  final Color bg, fg;
  final IconData icon;
  const _ChipCfg(this.bg, this.fg, this.icon);
}

class _PaymentChip extends StatelessWidget {
  final String status;
  const _PaymentChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final isPaid = status == 'paid';
    final isRefunded = status == 'refunded';

    final Color bg;
    final Color fg;
    final IconData icon;
    final String label;

    if (isPaid) {
      bg = const Color(0xFFD1FAE5);
      fg = const Color(0xFF059669);
      icon = Icons.check_circle_outline_rounded;
      label = 'Paid';
    } else if (isRefunded) {
      bg = const Color(0xFFFEF3C7);
      fg = const Color(0xFFD97706);
      icon = Icons.replay_rounded;
      label = 'Refunded';
    } else {
      bg = const Color(0xFFFEE2E2);
      fg = const Color(0xFFDC2626);
      icon = Icons.cancel_outlined;
      label = 'Unpaid';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: fg,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}