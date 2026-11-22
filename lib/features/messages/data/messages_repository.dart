import '../../../core/api/api_client.dart';
import '../../../core/api/api_envelope.dart';
import '../../../core/constants.dart';
import '../domain/recipient.dart';
import '../domain/sent_message.dart';

class MessagesRepository {
  const MessagesRepository(this._api);

  final ApiClient _api;

  /// Who this telecaller may write to: MRs covering a region they cover,
  /// **plus** the MR assigned to the person being written about. Passing
  /// `personId` widens the picker, and the same rule validates the send —
  /// a doctor in one region can have a rep based in another.
  Future<List<Recipient>> recipients({int? personId}) async {
    final envelope = await _api.get(
      AppConstants.recipients,
      query: {'person_id': ?personId},
    );

    return envelope.dataList.map(Recipient.fromJson).toList();
  }

  Future<Paginated<SentMessage>> sent({int page = 1}) async {
    final envelope = await _api.get(
      AppConstants.sentMessages,
      query: {'page': page, 'per_page': AppConstants.pageSize},
    );

    return Paginated.from(envelope, SentMessage.fromJson);
  }

  Future<SentMessage> send({
    required int toUserId,
    required String subject,
    required String body,
    int? personId,
    int? callLogId,
  }) async {
    final envelope = await _api.post(
      AppConstants.messages,
      body: {
        'to_user_id': toUserId,
        'subject': subject,
        'body': body,
        // Both are validated against this caller: the person must be in
        // their regions and the call must be their own.
        'person_id': ?personId,
        'call_log_id': ?callLogId,
      },
    );

    return SentMessage.fromJson(envelope.dataMap);
  }
}
