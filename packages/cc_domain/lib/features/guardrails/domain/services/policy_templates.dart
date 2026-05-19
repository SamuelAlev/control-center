import 'package:cc_domain/features/guardrails/domain/entities/action_policy_rule.dart';
import 'package:cc_domain/features/guardrails/domain/entities/guard_decision.dart'
    show EnforcementLevel;
import 'package:cc_domain/features/guardrails/domain/value_objects/action_constraint.dart';
import 'package:cc_domain/features/guardrails/domain/value_objects/action_decision.dart';
import 'package:cc_harness/tools.dart';

/// A named starting posture for a workspace's guardrails.
///
/// Without these, every workspace starts at the built-in defaults and an
/// operator has to re-derive the same thirteen decisions by hand, per
/// workspace, from scratch — which is how a policy surface ends up unused.
/// A template is applied as ordinary rules, so it is a starting point the
/// operator then edits, never a mode they are stuck in.
enum PolicyTemplate {
  /// Everything effectful asks first; nothing is silently permitted.
  strict('strict'),

  /// The shipped defaults, plus the guardrails most teams actually want:
  /// protected refs are refused outright and destructive file operations ask.
  balanced('balanced'),

  /// Day-to-day work proceeds; only the genuinely irreversible asks.
  permissive('permissive');

  const PolicyTemplate(this.wire);

  /// Stable wire name.
  final String wire;

  /// Parses a wire name, or null.
  static PolicyTemplate? fromWire(String? value) {
    for (final t in PolicyTemplate.values) {
      if (t.wire == value) {
        return t;
      }
    }
    return null;
  }
}

/// Builds the rules one [PolicyTemplate] installs at workspace scope.
///
/// Pure: the caller supplies ids and the clock, so applying a template is
/// testable and deterministic.
class PolicyTemplates {
  /// Creates a [PolicyTemplates].
  const PolicyTemplates();

  /// The rules [template] installs in [workspaceId].
  List<ActionPolicyRule> rulesFor(
    PolicyTemplate template, {
    required String workspaceId,
    required String Function() idFactory,
    required DateTime now,
    String? createdBy,
  }) {
    ActionPolicyRule rule(
      ActionClass cls,
      ActionDecision decision, {
      ActionConstraint? constraint,
      EnforcementLevel enforcement = EnforcementLevel.hard,
    }) => ActionPolicyRule(
      id: idFactory(),
      workspaceId: workspaceId,
      scopeType: ActionScopeType.workspace,
      scopeId: '',
      actionClass: cls,
      decision: decision,
      constraint: constraint,
      enforcement: enforcement,
      createdBy: createdBy,
      createdAt: now,
      updatedAt: now,
    );

    // Protecting the trunk is the one rule almost every team wants and the
    // clearest demonstration of argument-level policy: push is allowed, but
    // never to these refs.
    const protectedRefs = ActionConstraint(
      refs: ['main', 'master', 'release/*', 'production'],
    );

    return switch (template) {
      PolicyTemplate.strict => [
        for (final cls in ActionClass.values)
          if (cls != ActionClass.workspaceMutation)
            rule(cls, ActionDecision.prompt),
        rule(
          ActionClass.gitPush,
          ActionDecision.deny,
          constraint: protectedRefs,
        ),
      ],
      PolicyTemplate.balanced => [
        rule(ActionClass.gitPush, ActionDecision.deny,
            constraint: protectedRefs),
        rule(ActionClass.fileDelete, ActionDecision.prompt),
        rule(ActionClass.secretAccess, ActionDecision.prompt),
        rule(ActionClass.packageInstall, ActionDecision.prompt),
        rule(ActionClass.prPublish, ActionDecision.prompt),
        rule(ActionClass.enclosureControl, ActionDecision.prompt),
      ],
      PolicyTemplate.permissive => [
        // Even here the trunk stays protected: "permissive" is about not
        // interrupting day-to-day work, not about letting an agent rewrite
        // the default branch unattended.
        rule(ActionClass.gitPush, ActionDecision.deny,
            constraint: protectedRefs),
        rule(ActionClass.gitPush, ActionDecision.allow),
        rule(ActionClass.prCreate, ActionDecision.allow),
        rule(ActionClass.vendorSyncWrite, ActionDecision.allow),
        rule(ActionClass.fileDelete, ActionDecision.prompt),
      ],
    };
  }

  /// Serializes [rules] to the portable JSON an operator can move between
  /// workspaces (and between installs).
  ///
  /// Ids, workspace and timestamps are deliberately omitted: an export is a
  /// POSTURE, not a set of rows, so importing it into another workspace mints
  /// fresh rules rather than colliding on ids.
  List<Map<String, Object?>> export(List<ActionPolicyRule> rules) => [
    for (final r in rules)
      {
        'scope_type': r.scopeType.wire,
        if (r.scopeId.isNotEmpty) 'scope_id': r.scopeId,
        if (r.actionClass != null) 'action_class': r.actionClass!.wire,
        if (r.commandPrefix != null) 'command_prefix': r.commandPrefix,
        'decision': r.decision.wire,
        'enforcement': r.enforcement.wire,
        if (r.constraint != null) 'constraint': r.constraint!.toJson(),
      },
  ];

  /// Parses exported JSON back into rules for [workspaceId].
  ///
  /// Entries that name no effect (neither a class nor a command prefix) are
  /// skipped rather than imported as something they are not.
  List<ActionPolicyRule> import(
    List<dynamic> json, {
    required String workspaceId,
    required String Function() idFactory,
    required DateTime now,
    String? createdBy,
  }) {
    final rules = <ActionPolicyRule>[];
    for (final entry in json) {
      if (entry is! Map) {
        continue;
      }
      final map = entry.cast<String, dynamic>();
      final clsWire = map['action_class'] as String?;
      final prefix = map['command_prefix'] as String?;
      final cls = clsWire == null ? null : ActionClass.fromWire(clsWire);
      if (cls == null && (prefix == null || prefix.isEmpty)) {
        continue;
      }
      final rawConstraint = map['constraint'];
      rules.add(
        ActionPolicyRule(
          id: idFactory(),
          workspaceId: workspaceId,
          scopeType: ActionScopeType.fromWire(
            map['scope_type'] as String? ?? 'workspace',
          ),
          scopeId: map['scope_id'] as String? ?? '',
          actionClass: cls,
          commandPrefix: cls == null ? prefix : null,
          decision: ActionDecision.fromWire(
            map['decision'] as String? ?? 'prompt',
          ),
          enforcement: EnforcementLevel.fromWire(map['enforcement'] as String?),
          constraint: rawConstraint is Map
              ? ActionConstraint.fromJson(rawConstraint.cast<String, dynamic>())
              : null,
          createdBy: createdBy,
          createdAt: now,
          updatedAt: now,
        ),
      );
    }
    return rules;
  }
}
