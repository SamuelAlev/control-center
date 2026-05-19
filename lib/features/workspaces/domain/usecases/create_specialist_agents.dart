import 'package:control_center/core/domain/entities/agent.dart';
import 'package:control_center/core/domain/ports/workspace_filesystem_port.dart';
import 'package:control_center/core/domain/repositories/agent_repository.dart';
import 'package:control_center/core/domain/value_objects/agent_skills.dart';
import 'package:control_center/features/workspaces/domain/constants/specialist_agent_seeds.dart';
import 'package:uuid/uuid.dart';

/// Seeds the default specialist agents (QA, Architect, Engineer, Librarian)
/// into a workspace alongside the CEO.
///
/// Idempotent: agents whose slug already exists in the workspace are left
/// alone; their filesystem files are re-written so a stale workspace gets
/// repaired on the next launch.
class CreateSpecialistAgentsUseCase {
  /// Creates a [CreateSpecialistAgentsUseCase].
  const CreateSpecialistAgentsUseCase({
    required AgentRepository agentRepository,
    required WorkspaceFilesystemPort filesystemService,
  }) : _agentRepository = agentRepository,
       _filesystemService = filesystemService;

  final AgentRepository _agentRepository;
  final WorkspaceFilesystemPort _filesystemService;

  /// Run the seed for [workspaceId].
  ///
  /// [ceoAgentId] is the agent id (UUID) of the CEO agent that the
  /// specialists report to. Required so the resulting [Agent.reportsTo]
  /// stores a real agent id, not a slug.
  Future<List<Agent>> execute(
    String workspaceId, {
    required String ceoAgentId,
    String? adapterId,
    String? modelId,
  }) async {
    await _filesystemService.ensureWorkspaceDirs(workspaceId);
    await _ensureSkillFiles(workspaceId);

    final created = <Agent>[];
    for (final spec in defaultSpecialistAgents) {
      final agent = await _seedOne(
        spec: spec,
        workspaceId: workspaceId,
        ceoAgentId: ceoAgentId,
        adapterId: adapterId,
        modelId: modelId,
      );
      created.add(agent);
    }
    return created;
  }

  Future<Agent> _seedOne({
    required DefaultSpecialistAgent spec,
    required String workspaceId,
    required String ceoAgentId,
    String? adapterId,
    String? modelId,
  }) async {
    final agentPath = await _filesystemService.agentFilePath(
      workspaceId,
      spec.slug,
    );
    await _filesystemService.writeAgentFile(
      workspaceId,
      spec.slug,
      spec.agentMdContent,
    );
    await _filesystemService.syncAgentSkillLinks(
      workspaceId,
      spec.slug,
      spec.skillSlugs,
    );

    final existing = await _agentRepository.findByWorkspaceAndName(
      workspaceId,
      spec.slug,
    );
    if (existing != null) {
      return existing;
    }

    final agent = Agent(
      id: const Uuid().v4(),
      name: spec.slug,
      title: spec.title,
      agentMdPath: agentPath,
      workspaceId: workspaceId,
      skills: AgentSkills(spec.skillSlugs),
      reportsTo: ceoAgentId,
      adapterId: adapterId,
      modelId: modelId,
      createdAt: DateTime.now(),
    );

    await _agentRepository.upsert(agent);
    return agent;
  }

  Future<void> _ensureSkillFiles(String workspaceId) async {
    final existingSlugs = await _filesystemService.listSkillSlugs(workspaceId);
    for (final entry in specialistSkillContentMap.entries) {
      if (!existingSlugs.contains(entry.key)) {
        await _filesystemService.writeSkillFile(
          workspaceId,
          entry.key,
          entry.value,
        );
      }
    }
  }
}
