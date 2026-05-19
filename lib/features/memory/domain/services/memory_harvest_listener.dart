import 'dart:async';

import 'package:control_center/core/domain/events/domain_event_bus.dart';
import 'package:control_center/core/domain/events/ticketing_events.dart';
import 'package:control_center/core/utils/app_log.dart';
import 'package:control_center/features/memory/domain/usecases/record_memory_fact_use_case.dart';
import 'package:control_center/features/memory/domain/value_objects/system_memory_domains.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket.dart';
import 'package:control_center/features/ticketing/domain/repositories/ticket_repository.dart';

/// Deterministically harvests schema-validated ticket outputs into workspace
/// memory when a ticket completes, so knowledge produced by one agent (a
/// decision, an outcome) is findable by any agent later — memory spanning
/// features. No LLM in the loop; best-effort (never blocks the ticket).
///
/// Only harvests tickets that declare an `expectedOutputSchema` (so the output
/// is structured, per the determinism backbone). Convention for the output
/// payload:
///   * `summary` (string)        → one fact in `ticket-outcomes`
///   * `decisions` (string list) → facts in `decisions`
///   * `facts` (objects of domain/topic/content/confidence) → verbatim
class MemoryHarvestListener {
  /// Creates a [MemoryHarvestListener].
  MemoryHarvestListener({
    required DomainEventBus eventBus,
    required TicketRepository ticketRepository,
    required RecordMemoryFactUseCase recordFact,
  })  : _eventBus = eventBus,
        _tickets = ticketRepository,
        _recordFact = recordFact;

  final DomainEventBus _eventBus;
  final TicketRepository _tickets;
  final RecordMemoryFactUseCase _recordFact;

  StreamSubscription<TicketStatusChanged>? _sub;

  /// Starts listening.
  void start() {
    _sub = _eventBus.on<TicketStatusChanged>().listen(_onStatusChanged);
  }

  /// Stops listening.
  void dispose() {
    _sub?.cancel();
  }

  Future<void> _onStatusChanged(TicketStatusChanged event) async {
    if (event.to != 'done') {
      return;
    }
    final workspaceId = event.workspaceId;
    try {
      final ticket = await _tickets.getById(event.ticketId);
      if (ticket == null ||
          ticket.workspaceId != workspaceId ||
          ticket.expectedOutputSchema == null ||
          ticket.outputJson == null) {
        return;
      }
      await _harvest(workspaceId, ticket, ticket.outputJson!);
    } on Object catch (e, st) {
      // Best-effort: a memory failure must never affect ticket completion.
      AppLog.w('MemoryHarvestListener', 'harvest failed: $e\n$st');
    }
  }

  Future<void> _harvest(
    String workspaceId,
    Ticket ticket,
    Map<String, dynamic> output,
  ) async {
    final topicSuffix = '${ticket.title} (ticket ${_short(ticket.id)})';

    final summary = output['summary'];
    if (summary is String && summary.trim().isNotEmpty) {
      await _recordFact.record(
        workspaceId: workspaceId,
        domain: SystemMemoryDomains.ticketOutcomes,
        topic: topicSuffix,
        content: summary,
        authoredByAgentId: ticket.assignedAgentId,
      );
    }

    final decisions = output['decisions'];
    if (decisions is List) {
      final live = <String>{};
      for (final d in decisions) {
        if (d is String && d.trim().isNotEmpty) {
          live.add(d.trim());
          await _recordFact.record(
            workspaceId: workspaceId,
            domain: SystemMemoryDomains.decisions,
            topic: topicSuffix,
            content: d,
            authoredByAgentId: ticket.assignedAgentId,
          );
        }
      }
      await _recordFact.reconcileTopic(
        workspaceId: workspaceId,
        topic: topicSuffix,
        liveContents: live,
      );
    }

    final facts = output['facts'];
    if (facts is List) {
      for (final f in facts) {
        if (f is! Map) {
          continue;
        }
        final domain = f['domain'];
        final topic = f['topic'];
        final content = f['content'];
        if (domain is String && topic is String && content is String) {
          await _recordFact.record(
            workspaceId: workspaceId,
            domain: domain,
            topic: topic,
            content: content,
            confidence: (f['confidence'] as num?)?.toDouble() ?? 1.0,
            authoredByAgentId: ticket.assignedAgentId,
          );
        }
      }
    }
  }

  static String _short(String s) => s.length <= 8 ? s : s.substring(0, 8);
}
