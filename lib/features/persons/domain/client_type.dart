/// One kind of client, as `/client-types` sends them.
///
/// The kinds are a master table an admin edits in the panel, not an enum, so
/// the Add Client form asks the server what it may offer rather than shipping
/// a list that goes stale on the next release (docs/modules/client-types.md).
class ClientType {
  const ClientType({
    required this.slug,
    required this.label,
    required this.hasSpecialization,
  });

  /// What goes back in `type` on a save — the id is never posted.
  final String slug;
  final String label;

  /// Whether this kind carries a specialization. A doctor does, a medical
  /// store does not, and the server nulls the column for the ones that do
  /// not — so the form hides the field rather than collecting text that
  /// would be silently dropped.
  final bool hasSpecialization;

  factory ClientType.fromJson(Map<String, dynamic> json) => ClientType(
    slug: json['slug'] as String? ?? '',
    label: json['label'] as String? ?? '',
    hasSpecialization: json['has_specialization'] == true,
  );
}
