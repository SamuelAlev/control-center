import 'dart:convert';

import 'package:cc_domain/core/domain/ports/confirmation_port.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/features/guardrails/domain/entities/action_policy_rule.dart';
import 'package:cc_domain/features/guardrails/domain/entities/guard_decision.dart'
    show EnforcementLevel;
import 'package:cc_domain/features/guardrails/domain/repositories/action_policy_repository.dart';
import 'package:cc_domain/features/guardrails/domain/services/action_approval_copy.dart';
import 'package:cc_domain/features/guardrails/domain/services/autonomy_composition.dart';
import 'package:cc_domain/features/guardrails/domain/services/policy_resolver.dart';
import 'package:cc_domain/features/guardrails/domain/value_objects/action_constraint.dart';
import 'package:cc_domain/features/guardrails/domain/value_objects/action_decision.dart';
import 'package:cc_domain/features/guardrails/domain/value_objects/action_request.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/autonomy_level.dart';
import 'package:cc_harness/tools.dart';

/// The agent-facing reason when a space's autonomy dial, not the action
/// policy, refused an action. One sentence for every runtime that applies the
/// dial, so a refusal reads the same whichever adapter ran the agent.
const kProposeOnlyReason =
    "this space's autonomy is set to propose-only; propose the action in a "
    'message instead and let the operator run it';

/// The verdict of an action-guard check.
class GuardVerdict {
  /// Creates a [GuardVerdict].
  const GuardVerdict({
    required this.allowed,
    this.reason,
    this.source,
    this.prompted = false,
    this.resolution,
  });

  /// An allow verdict. [prompted] is true when the operator was just asked to
  /// confirm (so a downstream gate can skip a redundant second confirmation).
  const GuardVerdict.allow({
    this.source = 'default',
    this.prompted = false,
    this.resolution,
  }) : allowed = true,
       reason = null;

  /// A deny verdict carrying the agent-facing [reason].
  const GuardVerdict.deny(
    this.reason, {
    this.source,
    this.prompted = false,
    this.resolution,
  }) : allowed = false;

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

  /// The policy's answer this verdict was decided from, or null when the call
  /// had no effects to resolve. A gate that asks on its own hands it to
  /// [ActionGuardService.approvalRequest].
  final ActionResolution? resolution;

  /// See [ActionResolution.standingApprovalCovers]; false for a denied call.
  bool standingApprovalCovers({String? tool, String? command}) =>
      allowed &&
      (resolution?.standingApprovalCovers(tool: tool, command: command) ??
          false);
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
    this._resolver = const PolicyResolver(),
    this._onAudit,
    Future<List<ActionPolicyRule>> Function()? managedRules,
  }) : _repo = repository,
       _confirm = confirmationPort,
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

  /// Resolves an action to its policy decision WITHOUT surfacing confirmation
  /// (pure read of the store + [PolicyResolver]). A chokepoint layering its own
  /// approval flow (e.g. the harness autonomy dial) must still honor a resolved
  /// `prompt` or `deny` and record the applied result with [recordOutcome].
  /// Returns an all-allow resolution for an effect-free action.
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
    String? conversationId,
    String? agentId,
    Mode mode = Mode.chat,
    String actionSummary = '',
    String? approvalRationale,
    bool operatorInitiated = false,
    String? onBehalfOfUserId,
    String? runId,
    ActionRequest request = ActionRequest.empty,
    // Soft-mandatory override: both are required together. A reason with no
    // permission is not an override, and a permission with no reason is an
    // unaudited one.
    bool canOverride = false,
    String? overrideReason,
    // The space's autonomy dial, composed AFTER policy exactly as the
    // harness gate composes it ([AutonomyComposition]): `proposeOnly` refuses
    // a gated action policy would allow or ask about; `actFreely` changes
    // nothing here, because it never overrides a policy `prompt`. [autonomyGated]
    // is false for an action the dial does not govern (a mode's pinned
    // output verbs).
    AutonomyLevel? autonomy,
    bool autonomyGated = true,
    // Completes when the caller stops waiting (a hook deadline, a run that
    // ended): carried onto the confirmation so the prompt is withdrawn.
    Future<void>? withdrawn,
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

    if (!operatorInitiated &&
        const AutonomyComposition().compose(
              decision: res.decision,
              autonomy: autonomy,
              isGated: autonomyGated,
            ) ==
            AutonomyOutcome.deny &&
        res.decision != ActionDecision.deny) {
      // Policy did not refuse; the space's dial did. Audited as the deny that
      // was applied, with the dial named so the operator can find it.
      audit(ActionDecision.deny);
      return GuardVerdict.deny(
        kProposeOnlyReason,
        source: res.driving.source,
        resolution: res,
      );
    }

    switch (res.decision) {
      case ActionDecision.allow:
        // Allows are recorded too: "which human authorized this agent action"
        // is unanswerable from a deny-only trail.
        audit(ActionDecision.allow);
        return GuardVerdict.allow(source: res.driving.source, resolution: res);
      case ActionDecision.prompt
          when res.driving.rule?.enforcement == EnforcementLevel.advisory:
        // ADVISORY: allow, but record that the rule matched. This is how a
        // strict rule gets adopted — roll it out advisory, read the audit
        // trail to see what it WOULD have blocked, then promote it.
        audit(ActionDecision.allow);
        return GuardVerdict.allow(source: res.driving.source, resolution: res);
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
          return GuardVerdict.allow(
            source: res.driving.source,
            resolution: res,
          );
        }
        audit(ActionDecision.deny);
        return GuardVerdict.deny(
          rule?.enforcement == EnforcementLevel.soft
              ? '${res.driving.reason} This rule may be overridden with a '
                    'recorded justification by someone holding the override '
                    'permission.'
              : res.driving.reason,
          source: res.driving.source,
          resolution: res,
        );
      case ActionDecision.prompt:
        if (operatorInitiated) {
          // The operator asked for this action directly; the request itself is
          // the approval. Audited as an allow so the trail still shows which
          // rule was in play and who satisfied it.
          audit(ActionDecision.allow);
          return GuardVerdict.allow(
            source: res.driving.source,
            resolution: res,
          );
        }
        final port = _confirm;
        if (port == null) {
          // Fail-closed: an action that must prompt but has no approver denies.
          audit(ActionDecision.deny);
          return GuardVerdict.deny(
            '${res.driving.reason} No approver is connected (fail-closed).',
            source: res.driving.source,
            resolution: res,
          );
        }
        final approved = await port.requestApproval(
          approvalRequest(
            resolution: res,
            spaceId: spaceId,
            conversationId: conversationId,
            actionSummary: actionSummary,
            workspaceId: workspaceId,
            agentId: agentId,
            request: request,
            classes: classes,
            command: command,
            rationale: approvalRationale,
            withdrawn: withdrawn,
          ),
        );
        audit(
          approved ? ActionDecision.allow : ActionDecision.deny,
          prompted: true,
        );
        return approved
            ? GuardVerdict.allow(
                source: res.driving.source,
                prompted: true,
                resolution: res,
              )
            : GuardVerdict.deny(
                'Denied at confirmation: ${res.driving.reason}',
                source: res.driving.source,
                prompted: true,
                resolution: res,
              );
    }
  }

  /// Asks [port] about [command], which a gate wants approved on its own (a
  /// mode's command net, an ACP agent's own permission request), unless a
  /// person's live standing approval covers exactly this command.
  ///
  /// Policy is read only for that approval: what the gate decided stands, so
  /// a policy deny does not refuse here and a plain allow does not spare the
  /// ask. Without [guard] or [workspaceId] nothing is consulted and the card
  /// offers no standing approval. A spared ask is audited as an allow.
  static Future<bool> confirmCommand({
    required ActionGuardService? guard,
    required ConfirmationPort port,
    required String? workspaceId,
    required Set<ActionClass> classes,
    required String command,
    String? spaceId,
    String? conversationId,
    String? agentId,
    Mode mode = Mode.chat,
    String actionSummary = '',
    String? onBehalfOfUserId,
    String? runId,
    String? detail,
    ConfirmationSeverity? severity,
    ConfirmationKind? kind,
    Future<void>? withdrawn,
  }) async {
    final request = ActionRequest(classes: classes, command: command);
    final ws = workspaceId;
    final resolution = guard == null || ws == null || ws.isEmpty
        ? null
        : await guard.resolve(
            workspaceId: ws,
            classes: classes,
            command: command,
            spaceId: spaceId,
            agentId: agentId,
            mode: mode,
            request: request,
          );
    if (resolution != null &&
        resolution.standingApprovalCovers(command: command)) {
      guard!.recordOutcome(
        workspaceId: ws!,
        resolution: resolution,
        applied: ActionDecision.allow,
        classes: classes,
        agentId: agentId,
        spaceId: spaceId,
        actionSummary: actionSummary,
        onBehalfOfUserId: onBehalfOfUserId,
        runId: runId,
        command: command,
      );
      return true;
    }
    return port.requestApproval(
      approvalRequest(
        resolution: resolution,
        classes: classes,
        askedByPolicy: false,
        request: request,
        spaceId: spaceId,
        conversationId: conversationId,
        workspaceId: workspaceId,
        agentId: agentId,
        actionSummary: actionSummary,
        detail: detail,
        severity: severity,
        kind: kind,
        withdrawn: withdrawn,
      ),
    );
  }

  /// Builds the confirmation a person is shown about an agent's action.
  ///
  /// Every gate that asks about something an agent is doing builds its
  /// request here, so every card offers "Approve for 8 hours" on the same
  /// terms and the answer writes a standing approval the same gate consults
  /// next time.
  ///
  /// [resolution] is the policy's answer for this call, resolved with the
  /// clock. Null means the gate could not consult policy, and nothing is
  /// offered. [askedByPolicy] is false for a gate that asks on its own after
  /// policy let the call through (an MCP tool's declared approval, a mode's
  /// command net, an ACP agent's own request): the approval then covers every
  /// declared class, since the person approved them together, and the gate
  /// skips its ask while [GuardVerdict.standingApprovalCovers] holds.
  ///
  /// A standing approval is never wider than what was approved: the classes
  /// that asked, narrowed by [_rememberConstraintFor]. A call with nothing to
  /// narrow it by offers none, except a commit ([standsWithoutConstraint]).
  /// A push alone is remembered by its branch, or by its exact command when
  /// it names no branch: the shell hook sees the command but not the host and
  /// the push gateway the refs but not the command, so a branch must match at
  /// both, and the gateway still asks about the real branch of a push
  /// approved by command.
  static ConfirmationRequest approvalRequest({
    required ActionResolution? resolution,
    required Set<ActionClass> classes,
    bool askedByPolicy = true,
    ActionRequest request = ActionRequest.empty,
    String? command,
    String? rationale,
    String? spaceId,
    String? conversationId,
    String actionSummary = '',
    String? workspaceId,
    String? agentId,
    String? title,
    String? detail,
    ConfirmationSeverity? severity,
    ConfirmationKind? kind,
    Future<void>? withdrawn,
  }) {
    final script = command ?? request.command;
    final copy = ActionApprovalCopy.describe(
      classes: classes,
      request: request,
      command: script,
      rationale: rationale,
    );
    final asked = switch (resolution) {
      null => const <ActionClass>[],
      ActionResolution(decision: ActionDecision.deny) => const <ActionClass>[],
      final ActionResolution res when askedByPolicy =>
        res.decision == ActionDecision.prompt
            ? [for (final r in res.prompting) ?r.actionClass]
            : const <ActionClass>[],
      _ => [
        for (final c in ActionClass.values)
          if (classes.contains(c)) c,
      ],
    };
    final mayRemember =
        asked.isNotEmpty &&
        (resolution!.rememberable ||
            (!askedByPolicy && resolution.decision == ActionDecision.allow));
    final wires = [for (final c in asked) c.wire];
    // A gate that asks on its own skips its ask only for an approval naming
    // its exact tool or command, so only the policy's own ask is remembered
    // for the class alone. And only when the call itself is a commit (its
    // request declares the class), not something that merely needs the
    // capability, like a skill install.
    final unconstrained =
        mayRemember &&
        askedByPolicy &&
        standsWithoutConstraint(wires) &&
        request.classes.contains(ActionClass.gitCommit);
    ActionConstraint? constraint;
    if (mayRemember && !unconstrained) {
      final trimmed = script?.trim();
      final pushOnly = asked.length == 1 && asked.single == ActionClass.gitPush;
      constraint = !pushOnly
          ? _rememberConstraintFor(request.withCommand(trimmed))
          : request.refs.isNotEmpty
          ? _rememberConstraintFor(ActionRequest(refs: request.refs))
          : trimmed != null && trimmed.isNotEmpty
          ? ActionConstraint(commands: [trimmed])
          : null;
      // Never "push anywhere": a push approval names a branch or a command.
      if (constraint != null &&
          asked.contains(ActionClass.gitPush) &&
          constraint.refs == null &&
          constraint.commands == null) {
        constraint = null;
      }
    }
    final drivingClass = askedByPolicy
        ? resolution?.driving.actionClass
        : asked.firstOrNull;
    return ConfirmationRequest(
      spaceId: spaceId ?? '',
      conversationId: conversationId,
      workspaceId: workspaceId,
      title: title ?? copy.title,
      detail: detail ?? copy.detail,
      command: script,
      severity: severity ?? _severityFor(drivingClass),
      kind: kind ?? _kindFor(drivingClass),
      rememberChoice: constraint != null || unconstrained
          ? RememberScope.workspace
          : null,
      // Identity stays tied to the attempted action, not to display wording.
      // Distinct scripts or targets cannot share a remembered answer.
      fingerprint: jsonEncode([
        'action',
        wires,
        actionSummary,
        script,
        request.refs,
        request.paths,
        request.hosts,
        request.tool,
        request.magnitude,
        request.micros,
      ]),
      actionClasses: wires,
      agentId: agentId,
      constraintJson: constraint?.encode(),
      withdrawn: withdrawn,
    );
  }

  /// The class a standing approval is filed under when the action declares
  /// no effect class: an external MCP server's tool, a request the classifier
  /// names nothing for. Policy for it is read only to find that approval; the
  /// gate that asks decides everything else.
  static const Set<ActionClass> undeclaredEffect = {ActionClass.processSpawn};

  /// Whether a standing approval of exactly these classes (wire names) may
  /// carry no constraint.
  ///
  /// Only a commit: it stays in the run's own worktree and has no branch,
  /// folder or host to narrow it by, and its command differs every time, so
  /// the approval covers commits at the scope it is written for. Every other
  /// approval names something narrower than its class. The card builder and
  /// `confirmation.respond` both ask here, so neither can widen the other.
  static bool standsWithoutConstraint(List<String> classWires) =>
      classWires.length == 1 && classWires.single == ActionClass.gitCommit.wire;

  /// Generalizes the approved call's arguments into the constraint a
  /// remembered rule should carry.
  ///
  /// A standing approval must be narrower than "yes to everything" and wider
  /// than "yes to this exact call" — approving one push to `feature/login`
  /// should not re-prompt on `feature/logout`, and must NOT cover `main`. So
  /// a ref is generalized to its first segment (`feature/**`), a path to its
  /// directory, and a host, a command and a tool are kept exactly. A request
  /// with none of them generalizes to null, and nothing is remembered: a rule
  /// with no constraint would cover the whole class.
  static ActionConstraint? _rememberConstraintFor(ActionRequest request) {
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
    final command = request.command?.trim();
    final tool = request.tool;
    final constraint = ActionConstraint(
      refs: generalizedRefs,
      paths: generalizedPaths,
      hosts: request.hosts.isEmpty
          ? null
          : (request.hosts.toSet().toList()..sort()),
      commands: command == null || command.isEmpty ? null : [command],
      tools: tool == null || tool.isEmpty ? null : [tool],
    );
    return constraint.isUnconstrained ? null : constraint;
  }

  static ConfirmationSeverity _severityFor(ActionClass? cls) {
    switch (cls) {
      case ActionClass.fileDelete:
      case ActionClass.gitPush:
      case ActionClass.prPublish:
        return ConfirmationSeverity.destructive;
      default:
        return ConfirmationSeverity.warning;
    }
  }

  static ConfirmationKind _kindFor(ActionClass? cls) {
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
