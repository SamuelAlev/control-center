import 'package:control_center/core/domain/entities/memory_access_grant.dart';
import 'package:control_center/core/domain/entities/memory_fact.dart';
import 'package:control_center/core/domain/entities/memory_policy.dart';
import 'package:control_center/core/providers/provider.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/memory/domain/entities/memory_domain.dart';
import 'package:control_center/features/memory/domain/services/memory_harvest_listener.dart';
import 'package:control_center/features/memory/presentation/widgets/agent_working_memory_panel.dart';
import 'package:control_center/features/memory/presentation/widgets/memory_panel.dart';
import 'package:control_center/features/ticketing/providers/ticketing_providers.dart';
import 'package:control_center/shared/widgets/workspace_panel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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

/// Keep-alive listener that harvests schema-validated ticket outputs into
/// workspace memory when a ticket completes (decisions, outcomes, facts).
final memoryHarvestListenerProvider = Provider<MemoryHarvestListener>((ref) {
  final listener = MemoryHarvestListener(
    eventBus: ref.watch(domainEventBusProvider),
    ticketRepository: ref.watch(ticketRepositoryProvider),
    recordFact: ref.watch(recordMemoryFactUseCaseProvider),
  )..start();
  ref.onDispose(listener.dispose);
  return listener;
});

/// Provides the memory workspace panel configuration.
final memoryWorkspacePanelProvider = Provider<WorkspacePanel>((ref) {
  return WorkspacePanel(
    label: 'Memory',
    icon: LucideIcons.brain,
    builder: (workspaceId) => MemoryPanel(workspaceId: workspaceId),
  );
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
