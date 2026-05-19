import 'package:control_center/core/domain/entities/agent.dart';
import 'package:control_center/core/domain/ports/workspace_filesystem_port.dart';
import 'package:control_center/core/domain/repositories/agent_repository.dart';
import 'package:control_center/core/domain/value_objects/agent_skills.dart';
import 'package:control_center/shared/utils/string_utils.dart';
import 'package:uuid/uuid.dart';

/// Thrown when attempting to create an agent whose [name] is already used by
/// another agent in the same workspace. Names are unique per workspace.
class DuplicateAgentNameException implements Exception {
  /// Creates a [DuplicateAgentNameException].
  const DuplicateAgentNameException({
    required this.name,
    required this.workspaceId,
  });

  /// The conflicting agent name.
  final String name;

  /// Workspace in which the conflict was found.
  final String workspaceId;

  @override
  String toString() =>
      'An agent named "$name" already exists in this workspace.';
}

/// Create agent command.
class CreateAgentCommand {
  /// Creates a new [CreateAgentCommand].
  const CreateAgentCommand({
    required this.name,
    required this.title,
    this.reportsTo,
    required this.skills,
    this.persona,
    this.systemPrompt,
    this.adapterId,
    this.modelId,
    this.strictMode = false,
    this.effort,
    this.contextSize,
    this.workspaceId,
  });

  /// The agent's unique name.
  final String name;

  /// The agent's display title.
  final String title;

  /// The name of the agent this one reports to.
  final String? reportsTo;

  /// The skills assigned to this agent.
  final List<String> skills;

  /// The agent's persona markdown.
  final String? persona;

  /// The system prompt for this agent.
  final String? systemPrompt;

  /// The adapter ID for this agent.
  final String? adapterId;

  /// The model ID for this agent.
  final String? modelId;

  /// Whether strict mode is enabled.
  final bool strictMode;

  /// The effort level for this agent.
  final AgentEffort? effort;

  /// The context size for this agent.
  final int? contextSize;

  /// The workspace to create the agent in. Agents are always workspace-bound,
  /// so this is effectively required — [CreateAgentUseCase.execute] throws when
  /// it is null.
  final String? workspaceId;
}

/// Create agent use case.
class CreateAgentUseCase {
  /// Creates a new [CreateAgentUseCase].
  const CreateAgentUseCase({
    required AgentRepository repository,
    this.filesystemService,
  }) : _repository = repository;

  final AgentRepository _repository;

  /// Optional filesystem service for writing agent markdown files.
  final WorkspaceFilesystemPort? filesystemService;

  /// Execute.
  ///
  /// Throws [DuplicateAgentNameException] when the target workspace already
  /// has an agent with the same name. The check runs before any filesystem
  /// writes so a rejected create leaves no orphan files on disk.
  Future<Agent> execute(CreateAgentCommand command) async {
    // Agents are always owned by a workspace (Agent.workspaceId is non-null) —
    // refuse to create a workspace-less agent rather than silently inventing
    // one or leaking across workspaces.
    final workspaceId = command.workspaceId;
    if (workspaceId == null) {
      throw ArgumentError('Cannot create an agent without a workspace.');
    }

    final existing = await _repository.findByWorkspaceAndName(
      workspaceId,
      command.name,
    );
    if (existing != null) {
      throw DuplicateAgentNameException(
        name: command.name,
        workspaceId: workspaceId,
      );
    }

    String filePath = '';

    if (filesystemService != null) {
      await filesystemService!.ensureWorkspaceDirs(workspaceId);
      final slug = slugify(command.name);
      filePath = await filesystemService!.agentFilePath(workspaceId, slug);
      await filesystemService!.writeAgentFile(
        workspaceId,
        slug,
        _buildAgentMd(command),
      );
    }

    final agent = Agent(
      id: const Uuid().v4(),
      name: command.name,
      title: command.title,
      agentMdPath: filePath.isNotEmpty ? filePath : '',
      workspaceId: workspaceId,
      reportsTo: command.reportsTo,
      skills: AgentSkills(command.skills),
      persona: command.persona,
      systemPrompt: command.systemPrompt,
      adapterId: command.adapterId,
      modelId: command.modelId,
      strictMode: command.strictMode,
      effort: command.effort,
      contextSize: command.contextSize,
      createdAt: DateTime.now(),
    );

    await _repository.upsert(agent);
    return agent;
  }

  String _buildAgentMd(CreateAgentCommand command) {
    final buf = StringBuffer();
    buf.writeln('---');
    buf.writeln('name: ${command.name}');
    if (command.reportsTo != null && command.reportsTo!.isNotEmpty) {
      buf.writeln('reportsTo: ${command.reportsTo}');
    }
    if (command.skills.isNotEmpty) {
      buf.writeln('skills:');
      for (final skill in command.skills) {
        buf.writeln('  - $skill');
      }
    }
    if (command.adapterId != null && command.adapterId!.isNotEmpty) {
      buf.writeln('adapter: ${command.adapterId}');
    }
    if (command.modelId != null && command.modelId!.isNotEmpty) {
      buf.writeln('model: ${command.modelId}');
    }
    if (command.strictMode) {
      buf.writeln('strictMode: true');
    }
    if (command.effort != null) {
      buf.writeln('effort: ${command.effort!.name}');
    }
    if (command.contextSize != null) {
      buf.writeln('contextSize: ${command.contextSize}');
    }
    buf.writeln('---');
    buf.writeln();
    if (command.systemPrompt != null && command.systemPrompt!.isNotEmpty) {
      buf.writeln(command.systemPrompt);
    }
    if (command.persona != null && command.persona!.isNotEmpty) {
      buf.writeln();
      buf.writeln('## Persona');
      buf.writeln(command.persona);
    }
    if (command.systemPrompt == null && command.persona == null) {
      buf.writeln('# ${command.title}');
      buf.writeln();
      buf.writeln('Agent profile for **${command.name}**.');
    }
    return buf.toString();
  }
}

