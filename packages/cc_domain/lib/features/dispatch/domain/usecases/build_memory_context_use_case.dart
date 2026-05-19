import 'package:cc_domain/core/domain/entities/memory_policy.dart';
import 'package:cc_domain/core/logging/cc_domain_log.dart';
import 'package:cc_domain/features/memory/domain/repositories/agent_working_memory_repository.dart';
import 'package:cc_domain/features/memory/domain/repositories/memory_fact_repository.dart';
import 'package:cc_domain/features/memory/domain/repositories/memory_policy_repository.dart';
import 'package:cc_domain/features/memory/domain/value_objects/memory_domain_scope.dart';

/// Builds the small, always-relevant memory preamble injected into an agent's
/// dispatch prompt: active workspace policies, the agent's own working-memory
/// notes and a keyword-matched shortlist of durable facts for the task.
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
  }) : _policyRepository = policyRepository,
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
  /// [repoSlug] names the repository the agent is working in, when known.
  ///
  /// It ranks rather than filters: repo-scoped memory floats to the top of the
  /// preamble but workspace-wide memory is still included, so a standing
  /// preference does not disappear the moment work happens inside a repo.
  Future<String> execute({
    required String workspaceId,
    required String agentId,
    String? taskDescription,
    String? repoSlug,
  }) async {
    final parts = <String>[];

    // Policies — isolated so a load failure never blocks working memory.
    try {
      final policies = sortByRepoAffinity<MemoryPolicy>(
        await _policyRepository.getActiveByWorkspace(workspaceId),
        repoSlug,
        domainOf: (p) => p.domain,
      );
      CcDomainLog.info(
        'BuildMemoryContextUseCase: policies: ${policies.length}',
      );
      if (policies.isNotEmpty) {
        final policyLines = policies.map(
          (p) => '- [${_label(p.domain)}] ${p.rule}',
        );
        parts.add('## Active Policies\n${policyLines.join('\n')}');
      }
    } catch (e) {
      CcDomainLog.error(
        'BuildMemoryContextUseCase: policies load failed: $e',
        e,
      );
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
      CcDomainLog.error(
        'BuildMemoryContextUseCase: working memory load failed: $e',
        e,
      );
    }

    // Task-relevant facts — keyword-only (no embedding on the hot path),
    // capped, isolated. Skipped for trivial/empty task descriptions.
    final factRepo = _factRepository;
    final task = taskDescription?.trim();
    if (factRepo != null && task != null && task.length >= 20) {
      try {
        final facts = await factRepo.search(
          workspaceId,
          task,
          boostRepoSlug: repoSlug,
        );
        final lines = <String>[];
        var used = 0;
        for (final f in facts.where((f) => !f.isSuperseded)) {
          if (lines.length >= _maxFacts) {
            break;
          }
          final body = f.content.trim();
          final snippet = body.length > 200
              ? '${body.substring(0, 200)}…'
              : body;
          final line =
              '- [${_label(f.domain)}/${f.topic}] $snippet (confidence ${f.confidence.toStringAsFixed(1)})';
          if (used + line.length > _factBudgetChars) {
            break;
          }
          lines.add(line);
          used += line.length;
        }
        if (lines.isNotEmpty) {
          parts.add(
            '## Possibly relevant facts (keyword match for this task)\n'
            '${lines.join('\n')}\n'
            '_Verify load-bearing items with `search_memory`._',
          );
        }
      } catch (e) {
        CcDomainLog.error(
          'BuildMemoryContextUseCase: fact retrieval failed: $e',
          e,
        );
      }
    }

    if (parts.isEmpty) {
      return '';
    }
    return '## Agent Memory\n\n${parts.join('\n\n')}\n\n'
        '_Search durable facts on demand with the `search_memory` tool._';
  }

  /// Renders a domain slug for the prompt.
  ///
  /// A repo-scoped slug reads `owner-project · architecture` rather than the
  /// raw `repo:owner-project/architecture`, so the agent sees WHICH codebase a
  /// rule belongs to instead of a prefix it might mistake for part of the name
  /// and echo back into a `domain` argument.
  static String _label(String slug) {
    final scope = MemoryDomainScope.parse(slug);
    return scope.isRepoScoped
        ? '${scope.repoSlug} · ${scope.name}'
        : scope.name;
  }
}
