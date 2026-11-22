import '../../calls/domain/call_log.dart';

/// A person on the call queue, as `PersonResource` sends them.
///
/// The list is region-scoped server-side, so the app never sends a filter it
/// could tamper with. `last_call` is the last call **this** telecaller made
/// on that person — absent entirely if they never rang.
class Person {
  const Person({
    required this.id,
    required this.name,
    required this.type,
    required this.typeLabel,
    this.mobile,
    this.city,
    this.specialization,
    this.regionName,
    this.lastCall,
  });

  final int id;
  final String name;
  final String type;
  final String typeLabel;
  final String? mobile;
  final String? city;
  final String? specialization;
  final String? regionName;

  /// Shaped exactly as `/call-logs` returns a call, so one parser serves
  /// both — the server sends it through the Calls module's own resource.
  final CallLog? lastCall;

  bool get neverCalled => lastCall == null;

  bool get hasDueFollowUp => lastCall?.followUpDue ?? false;

  bool get canDial => (mobile ?? '').trim().isNotEmpty;

  String get subtitle => [
        typeLabel,
        if ((specialization ?? '').isNotEmpty) specialization,
        if ((city ?? '').isNotEmpty) city,
      ].join(' · ');

  factory Person.fromJson(Map<String, dynamic> json) {
    final call = (json['last_call'] as Map?)?.cast<String, dynamic>();

    return Person(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? '',
      typeLabel: json['type_label'] as String? ?? '',
      mobile: json['mobile'] as String?,
      city: json['city'] as String?,
      specialization: json['specialization'] as String?,
      regionName: (json['region'] as Map?)?['name'] as String?,
      lastCall: call == null ? null : CallLog.fromJson(call),
    );
  }
}
