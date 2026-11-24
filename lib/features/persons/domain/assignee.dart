/// An MR this telecaller may hand a client to, as `AssigneeResource` sends
/// them.
///
/// Not the same question as [Recipient] in the messages feature, which asks
/// who may be *written* to and is region-scoped for that reason. This list is
/// every active MR, because assigning a client crosses territories by design
/// — so [subtitle] matters: the telecaller needs to see who works where to
/// choose the right rep.
class Assignee {
  const Assignee({
    required this.id,
    required this.name,
    this.mobile,
    this.regionNames = const [],
  });

  final int id;
  final String name;
  final String? mobile;

  /// Every region this person covers. An MR has one; the server flattens
  /// both role shapes into this one field.
  final List<String> regionNames;

  /// The line under the name in the dropdown: where they work, or a plain
  /// note that nobody has given them a territory yet.
  String get subtitle =>
      regionNames.isEmpty ? 'No region assigned' : regionNames.join(' · ');

  factory Assignee.fromJson(Map<String, dynamic> json) => Assignee(
    id: (json['id'] as num?)?.toInt() ?? 0,
    name: json['name'] as String? ?? '',
    mobile: json['mobile'] as String?,
    regionNames:
        (json['regions'] as List?)
            ?.whereType<Map>()
            .map((region) => region['name'] as String? ?? '')
            .where((name) => name.isNotEmpty)
            .toList() ??
        const [],
  );
}
