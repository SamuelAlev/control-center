import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/script_approval_budget.dart';
import 'package:cc_domain/features/guardrails/domain/entities/guard_decision.dart'
    show EnforcementLevel;
import 'package:cc_domain/features/guardrails/domain/services/action_guard_service.dart';
import 'package:cc_domain/features/guardrails/domain/services/autonomy_composition.dart';
import 'package:cc_domain/features/guardrails/domain/services/policy_resolver.dart';
import 'package:cc_domain/features/guardrails/domain/value_objects/action_decision.dart';
import 'package:cc_domain/features/guardrails/domain/value_objects/action_request.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/autonomy_level.dart';
import 'package:cc_harness/tools.dart' show ActionClass, PersonWaitListener;

/// Whether a guard check of [resolution] would ask a person: a `prompt`
/// decision whose driving rule is not advisory (an advisory rule allows),
/// and that the space's [autonomy] dial does not refuse first.
bool guardWouldAsk(ActionResolution resolution, {AutonomyLevel? autonomy}) =>
    resolution.decision == ActionDecision.prompt &&
    resolution.driving.rule?.enforcement != EnforcementLevel.advisory &&
    const AutonomyComposition().compose(
          decision: resolution.decision,
          autonomy: autonomy,
        ) !=
        AutonomyOutcome.deny;

/// [resolution] as the denial a script's spent approval budget applied: the
/// rule that would have asked stays named, and the reason is [refusal], the
/// budget's own. What the audit trail records for a call refused without
/// asking anyone, so the trail says why nobody was asked.
ActionResolution scriptApprovalDenial(
  ActionResolution resolution,
  String refusal,
) {
  final driving = resolution.driving;
  return ActionResolution(
    decision: ActionDecision.deny,
    driving: PolicyResolution(
      decision: ActionDecision.deny,
      source: driving.source,
      reason: refusal,
      rule: driving.rule,
      actionClass: driving.actionClass,
    ),
    prompting: resolution.prompting,
  );
}

/// Counts one ask against every budget in [approvals], or says why none may
/// be made: the first held budget's [ScriptApprovalBudget.refusal]. The check
/// and the count are one synchronous step, so calls that would ask a person
/// and arrive together cannot all pass a check none of them has counted
/// against yet. A gate calls it before it awaits the card, and gives the ask
/// back ([ScriptApprovalBudget.release]) when no card went up.
String? reserveScriptAsk(Iterable<ScriptApprovalBudget> approvals) {
  final refusal = approvals.map((a) => a.refusal).nonNulls.firstOrNull;
  if (refusal == null) {
    for (final budget in approvals) {
      budget.asking();
    }
  }
  return refusal;
}

/// Runs one guard [check] that may ask a person while scripts of the run are
/// in flight, holding the ask to every one of their [approvals].
///
/// With no budget held, [check] runs as it would without code mode.
/// Otherwise the call is resolved first: one that would ask a person
/// ([guardWouldAsk]) counts its ask against every held budget before the
/// check runs ([reserveScriptAsk]), or, when a held budget refuses, is
/// denied without asking and audited as that denial with the budget's
/// reason ([scriptApprovalDenial]). When the check then raises no card (a
/// standing approval or an earlier answer covered the call), the ask is
/// given back; a card the resolution did not foresee (the policy changed in
/// between) is reserved the same way just before it goes up
/// ([ActionGuardService.check]'s `beforeCard`), or refused without a card
/// when a held budget refuses. A card's answer is recorded on each
/// budget (`answered`); a card that came down with nobody's answer (the
/// verdict says so, [GuardVerdict.unanswered], or [unanswered] does, for a
/// deadline of the caller's own) is recorded as no decision. Charging every
/// script in flight never counts an ask against fewer scripts than caused it:
/// which command a request comes from is not something a sandboxed process
/// can be trusted to say. So a decline of a card raised while two scripts
/// of the run are in flight refuses the later asks of both.
///
/// [onPersonWait] still hears every ask, as it would from [check] directly.
/// [onDecided] hears what stopped the request or what a person decided for
/// it: `false` for any denial (a person declined, a budget refused it, the
/// policy denied it, a card nobody answered in time), `true` when a person
/// approved a card for it; nothing for a request allowed without a card. The
/// gateway hands it to the command the request names, so that command's
/// tool call is recorded with the decision.
///
/// [executed] is what the call runs, as [check] is handed it
/// ([ActionGuardService.check]'s `executed`): a denial recorded here names
/// and digests it the same way, and policy never sees it.
Future<GuardVerdict> checkWithinScriptApprovals({
  required ActionGuardService guard,
  required List<ScriptApprovalBudget> approvals,
  required String workspaceId,
  required Set<ActionClass> classes,
  required ActionRequest request,
  required String actionSummary,
  required Future<GuardVerdict> Function(
    PersonWaitListener? onPersonWait,
    String? Function()? beforeCard,
  )
  check,
  String? command,
  String? executed,
  String? spaceId,
  String? agentId,
  Mode mode = Mode.chat,
  AutonomyLevel? autonomy,
  String? onBehalfOfUserId,
  String? runId,
  PersonWaitListener? onPersonWait,
  bool Function(GuardVerdict verdict)? unanswered,
  void Function(bool approved)? onDecided,
}) async {
  if (approvals.isEmpty) {
    var raised = false;
    final verdict = await check(
      onDecided == null
          ? onPersonWait
          : (waiting) {
              raised |= waiting;
              onPersonWait?.call(waiting);
            },
      null,
    );
    if (!verdict.allowed) {
      onDecided?.call(false);
    } else if (raised) {
      onDecided?.call(true);
    }
    return verdict;
  }
  final resolution = await guard.resolve(
    workspaceId: workspaceId,
    classes: classes,
    command: command,
    spaceId: spaceId,
    agentId: agentId,
    mode: mode,
    request: request,
  );
  var reserved = false;
  if (guardWouldAsk(resolution, autonomy: autonomy)) {
    final refusal = reserveScriptAsk(approvals);
    if (refusal != null) {
      guard.recordOutcome(
        workspaceId: workspaceId,
        resolution: scriptApprovalDenial(resolution, refusal),
        applied: ActionDecision.deny,
        classes: classes,
        agentId: agentId,
        spaceId: spaceId,
        actionSummary: ActionGuardService.toolActionSummary(
          actionSummary,
          executed,
        ),
        onBehalfOfUserId: onBehalfOfUserId,
        runId: runId,
        command: executed ?? command,
      );
      onDecided?.call(false);
      return GuardVerdict.deny(
        refusal,
        source: resolution.driving.source,
        resolution: resolution,
      );
    }
    reserved = true;
  }
  var asked = false;
  final GuardVerdict verdict;
  try {
    verdict = await check(
      (waiting) {
        if (waiting && !asked) {
          asked = true;
          // A check that raised a card without asking `beforeCard` first:
          // the card is up, so it counts.
          if (!reserved) {
            for (final budget in approvals) {
              budget.asking();
            }
          }
        }
        onPersonWait?.call(waiting);
      },
      // A card the resolution did not foresee (the policy changed in
      // between) takes the same step as a foreseen one, just before it
      // would go up: counted, or refused without a card.
      () {
        if (reserved) {
          return null;
        }
        final refusal = reserveScriptAsk(approvals);
        reserved = refusal == null;
        return refusal;
      },
    );
  } finally {
    if (reserved && !asked) {
      for (final budget in approvals) {
        budget.release();
      }
    }
  }
  if (asked) {
    final nobody = verdict.unanswered || (unanswered?.call(verdict) ?? false);
    for (final budget in approvals) {
      budget.answered(approved: verdict.allowed, unanswered: nobody);
    }
  }
  if (!verdict.allowed) {
    onDecided?.call(false);
  } else if (asked) {
    onDecided?.call(true);
  }
  return verdict;
}
