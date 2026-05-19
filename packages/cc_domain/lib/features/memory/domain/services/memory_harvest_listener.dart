import 'dart:async';

import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/events/agent_events.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/core/logging/cc_domain_log.dart';
import 'package:cc_domain/features/memory/domain/usecases/extract_memory_use_case.dart';
import 'package:cc_domain/features/memory/domain/usecases/record_memory_fact_use_case.dart';
import 'package:cc_domain/features/memory/domain/value_objects/system_memory_domains.dart';

/// Deterministically harvests schema-validated agent-run outputs into workspace
/// memory when a pipeline-dispatched run completes, so knowledge produced by
/// one agent (a decision, an outcome) is findable by any agent later — memory
/// spanning features. No LLM in the loop; best-effort (never blocks the run).
///
/// Only harvests runs that declare an `expectedOutputSchema` (so the output is
/// structured, per the determinism backbone) and actually produced `outputJson`.
/// Convention for the output payload:
///   * `summary` (string)        → one fact in `ticket-outcomes`
///   * `decisions` (string list) → facts in `decisions`
///   * `facts` (objects of domain/topic/content/confidence) → verbatim
class MemoryHarvestListener {
  /// Creates a [MemoryHarvestListener].
  ///
  /// When [extractMemory] is supplied, the run's free-text `summary` is also
  /// passed through passive fact extraction so facts surface without an explicit
  /// `propose_fact` call.
  MemoryHarvestListener({
    required DomainEventBus eventBus,
    required AgentRunLogRepository runLogRepository,
    required RecordMemoryFactUseCase recordFact,
    ExtractMemoryUseCase? extractMemory,
  })  : _eventBus = eventBus,
        _runLogs = runLogRepository,
        _recordFact = recordFact,
        _extractMemory = extractMemory;

  final DomainEventBus _eventBus;
  final AgentRunLogRepository _runLogs;
  final RecordMemoryFactUseCase _recordFact;
  final ExtractMemoryUseCase? _extractMemory;

  StreamSubscription<AgentRunCompleted>? _sub;

  /// Starts listening.
  void start() {
    _sub = _eventBus.on<AgentRunCompleted>().listen(_onCompleted);
  }

  /// Stops listening.
  void dispose() {
    _sub?.cancel();
  }

  Future<void> _onCompleted(AgentRunCompleted event) async {
    final runId = event.runId;
    final workspaceId = event.workspaceId;
    if (runId == null || workspaceId == null) {
      return;
    }
    try {
      final run = await _runLogs.getById(runId);
      if (run == null ||
          run.workspaceId != workspaceId ||
          run.expectedOutputSchema == null ||
          run.outputJson == null) {
        return;
      }
      await _harvest(workspaceId, run, run.outputJson!);
    } on Object catch (e, st) {
      // Best-effort: a memory failure must never affect the run.
      CcDomainLog.warning('MemoryHarvestListener: harvest failed: $e\n$st');
    }
  }

  Future<void> _harvest(
    String workspaceId,
    AgentRunLog run,
    Map<String, dynamic> output,
  ) async {
    final topicSuffix = 'run ${_short(run.id)}';

    final summary = output['summary'];
    if (summary is String && summary.trim().isNotEmpty) {
      await _recordFact.record(
        workspaceId: workspaceId,
        domain: SystemMemoryDomains.ticketOutcomes,
        topic: topicSuffix,
        content: summary,
        authoredByAgentId: run.agentId,
      );
      // Passive extraction: mine the free-text summary for additional facts /
      // preferences / instructions the agent stated without an explicit
      // propose_fact call.
      await _extractMemory?.extractAndRecord(
        workspaceId: workspaceId,
        text: summary,
        authoredByAgentId: run.agentId,
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
            authoredByAgentId: run.agentId,
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
            authoredByAgentId: run.agentId,
          );
        }
      }
    }
  }

  static String _short(String s) => s.length <= 8 ? s : s.substring(0, 8);
}
