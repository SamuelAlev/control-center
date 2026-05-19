import 'dart:convert';

import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/memory/domain/repositories/agent_working_memory_repository.dart';
import 'package:cc_domain/features/memory/domain/repositories/memory_fact_repository.dart';
import 'package:cc_domain/features/memory/domain/repositories/memory_policy_repository.dart';
import 'package:cc_infra/src/ports/workspace_filesystem_port.dart';
import 'package:cc_mcp/src/tools/read/internal_url.dart';
import 'package:cc_mcp/src/tools/read/internal_url_router.dart';

/// Handles `memory://root[/MEMORY.md|/skills/<slug>/SKILL.md|/policies/<slug>]`
/// URLs by reading from the memory repositories and workspace filesystem.
class MemoryProtocolHandler {
  /// Creates a [MemoryProtocolHandler].
  MemoryProtocolHandler({
    required MemoryFactRepository facts,
    required MemoryPolicyRepository policies,
    required AgentWorkingMemoryRepository workingMemory,
    required WorkspaceFilesystemPort filesystem,
  })  : _facts = facts,
        _policies = policies,
        _workingMemory = workingMemory,
        _filesystem = filesystem;

  final MemoryFactRepository _facts;
  final MemoryPolicyRepository _policies;
  final AgentWorkingMemoryRepository _workingMemory;
  final WorkspaceFilesystemPort _filesystem;

  /// Resolves [url] against the workspace memory stores.
  Future<CallResult> handle(MemoryUrl url, ReadContext context) async {
    final workspaceId = context.workspaceId;
    if (workspaceId == null) {
      return CallResult.error(
        'memory:// requires a workspace_id context',
      );
    }

    switch (url.kind) {
      case MemoryUrlKind.summary:
        return _buildSummary(workspaceId);
      case MemoryUrlKind.full:
        return _buildFull(workspaceId);
      case MemoryUrlKind.skill:
        return _readSkill(workspaceId, url.slug!);
      case MemoryUrlKind.policy:
        return _readPolicy(workspaceId, url.slug!);
      case MemoryUrlKind.agent:
        return _readAgentWorkingMemory(workspaceId, url.agentId!);
    }
  }

  Future<CallResult> _buildSummary(String workspaceId) async {
    final facts = await _facts.getByWorkspace(workspaceId);
    final policies = await _policies.getByWorkspace(workspaceId);

    return CallResult.success(
      jsonEncode({
        'workspace_id': workspaceId,
        'fact_count': facts.length,
        'policy_count': policies.length,
        'topics': facts.map((f) => f.topic).toSet().toList(),
        'domains': policies.map((p) => p.domain).toSet().toList(),
      }),
    );
  }

  Future<CallResult> _buildFull(String workspaceId) async {
    final facts = await _facts.getByWorkspace(workspaceId);
    final policies = await _policies.getByWorkspace(workspaceId);

    final lines = <String>[
      '# Memory Index',
      '',
      '## Facts (${facts.length})',
    ];
    for (final f in facts) {
      lines.add('- **${f.topic}** [${f.domain}] — ${f.content}');
    }

    lines.addAll(['', '## Policies (${policies.length})']);
    for (final p in policies) {
      lines.add('- **${p.domain}**: ${p.rule}');
    }

    return CallResult.success(
      jsonEncode({
        'workspace_id': workspaceId,
        'content': lines.join('\n'),
        'fact_count': facts.length,
        'policy_count': policies.length,
      }),
    );
  }

  Future<CallResult> _readSkill(String workspaceId, String slug) async {
    final content = await _filesystem.readSkillFile(workspaceId, slug);
    if (content == null) {
      return CallResult.error(
        'Skill not found in memory: $slug in workspace $workspaceId',
      );
    }
    return CallResult.success(
      jsonEncode({
        'skill_slug': slug,
        'workspace_id': workspaceId,
        'content': content,
      }),
    );
  }

  Future<CallResult> _readPolicy(String workspaceId, String domain) async {
    final matches = await _policies.getActiveByWorkspace(
      workspaceId,
      domain: domain,
    );
    if (matches.isEmpty) {
      return CallResult.error(
        'Policy not found in memory: $domain in workspace $workspaceId',
      );
    }
    return CallResult.success(
      jsonEncode({
        'domain': domain,
        'workspace_id': workspaceId,
        'rules': matches.map((p) => {
          'id': p.id,
          'rule': p.rule,
          'required_role': p.requiredRole?.name,
        }).toList(),
      }),
    );
  }

  Future<CallResult> _readAgentWorkingMemory(
    String workspaceId,
    String agentId,
  ) async {
    final memory = await _workingMemory.getByAgent(workspaceId, agentId);
    if (memory == null) {
      return CallResult.error(
        'No working memory found for agent $agentId in workspace $workspaceId',
      );
    }
    return CallResult.success(
      jsonEncode({
        'agent_id': agentId,
        'workspace_id': workspaceId,
        'content': memory.content,
        'updated_at': memory.updatedAt.toIso8601String(),
      }),
    );
  }
}
