import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:telecaller_app/core/api/api_client.dart';
import 'package:telecaller_app/core/api/api_failure.dart';
import 'package:telecaller_app/core/api/token_store.dart';
import 'package:telecaller_app/features/calls/data/calls_repository.dart';
import 'package:telecaller_app/features/calls/domain/call_status.dart';

/// Captures the request so the body the client builds can be asserted.
class _Spy implements HttpClientAdapter {
  _Spy(this.body, {this.status = 200});

  final String body;
  final int status;

  RequestOptions? request;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    request = options;

    return ResponseBody.fromString(
      body,
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Future<CallsRepository> _repoWith(_Spy spy) async {
  SharedPreferences.setMockInitialValues({'auth_token': 't'});
  final dio = Dio()..httpClientAdapter = spy;

  return CallsRepository(
    ApiClient(tokens: await TokenStore.open(), dio: dio),
  );
}

String okCall(String status) => jsonEncode({
      'success': true,
      'message': 'Call logged.',
      'data': {'id': 1, 'status': status, 'status_label': status},
    });

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a callback sends follow_up_at', () async {
    final spy = _Spy(okCall('callback'));
    final at = DateTime.now().toUtc().add(const Duration(days: 2));

    await (await _repoWith(spy)).log(
      personId: 1,
      status: CallStatus.callback,
      followUpAt: at,
    );

    final body = spy.request!.data as Map<String, dynamic>;
    expect(body['status'], 'callback');
    expect(body['follow_up_at'], isNotNull);
    // The server compares it against "now", so it must be a plain
    // date-time string, not an ISO value with a zone suffix.
    expect(body['follow_up_at'], matches(r'^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$'));
  });

  test('a non-callback never sends follow_up_at, even if one is passed',
      () async {
    final spy = _Spy(okCall('interested'));

    await (await _repoWith(spy)).log(
      personId: 1,
      status: CallStatus.interested,
      // A stale date left on the form must not reach the wire: the server
      // answers "Only a call-back carries a follow-up date."
      followUpAt: DateTime.now().add(const Duration(days: 2)),
    );

    final body = spy.request!.data as Map<String, dynamic>;
    expect(body.containsKey('follow_up_at'), isFalse);
  });

  test('empty notes are left out rather than sent blank', () async {
    final spy = _Spy(okCall('interested'));

    await (await _repoWith(spy))
        .log(personId: 1, status: CallStatus.interested, notes: '');

    expect((spy.request!.data as Map).containsKey('notes'), isFalse);
  });

  test('the client never sends telecaller_id or called_at', () async {
    final spy = _Spy(okCall('converted'));

    await (await _repoWith(spy))
        .log(personId: 1, status: CallStatus.converted, notes: 'Signed.');

    final body = spy.request!.data as Map<String, dynamic>;
    // Both come from the token and the server clock; sending them would be
    // a device claiming when it did the work.
    expect(body.containsKey('telecaller_id'), isFalse);
    expect(body.containsKey('called_at'), isFalse);
  });

  test('the real "callback needs a date" 422 surfaces on the field',
      () async {
    final spy = _Spy(
      File('test/fixtures/error_cb_nodate.json').readAsStringSync(),
      status: 422,
    );

    final failure = await (await _repoWith(spy))
        .log(personId: 1, status: CallStatus.callback)
        .then<ApiFailure?>((_) => null, onError: (Object e) => e as ApiFailure);

    expect(failure!.reason, ApiReason.validation);
    expect(failure.fieldError('follow_up_at'),
        'A call-back needs a date to come back on.');
  });

  test('the real "date must be future" 422 surfaces on the field', () async {
    final spy = _Spy(
      File('test/fixtures/error_past.json').readAsStringSync(),
      status: 422,
    );

    final failure = await (await _repoWith(spy))
        .log(
          personId: 1,
          status: CallStatus.callback,
          followUpAt: DateTime.now().add(const Duration(days: 1)),
        )
        .then<ApiFailure?>((_) => null, onError: (Object e) => e as ApiFailure);

    expect(failure!.fieldError('follow_up_at'),
        'The follow-up date has to be in the future.');
  });

  test('follow-ups asks for due only, or everything open', () async {
    final page = jsonEncode({'success': true, 'data': <dynamic>[]});

    var spy = _Spy(page);
    await (await _repoWith(spy)).followUps();
    expect(spy.request!.queryParameters['due'], 1);

    spy = _Spy(page);
    await (await _repoWith(spy)).followUps(dueOnly: false);
    expect(spy.request!.queryParameters['due'], 0);
  });
}
