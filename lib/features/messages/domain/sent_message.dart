/// A message this telecaller sent to an MR.
///
/// Messaging is one-directional: the telecaller writes, the MR reads. So the
/// interesting state here is whether the MR has opened it yet.
class SentMessage {
  const SentMessage({
    required this.id,
    required this.subject,
    required this.body,
    required this.isRead,
    this.sentAt,
    this.toName,
    this.personName,
  });

  final int id;
  final String subject;
  final String body;

  /// Read by the recipient — derived server-side from `read_at`, the only
  /// state stored. The sender cannot change it.
  final bool isRead;

  final DateTime? sentAt;
  final String? toName;
  final String? personName;

  factory SentMessage.fromJson(Map<String, dynamic> json) => SentMessage(
        id: (json['id'] as num?)?.toInt() ?? 0,
        subject: json['subject'] as String? ?? '',
        body: json['body'] as String? ?? '',
        isRead: json['is_read'] == true,
        sentAt: DateTime.tryParse(json['sent_at'] as String? ?? ''),
        toName: (json['to'] as Map?)?['name'] as String?,
        personName: (json['person'] as Map?)?['name'] as String?,
      );
}
