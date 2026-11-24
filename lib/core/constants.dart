/// Everything the app needs to find the backend, in one place.
///
/// The paths mirror `docs/api/v1-telecaller.md` in the CRM repo. That
/// document is the contract: a field named here exists there, and renaming
/// one on either side breaks a shipped build.
class AppConstants {
  AppConstants._();

  static const String appName = 'Prisha Pharma Telecaller';

  /// `10.0.2.2` is the host machine as seen from the Android emulator.
  /// Override at build time:
  ///   flutter run --dart-define=API_BASE_URL=https://crm.example.com/api/v1
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://prishapharmacrm.turnkeyinfotech.live/api/v1',
  );

  /// Sent on login so the server refuses an MR's account here rather than
  /// letting them in and failing on the first endpoint (docs/api/v1-auth.md).
  static const String appRole = 'telecaller';
  static const String deviceName = 'telecaller-app';

  // Storage keys.
  static const String tokenKey = 'auth_token';
  static const String userKey = 'auth_user';

  // Endpoints — /api/v1, never the unversioned legacy routes.
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String me = '/auth/me';

  /// The call queue: region-scoped server-side, each row carrying the last
  /// call *this* telecaller made on that person.
  static const String persons = '/persons';

  static const String callLogs = '/call-logs';
  static const String followUps = '/call-logs/follow-ups';
  static String followUpDone(int id) => '/call-logs/$id/follow-up-done';
  static String callLog(int id) => '/call-logs/$id';

  static const String messages = '/messages';
  static const String sentMessages = '/messages/sent';

  /// Who this telecaller may write to: MRs covering a region they cover,
  /// plus the MR assigned to a named person.
  static const String recipients = '/mrs';

  /// The Add Client form's two pickers. `client-types` is the panel's own
  /// master, so a kind added there is offered here with no release.
  ///
  /// `assignees/mrs` is a different list from [recipients] above: every
  /// active MR, not only those covering this telecaller's regions, because
  /// assigning a client crosses territories by design
  /// (docs/api/v1-telecaller.md).
  static const String clientTypes = '/client-types';
  static const String assignableMrs = '/assignees/mrs';

  static const Duration connectTimeout = Duration(seconds: 20);
  static const Duration receiveTimeout = Duration(seconds: 20);

  /// Matches the server's default; it clamps anything over 100.
  static const int pageSize = 20;
}
