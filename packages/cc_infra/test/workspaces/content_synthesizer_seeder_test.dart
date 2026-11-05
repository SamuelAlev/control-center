import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/ports/workspace_filesystem_port.dart';
import 'package:cc_domain/core/domain/repositories/workspace_settings_repository.dart';
import 'package:cc_domain/core/domain/value_objects/agent_skills.dart';
import 'package:cc_domain/features/agents/domain/services/content_synthesizer.dart';
import 'package:cc_infra/src/workspaces/content_synthesizer_seeder.dart';
import 'package:test/test.dart';

import '../helpers/fake_agent_roster.dart';

void main() {
  late FakeAgentRoster agents;
  late _Fs fs;
  late _Settings settings;

  setUp(() {
    agents = FakeAgentRoster();
    fs = _Fs();
    settings = _Settings();
  });

  ContentSynthesizerSeeder seeder() => ContentSynthesizerSeeder(
    agentRepository: agents,
    filesystem: fs,
    settings: settings,
  );

  Agent ceo(String workspaceId) => Agent(
    id: 'ceo-$workspaceId',
    name: 'ceo',
    title: 'CEO',
    agentMdPath: '/ws/ceo/AGENTS.md',
    workspaceId: workspaceId,
    skills: AgentSkills(const []),
    createdAt: DateTime(2026),
  );

  test('adds the agent to an older workspace, under its CEO', () async {
    agents.put(ceo('ws'));

    await seeder().ensure('ws');

    final synth = agents.named('ws', kContentSynthesizerSlug)!;
    expect(synth.reportsTo, 'ceo-ws');
    expect(synth.title, 'Content synthesizer');
    // The persona is on the row, where the agent form edits it.
    expect(synth.persona, contains('## Titles'));
    expect(synth.adapterId, isNull);
    expect(fs.agentFiles, [kContentSynthesizerSlug]);
    expect(settings.values[kContentSynthesizerSeededSettingKey], '1');
  });

  test(
    'carries a retired short-task runner onto it, then deletes it',
    () async {
      settings.values[kLegacyShortTaskAdapterSettingKey] = 'claude-code';
      settings.values[kLegacyShortTaskModelSettingKey] = 'haiku';

      await seeder().ensure('ws');

      final synth = agents.named('ws', kContentSynthesizerSlug)!;
      expect(synth.adapterId, 'claude-code');
      expect(synth.modelId, 'haiku');
      expect(synth.reportsTo, isNull);
      expect(
        settings.values,
        isNot(contains(kLegacyShortTaskAdapterSettingKey)),
      );
      expect(settings.values, isNot(contains(kLegacyShortTaskModelSettingKey)));
    },
  );

  test('a model without its adapter is not carried over', () async {
    settings.values[kLegacyShortTaskModelSettingKey] = 'haiku';

    await seeder().ensure('ws');

    expect(agents.named('ws', kContentSynthesizerSlug)!.modelId, isNull);
  });

  test('an existing synthesizer is kept, its runner filled if unset', () async {
    agents.put(contentSynthesizerAgent(workspaceId: 'ws', persona: 'mine'));
    settings.values[kLegacyShortTaskAdapterSettingKey] = 'cc-harness';

    await seeder().ensure('ws');

    final synth = agents.named('ws', kContentSynthesizerSlug)!;
    expect(synth.persona, 'mine');
    expect(synth.adapterId, 'cc-harness');
    // Its AGENTS.md is the operator's now; nothing rewrites it.
    expect(fs.agentFiles, isEmpty);
  });

  test('runs once: a deleted synthesizer stays deleted', () async {
    await seeder().ensure('ws');
    final first = agents.upserted.length;
    agents.remove('ws', kContentSynthesizerSlug);

    await seeder().ensure('ws');

    expect(agents.named('ws', kContentSynthesizerSlug), isNull);
    expect(agents.upserted, hasLength(first));
  });

  test('workspaces are seeded independently', () async {
    await seeder().ensure('ws-a');

    expect(agents.named('ws-a', kContentSynthesizerSlug), isNotNull);
    expect(agents.named('ws-b', kContentSynthesizerSlug), isNull);
    expect(settings.byWorkspace['ws-b'], isNull);
  });
}

class _Settings implements WorkspaceSettingsRepository {
  final Map<String, Map<String, String>> byWorkspace = {};

  /// The values of workspace `ws`, which most tests use.
  Map<String, String> get values => byWorkspace.putIfAbsent('ws', () => {});

  @override
  Future<String?> get(String workspaceId, String key) async =>
      byWorkspace[workspaceId]?[key];

  @override
  Future<void> set(String workspaceId, String key, String? value) async {
    final values = byWorkspace.putIfAbsent(workspaceId, () => {});
    if (value == null) {
      values.remove(key);
    } else {
      values[key] = value;
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Fs implements WorkspaceFilesystemPort {
  final List<String> agentFiles = [];

  @override
  Future<void> ensureWorkspaceDirs(String workspaceId) async {}

  @override
  Future<void> writeAgentFile(
    String workspaceId,
    String slug,
    String content,
  ) async => agentFiles.add(slug);

  @override
  Future<void> syncAgentSkillLinks(
    String workspaceId,
    String slug,
    List<String> skillSlugs,
  ) async {}

  @override
  Future<String> agentFilePath(String workspaceId, String slug) async =>
      '/ws/$slug/AGENTS.md';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
