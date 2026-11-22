/// An MR this telecaller may write to, as `RecipientResource` sends them.
///
/// Deliberately not the full user shape — a picker has no business carrying
/// email addresses or activity flags.
class Recipient {
  const Recipient({
    required this.id,
    required this.name,
    this.mobile,
    this.regionName,
  });

  final int id;
  final String name;
  final String? mobile;
  final String? regionName;

  factory Recipient.fromJson(Map<String, dynamic> json) => Recipient(
        id: (json['id'] as num?)?.toInt() ?? 0,
        name: json['name'] as String? ?? '',
        mobile: json['mobile'] as String?,
        regionName: (json['region'] as Map?)?['name'] as String?,
      );
}
