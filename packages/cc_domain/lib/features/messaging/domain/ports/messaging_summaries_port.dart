import 'package:cc_domain/features/messaging/domain/value_objects/conversation_token_totals.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/space_activity.dart';

/// Client-side port for the server-computed messaging aggregates: per-space
/// activity signals (`messaging.watchSpaceActivity`) and conversation size
/// (`messaging.watchConversationTokens`).
///
/// Deliberately NOT part of `MessagingRepository`: these are read-model
/// projections that exist to keep list subscriptions off the wire; the server
/// computes them straight from SQL and only RPC-backed clients consume them.
abstract class MessagingSummariesPort {
  /// Activity signals for every space in the bound workspace. The
  /// [workspaceId] is informational (the host binds the authoritative
  /// workspace per session) — it keys client-side caching.
  Stream<List<SpaceActivity>> watchSpaceActivity(String workspaceId);

  /// The size of one conversation's live region, for the context meters.
  ///
  /// Same bargain as [watchSpaceActivity], one conversation deeper: the meters
  /// render a total, and computing it client-side meant holding the whole
  /// conversation open — an uncapped subscription re-sending every message on
  /// every write, paid on every chat open and every sidebar hover.
  Stream<ConversationTokenTotals> watchConversationTokens(
    String workspaceId,
    String spaceId,
    String conversationId,
  );
}
