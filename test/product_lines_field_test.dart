import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:telecaller_app/core/app_theme.dart';
import 'package:telecaller_app/features/products/domain/product.dart';
import 'package:telecaller_app/features/products/state/products_controller.dart';
import 'package:telecaller_app/features/products/ui/product_lines_field.dart';

/// The repeatable product rows shared by the visit form and the telecaller
/// app's call sheet.
void main() {
  const catalogue = [
    Product(id: 1, name: 'Paracetamol 500mg', cost: 120, boxQty: 40),
    Product(id: 2, name: 'Amoxicillin 250mg', cost: 45.5, boxQty: 0),
  ];

  late List<ProductLineInput> reported;

  Future<void> pump(WidgetTester tester, {List<Product> products = catalogue}) {
    reported = const [];

    return tester.pumpWidget(
      ProviderScope(
        overrides: [
          productsProvider.overrideWith((ref) async => products),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: SingleChildScrollView(
              child: ProductLinesField(onChanged: (lines) => reported = lines),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('starts with no rows at all', (tester) async {
    await pump(tester);
    await tester.pumpAndSettle();

    expect(find.text('Add product'), findsOneWidget);
    expect(find.text('Boxes'), findsNothing);
    expect(reported, isEmpty);
  });

  testWidgets('+ adds a row, and a row reports nothing until a product is picked',
      (tester) async {
    await pump(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add product'));
    await tester.pumpAndSettle();

    expect(find.text('Boxes'), findsOneWidget);
    expect(reported, isEmpty);
  });

  testWidgets('picking a product reports one line of one box', (tester) async {
    await pump(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add product'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButtonFormField<Product>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Paracetamol 500mg · ₹120.00').last);
    await tester.pumpAndSettle();

    expect(reported, hasLength(1));
    expect(reported.first.productId, 1);
    expect(reported.first.boxQty, 1);
  });

  testWidgets('the quantity is read off the field', (tester) async {
    await pump(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add product'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<Product>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Amoxicillin 250mg · ₹45.50').last);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), '12');
    await tester.pumpAndSettle();

    expect(reported.single.boxQty, 12);
  });

  /// A blank quantity is not zero boxes of something — it is an unfinished
  /// row, and the server should not be told about it.
  testWidgets('an empty quantity drops the line', (tester) async {
    await pump(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add product'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<Product>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Paracetamol 500mg · ₹120.00').last);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), '');
    await tester.pumpAndSettle();

    expect(reported, isEmpty);
  });

  testWidgets('removing a row takes its line with it', (tester) async {
    await pump(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add product'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<Product>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Paracetamol 500mg · ₹120.00').last);
    await tester.pumpAndSettle();

    expect(reported, hasLength(1));

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();

    expect(reported, isEmpty);
    expect(find.text('Add product'), findsOneWidget);
  });

  testWidgets('an empty catalogue says so and offers no +', (tester) async {
    await pump(tester, products: const []);
    await tester.pumpAndSettle();

    expect(find.text('No products in the catalogue yet.'), findsOneWidget);
    expect(find.text('Add product'), findsNothing);
  });
}
