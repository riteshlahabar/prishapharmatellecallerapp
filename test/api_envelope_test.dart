import 'package:flutter_test/flutter_test.dart';
import 'package:telecaller_app/core/api/api_envelope.dart';
import 'package:telecaller_app/core/api/api_failure.dart';

void main() {
  group('ApiEnvelope', () {
    test('reads a success envelope', () {
      final envelope = ApiEnvelope.fromJson({
        'success': true,
        'message': 'Today loaded.',
        'data': {'status': 'On duty'},
      });

      expect(envelope.success, isTrue);
      expect(envelope.message, 'Today loaded.');
      expect(envelope.dataMap['status'], 'On duty');
    });

    test('a failure envelope is not success, whatever the data says', () {
      final envelope = ApiEnvelope.fromJson({
        'success': false,
        'message': 'Not found.',
        'errors': {'reason': 'not_found'},
      });

      expect(envelope.success, isFalse);
      expect(envelope.errors?['reason'], 'not_found');
    });

    test('a missing success key is treated as failure, not success', () {
      // Defensive: anything that is not literally `true` must not be read
      // as a success, or a malformed body would look like an empty result.
      expect(ApiEnvelope.fromJson({'message': 'hm'}).success, isFalse);
      expect(ApiEnvelope.fromJson({'success': 'yes'}).success, isFalse);
    });

    test('dataList skips anything that is not an object', () {
      final envelope = ApiEnvelope.fromJson({
        'success': true,
        'data': [
          {'id': 1},
          'rubbish',
          {'id': 2},
        ],
      });

      expect(envelope.dataList.map((e) => e['id']), [1, 2]);
    });
  });

  group('Paginated', () {
    test('reads meta and trusts has_more over page arithmetic', () {
      final page = Paginated.from(
        ApiEnvelope.fromJson({
          'success': true,
          'data': [
            {'id': 7},
          ],
          'meta': {
            'current_page': 2,
            'last_page': 5,
            'per_page': 20,
            'total': 93,
            'has_more': true,
          },
        }),
        (json) => json['id'] as int,
      );

      expect(page.items, [7]);
      expect(page.page, 2);
      expect(page.total, 93);
      expect(page.hasMore, isTrue);
    });

    test('survives a list with no meta at all', () {
      final page = Paginated.from(
        ApiEnvelope.fromJson({'success': true, 'data': <dynamic>[]}),
        (json) => json,
      );

      expect(page.items, isEmpty);
      expect(page.page, 1);
      expect(page.hasMore, isFalse);
    });
  });

  group('ApiReason', () {
    test('maps every reason the server documents', () {
      expect(ApiReason.parse('unauthenticated'), ApiReason.unauthenticated);
      expect(ApiReason.parse('account_inactive'), ApiReason.accountInactive);
      expect(ApiReason.parse('role_changed'), ApiReason.roleChanged);
      expect(ApiReason.parse('already_checked_in'), ApiReason.alreadyCheckedIn);
      expect(ApiReason.parse('wrong_app'), ApiReason.wrongApp);
    });

    test('an unknown reason degrades instead of throwing', () {
      // A newer server may invent reasons this build has never seen.
      expect(ApiReason.parse('teapot'), ApiReason.unknown);
      expect(ApiReason.parse(null), ApiReason.unknown);
    });
  });

  group('ApiFailure', () {
    test('only the three terminal reasons force a sign-out', () {
      bool signsOut(ApiReason reason) =>
          ApiFailure(reason: reason, message: '').requiresSignOut;

      expect(signsOut(ApiReason.unauthenticated), isTrue);
      expect(signsOut(ApiReason.accountInactive), isTrue);
      expect(signsOut(ApiReason.roleChanged), isTrue);

      // A 403 on one endpoint must NOT log the rep out of the whole app.
      expect(signsOut(ApiReason.forbidden), isFalse);
      expect(signsOut(ApiReason.validation), isFalse);
      expect(signsOut(ApiReason.notFound), isFalse);
      expect(signsOut(ApiReason.network), isFalse);
    });

    test('exposes the first message for a field', () {
      const failure = ApiFailure(
        reason: ApiReason.validation,
        message: 'The given data was invalid.',
        fieldErrors: {
          'out_time': ['The out time cannot be before the in time.'],
        },
      );

      expect(failure.fieldError('out_time'),
          'The out time cannot be before the in time.');
      expect(failure.fieldError('notes'), isNull);
    });
  });
}
