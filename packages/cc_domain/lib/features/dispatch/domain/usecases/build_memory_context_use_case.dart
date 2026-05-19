import 'package:cc_domain/core/logging/cc_domain_log.dart';
import 'package:cc_domain/features/memory/domain/repositories/agent_working_memory_repository.dart';
import 'package:cc_domain/features/memory/domain/repositories/memory_fact_repository.dart';
import 'package:cc_domain/features/memory/domain/repositories/memory_policy_repository.dart';

/// Builds the small, always-relevant memory preamble injected into an agent's
/// dispatch prompt: active workspace policies, the agent's own working-memory
/// notes, and a keyword-matched shortlist of durable facts for the task.
///
/// Full durable-fact search stays on-demand via the `search_memory` MCP tool
/// (which can run the slow embedding + vector path); the dispatch-time
/// shortlist is FTS/keyword-only and capped, so it surfaces the most obviously
/// relevant facts without moving the slow path onto the dispatch hot path.
class BuildMemoryContextUseCase {
  /// Creates a [BuildMemoryContextUseCase].
  BuildMemoryContextUseCase({
    required MemoryPolicyRepository policyRepository,
    required AgentWorkingMemoryRepository workingMemoryRepository,
    MemoryFactRepository? factRepository,
  })  : _policyRepository = policyRepository,
        _workingMemoryRepository = workingMemoryRepository,
        _factRepository = factRepository;

  final MemoryPolicyRepository _policyRepository;
  final AgentWorkingMemoryRepository _workingMemoryRepository;
  final MemoryFactRepository? _factRepository;

  /// Max facts injected at dispatch time.
  static const int _maxFacts = 5;

  /// Character budget for the dispatch-time fact shortlist.
  static const int _factBudgetChars = 1200;

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
      CcDomainLog.info('BuildMemoryContextUseCase: policies: ${policies.length}');
      if (policies.isNotEmpty) {
        final policyLines = policies.map((p) => '- [${p.domain}] ${p.rule}');
        parts.add('## Active Policies\n${policyLines.join('\n')}');
      }
    } catch (e) {
      CcDomainLog.error('BuildMemoryContextUseCase: policies load failed: $e', e);
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
      CcDomainLog.error('BuildMemoryContextUseCase: working memory load failed: $e', e);
    }

    // Task-relevant facts — keyword-only (no embedding on the hot path),
    // capped, isolated. Skipped for trivial/empty task descriptions.
    final factRepo = _factRepository;
    final task = taskDescription?.trim();
    if (factRepo != null && task != null && task.length >= 20) {
      try {
        final facts = await factRepo.search(workspaceId, task);
        final lines = <String>[];
        var used = 0;
        for (final f in facts.where((f) => !f.isSuperseded)) {
          if (lines.length >= _maxFacts) {
            break;
          }
          final body = f.content.trim();
          final snippet = body.length > 200 ? '${body.substring(0, 200)}…' : body;
          final line =
              '- [${f.domain}/${f.topic}] $snippet (confidence ${f.confidence.toStringAsFixed(1)})';
          if (used + line.length > _factBudgetChars) {
            break;
          }
          lines.add(line);
          used += line.length;
        }
        if (lines.isNotEmpty) {
          parts.add('## Possibly relevant facts (keyword match for this task)\n'
              '${lines.join('\n')}\n'
              '_Verify load-bearing items with `search_memory`._');
        }
      } catch (e) {
        CcDomainLog.error('BuildMemoryContextUseCase: fact retrieval failed: $e', e);
      }
    }

    if (parts.isEmpty) {
      return '';
    }
    return '## Agent Memory\n\n${parts.join('\n\n')}\n\n'
        '_Search durable facts on demand with the `search_memory` tool._';
  }
}
