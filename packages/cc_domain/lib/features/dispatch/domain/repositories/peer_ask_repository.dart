import 'package:cc_domain/features/dispatch/domain/entities/peer_ask.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/peer_ask_values.dart';

/// Persistence port for peer asks (`peer_asks`).
///
/// Every method is workspace-scoped: [insertWithinLimits] takes the
/// workspace from the ask, every other method takes `workspaceId` first.
///
/// There is no full-row update: [setDispatched], the three once-only
/// markers and [settle] are each one conditional statement on a `pending`
/// ask, and [settle] is the only way out of `pending`, so a writer holding
/// an older copy never re-opens a settled ask.
///
/// A stored ask the entity refuses (an import or a hand edit) is left out of
/// every read; a read that meets a `pending` one settles it as `failed` with
/// the error `invalid_row`, so it neither waits forever nor counts against a
/// limit.
abstract interface class PeerAskRepository {
  /// Inserts the new [ask] unless it breaks one of [limits], checked in one
  /// transaction with the insert so two asks at once cannot both pass: a
  /// pending duplicate (same asker, recipient and question hash, made at or
  /// after [PeerAskInsertLimits.duplicateSince]), then the asker's pending
  /// count, then the recipient's. Returns the first limit that refused, or
  /// null when the ask was written. Throws when its id exists.
  Future<PeerAskLimitHit?> insertWithinLimits(
    PeerAsk ask, {
    required PeerAskInsertLimits limits,
  });

  /// Records where the `pending` ask [id] is being answered: the recipient's
  /// run [dispatchedRunId], and the conversation, space and question message
  /// when given (null leaves a field as it is). Returns false when the ask
  /// is not pending (it settled meanwhile) or does not exist.
  Future<bool> setDispatched(
    String workspaceId, {
    required String id,
    required String dispatchedRunId,
    String? recipientConversationId,
    String? recipientSpaceId,
    String? questionMessageId,
  });

  /// The ask [id], or null.
  Future<PeerAsk?> getById(String workspaceId, String id);

  /// The ask whose recipient run is [runId], or null.
  Future<PeerAsk?> getByDispatchedRun(String workspaceId, String runId);

  /// `pending` asks, oldest first, narrowed by every given filter.
  Future<List<PeerAsk>> listPending(
    String workspaceId, {
    String? askerAgentId,
    String? recipientAgentId,
    String? askerConversationId,
  });

  /// How many asks are `pending`, narrowed by every given filter (a
  /// recipient may have 20, an asker 10).
  Future<int> countPending(
    String workspaceId, {
    String? askerAgentId,
    String? recipientAgentId,
  });

  /// A `pending` ask from [askerAgentId] to [recipientAgentId] with
  /// [questionHash] created at or after [since], or null (the 10-minute
  /// repeat refusal).
  Future<PeerAsk?> findPendingDuplicate(
    String workspaceId, {
    required String askerAgentId,
    required String recipientAgentId,
    required String questionHash,
    required DateTime since,
  });

  /// Settles the ask [id] from `pending` to [status], writing the given
  /// reply fields and `settledAt` = [now]. Returns true only for the caller
  /// that moved it, so the notice is sent exactly once.
  Future<bool> settle(
    String workspaceId, {
    required String id,
    required PeerAskStatus status,
    String? replyMessageId,
    String? error,
    bool? replyInline,
    required DateTime now,
  });

  /// Sets `promisedAt` = [now] on the ask [id] while it is `pending` and not
  /// yet promised. Returns true only for the caller that set it, so the
  /// asker is told once that an answer is promised.
  Future<bool> markPromised(
    String workspaceId, {
    required String id,
    required DateTime now,
  });

  /// Sets `blockedNoticedAt` = [now] on the ask [id] while it is `pending`
  /// and not yet noticed. Returns true only for the caller that set it, so
  /// the asker is told once that the recipient waits on a person.
  Future<bool> markBlockedNoticed(
    String workspaceId, {
    required String id,
    required DateTime now,
  });

  /// Sets `stallNoticedRunId` = [runId] on the ask [id] while it is
  /// `pending` and no run was reminded yet. Returns true only for the caller
  /// that set it, so the recipient is reminded once.
  Future<bool> markStallNoticed(
    String workspaceId, {
    required String id,
    required String runId,
  });

  /// The `pending` asks to [recipientAgentId] answered in
  /// [recipientConversationId], oldest first (the settle path of a
  /// recipient's run).
  Future<List<PeerAsk>> listPendingForRecipientConversation(
    String workspaceId, {
    required String recipientAgentId,
    required String recipientConversationId,
  });

  /// `pending` asks whose `expiresAt` is at or before [now], oldest first.
  Future<List<PeerAsk>> listExpired(
    String workspaceId, {
    required DateTime now,
  });

  /// Watches the asks made from [conversationId], newest first.
  Stream<List<PeerAsk>> watchForConversation(
    String workspaceId,
    String conversationId,
  );

  /// Deletes settled asks that settled before [cutoff]. Returns how many.
  Future<int> deleteSettledBefore(
    String workspaceId, {
    required DateTime cutoff,
  });

  /// The workspaces that hold a pending ask (the sweep's starting point).
  Future<List<String>> workspacesWithPendingAsks();
}
