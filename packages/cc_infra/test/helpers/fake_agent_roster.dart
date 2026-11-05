import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/value_objects/agent_skills.dart';
import 'package:cc_domain/features/agents/domain/services/content_synthesizer.dart';

/// An in-memory roster keyed by workspace and agent name: the lookups the
/// content synthesizer resolver and seeder make, and nothing else.
class FakeAgentRoster implements AgentRepository {
  final Map<String, Agent> _byName = {};

  /// Every row written through [upsert], in order.
  final List<Agent> upserted = [];

  /// Adds [agent] without recording it as an upsert.
  void put(Agent agent) =>
      _byName['${agent.workspaceId}|${agent.name}'] = agent;

  /// Deletes the agent called [name] in [workspaceId].
  void remove(String workspaceId, String name) =>
      _byName.remove('$workspaceId|$name');

  /// The agent called [name] in [workspaceId], if any.
  Agent? named(String workspaceId, String name) =>
      _byName['$workspaceId|$name'];

  @override
  Future<Agent?> findByWorkspaceAndName(
    String workspaceId,
    String name,
  ) async => _byName['$workspaceId|$name'];

  @override
  Future<void> upsert(Agent agent) async {
    upserted.add(agent);
    put(agent);
  }

  @override
  Stream<List<Agent>> watchByWorkspace(String workspaceId) => Stream.value([
    for (final a in _byName.values)
      if (a.workspaceId == workspaceId) a,
  ]);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A content synthesizer agent row for [workspaceId].
Agent contentSynthesizerAgent({
  String workspaceId = 'ws1',
  String? adapterId,
  String? modelId,
  String? persona,
  String? systemPrompt,
}) => Agent(
  id: 'synth-$workspaceId',
  name: kContentSynthesizerSlug,
  title: 'Content synthesizer',
  agentMdPath: '/agents/$kContentSynthesizerSlug/AGENTS.md',
  workspaceId: workspaceId,
  skills: AgentSkills(const []),
  adapterId: adapterId,
  modelId: modelId,
  persona: persona,
  systemPrompt: systemPrompt,
  createdAt: DateTime(2026),
);
