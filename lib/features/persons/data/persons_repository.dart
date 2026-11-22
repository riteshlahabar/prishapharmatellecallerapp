import '../../../core/api/api_client.dart';
import '../../../core/api/api_envelope.dart';
import '../../../core/constants.dart';
import '../domain/person.dart';

class PersonsRepository {
  const PersonsRepository(this._api);

  final ApiClient _api;

  /// The call queue. Region-scoped server-side and active-only, with each
  /// row's `last_call` filled in one query for the whole page — so the queue
  /// needs exactly one request, not one per person.
  Future<Paginated<Person>> queue({int page = 1, String? search}) async {
    final envelope = await _api.get(
      AppConstants.persons,
      query: {
        'page': page,
        'per_page': AppConstants.pageSize,
        if ((search ?? '').trim().isNotEmpty) 'search': search!.trim(),
      },
    );

    return Paginated.from(envelope, Person.fromJson);
  }
}
