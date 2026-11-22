import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:telecaller_app/core/api/api_envelope.dart';
import 'package:telecaller_app/features/auth/domain/app_user.dart';
import 'package:telecaller_app/features/calls/domain/call_log.dart';
import 'package:telecaller_app/features/calls/domain/call_status.dart';
import 'package:telecaller_app/features/messages/domain/recipient.dart';
import 'package:telecaller_app/features/messages/domain/sent_message.dart';
import 'package:telecaller_app/features/persons/domain/person.dart';

/// Real responses captured from the Laravel API, not hand-written guesses —
/// so a server-side rename fails here rather than on a telecaller's phone.
ApiEnvelope fixture(String name) => ApiEnvelope.fromJson(
      jsonDecode(File('test/fixtures/$name.json').readAsStringSync())
          as Map<String, dynamic>,
    );

void main() {
  test('login returns a token and the signed-in telecaller', () {
    final data = fixture('login').dataMap;

    expect(data['token_type'], 'Bearer');
    expect((data['token'] as String).isNotEmpty, isTrue);

    final user =
        AppUser.fromJson((data['user'] as Map).cast<String, dynamic>());

    expect(user.role, 'telecaller');
  });

  test('/auth/me carries the regions this telecaller covers', () {
    final user = AppUser.fromJson(fixture('me').dataMap);

    expect(user.role, 'telecaller');
    // A telecaller has many regions and no single region_id; an empty list
    // would mean their whole queue is unexplained in the UI.
    expect(user.regions, isNotEmpty);
    expect(user.regionLabel, isNot('No region assigned'));
  });

  test('the queue carries each row last call, shaped like a call log', () {
    final page = Paginated.from(fixture('persons'), Person.fromJson);

    expect(page.items, isNotEmpty);

    final person = page.items.first;
    expect(person.name, isNotEmpty);
    expect(person.regionName, isNotEmpty);
    expect(person.subtitle, contains(person.typeLabel));

    // `last_call` arrives already rendered by the Calls module's resource,
    // so the same parser reads it here and on /call-logs.
    expect(person.lastCall, isNotNull);
    expect(person.neverCalled, isFalse);
    expect(person.lastCall!.statusLabel, isNotEmpty);
  });

  test('a person never rung has no last_call key at all', () {
    // The server omits the key rather than sending null, so parsing must
    // not depend on it being present.
    final person = Person.fromJson(const {
      'id': 9,
      'name': 'Dr New',
      'type': 'doctor',
      'type_label': 'Doctor',
    });

    expect(person.lastCall, isNull);
    expect(person.neverCalled, isTrue);
    expect(person.hasDueFollowUp, isFalse);
  });

  test('call logs parse, including the status enum and the person', () {
    final page = Paginated.from(fixture('calls'), CallLog.fromJson);

    expect(page.items, isNotEmpty);

    for (final call in page.items) {
      expect(call.status, isNotNull,
          reason: 'unmapped status on call ${call.id}');
      expect(call.statusLabel, isNotEmpty);
    }
  });

  test('an open call-back parses with its promise intact', () {
    final page = Paginated.from(fixture('followups'), CallLog.fromJson);

    expect(page.items, isNotEmpty);

    final call = page.items.first;
    expect(call.status, CallStatus.callback);
    expect(call.followUpOpen, isTrue);
    expect(call.followUpAt, isNotNull);
    expect(call.followUpDoneAt, isNull);
    expect(call.personName, isNotEmpty);
  });

  test('every CallStatus round-trips, and only callback wants a date', () {
    for (final status in CallStatus.values) {
      expect(CallStatus.fromValue(status.value), status);
    }
    expect(CallStatus.fromValue('not_a_status'), isNull);

    // The server requires follow_up_at on callback and refuses it
    // elsewhere, so exactly one case may be true.
    expect(
      CallStatus.values.where((s) => s.needsFollowUp).toList(),
      [CallStatus.callback],
    );
  });

  test('recipients are MRs with their region, and nothing else', () {
    final list = fixture('mrs').dataList.map(Recipient.fromJson).toList();

    expect(list, isNotEmpty);
    expect(list.first.name, isNotEmpty);
    expect(list.first.regionName, isNotEmpty);
  });

  test('sent messages carry the recipient read state', () {
    final page = Paginated.from(fixture('sent'), SentMessage.fromJson);

    expect(page.items, isNotEmpty);

    final message = page.items.first;
    expect(message.subject, isNotEmpty);
    expect(message.body, isNotEmpty);
    expect(message.toName, isNotEmpty);
    expect(message.isRead, isA<bool>());
  });
}
