import '../../../core/api/api_client.dart';
import '../../../core/constants.dart';
import '../domain/product.dart';

class ProductsRepository {
  const ProductsRepository(this._api);

  final ApiClient _api;

  /// The whole active catalogue, unpaginated — it is a short master the
  /// server sends in one go (docs/api/v1-common.md).
  Future<List<Product>> list() async {
    final envelope = await _api.get(AppConstants.products);

    return (envelope.data as List? ?? const [])
        .whereType<Map>()
        .map((row) => Product.fromJson(row.cast<String, dynamic>()))
        .toList();
  }
}
