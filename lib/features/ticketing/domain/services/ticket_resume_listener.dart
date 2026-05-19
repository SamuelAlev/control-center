import 'dart:async';

import 'package:control_center/core/domain/events/domain_event_bus.dart';
import 'package:control_center/core/domain/events/ticketing_events.dart';
import 'package:control_center/core/utils/app_log.dart';
import 'package:control_center/features/pipelines/domain/services/pipeline_engine.dart';
import 'package:control_center/features/ticketing/domain/repositories/ticket_repository.dart';

/// Listens for [TicketCompleted] and [TicketFailed] events. When the tickets
/// belonging to a suspended pipeline step have ALL reached terminal state,
/// resumes that step via [PipelineEngine.resumeStep].
///
/// Replaces the old `TaskResumeListener` verbatim — the match is still by
/// `(pipelineRunId, pipelineStepId)` and the engine harvests `outputJson` off
/// the sibling tickets exactly as it did tasks.
class TicketResumeListener {
  /// Creates a [TicketResumeListener].
  TicketResumeListener({
    required this.eventBus,
    required this.ticketRepository,
    required this.engine,
  });

  /// Event bus we subscribe to.
  final DomainEventBus eventBus;

  /// Read access to tickets.
  final TicketRepository ticketRepository;

  /// Engine to resume.
  final PipelineEngine engine;

  StreamSubscription<DomainEvent>? _sub;

  /// Start listening for ticket events.
  void start() {
    _sub = eventBus.on<DomainEvent>().listen(_onEvent);
  }

  /// Stop listening.
  void dispose() {
    _sub?.cancel();
  }

  Future<void> _onEvent(DomainEvent event) async {
    final ticketId = switch (event) {
      TicketCompleted() => event.ticketId,
      TicketFailed() => event.ticketId,
      _ => null,
    };
    if (ticketId == null) return;

    final ticket = await ticketRepository.getById(ticketId);
    if (ticket == null ||
        ticket.pipelineRunId == null ||
        ticket.pipelineStepId == null) {
      return;
    }

    final siblings = await ticketRepository.forPipelineStep(
      ticket.workspaceId,
      ticket.pipelineRunId!,
      ticket.pipelineStepId!,
    );
    if (siblings.isEmpty) return;
    if (!siblings.every((t) => t.isTerminal)) return;

    try {
      await engine.resumeStep(
        pipelineRunId: ticket.pipelineRunId!,
        stepId: ticket.pipelineStepId!,
      );
    } on Object catch (e, st) {
      AppLog.e('TicketResumeListener', 'Failed to resume step', e, st);
    }
  }
}
