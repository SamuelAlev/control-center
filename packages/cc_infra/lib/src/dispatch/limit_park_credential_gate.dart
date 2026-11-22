import 'package:cc_domain/core/domain/ports/run_credential_gate_port.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_infra/src/dispatch/limit_park_service.dart';

/// The credential gate with the durable record of a park at a provider's
/// usage limit: a run already recorded (the built-in harness, whose pool
/// refuses it mid-dispatch) that waits for a plan's reset gets the
/// `limitReset` wake a restart keeps ([LimitParkService.credentialParked]),
/// and does not go on when the wake queue resumed it first (the outcome is
/// then [RunCredentialOutcome.cancelled]).
///
/// A request with no recorded run (the Claude Code park before a run row
/// exists) passes straight through: `AgentDispatchService` writes that
/// record itself, from what only it knows (the requester, the wakes).
class LimitParkCredentialGate implements RunCredentialGatePort {
  /// Wraps the inner gate. The parks are read per park (null before the wake queue is
  /// built: the park stays in memory only).
  LimitParkCredentialGate(
    this._inner, {
    required this._parks,
    required this._runLogs,
  });

  final RunCredentialGatePort _inner;
  final LimitParkService? Function() _parks;
  final AgentRunLogRepository _runLogs;

  @override
  Future<RunCredentialOutcome> awaitCredentials(
    RunCredentialBlockRequest request, {
    required Future<bool> Function() recheck,
  }) async {
    final ticket = await _park(request);
    final outcome = await _inner.awaitCredentials(request, recheck: recheck);
    if (ticket == null) {
      return outcome;
    }
    final resolved = outcome == RunCredentialOutcome.resolved;
    final goOn = await ticket.parks.credentialParkEnded(
      ticket.ticket,
      outcome: outcome,
    );
    return resolved && !goOn ? RunCredentialOutcome.cancelled : outcome;
  }

  Future<({LimitParkService parks, LimitParkTicket ticket})?> _park(
    RunCredentialBlockRequest request,
  ) async {
    final parks = _parks();
    final workspaceId = request.workspaceId;
    final runId = request.runLogId;
    if (parks == null ||
        request.reason != RunCredentialReason.planSpent ||
        request.availableAt == null ||
        workspaceId == null ||
        workspaceId.isEmpty ||
        runId == null ||
        runId.isEmpty) {
      return null;
    }
    final log = await _runLogs.getById(workspaceId, runId);
    if (log == null || !log.isActive) {
      return null;
    }
    final ticket = await parks.credentialParked(
      LimitParkRun(
        workspaceId: workspaceId,
        spaceId: log.spaceId,
        conversationId: log.conversationId,
        agentId: log.agentId,
        runId: runId,
        requestedByUserId: log.requestedByUserId,
        wakeReason: log.wakeReason,
        wakeIds: log.wakeIds,
        adapter: log.adapter,
        modelId: log.modelId,
      ),
      resetsAt: request.availableAt,
    );
    return ticket == null ? null : (parks: parks, ticket: ticket);
  }
}
