@Tags(['screenshot'])
library;

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:telecaller_app/core/api/api_envelope.dart';
import 'package:telecaller_app/core/app_theme.dart';
import 'package:telecaller_app/features/auth/domain/app_user.dart';
import 'package:telecaller_app/features/auth/state/auth_controller.dart';
import 'package:telecaller_app/features/auth/ui/login_screen.dart';
import 'package:telecaller_app/features/calls/domain/call_log.dart';
import 'package:telecaller_app/features/calls/domain/call_status.dart';
import 'package:telecaller_app/features/calls/state/calls_controller.dart';
import 'package:telecaller_app/features/calls/ui/follow_ups_screen.dart';
import 'package:telecaller_app/features/calls/ui/history_screen.dart';
import 'package:telecaller_app/features/messages/domain/sent_message.dart';
import 'package:telecaller_app/features/messages/state/messages_controller.dart';
import 'package:telecaller_app/features/messages/ui/sent_screen.dart';
import 'package:telecaller_app/features/persons/domain/person.dart';
import 'package:telecaller_app/features/persons/state/persons_controller.dart';
import 'package:telecaller_app/features/persons/ui/queue_screen.dart';

/// Renders each screen to a PNG for human review of the ProKit styling.
/// Run: flutter test test/screenshot_test.dart --update-goldens

class _Auth extends AuthController {
  @override
  AppUser? build() => const AppUser(
        id: 4,
        name: 'Ravi Kulkarni',
        email: 'ravi@prishapharma.in',
        role: 'telecaller',
        mobile: '98200 44556',
        regions: [
          Region(id: 1, name: 'Pune West', code: 'PW'),
          Region(id: 2, name: 'Pune East', code: 'PE'),
        ],
      );
}

CallLog _call({
  required int id,
  required CallStatus status,
  String? person,
  String? notes,
  DateTime? at,
  DateTime? followUp,
  bool due = false,
}) =>
    CallLog(
      id: id,
      status: status,
      statusLabel: status.label,
      personName: person,
      personMobile: '9820011223',
      notes: notes,
      calledAt: at,
      followUpAt: followUp,
      followUpOpen: followUp != null,
      followUpDue: due,
    );

final _queue = Paginated<Person>(
  items: [
    Person(
      id: 1,
      name: 'Dr Meera Joshi',
      type: 'doctor',
      typeLabel: 'Doctor',
      mobile: '9820011223',
      city: 'Pune',
      specialization: 'Cardiology',
      regionName: 'Pune West',
      lastCall: _call(
        id: 9,
        status: CallStatus.callback,
        at: DateTime(2026, 11, 20, 11, 5),
        followUp: DateTime(2026, 11, 22, 10),
        due: true,
      ),
    ),
    Person(
      id: 2,
      name: 'Sunrise Medical Store',
      type: 'medical',
      typeLabel: 'Medical store',
      mobile: '9820099887',
      city: 'Pune',
      regionName: 'Pune West',
      lastCall: _call(
        id: 8,
        status: CallStatus.converted,
        at: DateTime(2026, 11, 19, 15, 40),
      ),
    ),
    const Person(
      id: 3,
      name: 'Dr Anil Deshmukh',
      type: 'doctor',
      typeLabel: 'Doctor',
      mobile: '9820055443',
      city: 'Pune',
      specialization: 'Paediatrics',
      regionName: 'Pune East',
    ),
  ],
  page: 1,
  lastPage: 1,
  total: 3,
  hasMore: false,
);

class _FollowUps extends AsyncNotifier<Paginated<CallLog>> {
  @override
  Future<Paginated<CallLog>> build() async => Paginated(
        items: [
          _call(
            id: 81,
            status: CallStatus.callback,
            person: 'Dr Meera Joshi',
            notes: 'Asked to be rung back after the weekend.',
            at: DateTime(2026, 11, 20, 11, 5),
            followUp: DateTime(2026, 11, 22, 10),
            due: true,
          ),
          _call(
            id: 77,
            status: CallStatus.callback,
            person: 'Krishna Pharmacy',
            at: DateTime(2026, 11, 21, 9, 30),
            followUp: DateTime(2026, 11, 25, 16),
          ),
        ],
        page: 1,
        lastPage: 1,
        total: 2,
        hasMore: false,
      );
}

class _History extends CallHistory {
  @override
  Future<Paginated<CallLog>> build() async => Paginated(
        items: [
          _call(
            id: 80,
            status: CallStatus.converted,
            person: 'Sunrise Medical Store',
            notes: 'Placing an order through their rep this week.',
            at: DateTime(2026, 11, 22, 9, 15),
          ),
          _call(
            id: 79,
            status: CallStatus.notReachable,
            person: 'Dr Anil Deshmukh',
            at: DateTime(2026, 11, 21, 17, 2),
          ),
        ],
        page: 1,
        lastPage: 1,
        total: 2,
        hasMore: false,
      );
}

class _Sent extends SentMessages {
  @override
  Future<Paginated<SentMessage>> build() async => Paginated(
        items: [
          SentMessage(
            id: 18,
            subject: 'Dr Meera Joshi: Interested',
            body: 'Asked for a sample pack of the cardio line on your next '
                'round.',
            isRead: true,
            toName: 'Asha Patel',
            personName: 'Dr Meera Joshi',
            sentAt: DateTime(2026, 11, 22, 9, 20),
          ),
          SentMessage(
            id: 15,
            subject: 'Pharmacy wants a delivery date',
            body: 'Sunrise Medical are asking when the next delivery lands.',
            isRead: false,
            toName: 'Asha Patel',
            sentAt: DateTime(2026, 11, 21, 16, 5),
          ),
        ],
        page: 1,
        lastPage: 1,
        total: 2,
        hasMore: false,
      );
}

/// Loads real fonts so the PNGs show text instead of the test font's boxes.
Future<void> loadFonts() async {
  // flutter_tester lives at <cache>/artifacts/engine/<platform>/, so three
  // levels up is the artifacts directory the fonts sit in.
  final artifacts = File(Platform.resolvedExecutable).parent.parent.parent.path;
  final dir = Directory('$artifacts/material_fonts');

  if (!dir.existsSync()) return;

  Future<void> load(String family, List<String> files) async {
    final loader = FontLoader(family);
    var found = false;

    for (final name in files) {
      final file = File('${dir.path}/$name');
      if (file.existsSync()) {
        loader.addFont(Future.value(file.readAsBytesSync().buffer.asByteData()));
        found = true;
      }
    }

    if (found) await loader.load();
  }

  await load('Roboto', [
    'Roboto-Regular.ttf',
    'Roboto-Medium.ttf',
    'Roboto-Bold.ttf',
  ]);
  await load('MaterialIcons', ['MaterialIcons-Regular.otf']);
}

/// The app theme with Roboto substituted for Poppins, because google_fonts
/// cannot fetch a typeface offline. Colour, spacing and layout are the
/// app's own; only the face differs.
ThemeData get reviewTheme {
  final base = AppTheme.light;
  const label = TextStyle(
    fontFamily: 'Roboto',
    fontSize: 15,
    fontWeight: FontWeight.w600,
  );

  return base.copyWith(
    textTheme: base.textTheme.apply(fontFamily: 'Roboto'),
    primaryTextTheme: base.primaryTextTheme.apply(fontFamily: 'Roboto'),
    filledButtonTheme: FilledButtonThemeData(
      style: base.filledButtonTheme.style
          ?.copyWith(textStyle: WidgetStateProperty.all(label)),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: base.outlinedButtonTheme.style
          ?.copyWith(textStyle: WidgetStateProperty.all(label)),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        textStyle: const TextStyle(fontFamily: 'Roboto', fontSize: 14),
      ),
    ),
  );
}

Future<void> shoot(WidgetTester tester, String name, Widget tree) async {
  // A typical mid-range Android handset, which is what telecallers use.
  tester.view.physicalSize = const Size(1080, 2160);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  await loadFonts();
  await tester.pumpWidget(tree);
  await tester.pumpAndSettle();

  await expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('golden/$name.png'),
  );
}

void main() {
  testWidgets('login', (t) async {
    await shoot(
      t,
      'login',
      ProviderScope(
        child: MaterialApp(theme: reviewTheme, home: const LoginScreen()),
      ),
    );
  });

  testWidgets('queue', (t) async {
    await shoot(
      t,
      'queue',
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(_Auth.new),
          queueProvider.overrideWith((ref) async => _queue),
          followUpsProvider.overrideWith((ref) async => Paginated.empty()),
        ],
        child: MaterialApp(theme: reviewTheme, home: const QueueScreen()),
      ),
    );
  });

  testWidgets('follow ups', (t) async {
    await shoot(
      t,
      'follow_ups',
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(_Auth.new),
          followUpsProvider
              .overrideWith((ref) async => await _FollowUps().build()),
        ],
        child: MaterialApp(theme: reviewTheme, home: const FollowUpsScreen()),
      ),
    );
  });

  testWidgets('history', (t) async {
    await shoot(
      t,
      'history',
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(_Auth.new),
          callHistoryProvider.overrideWith(_History.new),
        ],
        child: MaterialApp(theme: reviewTheme, home: const HistoryScreen()),
      ),
    );
  });

  testWidgets('sent', (t) async {
    await shoot(
      t,
      'sent',
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(_Auth.new),
          sentMessagesProvider.overrideWith(_Sent.new),
        ],
        child: MaterialApp(theme: reviewTheme, home: const SentScreen()),
      ),
    );
  });
}
