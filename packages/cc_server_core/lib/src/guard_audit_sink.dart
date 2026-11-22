import 'dart:async';

import 'package:cc_domain/features/code_mode/domain/services/utf8_bounds.dart';
import 'package:cc_domain/features/evals/domain/value_objects/agent_config_hash.dart'
    show canonicalHash;
import 'package:cc_domain/features/guardrails/domain/entities/guard_decision.dart';
import 'package:cc_domain/features/guardrails/domain/repositories/guard_decision_repository.dart';
import 'package:cc_domain/features/guardrails/domain/services/action_guard_service.dart';
import 'package:cc_domain/features/guardrails/domain/value_objects/action_decision.dart';
import 'package:cc_host/cc_host.dart';
import 'package:cc_server_core/src/agent_action_blocked_publisher.dart';
import 'package:uuid/uuid.dart';

/// Where every verdict of the action guard goes: one row in the workspace's
/// hash-chained audit, a copy to the operator's SIEM when one is configured,
/// a server log line for a denial and, for a refusal nobody was asked about,
/// a blocked-action event for clients.
///
/// Every row it builds is bounded here, whichever tool asked: the action's
/// summary (a `bash` command in full, for instance) is stored whole up to
/// [GuardDecision.maxActionNameBytes] and cut with its full length past that
/// ([GuardDecision.boundActionName]). The log line and the event carry at
/// most [kMaxShownActionSummaryBytes] of it.
class GuardAuditSink {
  /// Creates a sink appending to the workspaces' audit chains.
  GuardAuditSink({
    required this._decisions,
    required this._blocked,
    this._siem,
  });

  final GuardDecisionRepository _decisions;
  final AgentActionBlockedPublisher _blocked;
  final void Function(GuardDecision decision)? _siem;

  /// Records [a].
  void record(GuardAudit a) {
    if (a.decision == ActionDecision.deny) {
      CcHostLog.info(
        'guardrail deny [${a.source}] '
        '${boundUtf8(a.actionSummary, kMaxShownActionSummaryBytes)}: '
        '${a.reason}',
      );
    }
    _blocked.report(a);
    final command = a.command;
    final decision = GuardDecision(
      id: const Uuid().v4(),
      workspaceId: a.workspaceId,
      occurredAt: DateTime.now(),
      // The guard's callers are agents; the repo-op dispatcher records its
      // own human-lane rows with actorType 'user'.
      actorType: a.agentId == null ? 'system' : 'agent',
      actorId: a.agentId ?? 'server',
      onBehalfOfUserId: a.onBehalfOfUserId,
      spaceId: a.spaceId,
      runId: a.runId,
      surface: GuardSurface.harness,
      actionName: GuardDecision.boundActionName(
        a.actionSummary.isEmpty ? (command ?? 'action') : a.actionSummary,
        digested: command != null,
      ),
      actionClasses: a.actionClasses,
      decision: a.decision,
      sourceScope: a.source,
      ruleId: a.ruleId,
      prompted: a.prompted,
      unanswered: a.unanswered,
      argsDigest: command == null ? null : canonicalHash({'command': command}),
    );
    // Fire-and-forget: this runs on the hot path of every gated tool call,
    // so a slow append must never delay the agent, and a failed append is
    // logged, never raised into the caller's verdict.
    unawaited(
      _decisions
          .append(decision)
          .catchError(
            (Object error) =>
                CcHostLog.warning('guard audit append failed: $error'),
          ),
    );
    // A COPY to the operator's SIEM. Never gates the decision: the durable,
    // verifiable record is the local chain.
    _siem?.call(decision);
  }
}
