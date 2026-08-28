import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/theme.dart';
import '../../providers/product_provider.dart';

class BulkProductEditorSheet extends ConsumerStatefulWidget {
  final List<String> skus;

  const BulkProductEditorSheet({
    super.key,
    required this.skus,
  });

  @override
  ConsumerState<BulkProductEditorSheet> createState() =>
      _BulkProductEditorSheetState();
}

class _BulkProductEditorSheetState
    extends ConsumerState<BulkProductEditorSheet> {
  final _valueController = TextEditingController();

  String _field = 'price';
  String _mode = 'set';
  bool _boolValue = true;
  bool _saving = false;

  static const _fieldLabels = {
    'price': 'Sale Price',
    'compare_price': 'MRP',
    'stock': 'Stock',
    'category': 'Category',
    'subcategory': 'Subcategory',
'material': 'Material',
'finish': 'Finish',
'tags': 'Tags',
    'is_active': 'Active Status',
    'is_featured': 'Featured Status',
  };

  bool get _isNumeric =>
      _field == 'price' ||
      _field == 'compare_price' ||
      _field == 'stock';

  bool get _isBoolean =>
      _field == 'is_active' ||
      _field == 'is_featured';

  List<String> get _availableModes {
    if (_field == 'stock') {
      return const [
        'set',
        'add',
        'subtract',
      ];
    }

    if (_field == 'price') {
      return const [
        'set',
        'increase_amount',
        'decrease_amount',
        'increase_percent',
        'decrease_percent',
      ];
    }

    if (_field == 'compare_price') {
      return const [
        'set',
        'clear',
        'increase_amount',
        'decrease_amount',
        'increase_percent',
        'decrease_percent',
      ];
    }

    return const ['set'];
  }

  String _modeLabel(String mode) {
    switch (mode) {
      case 'set':
        return 'Set exact value';
      case 'clear':
        return 'Clear value';
      case 'add':
        return 'Add quantity';
      case 'subtract':
        return 'Subtract quantity';
      case 'increase_amount':
        return 'Increase by amount';
      case 'decrease_amount':
        return 'Decrease by amount';
      case 'increase_percent':
        return 'Increase by percentage';
      case 'decrease_percent':
        return 'Decrease by percentage';
      default:
        return mode;
    }
  }

  Future<void> _apply() async {
    if (_saving) return;

    final changes = <String, dynamic>{};

    if (_isBoolean) {
      changes[_field] = _boolValue ? 1 : 0;
    } else if (_field == 'tags') {
      final tags = _valueController.text
          .split(',')
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .toSet()
          .toList();

      changes['tags'] = tags;
    } else if (_isNumeric) {
      if (_mode == 'clear') {
        changes[_field] = {'mode': 'clear'};
      } else {
        final value = double.tryParse(
          _valueController.text.trim(),
        );

        if (value == null || value < 0) {
          _showMessage('Enter a valid non-negative value');
          return;
        }

        changes[_field] = {
          'mode': _mode,
          'value': value,
        };
      }
    } else {
      final value = _valueController.text.trim();

      if (value.isEmpty) {
        _showMessage('Enter a value');
        return;
      }

      changes[_field] = value;
    }

    setState(() => _saving = true);

    final success = await ref
        .read(productProvider.notifier)
        .bulkUpdateProducts(widget.skus, changes);

    if (!mounted) return;

    setState(() => _saving = false);

    if (success) {
      Navigator.pop(context, true);
    } else {
      final error = ref.read(productProvider).error;
      _showMessage(error ?? 'Bulk update failed');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Bulk Product Editor',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              Text(
                '${widget.skus.length} products selected',
                style: TextStyle(
                  color: KaapavTheme.gold,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 18),
              DropdownButtonFormField<String>(
                value: _field,
                decoration: const InputDecoration(
                  labelText: 'Field to update',
                  border: OutlineInputBorder(),
                ),
                items: _fieldLabels.entries
                    .map(
                      (entry) => DropdownMenuItem(
                        value: entry.key,
                        child: Text(entry.value),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;

                  setState(() {
                    _field = value;
                    _mode = 'set';
                    _valueController.clear();
                  });
                },
              ),
              const SizedBox(height: 14),
              if (_isNumeric)
                DropdownButtonFormField<String>(
                  value: _mode,
                  decoration: const InputDecoration(
                    labelText: 'Operation',
                    border: OutlineInputBorder(),
                  ),
                  items: _availableModes
                      .map(
                        (mode) => DropdownMenuItem(
                          value: mode,
                          child: Text(_modeLabel(mode)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _mode = value);
                  },
                ),
              if (_isNumeric) const SizedBox(height: 14),
              if (_isBoolean)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    _field == 'is_active'
                        ? 'Products enabled'
                        : 'Products featured',
                  ),
                  value: _boolValue,
                  activeColor: KaapavTheme.gold,
                  onChanged: (value) {
                    setState(() => _boolValue = value);
                  },
                )
              else if (_mode != 'clear')
                TextField(
                  controller: _valueController,
                  keyboardType: _isNumeric
                      ? const TextInputType.numberWithOptions(
                          decimal: true,
                        )
                      : TextInputType.text,
                  decoration: InputDecoration(
                    labelText: _field == 'tags'
                        ? 'Comma-separated tags'
                        : 'New value',
                    hintText: _field == 'tags'
                        ? 'On Offer, Bestseller'
                        : null,
                    border: const OutlineInputBorder(),
                  ),
                ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : KaapavTheme.gold.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'This change will affect all '
                  '${widget.skus.length} selected products.',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _saving ? null : _apply,
                  style: FilledButton.styleFrom(
                    backgroundColor: KaapavTheme.gold,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                    ),
                  ),
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.save_rounded),
                  label: Text(
                    _saving
                        ? 'Applying changes...'
                        : 'Apply Bulk Change',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}