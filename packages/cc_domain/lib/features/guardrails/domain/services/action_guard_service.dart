import 'package:cc_domain/core/domain/ports/confirmation_port.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/features/guardrails/domain/repositories/action_policy_repository.dart';
import 'package:cc_domain/features/guardrails/domain/services/policy_resolver.dart';
import 'package:cc_domain/features/guardrails/domain/value_objects/action_decision.dart';
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

  /// The provenance of the decision (channel/agent/workspace/preset/default).
  final String? source;

  /// Whether this verdict surfaced a confirmation prompt to the operator. Lets
  /// a downstream capability-tier gate avoid a DOUBLE confirmation for the same
  /// tool call (PRD 24 — the guard owns the declared classes and already asked).
  final bool prompted;
}

/// A record of a guard decision for the audit trail (PRD 24 §5).
class GuardAudit {
  /// Creates a [GuardAudit].
  const GuardAudit({
    required this.workspaceId,
    required this.decision,
    required this.reason,
    required this.source,
    this.agentId,
    this.channelId,
    this.actionSummary = '',
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

  /// Channel context.
  final String? channelId;

  /// A short description of the action (tool/op name + classes).
  final String actionSummary;
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
  }) : _repo = repository,
       _confirm = confirmationPort,
       _resolver = resolver,
       _onAudit = onAudit;

  final ActionPolicyRepository _repo;
  final ConfirmationPort? _confirm;
  final PolicyResolver _resolver;
  final void Function(GuardAudit audit)? _onAudit;

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
    String? channelId,
    String? agentId,
    Mode mode = Mode.chat,
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
      channelId: channelId,
      agentId: agentId,
      mode: mode,
    );
  }

  /// Checks an action declaring [classes] (and optionally a shell [command]).
  Future<GuardVerdict> check({
    required String workspaceId,
    required Set<ActionClass> classes,
    String? command,
    String? channelId,
    String? agentId,
    Mode mode = Mode.chat,
    String actionSummary = '',
  }) async {
    if (classes.isEmpty && (command == null || command.isEmpty)) {
      return const GuardVerdict.allow();
    }
    final rules = await _repo.rules(workspaceId);
    final res = _resolver.resolveAction(
      classes,
      rules: rules,
      command: command,
      channelId: channelId,
      agentId: agentId,
      mode: mode,
    );

    void audit(ActionDecision decision) {
      _onAudit?.call(
        GuardAudit(
          workspaceId: workspaceId,
          decision: decision,
          reason: res.driving.reason,
          source: res.driving.source,
          agentId: agentId,
          channelId: channelId,
          actionSummary: actionSummary,
        ),
      );
    }

    switch (res.decision) {
      case ActionDecision.allow:
        return GuardVerdict.allow(source: res.driving.source);
      case ActionDecision.deny:
        audit(ActionDecision.deny);
        return GuardVerdict.deny(
          res.driving.reason,
          source: res.driving.source,
        );
      case ActionDecision.prompt:
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
            channelId: channelId,
            actionSummary: actionSummary,
            workspaceId: workspaceId,
          ),
        );
        audit(approved ? ActionDecision.allow : ActionDecision.deny);
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
    String? channelId,
    String actionSummary = '',
    String? workspaceId,
  }) {
    final classes = res.prompting
        .map((r) => r.actionClass?.wire)
        .whereType<String>()
        .toList();
    final drivingClass = res.driving.actionClass;
    return ConfirmationRequest(
      conversationId: channelId ?? '',
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
    );
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
