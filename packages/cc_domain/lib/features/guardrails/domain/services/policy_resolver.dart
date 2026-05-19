import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/features/dispatch/domain/modes/mode_capability_profile.dart';
import 'package:cc_domain/features/guardrails/domain/entities/action_policy_rule.dart';
import 'package:cc_domain/features/guardrails/domain/value_objects/action_constraint.dart';
import 'package:cc_domain/features/guardrails/domain/value_objects/action_decision.dart';
import 'package:cc_domain/features/guardrails/domain/value_objects/action_request.dart';
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

  /// Where the decision came from: `space`/`agent`/`workspace`/`preset`/
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

/// One rule considered for a request, with the decision it actually yields.
///
/// The two can differ: a restrictive rule whose constraint cannot be evaluated
/// against this request yields `prompt` rather than its stored decision, so an
/// unevaluable safety rule asks a human instead of resolving silently either
/// way.
class _Candidate {
  const _Candidate(this.rule, this.decision, {required this.unevaluable});

  final ActionPolicyRule rule;
  final ActionDecision decision;
  final bool unevaluable;
}

/// The deterministic action-guardrail resolver (PRD 24 §2).
///
/// Precedence: **space > agent > workspace > mode preset > built-in default**
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
    String? spaceId,
    String? agentId,
    Mode mode = Mode.chat,
    ActionRequest request = ActionRequest.empty,
    DateTime? now,
  }) {
    final live = _live(rules, now);
    for (final scope in _scopeChain(spaceId, agentId)) {
      final match = _findClassRule(live, scope.$1, scope.$2, cls, request);
      if (match != null) {
        return PolicyResolution(
          decision: match.decision,
          source: scope.$1.wire,
          reason: match.unevaluable
              ? 'Policy: ${cls.wire} needs approval — a ${scope.$1.wire} '
                    'rule restricts it and this action does not say whether '
                    'it applies.'
              : 'Policy: ${cls.wire} = ${match.decision.wire} '
                    '(${scope.$1.wire} rule).',
          rule: match.rule,
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
    String? spaceId,
    String? agentId,
    ActionRequest request = ActionRequest.empty,
    DateTime? now,
  }) {
    final live = _live(rules, now);
    for (final scope in _scopeChain(spaceId, agentId)) {
      final match = _findCommandRule(live, scope.$1, scope.$2, command, request);
      if (match != null) {
        return PolicyResolution(
          decision: match.decision,
          source: scope.$1.wire,
          reason:
              'Policy: `${match.rule.commandPrefix}` = '
              '${match.decision.wire} (${scope.$1.wire} rule).',
          rule: match.rule,
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
    String? spaceId,
    String? agentId,
    Mode mode = Mode.chat,
    ActionRequest request = ActionRequest.empty,
    List<ActionPolicyRule> managedRules = const [],
    DateTime? now,
  }) {
    final effectiveCommand =
        command ?? (request.command?.isNotEmpty ?? false ? request.command : null);
    final resolutions = <PolicyResolution>[
      for (final c in classes)
        resolveClass(
          c,
          rules: rules,
          spaceId: spaceId,
          agentId: agentId,
          mode: mode,
          request: request,
          now: now,
        ),
    ];
    if (effectiveCommand != null && effectiveCommand.isNotEmpty) {
      final cmd = resolveCommand(
        effectiveCommand,
        rules: rules,
        spaceId: spaceId,
        agentId: agentId,
        request: request,
        now: now,
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
    // The MANAGED (install-wide) tier CLAMPS: it is merged most-restrictive
    // with whatever the workspace chain decided, never inserted at the head
    // of it. A head-of-chain managed `allow` would let the install LOOSEN a
    // workspace's own deny — the exact opposite of what an operator clamp is
    // for.
    if (managedRules.isNotEmpty) {
      final managed = _resolveManaged(
        classes,
        managedRules: managedRules,
        command: effectiveCommand,
        request: request,
        now: now,
      );
      if (managed != null &&
          managed.decision.isMoreRestrictiveThan(driving.decision)) {
        driving = managed;
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

  /// Resolves the managed (install-wide) tier on its own. Managed rules are
  /// stored with [ActionScopeType.workspace] and an empty scope id — they are
  /// not a scope in the chain, they are a separate resolution merged
  /// most-restrictive by [resolveAction].
  PolicyResolution? _resolveManaged(
    Set<ActionClass> classes, {
    required List<ActionPolicyRule> managedRules,
    String? command,
    ActionRequest request = ActionRequest.empty,
    DateTime? now,
  }) {
    final live = _live(managedRules, now);
    PolicyResolution? worst;
    void consider(PolicyResolution? r) {
      if (r == null) {
        return;
      }
      if (worst == null || r.decision.isMoreRestrictiveThan(worst!.decision)) {
        worst = r;
      }
    }

    for (final cls in classes) {
      final match = _findClassRule(
        live,
        ActionScopeType.workspace,
        '',
        cls,
        request,
      );
      if (match != null) {
        consider(
          PolicyResolution(
            decision: match.decision,
            source: 'managed',
            reason: match.unevaluable
                ? 'Policy: ${cls.wire} needs approval — an install-wide '
                      'managed rule restricts it and this action does not '
                      'say whether it applies.'
                : 'Policy: ${cls.wire} = ${match.decision.wire} '
                      '(install-wide managed rule).',
            rule: match.rule,
            actionClass: cls,
          ),
        );
      }
    }
    if (command != null && command.isNotEmpty) {
      final match = _findCommandRule(
        live,
        ActionScopeType.workspace,
        '',
        command,
        request,
      );
      if (match != null) {
        consider(
          PolicyResolution(
            decision: match.decision,
            source: 'managed',
            reason:
                'Policy: `${match.rule.commandPrefix}` = '
                '${match.decision.wire} (install-wide managed rule).',
            rule: match.rule,
          ),
        );
      }
    }
    return worst;
  }

  List<(ActionScopeType, String)> _scopeChain(
    String? spaceId,
    String? agentId,
  ) => [
    if (spaceId != null && spaceId.isNotEmpty) (ActionScopeType.space, spaceId),
    if (agentId != null && agentId.isNotEmpty) (ActionScopeType.agent, agentId),
    (ActionScopeType.workspace, ''),
  ];

  /// Drops rules that have expired — a standing approval self-revokes rather
  /// than quietly becoming permanent policy.
  List<ActionPolicyRule> _live(List<ActionPolicyRule> rules, DateTime? now) {
    if (now == null) {
      return rules;
    }
    return [
      for (final r in rules)
        if (!r.isExpiredAt(now)) r,
    ];
  }

  _Candidate? _findClassRule(
    List<ActionPolicyRule> rules,
    ActionScopeType type,
    String id,
    ActionClass cls,
    ActionRequest request,
  ) {
    // At most one rule per (scope, class) is the *intended* invariant, enforced
    // at the repository chokepoint. But SQLite treats the NULL-bearing unique
    // key as distinct, so it cannot enforce it — so if a logical duplicate ever
    // slips in, resolve MOST-RESTRICTIVE (not first-in-list) to stay
    // deterministic and safe (an allow can never win over a duplicate deny).
    _Candidate? best;
    for (final r in rules) {
      if (r.scopeType != type ||
          r.scopeId != id ||
          r.actionClass != cls ||
          r.commandPrefix != null) {
        continue;
      }
      final candidate = _candidateFor(r, request);
      if (candidate == null) {
        continue;
      }
      if (best == null ||
          _isMoreSpecific(r, best.rule) ||
          (_equallySpecific(r, best.rule) &&
              candidate.decision.isMoreRestrictiveThan(best.decision))) {
        best = candidate;
      }
    }
    return best;
  }

  /// Turns one rule into a candidate for [request], or null when it provably
  /// does not apply.
  ///
  /// This is where the tri-state matters. A restrictive rule whose constraint
  /// cannot be evaluated — "never push to `main`" against a push whose ref
  /// nobody extracted — is NOT skipped (that would make every protected-branch
  /// rule inert) and is NOT applied as a deny (that would refuse every push
  /// the extractor cannot describe). It escalates to a PROMPT: a human is
  /// asked, and with nobody to ask the existing fail-closed rule denies. An
  /// unevaluable safety rule must never resolve silently.
  _Candidate? _candidateFor(ActionPolicyRule rule, ActionRequest request) {
    switch (rule.coverageOf(request)) {
      case ConstraintMatch.hit:
        return _Candidate(rule, rule.decision, unevaluable: false);
      case ConstraintMatch.miss:
        return null;
      case ConstraintMatch.unknown:
        return rule.isRestrictive
            ? _Candidate(rule, ActionDecision.prompt, unevaluable: true)
            : null;
    }
  }

  _Candidate? _findCommandRule(
    List<ActionPolicyRule> rules,
    ActionScopeType type,
    String id,
    String command,
    ActionRequest request,
  ) {
    _Candidate? best;
    for (final r in rules) {
      final prefix = r.commandPrefix;
      if (r.scopeType != type || r.scopeId != id || prefix == null) {
        continue;
      }
      if (!_commandMatchesPrefix(command, prefix)) {
        continue;
      }
      final candidate = _candidateFor(r, request);
      if (candidate == null) {
        continue;
      }
      if (best == null) {
        best = candidate;
        continue;
      }
      final bestLen = best.rule.commandPrefix!.length;
      if (prefix.length > bestLen) {
        best = candidate; // longer prefix wins
      } else if (prefix.length == bestLen &&
          candidate.decision.isMoreRestrictiveThan(best.decision)) {
        best = candidate; // equally specific → most restrictive
      }
    }
    return best;
  }

  /// A CONSTRAINED rule is more specific than an unconstrained one at the
  /// same scope: "deny push to main" must beat "allow push" without the
  /// operator having to think about ordering.
  bool _isMoreSpecific(ActionPolicyRule a, ActionPolicyRule b) =>
      a.constraint != null && b.constraint == null;

  bool _equallySpecific(ActionPolicyRule a, ActionPolicyRule b) =>
      (a.constraint == null) == (b.constraint == null);

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
  /// the tool surface and the sandbox also project from. A second copy here is
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
