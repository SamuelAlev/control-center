import 'package:control_center/core/domain/entities/agent.dart';
import 'package:control_center/core/domain/ports/workspace_filesystem_port.dart';
import 'package:control_center/core/domain/repositories/agent_repository.dart';
import 'package:control_center/core/domain/services/slugify.dart';
import 'package:control_center/core/domain/value_objects/agent_role.dart';
import 'package:control_center/core/domain/value_objects/agent_skills.dart';
import 'package:uuid/uuid.dart';

/// Creates (hires) a new agent: writes its `AGENTS.md`, links skills, and
/// persists the [Agent] row. Extracted from `HireAgentTool` so both the MCP
/// tool and the orchestration materializer hire through one path.
class HireAgentUseCase {
  /// Creates a [HireAgentUseCase].
  const HireAgentUseCase({
    required AgentRepository repository,
    required WorkspaceFilesystemPort filesystem,
  })  : _repository = repository,
        _filesystem = filesystem;

  final AgentRepository _repository;
  final WorkspaceFilesystemPort _filesystem;

  /// Hires an agent and returns the persisted [Agent].
  Future<Agent> hire({
    required String workspaceId,
    required String name,
    required String title,
    required String agentMdContent,
    List<String> skills = const [],
    String? reportsTo,
    String? persona,
    AgentRole? role,
  }) async {
    final slug = slugify(name);
    await _filesystem.ensureWorkspaceDirs(workspaceId);
    await _filesystem.writeAgentFile(workspaceId, slug, agentMdContent);
    final agentMdPath = await _filesystem.agentFilePath(workspaceId, slug);

    if (skills.isNotEmpty) {
      await _filesystem.syncAgentSkillLinks(workspaceId, slug, skills);
    }

    final agent = Agent(
      id: const Uuid().v4(),
      name: name,
      title: title,
      agentMdPath: agentMdPath,
      workspaceId: workspaceId,
      reportsTo: reportsTo,
      skills: AgentSkills(skills),
      persona: persona,
      role: role,
      createdAt: DateTime.now(),
    );

    await _repository.upsert(agent);
    return agent;
  }
}
