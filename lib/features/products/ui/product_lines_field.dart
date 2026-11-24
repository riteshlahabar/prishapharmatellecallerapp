import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/app_theme.dart';
import '../../../core/widgets/app_feedback.dart';
import '../../../core/widgets/brand.dart';
import '../domain/product.dart';
import '../state/products_controller.dart';

/// The repeatable product rows: a product and how many boxes of it, with a
/// **+** to add another and a bin to drop one.
///
/// Used in the telecaller app's log-call sheet and on the MR app's visit
/// form — the two are the same field in two places, so it lives in one
/// widget and the screens only read [onChanged]. Keep the two copies in
/// step.
///
/// Nothing here is required: a visit or a call with no products is the
/// normal case, and the field starts empty rather than with a blank row
/// asking to be filled.
class ProductLinesField extends ConsumerStatefulWidget {
  const ProductLinesField({
    required this.onChanged,
    this.title = 'Products',
    this.subtitle = 'Optional — what you discussed, and how many boxes',
    super.key,
  });

  /// Called with the complete, valid lines whenever a row changes. Rows
  /// without a product, or with a quantity below one, are left out.
  final ValueChanged<List<ProductLineInput>> onChanged;

  final String title;
  final String subtitle;

  @override
  ConsumerState<ProductLinesField> createState() => _ProductLinesFieldState();
}

class _ProductLinesFieldState extends ConsumerState<ProductLinesField> {
  final List<_Row> _rows = [];

  @override
  void dispose() {
    for (final row in _rows) {
      row.qty.dispose();
    }
    super.dispose();
  }

  void _publish() {
    widget.onChanged([
      for (final row in _rows)
        if (row.product != null && row.quantity > 0)
          ProductLineInput(productId: row.product!.id, boxQty: row.quantity),
    ]);
  }

  void _add() {
    setState(() => _rows.add(_Row()));
    _publish();
  }

  void _remove(int index) {
    setState(() => _rows.removeAt(index).qty.dispose());
    _publish();
  }

  /// The products this row may choose: everything except what the other
  /// rows already took, so the same product cannot be entered twice.
  List<Product> _choicesFor(int index, List<Product> all) {
    final taken = <int>{
      for (var i = 0; i < _rows.length; i++)
        if (i != index && _rows[i].product != null) _rows[i].product!.id,
    };

    return all.where((p) => !taken.contains(p.id)).toList();
  }

  double get _total => _rows.fold(
    0,
    (sum, row) =>
        sum + (row.product == null ? 0 : row.product!.cost * row.quantity),
  );

  @override
  Widget build(BuildContext context) {
    final catalogue = ref.watch(productsProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const IconPad(
                  icon: Icons.inventory_2_outlined,
                  colour: AppTheme.tileGreen,
                  size: 36,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        widget.subtitle,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_total > 0)
                  StatusChip(
                    label: '₹${_total.toStringAsFixed(2)}',
                    colour: AppTheme.tileGreen,
                  ),
              ],
            ),
            catalogue.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 18),
                child: Center(
                  child: SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
              error: (error, _) => Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        describeError(error),
                        style: const TextStyle(
                          color: AppTheme.danger,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => ref.invalidate(productsProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (products) => _rowsFor(products),
            ),
          ],
        ),
      ),
    );
  }

  Widget _rowsFor(List<Product> products) {
    if (products.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 12),
        child: Text(
          'No products in the catalogue yet.',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 12.5),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < _rows.length; index++)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 5,
                  child: DropdownButtonFormField<Product>(
                    isExpanded: true,
                    initialValue: _rows[index].product,
                    decoration: const InputDecoration(
                      labelText: 'Product',
                      isDense: true,
                    ),
                    items: [
                      for (final product in _choicesFor(index, products))
                        DropdownMenuItem(
                          value: product,
                          child: Text(
                            product.label,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (value) {
                      setState(() => _rows[index].product = value);
                      _publish();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _rows[index].qty,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Boxes',
                      isDense: true,
                    ),
                    onChanged: (_) {
                      setState(() {});
                      _publish();
                    },
                  ),
                ),
                IconButton(
                  tooltip: 'Remove',
                  onPressed: () => _remove(index),
                  icon: const Icon(
                    Icons.delete_outline,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _rows.length >= products.length ? null : _add,
            icon: const Icon(Icons.add, size: 18),
            label: Text(_rows.isEmpty ? 'Add product' : 'Add another'),
          ),
        ),
      ],
    );
  }
}

/// One row's mutable state. The quantity is a controller rather than an int
/// so a half-typed value ("1" on the way to "12") is never thrown away.
class _Row {
  _Row() : qty = TextEditingController(text: '1');

  final TextEditingController qty;
  Product? product;

  int get quantity => int.tryParse(qty.text.trim()) ?? 0;
}
