import 'package:control_center/core/utils/app_log.dart';
import 'package:control_center/features/memory/domain/repositories/agent_working_memory_repository.dart';
import 'package:control_center/features/memory/domain/repositories/memory_policy_repository.dart';

/// Builds the small, always-relevant memory preamble injected into an agent's
/// dispatch prompt: active workspace policies and the agent's own working-memory
/// notes.
///
/// Durable facts are intentionally **not** injected here. They are retrieved
/// on-demand by agents via the `search_memory` MCP tool, which keeps the
/// dispatch prompt small and moves the (potentially slow) embedding + vector
/// search off the dispatch hot path. Policies and working memory stay eager
/// because they are tiny and load-bearing (e.g. "remember my name" flows).
class BuildMemoryContextUseCase {
  /// Creates a [BuildMemoryContextUseCase].
  BuildMemoryContextUseCase({
    required MemoryPolicyRepository policyRepository,
    required AgentWorkingMemoryRepository workingMemoryRepository,
  })  : _policyRepository = policyRepository,
        _workingMemoryRepository = workingMemoryRepository;

  final MemoryPolicyRepository _policyRepository;
  final AgentWorkingMemoryRepository _workingMemoryRepository;

  /// Executes the use case, returning the memory preamble string.
  Future<String> execute({
    required String workspaceId,
    required String agentId,
    String? taskDescription,
  }) async {
    final parts = <String>[];

    // Policies — isolated so a load failure never blocks working memory.
    try {
      final policies =
          await _policyRepository.getActiveByWorkspace(workspaceId);
      AppLog.d('BuildMemoryContextUseCase', 'policies: ${policies.length}');
      if (policies.isNotEmpty) {
        final policyLines = policies.map((p) => '- [${p.domain}] ${p.rule}');
        parts.add('## Active Policies\n${policyLines.join('\n')}');
      }
    } catch (e) {
      AppLog.e('BuildMemoryContextUseCase', 'policies load failed: $e', e);
    }

    // Working memory — the most load-bearing slot for "remember my name" style
    // flows. Isolated so a policy failure cannot block it.
    try {
      final workingMemory = await _workingMemoryRepository.getByAgent(
        workspaceId,
        agentId,
      );
      final hasContent =
          workingMemory != null && workingMemory.content.trim().isNotEmpty;
      if (hasContent) {
        parts.add('## My Notes\n${workingMemory.content}');
      }
    } catch (e) {
      AppLog.e('BuildMemoryContextUseCase', 'working memory load failed: $e', e);
    }

    if (parts.isEmpty) {
      return '';
    }
    return '## Agent Memory\n\n${parts.join('\n\n')}\n\n'
        '_Search durable facts on demand with the `search_memory` tool._';
  }
}
