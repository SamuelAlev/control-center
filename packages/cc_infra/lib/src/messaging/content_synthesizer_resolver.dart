import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/features/agents/domain/services/content_synthesizer.dart';

/// Finds what a workspace's one-shot syntheses run on: its
/// [kContentSynthesizerSlug] agent, read per call so an edit to the agent
/// applies to the next title without a restart.
///
/// Shared by conversation titling, side questions and the `/goal` interview,
/// so the three cannot disagree about which model the operator chose.
class ContentSynthesizerResolver {
  /// Creates a [ContentSynthesizerResolver].
  const ContentSynthesizerResolver(this._agents);

  final AgentRepository _agents;

  /// The workspace's content synthesizer, or null when it has none — those
  /// features are then off, never run on some other agent's model.
  Future<ContentSynthesizer?> forWorkspace(String workspaceId) async {
    final agent = await _agents.findByWorkspaceAndName(
      workspaceId,
      kContentSynthesizerSlug,
    );
    return agent == null ? null : ContentSynthesizer.fromAgent(agent);
  }
}
