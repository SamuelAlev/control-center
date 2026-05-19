import 'package:control_center/di/providers.dart';
import 'package:control_center/features/agents/domain/usecases/create_agent.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for the [CreateAgentUseCase].
final createAgentUseCaseProvider = Provider<CreateAgentUseCase>((ref) {
  return CreateAgentUseCase(
    repository: ref.watch(agentRepositoryProvider),
    filesystemService: ref.watch(workspaceFilesystemPortProvider),
  );
});

