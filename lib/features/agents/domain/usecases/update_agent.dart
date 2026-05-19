import 'package:control_center/core/domain/entities/agent.dart';
import 'package:control_center/core/domain/repositories/agent_repository.dart';
import 'package:control_center/core/domain/value_objects/agent_skills.dart';
import 'package:control_center/core/errors/app_exceptions.dart';

/// Command describing an edit to an existing agent.
///
/// Only the operator-editable fields are exposed here; identity ([agentId]),
/// ownership ([workspaceId]) and the on-disk path are never reassigned through
/// this path.
class UpdateAgentCommand {
  /// Creates an [UpdateAgentCommand].
  const UpdateAgentCommand({
    required this.agentId,
    required this.workspaceId,
    required this.title,
    required this.skills,
    this.reportsTo,
    this.persona,
  });

  /// Id of the agent being edited.
  final String agentId;

  /// Workspace the caller believes owns the agent. Validated before any write.
  final String workspaceId;

  /// New display title.
  final String title;

  /// New skill set.
  final List<String> skills;

  /// Id of the manager agent, or null to clear the reporting line.
  final String? reportsTo;

  /// New persona markdown, or null to clear it.
  final String? persona;
}

/// Updates an existing agent's operator-editable fields.
///
/// Loads the row, asserts it belongs to [UpdateAgentCommand.workspaceId]
/// (denying cross-workspace edits loudly via [WorkspaceMismatchException]),
/// then persists the change. The database is the source of truth for the
/// agent's displayed fields; the seeded `AGENTS.md` file is left untouched.
class UpdateAgentUseCase {
  /// Creates an [UpdateAgentUseCase].
  const UpdateAgentUseCase({required AgentRepository repository})
      : _repository = repository;

  final AgentRepository _repository;

  /// Execute.
  Future<Agent> execute(UpdateAgentCommand command) async {
    final existing = await _repository.getById(command.agentId);
    if (existing == null) {
      throw ArgumentError('No agent with id "${command.agentId}".');
    }
    if (existing.workspaceId != command.workspaceId) {
      throw const WorkspaceMismatchException(
        'This agent belongs to a different workspace.',
      );
    }
    final reportsTo = command.reportsTo;
    final persona = command.persona;
    final updated = existing.copyWith(
      title: command.title,
      skills: AgentSkills(command.skills),
      reportsTo: reportsTo,
      removeReportsTo: reportsTo == null,
      persona: persona,
      removePersona: persona == null,
    );
    await _repository.upsert(updated);
    return updated;
  }
}

/// Deletes an agent after confirming it belongs to the caller's workspace.
class DeleteAgentUseCase {
  /// Creates a [DeleteAgentUseCase].
  const DeleteAgentUseCase({required AgentRepository repository})
      : _repository = repository;

  final AgentRepository _repository;

  /// Execute. Throws [WorkspaceMismatchException] if [workspaceId] does not own
  /// the agent, so a stale id can never delete across workspaces.
  Future<void> execute({
    required String agentId,
    required String workspaceId,
  }) async {
    final existing = await _repository.getById(agentId);
    if (existing == null) {
      return;
    }
    if (existing.workspaceId != workspaceId) {
      throw const WorkspaceMismatchException(
        'This agent belongs to a different workspace.',
      );
    }
    await _repository.delete(agentId);
  }
}
