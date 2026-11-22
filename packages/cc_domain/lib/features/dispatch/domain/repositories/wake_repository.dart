import 'package:cc_domain/features/dispatch/domain/entities/wake.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_values.dart';

/// Persistence port for wakes (`agent_wakes`), the durable outbox every
/// server-started run comes from.
///
/// Every method is workspace-scoped: [insertIfAbsent] takes the workspace
/// from the wake, every other method takes `workspaceId` first. A foreign id
/// is simply not found. State changes are conditional updates from the
/// states they leave, so two racing callers never both move a wake.
///
/// A stored wake the entity refuses (an import or a hand edit) is left out
/// of every read; a read that meets one that is still pending, held or
/// claimed settles it as `skipped` with the reason `invalid_row`, so no due
/// list, count or timer keeps returning it.
abstract interface class WakeRepository {
  /// Inserts [wake] unless a wake with its `dedupKey` exists. Returns true
  /// when this call wrote it, false (and no write) for a duplicate key.
  Future<bool> insertIfAbsent(Wake wake);

  /// The wake [id], or null.
  Future<Wake?> getById(String workspaceId, String id);

  /// The wake with [dedupKey], or null.
  Future<Wake?> getByDedupKey(String workspaceId, String dedupKey);

  /// `pending` wakes whose `notBefore` is at or before [now], oldest
  /// `notBefore` first, at most [limit].
  Future<List<Wake>> listDue(
    String workspaceId, {
    required DateTime now,
    int limit = 100,
  });

  /// The earliest `notBefore` among readable `pending` wakes, or null when
  /// none is pending (the wake queue's single timer). A refused row met on
  /// the way is settled, never returned.
  Future<DateTime?> earliestPendingNotBefore(String workspaceId);

  /// The conversation's wakes, newest first, narrowed to [states] when given.
  Future<List<Wake>> listForConversation(
    String workspaceId,
    String conversationId, {
    Set<WakeState>? states,
  });

  /// The wakes of the rule [ruleId] in [conversationId] (detail `ruleId`),
  /// newest first (`createdAt`, then id), at most [limit], those after
  /// [before] (the last row of the previous page) when given.
  Future<List<Wake>> listForRule(
    String workspaceId, {
    required String conversationId,
    required String ruleId,
    required int limit,
    ({DateTime createdAt, String id})? before,
  });

  /// The `pending` wakes aimed at [agentId] in [conversationId], oldest
  /// `notBefore` first.
  Future<List<Wake>> listPendingFor(
    String workspaceId, {
    required String conversationId,
    required String agentId,
  });

  /// Watches the conversation's `pending` and `held` wakes, ordered by
  /// `notBefore` (the queue strip above the composer).
  Stream<List<Wake>> watchForConversation(
    String workspaceId,
    String conversationId,
  );

  /// Moves each of [ids] from `pending` to `claimed`, sets `claimedAt` to
  /// [now] and adds one to `attempt`. Returns the ids this call moved; an id
  /// another caller claimed first, or that is not pending, is left out.
  Future<List<String>> claim(
    String workspaceId, {
    required List<String> ids,
    required DateTime now,
  });

  /// Marks [ids] `delivered` to [runId] (from `pending` or `claimed`).
  /// Returns how many moved.
  Future<int> markDelivered(
    String workspaceId, {
    required List<String> ids,
    required String? runId,
    required DateTime now,
  });

  /// Marks [ids] `skipped` with [reason] (from `pending`, `held` or
  /// `claimed`). Returns how many moved.
  Future<int> markSkipped(
    String workspaceId, {
    required List<String> ids,
    required String reason,
    required DateTime now,
  });

  /// Marks [ids] `expired` with [reason] (from `pending`, `held` or
  /// `claimed`). Returns how many moved.
  Future<int> markExpired(
    String workspaceId, {
    required List<String> ids,
    required String reason,
    required DateTime now,
  });

  /// Cancels [ids] with [reason] (from `pending`, `held` or `claimed`).
  /// Returns how many moved.
  Future<int> cancel(
    String workspaceId, {
    required List<String> ids,
    required String reason,
    required DateTime now,
  });

  /// Holds [ids] with [reason] (`pending` to `held`). Returns how many moved.
  Future<int> hold(
    String workspaceId, {
    required List<String> ids,
    required String reason,
  });

  /// Releases [ids] (`held` to `pending`). Returns how many moved.
  Future<int> release(String workspaceId, {required List<String> ids});

  /// Returns claimed [ids] to `pending` (the dispatch did not start).
  /// Returns how many moved.
  Future<int> releaseClaim(String workspaceId, {required List<String> ids});

  /// Returns every `claimed` wake claimed before [claimedBefore] to
  /// `pending` in one conditional statement (the age is part of the
  /// condition, so a claim released and taken afresh meanwhile stays), and
  /// returns the wakes it moved.
  Future<List<Wake>> reclaimStaleClaims(
    String workspaceId, {
    required DateTime claimedBefore,
  });

  /// Marks `pending` and `held` wakes whose `expiresAt` is at or before [now]
  /// `expired` (`expires_at_passed`). Returns the wakes it moved.
  Future<List<Wake>> expireDue(String workspaceId, {required DateTime now});

  /// Puts [ids] back to wait (`pending` or `claimed` to `pending`) until
  /// [until], with [reason] saying why (a self-clearing refusal: a take-over,
  /// a rate cap, a guard's deferral, a live run that takes no input). Returns
  /// how many moved.
  Future<int> defer(
    String workspaceId, {
    required List<String> ids,
    required DateTime until,
    required String reason,
  });

  /// [defer] for one wake [id] waiting out a refusal that clears by itself
  /// (a budget block, a paused agent), with its `expiresAt` set to
  /// [expiresAt], its bound. Returns how many moved (0 or 1).
  Future<int> deferWaiting(
    String workspaceId, {
    required String id,
    required DateTime until,
    required String reason,
    required DateTime expiresAt,
  });

  /// Marks `pending` wakes whose state reason is one of [reasons] and whose
  /// `expiresAt` is at or before [now] `expired`, keeping that reason (a
  /// refusal waited out for its whole bound). Returns the wakes it moved.
  Future<List<Wake>> expireWaiting(
    String workspaceId, {
    required DateTime now,
    required Set<String> reasons,
  });

  /// Stamps `claimed_at` = [now] on those of [ids] still `claimed`: a claim
  /// whose delivery is still under way (a dispatch starting, a wake in a
  /// live run's lane) is not stale. Returns how many.
  Future<int> refreshClaims(
    String workspaceId, {
    required List<String> ids,
    required DateTime now,
  });

  /// Returns `delivered` [ids] to `pending` with [reason] (the run they
  /// started was stopped by a server restart). Clears the run id and the
  /// settled time; the attempt count stays. Returns how many moved.
  Future<int> reopenDelivered(
    String workspaceId, {
    required List<String> ids,
    required String reason,
  });

  /// Deletes settled wakes (`delivered`, `skipped`, `expired`, `cancelled`)
  /// that settled before [cutoff]. Returns how many.
  Future<int> deleteSettledBefore(
    String workspaceId, {
    required DateTime cutoff,
  });

  /// How many distinct runs wakes were delivered to since [since], in the
  /// workspace or in [conversationId] (the rate caps).
  Future<int> countDeliveredRunsSince(
    String workspaceId, {
    required DateTime since,
    String? conversationId,
  });

  /// Cancels the `pending` and `held` wakes matching every given filter
  /// (detail `goalId`, `ruleId`, `askId`; `requestedByUserId`;
  /// `conversationId`) with [reason]. At least one filter is required.
  /// Returns the wakes it moved.
  Future<List<Wake>> cancelWhere(
    String workspaceId, {
    String? goalId,
    String? ruleId,
    String? askId,
    String? requestedByUserId,
    String? conversationId,
    required String reason,
    required DateTime now,
  });

  /// Whether [workspaceId] holds a `held` wake with an `expiresAt` (a
  /// person's usage-limit pause): the queue keeps maintaining it so the
  /// expiry is applied ([expireDue]).
  Future<bool> hasExpiringHeld(String workspaceId);

  /// The ids of the registered workspaces that have `pending` or `claimed`
  /// wakes, or a `held` wake with an `expiresAt`.
  ///
  /// CROSS-WORKSPACE BY DESIGN: the wake queue arms its timer at boot from
  /// every workspace; each later read is workspace-scoped.
  Future<List<String>> workspacesWithOpenWakes();
}
