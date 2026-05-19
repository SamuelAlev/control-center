import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/features/dispatch/domain/modes/mode_capability_profile.dart';
import 'package:cc_domain/features/guardrails/domain/entities/action_policy_rule.dart';
import 'package:cc_domain/features/guardrails/domain/value_objects/action_decision.dart';
import 'package:cc_harness/tools.dart';

/// The outcome of resolving an action against the policy (PRD 24 §2, §4).
class PolicyResolution {
  /// Creates a [PolicyResolution].
  const PolicyResolution({
    required this.decision,
    required this.source,
    required this.reason,
    this.rule,
    this.actionClass,
  });

  /// The resolved decision.
  final ActionDecision decision;

  /// Where the decision came from: `channel`/`agent`/`workspace`/`preset`/
  /// `default` — the provenance shown per matrix cell.
  final String source;

  /// Human/agent-facing explanation naming the winning rule (informative +
  /// terminal for a deny, so the agent can replan).
  final String reason;

  /// The winning rule, when the decision came from the store.
  final ActionPolicyRule? rule;

  /// The action class this resolution is about (null for a command resolution).
  final ActionClass? actionClass;
}

/// The deterministic action-guardrail resolver (PRD 24 §2).
///
/// Precedence: **channel > agent > workspace > mode preset > built-in default**
/// — the first scope with a matching rule decides and resolution stops. Within
/// a scope, a command uses the longest matching prefix; an equally-specific
/// conflict resolves **most-restrictive** (deny > prompt > allow) — the flat
/// engine's allow-beats-deny is gone. A multi-class action resolves each class
/// independently, then combines most-restrictive. Pure and deterministic: the
/// same inputs always produce the same decision.
class PolicyResolver {
  /// Creates a [PolicyResolver].
  const PolicyResolver();

  /// Resolves a single [cls] under the scope chain + mode preset + default.
  PolicyResolution resolveClass(
    ActionClass cls, {
    required List<ActionPolicyRule> rules,
    String? channelId,
    String? agentId,
    Mode mode = Mode.chat,
  }) {
    for (final scope in _scopeChain(channelId, agentId)) {
      final match = _findClassRule(rules, scope.$1, scope.$2, cls);
      if (match != null) {
        return PolicyResolution(
          decision: match.decision,
          source: scope.$1.wire,
          reason:
              'Policy: ${cls.wire} = ${match.decision.wire} '
              '(${scope.$1.wire} rule).',
          rule: match,
          actionClass: cls,
        );
      }
    }
    final preset = _presetDecision(mode, cls);
    if (preset != null) {
      return PolicyResolution(
        decision: preset,
        source: 'preset',
        reason:
            'Policy: ${cls.wire} = ${preset.wire} (${mode.name} mode is '
            'read-only).',
        actionClass: cls,
      );
    }
    final def = _defaultFor(cls);
    return PolicyResolution(
      decision: def,
      source: 'default',
      reason: 'Policy: ${cls.wire} = ${def.wire} (built-in default).',
      actionClass: cls,
    );
  }

  /// Resolves a shell [command] against command-prefix rules in the store.
  /// Returns null when no store rule matches (the caller falls back to the
  /// legacy `CommandPolicy` command net).
  PolicyResolution? resolveCommand(
    String command, {
    required List<ActionPolicyRule> rules,
    String? channelId,
    String? agentId,
  }) {
    for (final scope in _scopeChain(channelId, agentId)) {
      final match = _findCommandRule(rules, scope.$1, scope.$2, command);
      if (match != null) {
        return PolicyResolution(
          decision: match.decision,
          source: scope.$1.wire,
          reason:
              'Policy: `${match.commandPrefix}` = ${match.decision.wire} '
              '(${scope.$1.wire} rule).',
          rule: match,
        );
      }
    }
    return null;
  }

  /// Resolves a whole action declaring several [classes] (and optionally a
  /// [command]): each resolves independently, then combines most-restrictive.
  /// Returns the resolution that drove the combined decision (for the reason /
  /// confirmation), plus every prompting class (so one confirmation lists all).
  ActionResolution resolveAction(
    Set<ActionClass> classes, {
    required List<ActionPolicyRule> rules,
    String? command,
    String? channelId,
    String? agentId,
    Mode mode = Mode.chat,
  }) {
    final resolutions = <PolicyResolution>[
      for (final c in classes)
        resolveClass(
          c,
          rules: rules,
          channelId: channelId,
          agentId: agentId,
          mode: mode,
        ),
    ];
    if (command != null && command.isNotEmpty) {
      final cmd = resolveCommand(
        command,
        rules: rules,
        channelId: channelId,
        agentId: agentId,
      );
      if (cmd != null) {
        resolutions.add(cmd);
      }
    }
    if (resolutions.isEmpty) {
      return const ActionResolution(
        decision: ActionDecision.allow,
        driving: PolicyResolution(
          decision: ActionDecision.allow,
          source: 'default',
          reason: 'No classified effects.',
        ),
        prompting: [],
      );
    }
    // Most restrictive drives the combined decision.
    var driving = resolutions.first;
    for (final r in resolutions.skip(1)) {
      if (r.decision.isMoreRestrictiveThan(driving.decision)) {
        driving = r;
      }
    }
    final prompting = resolutions
        .where((r) => r.decision == ActionDecision.prompt)
        .toList();
    return ActionResolution(
      decision: driving.decision,
      driving: driving,
      prompting: prompting,
    );
  }

  List<(ActionScopeType, String)> _scopeChain(
    String? channelId,
    String? agentId,
  ) => [
    if (channelId != null && channelId.isNotEmpty)
      (ActionScopeType.channel, channelId),
    if (agentId != null && agentId.isNotEmpty) (ActionScopeType.agent, agentId),
    (ActionScopeType.workspace, ''),
  ];

  ActionPolicyRule? _findClassRule(
    List<ActionPolicyRule> rules,
    ActionScopeType type,
    String id,
    ActionClass cls,
  ) {
    // At most one rule per (scope, class) is the *intended* invariant, enforced
    // at the repository chokepoint. But SQLite treats the NULL-bearing unique
    // key as distinct, so it cannot enforce it — so if a logical duplicate ever
    // slips in, resolve MOST-RESTRICTIVE (not first-in-list) to stay
    // deterministic and safe (an allow can never win over a duplicate deny).
    ActionPolicyRule? best;
    for (final r in rules) {
      if (r.scopeType == type &&
          r.scopeId == id &&
          r.actionClass == cls &&
          r.commandPrefix == null) {
        if (best == null || r.decision.isMoreRestrictiveThan(best.decision)) {
          best = r;
        }
      }
    }
    return best;
  }

  ActionPolicyRule? _findCommandRule(
    List<ActionPolicyRule> rules,
    ActionScopeType type,
    String id,
    String command,
  ) {
    ActionPolicyRule? best;
    for (final r in rules) {
      final prefix = r.commandPrefix;
      if (r.scopeType != type || r.scopeId != id || prefix == null) {
        continue;
      }
      if (!_commandMatchesPrefix(command, prefix)) {
        continue;
      }
      if (best == null) {
        best = r;
        continue;
      }
      final bestLen = best.commandPrefix!.length;
      if (prefix.length > bestLen) {
        best = r; // longer prefix wins
      } else if (prefix.length == bestLen &&
          r.decision.isMoreRestrictiveThan(best.decision)) {
        best = r; // equally specific → most restrictive
      }
    }
    return best;
  }

  bool _commandMatchesPrefix(String command, String prefix) {
    final c = command.trim();
    if (c == prefix) {
      return true;
    }
    return c.startsWith('$prefix ');
  }

  /// The mode preset: read-only modes (plan/review/orchestrate) deny mutating +
  /// exec effects; chat has no preset (falls through to the built-in default).
  ///
  /// The deny set is NOT declared here — it is read from
  /// [ModeCapabilityProfile.deniedClasses], the single declaration the prompt,
  /// the tool surface, and the sandbox also project from. A second copy here is
  /// how orchestrate mode came to deny `vendorSyncWrite`, the effect class of
  /// the only verb that mode can use to deliver anything.
  ///
  /// A mode's own output verbs are exempt: they are pinned into the tool surface
  /// and pre-approved at the dispatch gate before this resolver is consulted.
  ActionDecision? _presetDecision(Mode mode, ActionClass cls) =>
      profileFor(mode).deniedClasses.contains(cls) ? ActionDecision.deny : null;

  ActionDecision _defaultFor(ActionClass cls) =>
      cls.defaultDecisionHint == ActionDecisionDefault.prompt
      ? ActionDecision.prompt
      : ActionDecision.allow;
}

/// The combined result of resolving a multi-class action.
class ActionResolution {
  /// Creates an [ActionResolution].
  const ActionResolution({
    required this.decision,
    required this.driving,
    required this.prompting,
  });

  /// The combined (most-restrictive) decision.
  final ActionDecision decision;

  /// The single resolution that drove [decision] (for the reason line).
  final PolicyResolution driving;

  /// Every class that resolved to `prompt` (so ONE confirmation can list them).
  final List<PolicyResolution> prompting;
}
