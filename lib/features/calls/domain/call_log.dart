import 'call_status.dart';

/// A logged call, as `CallLogResource` sends it.
///
/// `follow_up_open` and `follow_up_due` are computed server-side, so the
/// queue badge never trusts the device clock (docs/api/v1-telecaller.md).
class CallLog {
  const CallLog({
    required this.id,
    required this.statusLabel,
    this.status,
    this.notes,
    this.calledAt,
    this.followUpAt,
    this.followUpDoneAt,
    this.followUpOpen = false,
    this.followUpDue = false,
    this.personId,
    this.personName,
    this.personMobile,
    this.personCity,
  });

  final int id;
  final CallStatus? status;
  final String statusLabel;
  final String? notes;
  final DateTime? calledAt;
  final DateTime? followUpAt;
  final DateTime? followUpDoneAt;

  /// A call-back was promised and has not been closed.
  final bool followUpOpen;

  /// Promised, still open, and the time has come.
  final bool followUpDue;

  final int? personId;
  final String? personName;
  final String? personMobile;
  final String? personCity;

  factory CallLog.fromJson(Map<String, dynamic> json) {
    final person = (json['person'] as Map?)?.cast<String, dynamic>();

    return CallLog(
      id: (json['id'] as num?)?.toInt() ?? 0,
      status: CallStatus.fromValue(json['status'] as String?),
      statusLabel: json['status_label'] as String? ?? '',
      notes: json['notes'] as String?,
      calledAt: DateTime.tryParse(json['called_at'] as String? ?? ''),
      followUpAt: DateTime.tryParse(json['follow_up_at'] as String? ?? ''),
      followUpDoneAt:
          DateTime.tryParse(json['follow_up_done_at'] as String? ?? ''),
      followUpOpen: json['follow_up_open'] == true,
      followUpDue: json['follow_up_due'] == true,
      personId: (person?['id'] as num?)?.toInt(),
      personName: person?['name'] as String?,
      personMobile: person?['mobile'] as String?,
      personCity: person?['city'] as String?,
    );
  }
}
