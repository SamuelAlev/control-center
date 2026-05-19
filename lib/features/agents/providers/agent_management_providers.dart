import 'package:control_center/di/providers.dart';
import 'package:control_center/features/agents/data/services/agent_discovery_service.dart';
import 'package:control_center/features/agents/domain/usecases/update_agent.dart';
import 'package:control_center/features/agents/domain/value_objects/discovered_agent.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for the [UpdateAgentUseCase].
final updateAgentUseCaseProvider = Provider<UpdateAgentUseCase>((ref) {
  return UpdateAgentUseCase(repository: ref.watch(agentRepositoryProvider));
});

/// Provider for the [DeleteAgentUseCase].
final deleteAgentUseCaseProvider = Provider<DeleteAgentUseCase>((ref) {
  return DeleteAgentUseCase(repository: ref.watch(agentRepositoryProvider));
});

/// Provider for the [AgentDiscoveryService].
final agentDiscoveryServiceProvider = Provider<AgentDiscoveryService>((ref) {
  return AgentDiscoveryService(
    filesystem: ref.watch(workspaceFilesystemPortProvider),
  );
});

/// Discovers `AGENTS.md` definitions present in the workspace directory that
/// are not yet registered as agents, so the operator can import them.
final discoverableAgentsProvider =
    FutureProvider.family<List<DiscoveredAgent>, String>((
  ref,
  workspaceId,
) async {
  final service = ref.watch(agentDiscoveryServiceProvider);
  final existing =
      ref.watch(workspaceAgentsProvider(workspaceId)).asData?.value ??
          const [];
  final names = existing.map((a) => a.name.toLowerCase()).toSet();
  return service.findImportable(
    workspaceId: workspaceId,
    existingNamesLower: names,
  );
});
