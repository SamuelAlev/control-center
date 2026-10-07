import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/core/domain/value_objects/principal.dart';

/// Decodes `metadata['mentions']` (see `MessagingService.sendAndDispatch`)
/// into wire-ready [Principal]s for the `MessageReceived` notification
/// event (PRD 16 §7/§15) — a human mention rides this path so a mentioned
/// teammate is notified even though the message itself is human-authored
/// (which otherwise never raises a notification).
List<Principal> decodeMentionPrincipals(Map<String, dynamic>? metadata) {
  final raw = metadata?['mentions'];
  if (raw is! List) {
    return const [];
  }
  final principals = <Principal>[];
  for (final m in raw) {
    if (m is Map<String, dynamic>) {
      final mention = MessageMention.fromJson(m);
      principals.add(Principal.of(mention.principalType, mention.agentId));
    }
  }
  return principals;
}
