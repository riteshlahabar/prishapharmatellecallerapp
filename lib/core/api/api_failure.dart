/// A failed call, already interpreted.
///
/// The server answers every failure in one envelope and puts a stable token
/// in `errors.reason` precisely so a client can branch on it — `message` is
/// display text and is free to be reworded (docs/api/v1-common.md). So the
/// app switches on [reason] and shows [message]; it never parses prose.
enum ApiReason {
  unauthenticated,
  forbidden,
  accountInactive,
  roleChanged,
  notFound,
  validation,
  throttled,
  serverError,

  /// Login-specific, from docs/api/v1-auth.md.
  credentials,
  disabled,
  wrongSurface,
  wrongApp,

  /// Attendance sequence guards — the day's state forbids the punch.
  alreadyCheckedIn,
  notCheckedIn,
  alreadyCheckedOut,

  /// No response at all: aeroplane mode, dead wifi, server down.
  network,

  /// A reason this build has not been taught yet. Newer server, older app.
  unknown;

  static ApiReason parse(String? raw) => switch (raw) {
        'unauthenticated' => ApiReason.unauthenticated,
        'forbidden' => ApiReason.forbidden,
        'account_inactive' => ApiReason.accountInactive,
        'role_changed' => ApiReason.roleChanged,
        'not_found' => ApiReason.notFound,
        'validation' => ApiReason.validation,
        'throttled' => ApiReason.throttled,
        'server_error' => ApiReason.serverError,
        'credentials' => ApiReason.credentials,
        'disabled' => ApiReason.disabled,
        'wrong_surface' => ApiReason.wrongSurface,
        'wrong_app' => ApiReason.wrongApp,
        'already_checked_in' => ApiReason.alreadyCheckedIn,
        'not_checked_in' => ApiReason.notCheckedIn,
        'already_checked_out' => ApiReason.alreadyCheckedOut,
        _ => ApiReason.unknown,
      };
}

class ApiFailure implements Exception {
  const ApiFailure({
    required this.reason,
    required this.message,
    this.status,
    this.fieldErrors = const {},
    this.retryAfter,
  });

  final ApiReason reason;

  /// Safe to show: the server writes these for people.
  final String message;
  final int? status;

  /// On a 422, one entry per rejected field, as the server named it.
  final Map<String, List<String>> fieldErrors;

  /// Set on a 429, from the `Retry-After` header.
  final Duration? retryAfter;

  /// The account is gone or changed underneath this token, so the only sane
  /// move is to drop it and show the login screen. The server re-checks the
  /// account on every request, which is what makes these reachable at all.
  bool get requiresSignOut =>
      reason == ApiReason.unauthenticated ||
      reason == ApiReason.accountInactive ||
      reason == ApiReason.roleChanged;

  /// The first message for a field, for an inline error under an input.
  String? fieldError(String field) => fieldErrors[field]?.firstOrNull;

  @override
  String toString() => 'ApiFailure(${reason.name}, $status): $message';
}
