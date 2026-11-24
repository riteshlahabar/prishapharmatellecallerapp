/// A medical product, as `ProductResource` sends it.
///
/// `cost` arrives as a string because it is a decimal server-side: a price
/// that round-trips through a double is a price that can come back as
/// 119.99999. It is parsed once here, for arithmetic and display only.
class Product {
  const Product({
    required this.id,
    required this.name,
    required this.cost,
    required this.boxQty,
  });

  final int id;
  final String name;
  final double cost;

  /// Stock on hand. Shown so the caller knows what is available; nothing
  /// the app does changes it — that number is the admin's.
  final int boxQty;

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    id: (json['id'] as num?)?.toInt() ?? 0,
    name: json['name'] as String? ?? '',
    cost: double.tryParse('${json['cost'] ?? ''}') ?? 0,
    boxQty: (json['box_qty'] as num?)?.toInt() ?? 0,
  );

  String get costLabel => '₹${cost.toStringAsFixed(2)}';

  /// What the dropdown shows: the name and what a box costs.
  String get label => '$name · $costLabel';

  bool get isOutOfStock => boxQty <= 0;
}

/// One filled-in row, in the shape the API takes.
class ProductLineInput {
  const ProductLineInput({required this.productId, required this.boxQty});

  final int productId;
  final int boxQty;

  Map<String, Object?> toJson() => {'product_id': productId, 'box_qty': boxQty};
}
