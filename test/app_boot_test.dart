import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:telecaller_app/app.dart';
import 'package:telecaller_app/core/api/token_store.dart';
import 'package:telecaller_app/core/state/providers.dart';
import 'package:telecaller_app/features/auth/ui/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Boots the real [App] — router, theme and every screen behind it.
///
/// This is the app's compile check as much as its behaviour check: pumping
/// the real widget forces the whole graph through the compiler, which
/// `flutter analyze` alone does not do.
Future<void> pumpApp(WidgetTester tester, {String? token}) async {
  SharedPreferences.setMockInitialValues(
    token == null ? {} : {'auth_token': token},
  );

  final tokens = await TokenStore.open();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [tokenStoreProvider.overrideWithValue(tokens)],
      child: const App(),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('with no token the app opens on login', (tester) async {
    await pumpApp(tester);

    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Sign in'), findsWidgets);
    expect(find.text('Prisha Pharma Telecaller'), findsOneWidget);
  });

  testWidgets('login refuses an empty form before calling the server',
      (tester) async {
    await pumpApp(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pump();

    expect(find.text('Enter your email'), findsOneWidget);
    expect(find.text('Enter your password'), findsOneWidget);
  });

  testWidgets('a stored token sends the app past login', (tester) async {
    await pumpApp(tester, token: 'stored-token');
    // The shell renders; the attendance call will fail against no server,
    // which is the error path, not the login path.
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(LoginScreen), findsNothing);
  });
}
