/// The `CallStatus` enum, mirrored. The server rejects anything else with a
/// 422, so these values must stay in step with the CRM's enum.
///
/// `needsFollowUp` is the one rule worth carrying client-side: the server
/// **requires** `follow_up_at` on `callback` and **refuses** it on anything
/// else, so the form has to know which is which before it posts.
enum CallStatus {
  interested('interested', 'Interested'),
  notInterested('not_interested', 'Not interested'),
  callback('callback', 'Call back'),
  notReachable('not_reachable', 'Not reachable'),
  converted('converted', 'Converted');

  const CallStatus(this.value, this.label);

  final String value;
  final String label;

  bool get needsFollowUp => this == CallStatus.callback;

  static CallStatus? fromValue(String? value) {
    for (final status in CallStatus.values) {
      if (status.value == value) return status;
    }

    return null;
  }
}
