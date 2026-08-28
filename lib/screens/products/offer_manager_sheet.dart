import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/theme.dart';
import '../../models/coupon.dart';
import '../../providers/coupon_provider.dart';

class OfferManagerSheet extends ConsumerStatefulWidget {
  const OfferManagerSheet({super.key});

  @override
  ConsumerState<OfferManagerSheet> createState() =>
      _OfferManagerSheetState();
}

class _OfferManagerSheetState
    extends ConsumerState<OfferManagerSheet> {
  @override
  void initState() {
    super.initState();

    Future.microtask(
      () => ref.read(couponProvider.notifier).loadCoupons(),
    );
  }

  Future<void> _openForm([Coupon? coupon]) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _OfferFormSheet(coupon: coupon),
    );
  }

  Future<void> _remove(Coupon coupon) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove Offer?'),
        content: Text(
          '${coupon.code} will be disabled. '
          'Previous order history will remain safe.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Remove',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await ref
        .read(couponProvider.notifier)
        .removeCoupon(coupon);
  }

  Color _statusColor(Coupon coupon) {
    switch (coupon.statusLabel) {
      case 'Live':
        return KaapavTheme.success;
      case 'Scheduled':
        return KaapavTheme.info;
      case 'Expired':
      case 'Exhausted':
        return KaapavTheme.warning;
      default:
        return KaapavTheme.gray;
    }
  }

  String _formatDate(String? value) {
    if (value == null || value.isEmpty) return 'No limit';

    try {
      final date = DateTime.parse(value).toLocal();
      return '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.year}';
    } catch (_) {
      return value;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(couponProvider);

    return SafeArea(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.92,
        ),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Offer Codes',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                IconButton(
                  tooltip: 'Refresh',
                  onPressed: () => ref
                      .read(couponProvider.notifier)
                      .loadCoupons(),
                  icon: const Icon(Icons.refresh),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.icon(
                onPressed: () => _openForm(),
                style: FilledButton.styleFrom(
                  backgroundColor: KaapavTheme.gold,
                  foregroundColor: Colors.black,
                ),
                icon: const Icon(Icons.add),
                label: const Text('Add Offer'),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: state.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : state.error != null &&
                          state.coupons.isEmpty
                      ? Center(child: Text(state.error!))
                      : state.coupons.isEmpty
                          ? const Center(
                              child: Text(
                                'No offer codes created yet.',
                              ),
                            )
                          : ListView.separated(
                              itemCount: state.coupons.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (_, index) {
                                final coupon =
                                    state.coupons[index];
                                final color =
                                    _statusColor(coupon);

                                return Card(
                                  child: Padding(
                                    padding:
                                        const EdgeInsets.all(14),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                coupon.code,
                                                style: const TextStyle(
                                                  fontSize: 17,
                                                  fontWeight:
                                                      FontWeight.w800,
                                                ),
                                              ),
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets
                                                      .symmetric(
                                                horizontal: 9,
                                                vertical: 4,
                                              ),
                                              decoration:
                                                  BoxDecoration(
                                                color: color
                                                    .withValues(
                                                  alpha: 0.12,
                                                ),
                                                borderRadius:
                                                    BorderRadius
                                                        .circular(20),
                                              ),
                                              child: Text(
                                                coupon.statusLabel,
                                                style: TextStyle(
                                                  color: color,
                                                  fontSize: 11,
                                                  fontWeight:
                                                      FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          '${coupon.displayValue} discount',
                                          style: TextStyle(
                                            color: KaapavTheme.gold,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'From: ${_formatDate(coupon.startsAt)}'
                                          '   •   '
                                          'To: ${_formatDate(coupon.expiresAt)}',
                                          style:
                                              const TextStyle(fontSize: 12),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          coupon.usageLimit == null ||
                                                  coupon.usageLimit! <= 0
                                              ? 'Usage: ${coupon.usedCount} / Unlimited'
                                              : 'Usage: ${coupon.usedCount} / ${coupon.usageLimit}',
                                          style:
                                              const TextStyle(fontSize: 12),
                                        ),
                                        const SizedBox(height: 10),
                                        Row(
                                          children: [
                                            TextButton.icon(
                                              onPressed: () =>
                                                  _openForm(coupon),
                                              icon: const Icon(
                                                Icons.edit,
                                              ),
                                              label:
                                                  const Text('Edit'),
                                            ),
                                            TextButton.icon(
                                              onPressed: () => ref
                                                  .read(
                                                    couponProvider
                                                        .notifier,
                                                  )
                                                  .setActive(
                                                    coupon,
                                                    !coupon.isActive,
                                                  ),
                                              icon: Icon(
                                                coupon.isActive
                                                    ? Icons.pause
                                                    : Icons.play_arrow,
                                              ),
                                              label: Text(
                                                coupon.isActive
                                                    ? 'Disable'
                                                    : 'Activate',
                                              ),
                                            ),
                                            const Spacer(),
                                            IconButton(
                                              tooltip: 'Remove',
                                              onPressed: () =>
                                                  _remove(coupon),
                                              icon: const Icon(
                                                Icons.delete_outline,
                                                color: Colors.red,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OfferFormSheet extends ConsumerStatefulWidget {
  final Coupon? coupon;

  const _OfferFormSheet({
    required this.coupon,
  });

  @override
  ConsumerState<_OfferFormSheet> createState() =>
      _OfferFormSheetState();
}

class _OfferFormSheetState
    extends ConsumerState<_OfferFormSheet> {
  late final TextEditingController _codeController;
  late final TextEditingController _valueController;
  late final TextEditingController _minOrderController;
  late final TextEditingController _maxDiscountController;
  late final TextEditingController _usageController;

  String _type = 'percent';
  DateTime? _fromDate;
  DateTime? _toDate;
  bool _active = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();

    final coupon = widget.coupon;

    _codeController = TextEditingController(
      text: coupon?.code ?? '',
    );
    _valueController = TextEditingController(
      text: coupon == null ? '' : '${coupon.value}',
    );
    _minOrderController = TextEditingController(
      text: coupon?.minOrder == null
          ? ''
          : '${coupon!.minOrder}',
    );
    _maxDiscountController = TextEditingController(
      text: coupon?.maxDiscount == null
          ? ''
          : '${coupon!.maxDiscount}',
    );
    _usageController = TextEditingController(
      text: coupon?.usageLimit == null ||
              coupon!.usageLimit! <= 0
          ? ''
          : '${coupon.usageLimit}',
    );

    _type = coupon?.type ?? 'percent';
    _active = coupon?.isActive ?? true;
    _fromDate = _parseDate(coupon?.startsAt);
    _toDate = _parseDate(coupon?.expiresAt);
  }

  DateTime? _parseDate(String? value) {
    if (value == null || value.isEmpty) return null;

    try {
      return DateTime.parse(value).toLocal();
    } catch (_) {
      return null;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Select date';

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  Future<DateTime?> _pickDate(DateTime? initial) {
    final now = DateTime.now();

    return showDatePicker(
      context: context,
      initialDate: initial ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 10),
    );
  }

  Future<void> _save() async {
    final code = _codeController.text
        .trim()
        .toUpperCase();

    final value = double.tryParse(
      _valueController.text.trim(),
    );

    if (code.length < 3) {
      _message('Offer code must contain at least 3 characters');
      return;
    }

    if (value == null || value <= 0) {
      _message('Enter a valid discount value');
      return;
    }

    if (_type == 'percent' && value > 100) {
      _message('Percentage cannot be above 100');
      return;
    }

    if (_fromDate != null &&
        _toDate != null &&
        _toDate!.isBefore(_fromDate!)) {
      _message('To date cannot be before From date');
      return;
    }

    final fromUtc = _fromDate == null
        ? null
        : DateTime(
            _fromDate!.year,
            _fromDate!.month,
            _fromDate!.day,
          ).toUtc().toIso8601String();

    final toUtc = _toDate == null
        ? null
        : DateTime(
            _toDate!.year,
            _toDate!.month,
            _toDate!.day,
            23,
            59,
            59,
          ).toUtc().toIso8601String();

    final coupon = Coupon(
      id: widget.coupon?.id,
      code: code,
      type: _type,
      value: value,
      minOrder: double.tryParse(
        _minOrderController.text.trim(),
      ),
      maxDiscount: double.tryParse(
        _maxDiscountController.text.trim(),
      ),
      usageLimit:
          int.tryParse(_usageController.text.trim()) ?? 0,
      usedCount: widget.coupon?.usedCount ?? 0,
      startsAt: fromUtc,
      expiresAt: toUtc,
      isActive: _active,
      createdAt: widget.coupon?.createdAt,
    );

    setState(() => _saving = true);

    final notifier = ref.read(couponProvider.notifier);

    final success = widget.coupon == null
        ? await notifier.createCoupon(coupon)
        : await notifier.updateCoupon(coupon);

    if (!mounted) return;

    setState(() => _saving = false);

    if (success) {
      Navigator.pop(context);
    } else {
      _message(
        ref.read(couponProvider).error ??
            'Failed to save offer',
      );
    }
  }

  void _message(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    _valueController.dispose();
    _minOrderController.dispose();
    _maxDiscountController.dispose();
    _usageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(22),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            18,
            18,
            18,
            18 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.coupon == null
                      ? 'Add Offer Code'
                      : 'Edit Offer Code',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: _codeController,
                  textCapitalization:
                      TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Offer code',
                    hintText: 'FESTIVE20',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _type,
                  decoration: const InputDecoration(
                    labelText: 'Discount type',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'percent',
                      child: Text('Percentage'),
                    ),
                    DropdownMenuItem(
                      value: 'fixed',
                      child: Text('Fixed amount'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _type = value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _valueController,
                  keyboardType:
                      const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: _type == 'percent'
                        ? 'Discount percentage'
                        : 'Discount amount',
                    prefixText:
                        _type == 'fixed' ? '₹ ' : null,
                    suffixText:
                        _type == 'percent' ? '%' : null,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _DateButton(
                        label: 'From',
                        value: _formatDate(_fromDate),
                        onTap: () async {
                          final date =
                              await _pickDate(_fromDate);
                          if (date != null) {
                            setState(() => _fromDate = date);
                          }
                        },
                        onClear: _fromDate == null
                            ? null
                            : () => setState(
                                  () => _fromDate = null,
                                ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _DateButton(
                        label: 'To',
                        value: _formatDate(_toDate),
                        onTap: () async {
                          final date =
                              await _pickDate(_toDate);
                          if (date != null) {
                            setState(() => _toDate = date);
                          }
                        },
                        onClear: _toDate == null
                            ? null
                            : () => setState(
                                  () => _toDate = null,
                                ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _minOrderController,
                  keyboardType:
                      const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Minimum order',
                    prefixText: '₹ ',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _maxDiscountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText:
                        'Maximum discount (optional)',
                    prefixText: '₹ ',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _usageController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Usage limit',
                    hintText: 'Blank or 0 = Unlimited',
                    border: OutlineInputBorder(),
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Offer active'),
                  value: _active,
                  activeColor: KaapavTheme.gold,
                  onChanged: (value) {
                    setState(() => _active = value);
                  },
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _saving ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: KaapavTheme.gold,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                      ),
                    ),
                    child: Text(
                      _saving ? 'Saving...' : 'Save Offer',
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
}

class _DateButton extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const _DateButton({
    required this.label,
    required this.value,
    required this.onTap,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        suffixIcon: onClear == null
            ? const Icon(Icons.calendar_month)
            : IconButton(
                onPressed: onClear,
                icon: const Icon(Icons.clear),
              ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(value),
        ),
      ),
    );
  }
}