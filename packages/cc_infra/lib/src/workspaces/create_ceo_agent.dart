import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/value_objects/agent_skills.dart';
import 'package:cc_domain/features/workspaces/domain/constants/ceo_agent_skills.dart';
import 'package:cc_infra/src/ports/workspace_filesystem_port.dart';
import 'package:uuid/uuid.dart';

/// Seeds a CEO agent and default skills into a workspace.
class CreateCeoAgentUseCase {
  /// Creates a [CreateCeoAgentUseCase].
  const CreateCeoAgentUseCase({
    required AgentRepository agentRepository,
    required WorkspaceFilesystemPort filesystemService,
  }) : _agentRepository = agentRepository,
       _filesystemService = filesystemService;

  final AgentRepository _agentRepository;
  final WorkspaceFilesystemPort _filesystemService;

  /// Execute.
  ///
  /// If [adapterId] or [modelId] are provided, they are set on the created
  /// agent so the dispatch pipeline routes to the correct inference backend.
  ///
  /// Idempotent: if [workspaceId] already has an agent named `ceo`, the
  /// existing row is returned untouched. Filesystem seeding still runs so a
  /// pre-existing CEO row gets its on-disk files/skill links repaired.
  Future<Agent> execute(
    String workspaceId, {
    String? adapterId,
    String? modelId,
  }) async {
    await _filesystemService.ensureWorkspaceDirs(workspaceId);

    const agentSlug = 'ceo';
    final agentPath = await _filesystemService.agentFilePath(
      workspaceId,
      agentSlug,
    );
    await _filesystemService.writeAgentFile(
      workspaceId,
      agentSlug,
      ceoAgentMdContent,
    );

    await _seedSkillFiles(workspaceId);

    final existing = await _agentRepository.findByWorkspaceAndName(
      workspaceId,
      'ceo',
    );
    if (existing != null) {
      return existing;
    }

    final agent = Agent(
      id: const Uuid().v4(),
      name: 'ceo',
      title: 'Chief Executive Officer',
      agentMdPath: agentPath,
      workspaceId: workspaceId,
      skills: AgentSkills(ceoSkillSlugs),
      adapterId: adapterId,
      modelId: modelId,
      createdAt: DateTime.now(),
    );

    await _agentRepository.upsert(agent);
    return agent;
  }

  Future<void> _seedSkillFiles(String workspaceId) async {
    final existingSlugs = await _filesystemService.listSkillSlugs(workspaceId);
    for (final entry in ceoSkillContentMap.entries) {
      if (!existingSlugs.contains(entry.key)) {
        await _filesystemService.writeSkillFile(
          workspaceId,
          entry.key,
          entry.value,
        );
      }
    }

    await _filesystemService.syncAgentSkillLinks(
      workspaceId,
      'ceo',
      ceoSkillContentMap.keys.toList(),
    );
  }
}
