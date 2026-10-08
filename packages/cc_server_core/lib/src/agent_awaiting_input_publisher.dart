import 'dart:async';

import 'package:cc_domain/core/domain/events/agent_events.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/ports/agent_question_port.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_host/cc_host.dart';

/// Publishes [AgentAwaitingInput] whenever an agent stops to wait on a human.
///
/// Three things park an agent on a person, and each keeps its own state: the
/// approvals registry (every gated action, including the sandbox exec grant
/// and Claude Code's tool hook), the credential-block registry (a run held on
/// a credential that cannot serve it) and the question service (`ask_user`).
/// The registries are watched for entries not seen before; the question
/// service reports each question through [questionAsked]. Either way, one wait
/// is one event — which the notification wire turns into one toast and one
/// bell row.
class AgentAwaitingInputPublisher {
  /// Creates a publisher onto the event bus. The agent repository names the
  /// waiting agent when the wait itself does not.
  AgentAwaitingInputPublisher({
    required this._eventBus,
    required this._agents,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final DomainEventBus _eventBus;
  final AgentRepository _agents;
  final DateTime Function() _clock;

  final List<StreamSubscription<Object?>> _subs = [];
  final Set<String> _seenApprovals = {};
  final Set<String> _seenCredentialBlocks = {};

  /// Starts watching [confirmations] and, when the credential gate is on,
  /// [credentialBlocks].
  void watch({
    required PendingConfirmationRegistry confirmations,
    PendingCredentialBlockRegistry? credentialBlocks,
  }) {
    _subs.add(confirmations.pending.listen(_onApprovals));
    if (credentialBlocks != null) {
      _subs.add(credentialBlocks.blocked.listen(_onCredentialBlocks));
    }
  }

  /// Reports a question an agent just posted.
  void questionAsked(AgentQuestionRequest request) {
    _publish(
      workspaceId: request.workspaceId,
      kind: AgentInputKind.question,
      summary: request.question,
      spaceId: request.spaceId,
      agentId: request.askedByAgentId,
      agentName: request.askedByName,
    );
  }

  void _onApprovals(List<PendingConfirmation> pending) {
    final current = <String>{};
    for (final entry in pending) {
      current.add(entry.id);
      if (_seenApprovals.contains(entry.id)) {
        continue;
      }
      final request = entry.request;
      final workspaceId = request.workspaceId;
      if (workspaceId == null || workspaceId.isEmpty) {
        // Single-user hosts without identity wiring: no workspace to file the
        // notification under, and the approval card is the only surface.
        continue;
      }
      _publish(
        workspaceId: workspaceId,
        kind: AgentInputKind.approval,
        summary: request.title,
        spaceId: request.spaceId,
        agentId: request.agentId,
      );
    }
    // Forget resolved entries so the set stays the size of what is pending.
    _seenApprovals
      ..clear()
      ..addAll(current);
  }

  void _onCredentialBlocks(List<PendingCredentialBlock> blocked) {
    final current = <String>{};
    for (final entry in blocked) {
      current.add(entry.id);
      if (_seenCredentialBlocks.contains(entry.id)) {
        continue;
      }
      final request = entry.request;
      final workspaceId = request.workspaceId;
      if (workspaceId == null || workspaceId.isEmpty) {
        continue;
      }
      _publish(
        workspaceId: workspaceId,
        kind: AgentInputKind.credential,
        summary: request.detail,
        spaceId: request.spaceId,
        conversationId: request.conversationId,
        agentId: request.agentId,
        agentName: request.agentName,
      );
    }
    _seenCredentialBlocks
      ..clear()
      ..addAll(current);
  }

  void _publish({
    required String workspaceId,
    required AgentInputKind kind,
    required String summary,
    String? spaceId,
    String? conversationId,
    String? agentId,
    String? agentName,
  }) {
    final occurredAt = _clock().toUtc();
    unawaited(() async {
      final name = agentName ?? await _nameOf(workspaceId, agentId);
      try {
        _eventBus.publish(
          AgentAwaitingInput(
            workspaceId: workspaceId,
            kind: kind,
            summary: summary,
            spaceId: (spaceId == null || spaceId.isEmpty) ? null : spaceId,
            conversationId: conversationId,
            agentId: agentId,
            agentName: name,
            occurredAt: occurredAt,
          ),
        );
      } on StateError {
        // The bus closed while the name was resolving (server shutdown).
      }
    }());
  }

  Future<String?> _nameOf(String workspaceId, String? agentId) async {
    if (agentId == null || agentId.isEmpty) {
      return null;
    }
    try {
      return (await _agents.getById(workspaceId, agentId))?.name;
    } catch (_) {
      // A name is a nicety; the notification goes out without it.
      return null;
    }
  }

  /// Stops watching.
  Future<void> dispose() async {
    await Future.wait(_subs.map((s) => s.cancel()));
    _subs.clear();
  }
}
