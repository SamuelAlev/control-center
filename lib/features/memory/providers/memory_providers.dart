import 'package:cc_domain/core/domain/entities/memory_access_grant.dart';
import 'package:cc_domain/core/domain/entities/memory_fact.dart';
import 'package:cc_domain/core/domain/entities/memory_policy.dart';
import 'package:cc_domain/features/memory/domain/entities/memory_domain.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/memory/presentation/widgets/agent_working_memory_panel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Streams memory facts for a given workspace.
final memoryFactsProvider =
    StreamProvider.family<List<MemoryFact>, String>((ref, workspaceId) {
  final repo = ref.watch(memoryFactRepositoryProvider);
  return repo.watchByWorkspace(workspaceId);
});

/// Streams memory policies for a given workspace.
final memoryPoliciesProvider =
    StreamProvider.family<List<MemoryPolicy>, String>((ref, workspaceId) {
  final repo = ref.watch(memoryPolicyRepositoryProvider);
  return repo.watchByWorkspace(workspaceId);
});

/// Streams memory access grants for a given workspace.
final memoryAccessGrantsProvider =
    StreamProvider.family<List<MemoryAccessGrant>, String>((ref, workspaceId) {
  final repo = ref.watch(memoryAccessGrantRepositoryProvider);
  return repo.watchByWorkspace(workspaceId);
});

/// Streams memory domains for a given workspace.
final memoryDomainsProvider =
    StreamProvider.family<List<MemoryDomain>, String>((ref, workspaceId) {
  final repo = ref.watch(memoryDomainRepositoryProvider);
  return repo.watchByWorkspace(workspaceId);
});

/// Provides agent working memory panels for a given workspace and agent.
final agentWorkingMemoryPanelProvider = Provider.family<AgentWorkingMemoryPanel, ({String workspaceId, String agentId})>(
  (ref, params) {
    return AgentWorkingMemoryPanel(
      workspaceId: params.workspaceId,
      agentId: params.agentId,
    );
  },
);
