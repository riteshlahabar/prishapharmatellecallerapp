class AppConstants {
  static const String appName = 'Prisha Pharma Telecaller';
  static const String baseUrl = 'http://localhost:8000/api';

  // Shared Preferences Keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';

  // API Endpoints
  static const String loginEndpoint = '/login';
  static const String logoutEndpoint = '/logout';
  static const String userEndpoint = '/user';
  static const String customersEndpoint = '/customers';
  static const String callLogsEndpoint = '/call-logs';
  static const String callSchedulesEndpoint = '/call-schedules';
  static const String dashboardEndpoint = '/dashboard';
  static const String reportsEndpoint = '/reports';

  // Status Constants
  static const String statusPending = 'pending';
  static const String statusInProgress = 'in_progress';
  static const String statusCompleted = 'completed';
  static const String statusCancelled = 'cancelled';

  // Call Result Types
  static const String callResultConnected = 'connected';
  static const String callResultBusy = 'busy';
  static const String callResultNoAnswer = 'no_answer';
  static const String callResultWrongNumber = 'wrong_number';
  static const String callResultFollowUp = 'follow_up';

  static const List<String> callResultOptions = [
    callResultConnected,
    callResultBusy,
    callResultNoAnswer,
    callResultWrongNumber,
    callResultFollowUp,
  ];
}