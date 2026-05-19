import 'package:control_center/core/domain/entities/memory_access_grant.dart';
import 'package:control_center/core/domain/entities/memory_fact.dart';
import 'package:control_center/core/domain/entities/memory_policy.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/memory/domain/entities/memory_domain.dart';
import 'package:control_center/features/memory/presentation/widgets/agent_working_memory_panel.dart';
import 'package:control_center/features/memory/presentation/widgets/memory_panel.dart';
import 'package:control_center/shared/widgets/workspace_panel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

final memoryFactsProvider =
    StreamProvider.family<List<MemoryFact>, String>((ref, workspaceId) {
  final repo = ref.watch(memoryFactRepositoryProvider);
  return repo.watchByWorkspace(workspaceId);
});

final memoryPoliciesProvider =
    StreamProvider.family<List<MemoryPolicy>, String>((ref, workspaceId) {
  final repo = ref.watch(memoryPolicyRepositoryProvider);
  return repo.watchByWorkspace(workspaceId);
});

final memoryAccessGrantsProvider =
    StreamProvider.family<List<MemoryAccessGrant>, String>((ref, workspaceId) {
  final repo = ref.watch(memoryAccessGrantRepositoryProvider);
  return repo.watchByWorkspace(workspaceId);
});

final memoryDomainsProvider =
    StreamProvider.family<List<MemoryDomain>, String>((ref, workspaceId) {
  final repo = ref.watch(memoryDomainRepositoryProvider);
  return repo.watchByWorkspace(workspaceId);
});

final memoryWorkspacePanelProvider = Provider<WorkspacePanel>((ref) {
  return WorkspacePanel(
    label: 'Memory',
    icon: LucideIcons.brain,
    builder: (workspaceId) => MemoryPanel(workspaceId: workspaceId),
  );
});

final agentWorkingMemoryPanelProvider = Provider.family<AgentWorkingMemoryPanel, ({String workspaceId, String agentId})>(
  (ref, params) {
    return AgentWorkingMemoryPanel(
      workspaceId: params.workspaceId,
      agentId: params.agentId,
    );
  },
);
