import '../../../core/api/api_client.dart';
import '../../../core/api/api_envelope.dart';
import '../../../core/constants.dart';
import '../../products/domain/product.dart';
import '../domain/call_log.dart';
import '../domain/call_status.dart';

class CallsRepository {
  const CallsRepository(this._api);

  final ApiClient _api;

  Future<Paginated<CallLog>> history({int page = 1}) async {
    final envelope = await _api.get(
      AppConstants.callLogs,
      query: {'page': page, 'per_page': AppConstants.pageSize},
    );

    return Paginated.from(envelope, CallLog.fromJson);
  }

  /// The call-back queue. `due: true` is what the app opens on — the ones
  /// already due; `due: false` shows everything still promised.
  Future<Paginated<CallLog>> followUps({
    bool dueOnly = true,
    int page = 1,
  }) async {
    final envelope = await _api.get(
      AppConstants.followUps,
      query: {
        'due': dueOnly ? 1 : 0,
        'page': page,
        'per_page': AppConstants.pageSize,
      },
    );

    return Paginated.from(envelope, CallLog.fromJson);
  }

  /// Logs a call. `telecaller_id` and `called_at` are never sent: the server
  /// takes them from the token and its own clock, so a device cannot
  /// back-date work. Logging also closes any call-back still open on that
  /// person, server-side.
  Future<CallLog> log({
    required int personId,
    required CallStatus status,
    String? notes,
    DateTime? followUpAt,
    List<ProductLineInput> products = const [],
  }) async {
    final envelope = await _api.post(
      AppConstants.callLogs,
      body: {
        'person_id': personId,
        'status': status.value,
        if ((notes ?? '').isNotEmpty) 'notes': notes,
        // Required on `callback`, refused on anything else — so send it only
        // when the status asks for one, or the server answers 422.
        if (status.needsFollowUp && followUpAt != null)
          'follow_up_at': _wire(followUpAt),
        // Left out entirely when empty: the server reads an absent key as
        // "no products", and on an amend it means "leave them alone".
        if (products.isNotEmpty)
          'products': [for (final line in products) line.toJson()],
      },
    );

    return CallLog.fromJson(envelope.dataMap);
  }

  /// Amends a call. Another caller's log is 404, not 403.
  Future<CallLog> update({
    required int id,
    CallStatus? status,
    String? notes,
    DateTime? followUpAt,
  }) async {
    final envelope = await _api.patch(
      AppConstants.callLog(id),
      body: {
        if (status != null) 'status': status.value,
        'notes': ?notes,
        if (status != null && status.needsFollowUp && followUpAt != null)
          'follow_up_at': _wire(followUpAt),
      },
    );

    return CallLog.fromJson(envelope.dataMap);
  }

  /// Clears a promised call-back without logging a new call. Idempotent
  /// server-side, so a retry on a flaky connection is not an error.
  Future<CallLog> completeFollowUp(int id) async {
    final envelope = await _api.post(AppConstants.followUpDone(id));

    return CallLog.fromJson(envelope.dataMap);
  }

  /// The server wants a date-time it can compare against "now"; it must be
  /// in the future or the call is rejected.
  String _wire(DateTime at) =>
      at.toUtc().toIso8601String().replaceFirst('T', ' ').substring(0, 19);
}
