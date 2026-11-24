import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/state/providers.dart';
import '../domain/product.dart';

/// The product catalogue, fetched once and kept for the session.
///
/// A `FutureProvider` rather than a controller: nothing in the app writes to
/// this list, and it is small enough to hold whole. `ref.invalidate` is the
/// way to re-read it after the admin changes something.
final productsProvider = FutureProvider<List<Product>>((ref) async {
  return ref.watch(productsRepositoryProvider).list();
});
