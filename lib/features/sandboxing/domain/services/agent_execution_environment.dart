import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/features/dispatch/domain/prompts/prompt_builder.dart';
import 'package:cc_infra/cc_infra.dart';

/// Prepares an isolated per-task execution environment with context files
/// that the agent CLI reads from disk instead of receiving everything via
/// stdin. Writes AGENTS.md, SKILLS.md, MEMORY.md, TOOLS.md, and CONTINUATION.md.
class AgentExecutionEnvironment {
  /// Creates a new [AgentExecutionEnvironment] backed by [_filesystem].
  AgentExecutionEnvironment({required this._filesystem});

  final WorkspaceFilesystemPort _filesystem;

  /// Writes AGENTS.md, SKILLS.md, MEMORY.md, TOOLS.md, and CONTINUATION.md
  /// into a per-run directory, and returns the run directory path.
  Future<String> prepare({
    required Agent agent,
    required String workspaceId,
    required String ticketId,
    required Mode mode,
    String? memoryContext,
    String? conversationContext,
    String? continuationSummary,
  }) async {
    final runDir = '${agent.agentMdPath}/../runs/$ticketId';
    await _filesystem.ensureDir(runDir);

    final brief = PromptBuilder()
        .identity(agent)
        .resourceProtocols()
        .systemPrompt(agent.systemPrompt)
        .persona(agent.persona, role: agent.role)
        .skills(agent.skills)
        .executionContract()
        .mode(mode)
        .buildPersistentBrief();

    await _filesystem.writeString('$runDir/AGENTS.md', brief);

    if (agent.skills.isNotEmpty) {
      await _filesystem.writeString(
        '$runDir/SKILLS.md',
        '# Skills\n\n${agent.skills.join(', ')}',
      );
    }

    await _filesystem.writeString(
      '$runDir/TOOLS.md',
      '# Tools\n\n'
          '(Your tools will go here. Add notes about them as you acquire '
          'and use them.)\n',
    );

    if (memoryContext != null && memoryContext.isNotEmpty) {
      await _filesystem.writeString('$runDir/MEMORY.md', memoryContext);
    }

    if (continuationSummary != null && continuationSummary.isNotEmpty) {
      await _filesystem.writeString(
        '$runDir/CONTINUATION.md',
        '# Continuation\n\n$continuationSummary',
      );
    }

    return runDir;
  }
}
