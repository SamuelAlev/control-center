import 'package:cc_domain/core/domain/ports/confirmation_port.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/features/guardrails/domain/entities/action_policy_rule.dart';
import 'package:cc_domain/features/guardrails/domain/entities/guard_decision.dart'
    show EnforcementLevel;
import 'package:cc_domain/features/guardrails/domain/repositories/action_policy_repository.dart';
import 'package:cc_domain/features/guardrails/domain/services/policy_resolver.dart';
import 'package:cc_domain/features/guardrails/domain/value_objects/action_constraint.dart';
import 'package:cc_domain/features/guardrails/domain/value_objects/action_decision.dart';
import 'package:cc_domain/features/guardrails/domain/value_objects/action_request.dart';
import 'package:cc_harness/tools.dart';

/// The verdict of an action-guard check.
class GuardVerdict {
  /// Creates a [GuardVerdict].
  const GuardVerdict({
    required this.allowed,
    this.reason,
    this.source,
    this.prompted = false,
  });

  /// An allow verdict. [prompted] is true when the operator was just asked to
  /// confirm (so a downstream gate can skip a redundant second confirmation).
  const GuardVerdict.allow({this.source = 'default', this.prompted = false})
    : allowed = true,
      reason = null;

  /// A deny verdict carrying the agent-facing [reason].
  const GuardVerdict.deny(this.reason, {this.source, this.prompted = false})
    : allowed = false;

  /// Whether the action may proceed.
  final bool allowed;

  /// The informative, terminal reason when denied (so the agent can replan).
  final String? reason;

  /// The provenance of the decision (space/agent/workspace/preset/default).
  final String? source;

  /// Whether this verdict surfaced a confirmation prompt to the operator. Lets
  /// a downstream capability-tier gate avoid a DOUBLE confirmation for the same
  /// tool call (PRD 24 — the guard owns the declared classes and already asked).
  final bool prompted;
}

/// A record of a guard decision for the audit trail (PRD 24 §5).
///
/// Emitted for EVERY verdict — allow included. An audit trail that records
/// only refusals answers "what did we block?" but not "what did this agent
/// actually do, and who authorized it?", which is the question an incident
/// review starts from.
class GuardAudit {
  /// Creates a [GuardAudit].
  const GuardAudit({
    required this.workspaceId,
    required this.decision,
    required this.reason,
    required this.source,
    this.agentId,
    this.spaceId,
    this.actionSummary = '',
    this.actionClasses = const [],
    this.ruleId,
    this.prompted = false,
    this.onBehalfOfUserId,
    this.runId,
    this.command,
  });

  /// Owning workspace.
  final String workspaceId;

  /// The resolved decision.
  final ActionDecision decision;

  /// The reason / winning rule.
  final String reason;

  /// Provenance.
  final String source;

  /// Agent that attempted the action.
  final String? agentId;

  /// Space context.
  final String? spaceId;

  /// A short description of the action (tool/op name + classes).
  final String actionSummary;

  /// The effect classes the action declared.
  final List<String> actionClasses;

  /// The `action_policies` row that decided, when a stored rule did.
  final String? ruleId;

  /// Whether a human was asked and answered.
  final bool prompted;

  /// The human this agent acts on behalf of — the delegation link that makes
  /// an agent action attributable to a person.
  final String? onBehalfOfUserId;

  /// The agent run this action came from.
  final String? runId;

  /// The shell command, when the action was a command execution.
  final String? command;
}

/// Resolves an agent-initiated action against the policy store and gates it
/// (PRD 24 §3). The single seam every chokepoint (harness ToolRegistry, MCP
/// dispatcher, repo-op dispatcher, command runner) funnels through:
///
/// - `allow` → proceed.
/// - `deny` → refuse with an informative, terminal reason (audited).
/// - `prompt` → one [ConfirmationPort.requestApproval]; **fail-closed** when no
///   approver is connected (matches the harness posture). One confirmation is
///   shown even when several classes prompt.
///
/// The sandbox floor is enforced elsewhere and is always at least as strict —
/// an `allow` here never loosens it.
class ActionGuardService {
  /// Creates an [ActionGuardService].
  ActionGuardService({
    required ActionPolicyRepository repository,
    ConfirmationPort? confirmationPort,
    PolicyResolver resolver = const PolicyResolver(),
    void Function(GuardAudit audit)? onAudit,
    Future<List<ActionPolicyRule>> Function()? managedRules,
  }) : _repo = repository,
       _confirm = confirmationPort,
       _resolver = resolver,
       _onAudit = onAudit,
       _managed = managedRules;

  final ActionPolicyRepository _repo;
  final ConfirmationPort? _confirm;
  final PolicyResolver _resolver;
  final void Function(GuardAudit audit)? _onAudit;

  /// Loads the install-wide managed rules. Null (solo installs, tests) means
  /// there is no managed tier and resolution is the workspace chain alone.
  final Future<List<ActionPolicyRule>> Function()? _managed;

  Future<List<ActionPolicyRule>> _managedRules() async =>
      _managed?.call() ?? Future.value(const []);

  /// Resolves an action to its policy decision WITHOUT surfacing any
  /// confirmation (pure read of the store + [PolicyResolver]). A chokepoint that
  /// layers its own approval flow — e.g. the harness autonomy dial, where
  /// `actFreely` must pre-approve a `prompt` yet a hard `deny` rule must still
  /// block — resolves first with this, then decides whether to call [check] or
  /// its own port. Returns an all-allow resolution for an effect-free action.
  Future<ActionResolution> resolve({
    required String workspaceId,
    required Set<ActionClass> classes,
    String? command,
    String? spaceId,
    String? agentId,
    Mode mode = Mode.chat,
    ActionRequest request = ActionRequest.empty,
  }) async {
    if (classes.isEmpty && (command == null || command.isEmpty)) {
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
    final rules = await _repo.rules(workspaceId);
    return _resolver.resolveAction(
      classes,
      rules: rules,
      command: command,
      spaceId: spaceId,
      agentId: agentId,
      mode: mode,
      request: request,
      managedRules: await _managedRules(),
      now: DateTime.now(),
    );
  }

  /// Records the outcome a caller APPLIED after resolving policy itself.
  ///
  /// [resolve] is a pure read, so a chokepoint that layers its own approval
  /// flow on top — the harness tool gate composes the resolution with the
  /// space's autonomy dial — never went through [check] and therefore never
  /// audited. That silently exempted the busiest agent surface in the product
  /// from the audit trail while the trail claimed to record every verdict.
  /// Callers of [resolve] report what they did here.
  void recordOutcome({
    required String workspaceId,
    required ActionResolution resolution,
    required ActionDecision applied,
    required Set<ActionClass> classes,
    String? agentId,
    String? spaceId,
    String actionSummary = '',
    bool prompted = false,
    String? onBehalfOfUserId,
    String? runId,
    String? command,
  }) {
    _onAudit?.call(
      GuardAudit(
        workspaceId: workspaceId,
        decision: applied,
        reason: resolution.driving.reason,
        source: resolution.driving.source,
        agentId: agentId,
        spaceId: spaceId,
        actionSummary: actionSummary,
        actionClasses: [for (final c in classes) c.wire],
        ruleId: resolution.driving.rule?.id,
        prompted: prompted,
        onBehalfOfUserId: onBehalfOfUserId,
        runId: runId,
        command: command,
      ),
    );
  }

  /// Checks an action declaring [classes] (and optionally a shell [command]).
  ///
  /// [operatorInitiated] marks a call whose actor IS the human a `prompt` would
  /// ask — the operator's own click on a repo-RPC op, never an agent. For those,
  /// the click is the confirmation: a `prompt` decision resolves to allow
  /// without surfacing a dialog, because asking somebody to approve the button
  /// they just pressed is not a control, it is a second click. `deny` is
  /// unaffected — a workspace/space rule that forbids an effect still forbids it
  /// however it was initiated, and is still audited.
  Future<GuardVerdict> check({
    required String workspaceId,
    required Set<ActionClass> classes,
    String? command,
    String? spaceId,
    String? agentId,
    Mode mode = Mode.chat,
    String actionSummary = '',
    bool operatorInitiated = false,
    String? onBehalfOfUserId,
    String? runId,
    ActionRequest request = ActionRequest.empty,
    // Soft-mandatory override: both are required together. A reason with no
    // permission is not an override, and a permission with no reason is an
    // unaudited one.
    bool canOverride = false,
    String? overrideReason,
  }) async {
    if (classes.isEmpty && (command == null || command.isEmpty)) {
      return const GuardVerdict.allow();
    }
    final rules = await _repo.rules(workspaceId);
    final res = _resolver.resolveAction(
      classes,
      rules: rules,
      command: command,
      spaceId: spaceId,
      agentId: agentId,
      mode: mode,
      request: request,
      // The install-wide clamp and the clock: an expired standing approval
      // stops applying, and a managed rule can only tighten what the
      // workspace decided.
      managedRules: await _managedRules(),
      now: DateTime.now(),
    );

    void audit(ActionDecision decision, {bool prompted = false}) {
      _onAudit?.call(
        GuardAudit(
          workspaceId: workspaceId,
          decision: decision,
          reason: res.driving.reason,
          source: res.driving.source,
          agentId: agentId,
          spaceId: spaceId,
          actionSummary: actionSummary,
          actionClasses: [for (final c in classes) c.wire],
          ruleId: res.driving.rule?.id,
          prompted: prompted,
          onBehalfOfUserId: onBehalfOfUserId,
          runId: runId,
          command: command,
        ),
      );
    }

    switch (res.decision) {
      case ActionDecision.allow:
        // Allows are recorded too: "which human authorized this agent action"
        // is unanswerable from a deny-only trail.
        audit(ActionDecision.allow);
        return GuardVerdict.allow(source: res.driving.source);
      case ActionDecision.prompt when res.driving.rule?.enforcement ==
          EnforcementLevel.advisory:
        // ADVISORY: allow, but record that the rule matched. This is how a
        // strict rule gets adopted — roll it out advisory, read the audit
        // trail to see what it WOULD have blocked, then promote it.
        audit(ActionDecision.allow);
        return GuardVerdict.allow(source: res.driving.source);
      case ActionDecision.deny:
        // Soft-mandatory: a deny a holder of the override permission may
        // proceed through, WITH a recorded justification. This is the escape
        // hatch that makes strict policy adoptable (Sentinel's model) — and
        // it is deliberately not available on `hard`, which is the floor the
        // product's safety story rests on.
        final rule = res.driving.rule;
        if (rule?.enforcement == EnforcementLevel.soft &&
            overrideReason != null &&
            overrideReason.trim().isNotEmpty &&
            canOverride) {
          audit(ActionDecision.allow);
          return GuardVerdict.allow(source: res.driving.source);
        }
        audit(ActionDecision.deny);
        return GuardVerdict.deny(
          rule?.enforcement == EnforcementLevel.soft
              ? '${res.driving.reason} This rule may be overridden with a '
                    'recorded justification by someone holding the override '
                    'permission.'
              : res.driving.reason,
          source: res.driving.source,
        );
      case ActionDecision.prompt:
        if (operatorInitiated) {
          // The operator asked for this action directly; the request itself is
          // the approval. Audited as an allow so the trail still shows which
          // rule was in play and who satisfied it.
          audit(ActionDecision.allow);
          return GuardVerdict.allow(source: res.driving.source);
        }
        final port = _confirm;
        if (port == null) {
          // Fail-closed: an action that must prompt but has no approver denies.
          audit(ActionDecision.deny);
          return GuardVerdict.deny(
            '${res.driving.reason} No approver is connected (fail-closed).',
            source: res.driving.source,
          );
        }
        final approved = await port.requestApproval(
          _buildRequest(
            res,
            spaceId: spaceId,
            actionSummary: actionSummary,
            workspaceId: workspaceId,
            agentId: agentId,
            request: request,
          ),
        );
        audit(
          approved ? ActionDecision.allow : ActionDecision.deny,
          prompted: true,
        );
        return approved
            ? GuardVerdict.allow(source: res.driving.source, prompted: true)
            : GuardVerdict.deny(
                'Denied at confirmation: ${res.driving.reason}',
                source: res.driving.source,
                prompted: true,
              );
    }
  }

  ConfirmationRequest _buildRequest(
    ActionResolution res, {
    String? spaceId,
    String actionSummary = '',
    String? workspaceId,
    String? agentId,
    ActionRequest request = ActionRequest.empty,
  }) {
    final classes = res.prompting
        .map((r) => r.actionClass?.wire)
        .whereType<String>()
        .toList();
    final drivingClass = res.driving.actionClass;
    return ConfirmationRequest(
      spaceId: spaceId ?? '',
      workspaceId: workspaceId,
      title: actionSummary.isEmpty
          ? 'Allow this action?'
          : 'Allow: $actionSummary',
      detail: classes.isEmpty
          ? res.driving.reason
          : '${res.driving.reason}\nEffects requiring approval: '
                '${classes.join(", ")}.',
      severity: _severityFor(drivingClass),
      kind: _kindFor(drivingClass),
      rememberChoice: RememberScope.workspace,
      fingerprint: 'action:${classes.join("+")}:$actionSummary',
      // What a "remember this" answer needs in order to materialize a real,
      // NARROW rule: which effects prompted, whose agent it was, and the
      // arguments the approved call actually carried.
      actionClasses: classes,
      agentId: agentId,
      constraintJson: _rememberConstraintFor(request)?.encode(),
    );
  }

  /// Generalizes the approved call's arguments into the constraint a
  /// remembered rule should carry.
  ///
  /// A standing approval must be narrower than "yes to everything" and wider
  /// than "yes to this exact call" — approving one push to `feature/login`
  /// should not re-prompt on `feature/logout`, and must NOT cover `main`. So
  /// a ref is generalized to its first segment (`feature/**`), a path to its
  /// directory, and a host is kept exactly. An empty request generalizes to
  /// null: the rule then covers the class outright, which is what the operator
  /// answered when there was nothing narrower to say.
  ActionConstraint? _rememberConstraintFor(ActionRequest request) {
    if (request.isEmpty) {
      return null;
    }
    List<String>? generalizedRefs;
    if (request.refs.isNotEmpty) {
      generalizedRefs = {
        for (final ref in request.refs)
          if (ref.contains('/')) '${ref.split('/').first}/**' else ref,
      }.toList()..sort();
    }
    List<String>? generalizedPaths;
    if (request.paths.isNotEmpty) {
      generalizedPaths = {
        for (final path in request.paths)
          if (path.contains('/'))
            '${path.substring(0, path.lastIndexOf('/'))}/**'
          else
            path,
      }.toList()..sort();
    }
    final constraint = ActionConstraint(
      refs: generalizedRefs,
      paths: generalizedPaths,
      hosts: request.hosts.isEmpty ? null : (request.hosts.toSet().toList()..sort()),
      commands: request.command == null ? null : [request.command!],
    );
    return constraint.isUnconstrained ? null : constraint;
  }

  ConfirmationSeverity _severityFor(ActionClass? cls) {
    switch (cls) {
      case ActionClass.fileDelete:
      case ActionClass.gitPush:
      case ActionClass.prPublish:
        return ConfirmationSeverity.destructive;
      default:
        return ConfirmationSeverity.warning;
    }
  }

  ConfirmationKind _kindFor(ActionClass? cls) {
    switch (cls) {
      case ActionClass.fileDelete:
      case ActionClass.fileWriteOutsideWorktree:
        return ConfirmationKind.fileWrite;
      case ActionClass.networkEgress:
        return ConfirmationKind.networkEgress;
      case ActionClass.secretAccess:
        return ConfirmationKind.capabilityEscalation;
      default:
        return ConfirmationKind.command;
    }
  }
}
