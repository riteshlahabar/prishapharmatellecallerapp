/// The shape every endpoint answers in: `{success, message, data, meta}`,
/// with `errors` instead of `data` on a failure (docs/api/v1-common.md).
///
/// Decoding lives here rather than in each repository so that a change to the
/// envelope is a change to one file.
class ApiEnvelope {
  const ApiEnvelope({
    required this.success,
    this.message,
    this.data,
    this.meta,
    this.errors,
  });

  final bool success;
  final String? message;
  final dynamic data;
  final Map<String, dynamic>? meta;
  final Map<String, dynamic>? errors;

  factory ApiEnvelope.fromJson(Map<String, dynamic> json) => ApiEnvelope(
        // Branch on `success`, not the HTTP code — that is the contract.
        success: json['success'] == true,
        message: json['message'] as String?,
        data: json['data'],
        meta: (json['meta'] as Map?)?.cast<String, dynamic>(),
        errors: (json['errors'] as Map?)?.cast<String, dynamic>(),
      );

  Map<String, dynamic> get dataMap =>
      (data as Map?)?.cast<String, dynamic>() ?? const {};

  List<Map<String, dynamic>> get dataList =>
      (data as List?)
          ?.whereType<Map>()
          .map((e) => e.cast<String, dynamic>())
          .toList() ??
      const [];
}

/// One page of a list, plus what the server said about the rest of it.
class Paginated<T> {
  const Paginated({
    required this.items,
    required this.page,
    required this.lastPage,
    required this.total,
    required this.hasMore,
  });

  final List<T> items;
  final int page;
  final int lastPage;
  final int total;

  /// Straight from `meta.has_more`, so the list never has to compare page
  /// numbers to work out whether to keep scrolling.
  final bool hasMore;

  static Paginated<T> from<T>(
    ApiEnvelope envelope,
    T Function(Map<String, dynamic>) parse,
  ) {
    final meta = envelope.meta ?? const {};

    return Paginated<T>(
      items: envelope.dataList.map(parse).toList(),
      page: (meta['current_page'] as num?)?.toInt() ?? 1,
      lastPage: (meta['last_page'] as num?)?.toInt() ?? 1,
      total: (meta['total'] as num?)?.toInt() ?? 0,
      hasMore: meta['has_more'] == true,
    );
  }

  static Paginated<T> empty<T>() => Paginated<T>(
        items: const [],
        page: 1,
        lastPage: 1,
        total: 0,
        hasMore: false,
      );
}
