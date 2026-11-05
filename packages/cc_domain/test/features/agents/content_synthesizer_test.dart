import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/value_objects/agent_skills.dart';
import 'package:cc_domain/features/agents/domain/constants/builtin_agent_seeds.dart';
import 'package:cc_domain/features/agents/domain/services/content_synthesizer.dart';
import 'package:cc_domain/features/settings/domain/entities/adapter.dart';
import 'package:test/test.dart';

Agent _agent({
  String? adapterId,
  String? modelId,
  String? persona,
  String? systemPrompt,
}) => Agent(
  id: 'a',
  name: kContentSynthesizerSlug,
  title: 'Content synthesizer',
  agentMdPath: '/a/AGENTS.md',
  workspaceId: 'ws',
  skills: AgentSkills(const []),
  adapterId: adapterId,
  modelId: modelId,
  persona: persona,
  systemPrompt: systemPrompt,
  createdAt: DateTime(2026),
);

void main() {
  group('ContentSynthesizer.fromAgent', () {
    test('uses the agent runner and model', () {
      final s = ContentSynthesizer.fromAgent(
        _agent(adapterId: 'claude-code', modelId: ' haiku '),
      );
      expect(s.adapterId, 'claude-code');
      expect(s.modelId, 'haiku');
    });

    test('no runner or an unknown one runs on the built-in loop', () {
      expect(
        ContentSynthesizer.fromAgent(_agent()).adapterId,
        builtInAdapter.id,
      );
      expect(
        ContentSynthesizer.fromAgent(_agent(adapterId: 'gone')).adapterId,
        builtInAdapter.id,
      );
    });

    test('system prompt then persona become the instructions', () {
      final s = ContentSynthesizer.fromAgent(
        _agent(systemPrompt: 'Be terse.', persona: 'Titles in French.'),
      );
      expect(s.instructions, 'Be terse.\n\nTitles in French.');
    });
  });

  group('systemPromptFor', () {
    test('puts the fixed task contract after the instructions', () {
      const s = ContentSynthesizer(adapterId: 'x', instructions: 'Style.');
      final prompt = s.systemPromptFor('Reply with one line.');
      expect(prompt, startsWith('Style.'));
      expect(prompt, endsWith('Reply with one line.'));
    });

    test('blank instructions leave the contract alone', () {
      const s = ContentSynthesizer(adapterId: 'x');
      expect(s.systemPromptFor('Reply with one line.'), 'Reply with one line.');
    });
  });

  test('the seeded synthesizer can be reset to its persona', () {
    final seed = builtinAgentSeedFor(kContentSynthesizerSlug)!;
    expect(seed.title, 'Content synthesizer');
    expect(seed.reportsToSlug, 'ceo');
    // Reset stages the AGENTS.md body into the persona field, which is what
    // the synthesizer reads — the two must be the same text.
    expect(seed.agentMdBody, startsWith('# Content Synthesizer'));
    expect(seed.agentMdBody, contains('## Titles'));
  });
}
