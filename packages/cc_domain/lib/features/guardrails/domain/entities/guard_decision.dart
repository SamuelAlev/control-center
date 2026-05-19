import 'package:cc_domain/features/evals/domain/value_objects/agent_config_hash.dart'
    show canonicalHash;
import 'package:cc_domain/features/guardrails/domain/value_objects/action_decision.dart';

/// Which chokepoint made an authorization decision.
enum GuardSurface {
  /// The `repo/call` dispatcher (a human clicking in a client).
  repoRpc('repo_rpc'),

  /// The built-in harness tool gate (an agent's own tool call).
  harness('harness'),

  /// The MCP tool dispatcher (an agent, or an external MCP client).
  mcp('mcp'),

  /// The skill-install capability gate.
  skillInstall('skill_install'),

  /// The sandbox exec-grant gate.
  sandbox('sandbox'),

  /// The `sub/subscribe` reactive lane.
  subscription('subscription'),

  /// Written by the audit machinery itself (retention checkpoints).
  audit('audit');

  const GuardSurface(this.wire);

  /// Stable stored value.
  final String wire;

  /// Parses a stored value, defaulting to [repoRpc] for an unknown one.
  static GuardSurface fromWire(String? value) {
    for (final s in GuardSurface.values) {
      if (s.wire == value) {
        return s;
      }
    }
    return GuardSurface.repoRpc;
  }
}

/// How strongly a policy rule is enforced (PRD 24 + the Sentinel model).
///
/// The middle tier is the one that makes strict policy adoptable: an operator
/// can roll a rule out as [advisory] (allow + record) and read the audit trail
/// for a week to see exactly what it WOULD have blocked, then promote it.
/// Without that, nobody turns strict rules on.
enum EnforcementLevel {
  /// Allow, but record that the rule matched — the dry-run tier.
  advisory('advisory'),

  /// Deny, but a principal holding the override permission may proceed with a
  /// recorded justification.
  soft('soft'),

  /// Deny. Nothing overrides it — the documented safety floor.
  hard('hard');

  const EnforcementLevel(this.wire);

  /// Stable stored value.
  final String wire;

  /// Parses a stored value; null/unknown reads as [hard] (fail closed — an
  /// unparseable enforcement must never weaken a rule).
  static EnforcementLevel fromWire(String? value) {
    for (final e in EnforcementLevel.values) {
      if (e.wire == value) {
        return e;
      }
    }
    return EnforcementLevel.hard;
  }
}

/// One authorization decision, as recorded in the tamper-evident audit spine.
///
/// This is the row that answers the two questions an enterprise security
/// review actually asks — "what was refused, and by which rule?" and "which
/// human authorized this agent action?" — neither of which the human activity
/// log (successes only) or a stdout deny line could answer.
///
/// The attribution chain follows *Authenticated Delegation and Authorized AI
/// Agents* (arXiv 2501.09674): a third party must be able to verify that the
/// actor was an agent, that it acted on behalf of a specific human, and that
/// it held the permission for that specific action. [actorType]/[actorId],
/// [onBehalfOfUserId] and [sourceScope]/[ruleId] are those three claims.
class GuardDecision {
  /// Creates a [GuardDecision].
  const GuardDecision({
    required this.id,
    required this.workspaceId,
    required this.occurredAt,
    required this.actorType,
    required this.actorId,
    required this.surface,
    required this.actionName,
    required this.decision,
    this.seq = 0,
    this.onBehalfOfUserId,
    this.delegationChainId,
    this.delegationDepth,
    this.spaceId,
    this.runId,
    this.deviceId,
    this.ip,
    this.actionClasses = const [],
    this.permission,
    this.argsDigest,
    this.constraintSummary,
    this.enforcement,
    this.sourceScope,
    this.ruleId,
    this.prompted = false,
    this.responderUserId,
    this.overrideReason,
    this.correlationId,
    this.prevHash = '',
    this.entryHash = '',
    this.kind = 'decision',
  });

  /// Row id (UUID v4).
  final String id;

  /// Owning workspace.
  final String workspaceId;

  /// Monotonic per-workspace chain position (allocated at append).
  final int seq;

  /// When the decision was made.
  final DateTime occurredAt;

  /// `user` | `agent` | `system`.
  final String actorType;

  /// The acting principal's id.
  final String actorId;

  /// The human an agent acted on behalf of.
  final String? onBehalfOfUserId;

  /// The delegation chain root, when authority arrived via delegation.
  final String? delegationChainId;

  /// Depth in that chain (0 = direct).
  final int? delegationDepth;

  /// The space the action ran in.
  final String? spaceId;

  /// The agent run the action came from.
  final String? runId;

  /// The calling device (human surfaces).
  final String? deviceId;

  /// The client IP (human surfaces).
  final String? ip;

  /// Which chokepoint decided.
  final GuardSurface surface;

  /// The op/tool name that was gated.
  final String actionName;

  /// ActionClass wire names involved.
  final List<String> actionClasses;

  /// The derived permission (`domain:tier`) for human-lane decisions.
  final String? permission;

  /// SHA-256 over the redacted extracted arguments.
  final String? argsDigest;

  /// Human-readable summary of the constraint that matched.
  final String? constraintSummary;

  /// The resolved verdict.
  final ActionDecision decision;

  /// The deciding rule's enforcement level.
  final EnforcementLevel? enforcement;

  /// Which scope decided (`space`/`agent`/`workspace`/`managed`/`preset`/
  /// `default`/`role`/`grant`/`membership`).
  final String? sourceScope;

  /// The deciding `action_policies` row, when a stored rule decided.
  final String? ruleId;

  /// Whether a human was asked.
  final bool prompted;

  /// Who answered the prompt.
  final String? responderUserId;

  /// The justification recorded when a soft deny was overridden.
  final String? overrideReason;

  /// Correlates with the `user_activity` row for the same call.
  final String? correlationId;

  /// The previous row's [entryHash] ('' at the chain genesis).
  final String prevHash;

  /// `sha256(prevHash ‖ canonicalJson(payload))`.
  final String entryHash;

  /// `decision` or `checkpoint`.
  final String kind;

  /// The canonical payload the chain hash covers — every field that describes
  /// WHAT was decided, and none of the hashes themselves.
  ///
  /// Ordering does not matter (the encoder sorts keys), but the field LIST
  /// does: adding a field changes every subsequent hash, so extending it is a
  /// deliberate, chain-breaking act — verification of rows written before the
  /// change must use the old field list, exactly like `AgentConfigSnapshot`'s
  /// `hashVersion`.
  Map<String, Object?> hashPayload() => {
    'id': id,
    'workspace_id': workspaceId,
    'seq': seq,
    'occurred_at': occurredAt.toUtc().toIso8601String(),
    'actor_type': actorType,
    'actor_id': actorId,
    'on_behalf_of_user_id': onBehalfOfUserId,
    'delegation_chain_id': delegationChainId,
    'delegation_depth': delegationDepth,
    'space_id': spaceId,
    'run_id': runId,
    'device_id': deviceId,
    'ip': ip,
    'surface': surface.wire,
    'action_name': actionName,
    'action_classes': actionClasses,
    'permission': permission,
    'args_digest': argsDigest,
    'constraint_summary': constraintSummary,
    'decision': decision.wire,
    'enforcement': enforcement?.wire,
    'source_scope': sourceScope,
    'rule_id': ruleId,
    'prompted': prompted,
    'responder_user_id': responderUserId,
    'override_reason': overrideReason,
    'correlation_id': correlationId,
    'kind': kind,
  };

  /// Computes this row's [entryHash] given the chain's current head.
  ///
  /// `sha256(prevHash ‖ canonicalJson(hashPayload))` — deleting or editing any
  /// row breaks every hash after it, so an export plus the chain head proves
  /// integrity without trusting the database file.
  String computeEntryHash(String previousHash) =>
      canonicalHash({'prev': previousHash, 'entry': hashPayload()});

  /// A copy stamped with its chain position — used by the append path, which
  /// allocates [seq] and reads [prevHash] inside one transaction.
  GuardDecision chained({required int seq, required String prevHash}) {
    final positioned = copyWith(seq: seq, prevHash: prevHash);
    return positioned.copyWith(
      entryHash: positioned.computeEntryHash(prevHash),
    );
  }

  /// Identity is the row: an audit entry is uniquely identified by its id,
  /// and within a workspace by its chain position.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GuardDecision &&
          other.id == id &&
          other.workspaceId == workspaceId &&
          other.seq == seq &&
          other.entryHash == entryHash;

  @override
  int get hashCode => Object.hash(id, workspaceId, seq, entryHash);

  /// Returns a copy with the given fields replaced.
  GuardDecision copyWith({
    int? seq,
    String? prevHash,
    String? entryHash,
    String? correlationId,
  }) => GuardDecision(
    id: id,
    workspaceId: workspaceId,
    seq: seq ?? this.seq,
    occurredAt: occurredAt,
    actorType: actorType,
    actorId: actorId,
    onBehalfOfUserId: onBehalfOfUserId,
    delegationChainId: delegationChainId,
    delegationDepth: delegationDepth,
    spaceId: spaceId,
    runId: runId,
    deviceId: deviceId,
    ip: ip,
    surface: surface,
    actionName: actionName,
    actionClasses: actionClasses,
    permission: permission,
    argsDigest: argsDigest,
    constraintSummary: constraintSummary,
    decision: decision,
    enforcement: enforcement,
    sourceScope: sourceScope,
    ruleId: ruleId,
    prompted: prompted,
    responderUserId: responderUserId,
    overrideReason: overrideReason,
    correlationId: correlationId ?? this.correlationId,
    prevHash: prevHash ?? this.prevHash,
    entryHash: entryHash ?? this.entryHash,
    kind: kind,
  );
}

/// The result of verifying a stretch of the audit chain.
///
/// **What an intact result proves, and what it does not.** It proves no row
/// was edited, deleted or reordered by anything that could not also rewrite
/// every row after it — which covers a buggy sweeper, a careless operator and
/// anyone reaching the data through the application. It does NOT by itself
/// defeat an attacker with unrestricted write access to the database file,
/// who can recompute a whole self-consistent chain. Detecting that requires
/// the chain head to be recorded somewhere they cannot rewrite — which is
/// what shipping each entry's hash to an external SIEM gives you, and why
/// [checkpoints] is reported rather than hidden: truncation is legitimate,
/// but it is also the shape history-erasure would take.
class ChainVerification {
  /// Creates a [ChainVerification].
  const ChainVerification({
    required this.rowsChecked,
    required this.intact,
    this.brokenAtSeq,
    this.reason,
    this.checkpoints = 0,
  });

  /// How many rows were verified.
  final int rowsChecked;

  /// Whether every link held.
  final bool intact;

  /// The first sequence number whose link failed.
  final int? brokenAtSeq;

  /// Why it failed (recomputed-hash mismatch, or a gap in the chain).
  final String? reason;

  /// How many retention truncations this stretch of chain carries. Each one
  /// is a legitimate, hash-anchored removal of an exported segment — and each
  /// one is also a stretch of history no longer present to re-read.
  final int checkpoints;
}
