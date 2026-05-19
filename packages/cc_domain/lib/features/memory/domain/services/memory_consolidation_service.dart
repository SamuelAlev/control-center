import 'package:cc_domain/core/domain/entities/working_memory_item.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/memory_events.dart';
import 'package:cc_domain/features/memory/domain/repositories/working_memory_item_repository.dart';
import 'package:cc_domain/features/memory/domain/usecases/record_memory_fact_use_case.dart';

/// Two-tier consolidation: the `sleep()` job that rolls the hot working-memory
/// tier into durable episodic facts, ported from oh-my-pi mnemopi
/// `core/beam/store.ts` (`trimWorkingMemory` + consolidation pass).
class MemoryConsolidationService {
  /// Creates a [MemoryConsolidationService].
  const MemoryConsolidationService({
    required WorkingMemoryItemRepository workingMemory,
    required RecordMemoryFactUseCase recordFact,
    DomainEventBus? eventBus,
    this.maxItemsPerAgent = 50,
  })  : _working = workingMemory,
        _recordFact = recordFact,
        _eventBus = eventBus;

  final WorkingMemoryItemRepository _working;
  final RecordMemoryFactUseCase _recordFact;
  final DomainEventBus? _eventBus;

  /// Count-based eviction cap per agent (after TTL eviction).
  final int maxItemsPerAgent;

  /// The memory domain consolidated working items land in.
  static const String consolidatedDomain = 'working-memory';

  /// Runs a consolidation pass. When [agentId] is given, only that agent's hot
  /// tier is consolidated; otherwise the whole workspace is. Returns the audit
  /// report (also persisted).
  Future<ConsolidationPassReport> sleep({
    required String workspaceId,
    String? agentId,
    DateTime? now,
  }) async {
    final startedAt = now ?? DateTime.now();

    // 1. TTL eviction.
    final ttlEvicted = await _working.deleteExpired(workspaceId, startedAt);

    // 2. Load surviving items.
    final items = agentId != null
        ? await _working.getForAgent(workspaceId, agentId)
        : await _working.getForWorkspace(workspaceId);

    // 3. Count-based eviction (oldest-first beyond the per-agent cap).
    var countEvicted = 0;
    final byAgent = <String, List<WorkingMemoryItem>>{};
    for (final item in items) {
      byAgent.putIfAbsent(item.agentId, () => <WorkingMemoryItem>[]).add(item);
    }
    final keep = <WorkingMemoryItem>[];
    final overflowIds = <String>[];
    for (final agentItems in byAgent.values) {
      // items arrive newest-first; keep the newest [maxItemsPerAgent].
      for (var i = 0; i < agentItems.length; i++) {
        if (i < maxItemsPerAgent) {
          keep.add(agentItems[i]);
        } else {
          overflowIds.add(agentItems[i].id);
        }
      }
    }
    if (overflowIds.isNotEmpty) {
      await _working.deleteByIds(workspaceId, overflowIds);
      countEvicted = overflowIds.length;
    }

    // 4. Consolidate the consolidatable survivors into durable facts.
    var created = 0;
    var updated = 0;
    var conflicts = 0;
    final consolidatedIds = <String>[];
    for (final item in keep) {
      if (!item.memoryType.consolidatable) {
        continue;
      }
      final result = await _recordFact.record(
        workspaceId: workspaceId,
        domain: consolidatedDomain,
        topic: item.sessionId ?? 'agent ${_short(item.agentId)}',
        content: item.content,
        confidence: item.importance.clamp(0.0, 1.0),
        authoredByAgentId: item.agentId,
        memoryType: item.memoryType,
        veracity: item.veracity,
      );
      if (result == null) {
        continue;
      }
      consolidatedIds.add(item.id);
      conflicts += result.conflictsDetected;
      switch (result.outcome) {
        case RecordOutcome.created:
        case RecordOutcome.supersededByConflict:
          created++;
        case RecordOutcome.deduplicated:
          updated++;
      }
    }
    if (consolidatedIds.isNotEmpty) {
      await _working.deleteByIds(workspaceId, consolidatedIds);
    }

    final report = ConsolidationPassReport(
      workspaceId: workspaceId,
      agentId: agentId,
      itemsConsidered: items.length,
      factsCreated: created,
      factsUpdated: updated,
      conflictsDetected: conflicts,
      evicted: ttlEvicted + countEvicted,
      startedAt: startedAt,
      finishedAt: DateTime.now(),
    );
    await _working.recordConsolidationPass(report);
    _eventBus?.publish(
      MemoryConsolidated(
        workspaceId: workspaceId,
        factsCreated: created,
        factsUpdated: updated,
        occurredAt: DateTime.now(),
      ),
    );
    return report;
  }

  static String _short(String s) => s.length <= 8 ? s : s.substring(0, 8);
}