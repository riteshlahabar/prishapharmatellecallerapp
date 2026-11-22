/// The signed-in rep, as `AuthUserResource` sends them.
///
/// Fields may be added server-side; renaming one is a breaking change for a
/// shipped build (docs/api/v1-auth.md), so parse defensively and never
/// assume a new key exists.
class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.mobile,
    this.regions = const [],
  });

  final int id;
  final String name;
  final String email;
  final String role;
  final String? mobile;

  /// Territory, flattened by the server whichever shape the role uses — one
  /// entry for an MR. Empty until Phase 6 filled it, so old builds saw none.
  final List<Region> regions;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();

    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  String get regionLabel =>
      regions.isEmpty ? 'No region assigned' : regions.map((r) => r.name).join(', ');

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: (json['id'] as num?)?.toInt() ?? 0,
        name: json['name'] as String? ?? '',
        email: json['email'] as String? ?? '',
        role: json['role'] as String? ?? '',
        mobile: json['mobile'] as String?,
        regions: (json['regions'] as List?)
                ?.whereType<Map>()
                .map((e) => Region.fromJson(e.cast<String, dynamic>()))
                .toList() ??
            const [],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role,
        'mobile': mobile,
        'regions': regions.map((r) => r.toJson()).toList(),
      };
}

class Region {
  const Region({required this.id, required this.name, this.code});

  final int id;
  final String name;
  final String? code;

  factory Region.fromJson(Map<String, dynamic> json) => Region(
        id: (json['id'] as num?)?.toInt() ?? 0,
        name: json['name'] as String? ?? '',
        code: json['code'] as String?,
      );

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'code': code};
}
