import 'package:cc_domain/features/guardrails/domain/entities/guard_decision.dart'
    show EnforcementLevel;
import 'package:cc_domain/features/guardrails/domain/value_objects/action_constraint.dart';
import 'package:cc_domain/features/guardrails/domain/value_objects/action_decision.dart';
import 'package:cc_domain/features/guardrails/domain/value_objects/action_request.dart';
import 'package:cc_harness/tools.dart';

/// One user-defined guardrail rule (PRD 24 §2): a decision for an
/// [ActionClass] OR a [commandPrefix], at a given scope. Exactly one of
/// [actionClass] / [commandPrefix] is set.
class ActionPolicyRule {
  /// Creates an [ActionPolicyRule].
  const ActionPolicyRule({
    required this.id,
    required this.workspaceId,
    required this.scopeType,
    required this.scopeId,
    required this.decision,
    this.actionClass,
    this.commandPrefix,
    this.provenance = 'user',
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.constraint,
    this.expiresAt,
    this.enforcement = EnforcementLevel.hard,
  }) : assert(
         (actionClass == null) != (commandPrefix == null),
         'Exactly one of actionClass / commandPrefix must be set',
       );

  /// Unique rule id.
  final String id;

  /// Owning workspace.
  final String workspaceId;

  /// The scope this rule applies at.
  final ActionScopeType scopeType;

  /// The scope id (empty for workspace scope).
  final String scopeId;

  /// The governed action class (null when a command-prefix rule).
  final ActionClass? actionClass;

  /// The governed command prefix (null when an action-class rule).
  final String? commandPrefix;

  /// The decision.
  final ActionDecision decision;

  /// `user` or `remembered` (a materialized RememberScope decision).
  final String provenance;

  /// Principal that created the rule.
  final String? createdBy;

  /// Creation time.
  final DateTime createdAt;

  /// Last mutation time.
  final DateTime updatedAt;

  /// The argument-level condition this rule carries, or null for a rule that
  /// matches every request (which is what every pre-constraint row is).
  final ActionConstraint? constraint;

  /// When this rule stops applying, or null for a permanent rule.
  ///
  /// This is what makes a standing approval self-revoking: "allow pushes to
  /// `feature/*` in this space for the next 8 hours" is a real, expiring
  /// grant rather than a permanent policy change nobody remembers making.
  final DateTime? expiresAt;

  /// How strongly this rule is enforced (advisory / soft / hard).
  final EnforcementLevel enforcement;

  /// Whether this rule has expired at [now].
  bool isExpiredAt(DateTime now) =>
      expiresAt != null && !now.isBefore(expiresAt!);

  /// Whether this rule RESTRICTS rather than permits.
  ///
  /// Decides how its constraint is read: a deny/prompt asks "does the request
  /// touch anything I forbid?" (any value is enough), an allow asks "is the
  /// request entirely inside what I permit?" (every value must be).
  bool get isRestrictive => decision != ActionDecision.allow;

  /// How this rule's constraint relates to [request]. A rule with no
  /// constraint covers everything.
  ConstraintMatch coverageOf(ActionRequest request) =>
      constraint?.evaluate(request, restrictive: isRestrictive) ??
      ConstraintMatch.hit;

  /// Whether this rule's constraint covers [request] outright.
  bool coversRequest(ActionRequest request) =>
      coverageOf(request) == ConstraintMatch.hit;

  /// Whether this is a standing approval: an "Approve for 8 hours" answer
  /// written by `confirmation.respond`. It answers asks, never denies (see
  /// `PolicyResolver`).
  bool get isStandingApproval =>
      provenance == 'remembered' && decision == ActionDecision.allow;

  /// Whether this standing approval covers [request].
  ///
  /// Stricter than [coversRequest] about commands: a person approved the
  /// command they read, so it must be the whole command. Read as a prefix,
  /// `npm test` would also cover `npm test && ./anything`.
  bool standsFor(ActionRequest request) {
    if (!coversRequest(request)) {
      return false;
    }
    final commands = constraint?.commands;
    return commands == null || commands.contains(request.command?.trim());
  }

  /// Whether this is a plain rule: a person's decision for a whole class or
  /// command prefix, with no condition and no end.
  bool get isPlain =>
      provenance == 'user' && constraint == null && expiresAt == null;

  /// Whether saving [other] replaces this rule.
  ///
  /// A plain rule is unique per scope and class/prefix. Any other rule is
  /// unique per scope, class/prefix, exact constraint and provenance, so
  /// approving the same thing again refreshes it instead of stacking a copy,
  /// while a plain rule and a standing approval of one class coexist.
  bool sharesIdentityWith(ActionPolicyRule other) =>
      workspaceId == other.workspaceId &&
      scopeType == other.scopeType &&
      scopeId == other.scopeId &&
      actionClass == other.actionClass &&
      commandPrefix == other.commandPrefix &&
      isPlain == other.isPlain &&
      (isPlain ||
          (constraint == other.constraint && provenance == other.provenance));

  /// A short provenance label for the policy surface's badge.
  String get provenanceLabel {
    if (provenance == 'remembered') {
      return 'remembered';
    }
    return '${scopeType.wire} rule';
  }

  @override
  bool operator ==(Object other) => other is ActionPolicyRule && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
