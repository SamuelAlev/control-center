import 'package:cc_domain/features/memory/domain/repositories/agent_working_memory_repository.dart';
import 'package:cc_domain/features/memory/domain/repositories/memory_fact_repository.dart';

/// Cleans up stale memory entries (TTL / archiving).
class MemoryCleanupUseCase {
  /// Creates a [MemoryCleanupUseCase].
  MemoryCleanupUseCase({
    required MemoryFactRepository factRepository,
    required AgentWorkingMemoryRepository workingMemoryRepository,
  })  : _factRepository = factRepository,
        _workingMemoryRepository = workingMemoryRepository;

  final MemoryFactRepository _factRepository;
  final AgentWorkingMemoryRepository _workingMemoryRepository;

  static const _staleFactDays = 30;
  static const _staleConfidenceThreshold = 0.5;
  static const _maxWorkingMemoryChars = 5000;
  static const _truncatedWorkingMemoryChars = 2000;

  /// Archives stale facts and truncates bloated working memory.
  Future<void> execute(String workspaceId) async {
    await _archiveStaleFacts(workspaceId);
    await _truncateWorkingMemory(workspaceId);
  }

  Future<void> _archiveStaleFacts(String workspaceId) async {
    final facts = await _factRepository.getByWorkspace(workspaceId);
    final now = DateTime.now();

    for (final fact in facts) {
      if (fact.isSuperseded) {
        continue;
      }

      final ageDays = now.difference(fact.createdAt).inDays;
      if (ageDays > _staleFactDays && fact.confidence < _staleConfidenceThreshold) {
        final archived = fact.copyWith(supersededBy: 'system:cleanup');
        await _factRepository.upsert(archived);
      }
    }
  }

  Future<void> _truncateWorkingMemory(String workspaceId) async {
    final all = await _workingMemoryRepository.watchByWorkspace(workspaceId).first;
    final now = DateTime.now();

    for (final memory in all) {
      if (memory.content.length > _maxWorkingMemoryChars) {
        final ageDays = now.difference(memory.updatedAt).inDays;
        if (ageDays > 14) {
          final truncated = memory.content.substring(
            memory.content.length - _truncatedWorkingMemoryChars,
          );
          await _workingMemoryRepository.upsert(
            memory.copyWith(content: truncated, updatedAt: now),
          );
        }
      }
    }
  }
}
