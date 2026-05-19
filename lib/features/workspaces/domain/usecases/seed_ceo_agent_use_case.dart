import 'package:control_center/core/domain/entities/agent.dart';
import 'package:control_center/core/domain/entities/workspace.dart';
import 'package:control_center/core/domain/ports/workspace_filesystem_port.dart';
import 'package:control_center/core/domain/repositories/agent_repository.dart';
import 'package:control_center/core/domain/value_objects/agent_skills.dart';
import 'package:control_center/features/workspaces/domain/constants/ceo_agent_skills.dart';
import 'package:control_center/features/workspaces/domain/usecases/create_ceo_agent.dart';

/// Seeds the built-in CEO agent and its required skills into workspaces.
class SeedCeoAgentUseCase {
  /// Creates the use case with the dependencies needed to create and update the CEO agent.
  SeedCeoAgentUseCase({
    required AgentRepository agentRepository,
    required WorkspaceFilesystemPort filesystemService,
  }) : _agentRepository = agentRepository,
       _filesystemService = filesystemService;

  final AgentRepository _agentRepository;
  final WorkspaceFilesystemPort _filesystemService;
  final _seededPrefix = 'ceo_agent_seeded:';

  /// Ensures each workspace has the CEO agent, its seeded skill files, and skill links.
  Future<void> execute({
    required List<Workspace> workspaces,
    required List<Agent> agents,
    required Future<bool?> Function(String key) getSeededFlag,
    required Future<void> Function(String key, {required bool value})
    setSeededFlag,
  }) async {
    for (final ws in workspaces) {
      final key = '$_seededPrefix${ws.id}';
      if (await getSeededFlag(key) == true) {
        continue;
      }

      final hasCeo = agents.any((a) => a.name == 'ceo');
      if (hasCeo) {
        await setSeededFlag(key, value: true);
        await _seedSkillsIfMissing(ws.id);
        await _ensureCeoHasSkills(agents);
        continue;
      }

      await CreateCeoAgentUseCase(
        agentRepository: _agentRepository,
        filesystemService: _filesystemService,
      ).execute(ws.id);
      await setSeededFlag(key, value: true);
    }
  }

  Future<void> _seedSkillsIfMissing(String workspaceId) async {
    await _filesystemService.ensureWorkspaceDirs(workspaceId);
    final slugs = await _filesystemService.listSkillSlugs(workspaceId);

    for (final entry in ceoSkillContentMap.entries) {
      if (!slugs.contains(entry.key)) {
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

  Future<void> _ensureCeoHasSkills(List<Agent> agents) async {
    final ceo = agents.where((a) => a.name == 'ceo').firstOrNull;
    if (ceo == null) {
      return;
    }

    final ceoSkills = ceo.skills.toList().toSet();
    var changed = false;
    for (final skill in ceoSkillSlugs) {
      if (ceoSkills.add(skill)) {
        changed = true;
      }
    }
    if (changed) {
      await _agentRepository.upsert(
        ceo.copyWith(skills: AgentSkills(ceoSkills.toList())),
      );
    }
  }
}
