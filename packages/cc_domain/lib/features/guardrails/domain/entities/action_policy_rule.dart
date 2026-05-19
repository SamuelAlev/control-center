import 'package:cc_domain/features/guardrails/domain/value_objects/action_decision.dart';
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
