import 'package:cc_domain/core/domain/value_objects/wake_context.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_detail.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_rule_values.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_run_options.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_values.dart';

/// One reason for the server to run an agent in a conversation, or to tell a
/// running agent something (`agent_wakes`).
///
/// Everything that starts work without a person typing produces a wake: a
/// goal continuing, a rule firing, a reply arriving, a child finishing, a
/// provider limit resetting. A wake always names one agent in one
/// conversation. Producers insert with a [dedupKey]; a duplicate is a no-op,
/// so a producer may retry freely. Delivery is at-least-once.
///
/// [payload] is data, never instructions: the server renders it inside a
/// delimiter with a per-run nonce, and it cannot approve anything, run a
/// slash command or start a goal.
class Wake {
  /// Creates a wake; every time is kept in UTC. Throws [ArgumentError] for
  /// an empty id or target, a [payload] over [maxPayloadLength], an empty or
  /// over-long [dedupKey], a negative [attempt], an over-long [stateReason],
  /// an over-long [chain], or an [expiresAt] before [createdAt].
  Wake({
    required this.id,
    required this.workspaceId,
    required this.spaceId,
    required this.conversationId,
    required this.agentId,
    required this.reason,
    this.lane = WakeLane.aside,
    required this.payload,
    WakeDetail? detail,
    this.runOptions,
    required this.dedupKey,
    required DateTime notBefore,
    DateTime? expiresAt,
    this.requestedByUserId,
    List<String> chain = const [],
    this.expectsReply = false,
    this.state = WakeState.pending,
    this.stateReason,
    this.deliveredRunId,
    this.attempt = 0,
    required DateTime createdAt,
    DateTime? claimedAt,
    DateTime? settledAt,
  }) : notBefore = notBefore.toUtc(),
       expiresAt = expiresAt?.toUtc(),
       createdAt = createdAt.toUtc(),
       claimedAt = claimedAt?.toUtc(),
       settledAt = settledAt?.toUtc(),
       detail = detail ?? WakeDetail.empty,
       chain = List.unmodifiable(chain) {
    _requireId(id, 'id');
    _requireId(workspaceId, 'workspaceId');
    _requireId(spaceId, 'spaceId');
    _requireId(conversationId, 'conversationId');
    _requireId(agentId, 'agentId');
    if (payload.length > maxPayloadLength) {
      throw ArgumentError.value(
        payload.length,
        'payload',
        'must be at most $maxPayloadLength characters',
      );
    }
    if (dedupKey.isEmpty || dedupKey.length > maxDedupKeyLength) {
      throw ArgumentError.value(
        dedupKey,
        'dedupKey',
        'must be 1 to $maxDedupKeyLength characters',
      );
    }
    if (attempt < 0) {
      throw ArgumentError.value(attempt, 'attempt', 'must not be negative');
    }
    final why = stateReason;
    if (why != null && (why.isEmpty || why.length > maxStateReasonLength)) {
      throw ArgumentError.value(
        why,
        'stateReason',
        'must be 1 to $maxStateReasonLength characters',
      );
    }
    if (chain.length > maxChainLength || chain.any((a) => a.isEmpty)) {
      throw ArgumentError.value(
        chain,
        'chain',
        'at most $maxChainLength non-empty agent ids',
      );
    }
    final expiry = expiresAt;
    if (expiry != null && expiry.isBefore(createdAt)) {
      throw ArgumentError.value(
        expiry,
        'expiresAt',
        'must not be before createdAt',
      );
    }
  }

  /// The longest payload, in characters.
  static const int maxPayloadLength = 4000;

  /// The longest dedup key, in characters.
  static const int maxDedupKeyLength = 512;

  /// The longest [stateReason], in characters.
  static const int maxStateReasonLength = 100;

  /// The most agent ids a [chain] holds. Depth itself (3) is the peer
  /// service's rule; this only bounds the column.
  static const int maxChainLength = 16;

  /// Unique wake id.
  final String id;

  /// Owning workspace.
  final String workspaceId;

  /// Space of the target conversation.
  final String spaceId;

  /// Target conversation.
  final String conversationId;

  /// Target agent.
  final String agentId;

  /// Why the agent is woken.
  final WakeReason reason;

  /// How it enters a live run of the agent.
  final WakeLane lane;

  /// Text for the agent (data, not instructions), at most
  /// [maxPayloadLength] characters.
  final String payload;

  /// The typed facts behind it.
  final WakeDetail detail;

  /// How the run it starts is dispatched; null for the defaults.
  final WakeRunOptions? runOptions;

  /// Unique idempotency key: `goal:<id>:<runCount>`, `rule:<id>:<slot>`,
  /// `ask:<id>:reply`, `ticket:<id>:settled`.
  final String dedupKey;

  /// When it may be delivered.
  final DateTime notBefore;

  /// When it stops mattering; null for never.
  final DateTime? expiresAt;

  /// The accountable person, or null for the bot.
  final String? requestedByUserId;

  /// The agents that led here, oldest first (depth and cycle checks).
  final List<String> chain;

  /// Whether the source is told when the work this wake starts settles.
  final bool expectsReply;

  /// Where it is.
  final WakeState state;

  /// A short machine kind saying why it was skipped, held or cancelled.
  final String? stateReason;

  /// The run it was delivered to.
  final String? deliveredRunId;

  /// How many times it was claimed for a dispatch.
  final int attempt;

  /// When it was written.
  final DateTime createdAt;

  /// When it was last claimed.
  final DateTime? claimedAt;

  /// When it reached a settled state.
  final DateTime? settledAt;

  /// Whether it is finished.
  bool get isSettled => state.isSettled;

  /// Whether it is past its expiry at [now].
  bool expiredAt(DateTime now) {
    final expiry = expiresAt;
    return expiry != null && !now.isBefore(expiry);
  }

  /// Whether it may be delivered at [now] (pending and due).
  bool isDueAt(DateTime now) =>
      state == WakeState.pending && !now.isBefore(notBefore);

  static void _requireId(String value, String name) {
    if (value.isEmpty) {
      throw ArgumentError.value(value, name, 'must not be empty');
    }
  }

  /// A copy with the given fields replaced.
  Wake copyWith({
    String? id,
    String? workspaceId,
    String? spaceId,
    String? conversationId,
    String? agentId,
    WakeReason? reason,
    WakeLane? lane,
    String? payload,
    WakeDetail? detail,
    WakeRunOptions? runOptions,
    bool removeRunOptions = false,
    String? dedupKey,
    DateTime? notBefore,
    DateTime? expiresAt,
    bool removeExpiresAt = false,
    String? requestedByUserId,
    bool removeRequestedByUserId = false,
    List<String>? chain,
    bool? expectsReply,
    WakeState? state,
    String? stateReason,
    bool removeStateReason = false,
    String? deliveredRunId,
    bool removeDeliveredRunId = false,
    int? attempt,
    DateTime? createdAt,
    DateTime? claimedAt,
    bool removeClaimedAt = false,
    DateTime? settledAt,
    bool removeSettledAt = false,
  }) => Wake(
    id: id ?? this.id,
    workspaceId: workspaceId ?? this.workspaceId,
    spaceId: spaceId ?? this.spaceId,
    conversationId: conversationId ?? this.conversationId,
    agentId: agentId ?? this.agentId,
    reason: reason ?? this.reason,
    lane: lane ?? this.lane,
    payload: payload ?? this.payload,
    detail: detail ?? this.detail,
    runOptions: removeRunOptions ? null : (runOptions ?? this.runOptions),
    dedupKey: dedupKey ?? this.dedupKey,
    notBefore: notBefore ?? this.notBefore,
    expiresAt: removeExpiresAt ? null : (expiresAt ?? this.expiresAt),
    requestedByUserId: removeRequestedByUserId
        ? null
        : (requestedByUserId ?? this.requestedByUserId),
    chain: chain ?? this.chain,
    expectsReply: expectsReply ?? this.expectsReply,
    state: state ?? this.state,
    stateReason: removeStateReason ? null : (stateReason ?? this.stateReason),
    deliveredRunId: removeDeliveredRunId
        ? null
        : (deliveredRunId ?? this.deliveredRunId),
    attempt: attempt ?? this.attempt,
    createdAt: createdAt ?? this.createdAt,
    claimedAt: removeClaimedAt ? null : (claimedAt ?? this.claimedAt),
    settledAt: removeSettledAt ? null : (settledAt ?? this.settledAt),
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Wake &&
          id == other.id &&
          workspaceId == other.workspaceId &&
          spaceId == other.spaceId &&
          conversationId == other.conversationId &&
          agentId == other.agentId &&
          reason == other.reason &&
          lane == other.lane &&
          payload == other.payload &&
          detail == other.detail &&
          runOptions == other.runOptions &&
          dedupKey == other.dedupKey &&
          sameWakeInstant(notBefore, other.notBefore) &&
          sameWakeInstant(expiresAt, other.expiresAt) &&
          requestedByUserId == other.requestedByUserId &&
          _sameList(chain, other.chain) &&
          expectsReply == other.expectsReply &&
          state == other.state &&
          stateReason == other.stateReason &&
          deliveredRunId == other.deliveredRunId &&
          attempt == other.attempt &&
          sameWakeInstant(createdAt, other.createdAt) &&
          sameWakeInstant(claimedAt, other.claimedAt) &&
          sameWakeInstant(settledAt, other.settledAt);

  @override
  int get hashCode => Object.hashAll([
    id,
    workspaceId,
    spaceId,
    conversationId,
    agentId,
    reason,
    lane,
    payload,
    detail,
    runOptions,
    dedupKey,
    notBefore,
    expiresAt,
    requestedByUserId,
    Object.hashAll(chain),
    expectsReply,
    state,
    stateReason,
    deliveredRunId,
    attempt,
    createdAt,
    claimedAt,
    settledAt,
  ]);

  @override
  String toString() =>
      'Wake($id, ${reason.wire} -> $agentId in $conversationId, '
      '${state.wire}, key $dedupKey)';
}

bool _sameList(List<String> a, List<String> b) {
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}
