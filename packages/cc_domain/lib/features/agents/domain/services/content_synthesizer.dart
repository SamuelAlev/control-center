import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/features/settings/domain/entities/adapter.dart';

/// The name (and directory slug) of the seeded agent that writes the text
/// Control Center generates around a conversation: titles, `/btw` side
/// answers, `/handoff` documents and the `/goal` objective interview.
///
/// It is an ordinary roster agent, so its runner, model, persona and system
/// prompt are edited where every other agent's are. A workspace without it
/// has those features off.
const String kContentSynthesizerSlug = 'content-synthesizer';

/// What a one-shot synthesis runs on, resolved from the workspace's
/// content synthesizer agent.
class ContentSynthesizer {
  /// Creates a [ContentSynthesizer].
  const ContentSynthesizer({
    this.agentId,
    required this.adapterId,
    this.modelId,
    this.instructions = '',
  });

  /// Resolves [agent] the way dispatch resolves any agent: no adapter (or an
  /// unknown one) runs on the built-in loop.
  factory ContentSynthesizer.fromAgent(Agent agent) {
    final configured = agent.adapterId?.trim();
    final adapterId =
        predefinedAdapters.any((a) => a.id == configured) && configured != null
        ? configured
        : builtInAdapter.id;
    final model = agent.modelId?.trim();
    return ContentSynthesizer(
      agentId: agent.id,
      adapterId: adapterId,
      modelId: model == null || model.isEmpty ? null : model,
      instructions: [
        agent.systemPrompt?.trim() ?? '',
        agent.persona?.trim() ?? '',
      ].where((s) => s.isNotEmpty).join('\n\n'),
    );
  }

  /// The workspace's content-synthesizer agent id, when resolved from a roster
  /// agent. Threaded to one-shot runs so per-agent account pools and run logs
  /// attach to the agent.
  final String? agentId;

  /// The adapter that runs the completion.
  final String adapterId;

  /// The model, or null for the adapter's own default.
  final String? modelId;

  /// The agent's system prompt and persona, as the workspace edited them.
  /// Empty when both are blank.
  final String instructions;

  /// The system prompt for one synthesis: the workspace's instructions, then
  /// [task]'s fixed contract.
  ///
  /// The contract comes last and is never editable, because callers parse
  /// the reply (a single-line title, a `## Objective` section). The
  /// instructions decide how the text reads, the contract decides its shape.
  String systemPromptFor(String task) {
    if (instructions.isEmpty) {
      return task;
    }
    return '$instructions\n\n## This task\n\n$task';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContentSynthesizer &&
          agentId == other.agentId &&
          adapterId == other.adapterId &&
          modelId == other.modelId &&
          instructions == other.instructions;

  @override
  int get hashCode => Object.hash(agentId, adapterId, modelId, instructions);
}
