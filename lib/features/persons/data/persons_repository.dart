import '../../../core/api/api_client.dart';
import '../../../core/api/api_envelope.dart';
import '../../../core/constants.dart';
import '../domain/assignee.dart';
import '../domain/client_type.dart';
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

  /// My Clients: the clients this telecaller is the assigned one of.
  ///
  /// `mine=1` swaps the server's clamp from territory to ownership, which is
  /// the difference from [queue]: the queue is everyone in the regions this
  /// telecaller covers, this is the ones that are theirs — including a client
  /// an MR added and handed over, even if it sits outside those regions.
  Future<Paginated<Person>> mine({int page = 1, String? search}) async {
    final envelope = await _api.get(
      AppConstants.persons,
      query: {
        'mine': 1,
        'page': page,
        'per_page': AppConstants.pageSize,
        if ((search ?? '').trim().isNotEmpty) 'search': search!.trim(),
      },
    );

    return Paginated.from(envelope, Person.fromJson);
  }

  /// Adds a client. This telecaller becomes its telecaller and the chosen MR
  /// its MR.
  ///
  /// `assigned_telecaller_id` is never sent — the server takes it from the
  /// token, the same rule as `telecaller_id` on a call log — and neither is
  /// the region, which the server reads off the chosen MR's territory.
  /// Sending either is a 422, so this method is the contract as much as the
  /// convenience.
  Future<Person> create({
    required String name,
    required String type,
    required String mobile,
    required int mrId,
    String? email,
    String? city,
    String? address,
    String? specialization,
  }) async {
    final envelope = await _api.post(
      AppConstants.persons,
      body: {
        'name': name.trim(),
        'type': type,
        'mobile': mobile.trim(),
        'assigned_mr_id': mrId,
        if ((email ?? '').trim().isNotEmpty) 'email': email!.trim(),
        if ((city ?? '').trim().isNotEmpty) 'city': city!.trim(),
        if ((address ?? '').trim().isNotEmpty) 'address': address!.trim(),
        if ((specialization ?? '').trim().isNotEmpty)
          'specialization': specialization!.trim(),
      },
    );

    return Person.fromJson(envelope.dataMap);
  }

  /// The kinds of client the form may offer, straight from the panel's
  /// master. A plain array, not a page.
  Future<List<ClientType>> clientTypes() async {
    final envelope = await _api.get(AppConstants.clientTypes);

    return envelope.dataList.map(ClientType.fromJson).toList();
  }

  /// Every active MR, for the Add Client dropdown. Also a plain array — it is
  /// a picker, not a list to page through.
  Future<List<Assignee>> assignableMrs() async {
    final envelope = await _api.get(AppConstants.assignableMrs);

    return envelope.dataList.map(Assignee.fromJson).toList();
  }
}
