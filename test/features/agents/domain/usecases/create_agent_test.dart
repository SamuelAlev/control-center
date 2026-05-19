import 'package:control_center/core/domain/entities/agent.dart';
import 'package:control_center/core/domain/value_objects/agent_skills.dart';
import 'package:control_center/features/agents/domain/usecases/create_agent.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../fakes/fake_agent_repository.dart';
import '../../../../fakes/fake_filesystem_port.dart';

void main() {
  group('CreateAgentUseCase', () {
    late FakeAgentRepository repository;

    setUp(() {
      repository = FakeAgentRepository();
    });

    test('creates agent and persists to repository', () async {
      final useCase = CreateAgentUseCase(repository: repository);

      const command = CreateAgentCommand(
        name: 'Kilo',
        title: 'Kilo Agent',
        skills: ['dart', 'flutter'],
        workspaceId: 'ws-1',
      );

      final agent = await useCase.execute(command);

      expect(agent.name, 'Kilo');
      expect(agent.title, 'Kilo Agent');
      expect(agent.skills, isA<AgentSkills>());
      expect(agent.skills.hasSkill('dart'), isTrue);
      expect(agent.isTopLevel, isTrue);
      expect(repository.saved, contains(agent));
    });

    test('creates agent with reportsTo hierarchy', () async {
      final useCase = CreateAgentUseCase(repository: repository);

      const command = CreateAgentCommand(
        name: 'Worker',
        title: 'Worker Agent',
        reportsTo: 'ceo',
        skills: ['testing'],
        workspaceId: 'ws-1',
      );

      final agent = await useCase.execute(command);

      expect(agent.reportsTo, 'ceo');
      expect(agent.isTopLevel, isFalse);
    });

    test('creates agent with optional fields', () async {
      final useCase = CreateAgentUseCase(repository: repository);

      const command = CreateAgentCommand(
        name: 'Assistant',
        title: 'Assistant Agent',
        skills: ['chat'],
        persona: 'Friendly',
        systemPrompt: 'You are helpful.',
        adapterId: 'openai',
        modelId: 'gpt-4',
        strictMode: true,
        effort: AgentEffort.high,
        contextSize: 8192,
        workspaceId: 'ws-1',
      );

      final agent = await useCase.execute(command);

      expect(agent.persona, 'Friendly');
      expect(agent.systemPrompt, 'You are helpful.');
      expect(agent.adapterId, 'openai');
      expect(agent.modelId, 'gpt-4');
      expect(agent.strictMode, isTrue);
      expect(agent.effort, AgentEffort.high);
      expect(agent.contextSize, 8192);
    });

    test('sets agentMdPath from filesystem service', () async {
      final fs = FakeFilesystemPort();
      final useCase = CreateAgentUseCase(
        repository: repository,
        filesystemService: fs,
      );

      const command = CreateAgentCommand(
        name: 'Kilo',
        title: 'Kilo Agent',
        skills: ['dart'],
        workspaceId: 'ws-1',
      );

      final agent = await useCase.execute(command);

      expect(agent.agentMdPath, '/fake/ws-1/agents/kilo/AGENTS.md');
      expect(fs.files.containsKey('ws-1/agents/kilo/AGENTS.md'), isTrue);
    });

    test('generates valid AGENTS.md content', () async {
      final fs = FakeFilesystemPort();
      final useCase = CreateAgentUseCase(
        repository: repository,
        filesystemService: fs,
      );

      const command = CreateAgentCommand(
        name: 'Kilo',
        title: 'Kilo Agent',
        skills: ['dart', 'flutter'],
        adapterId: 'openai',
        modelId: 'gpt-4',
        strictMode: true,
        effort: AgentEffort.high,
        contextSize: 8192,
        persona: 'Friendly helper',
        systemPrompt: 'You are helpful.',
        workspaceId: 'ws-1',
      );

      await useCase.execute(command);
      final content = fs.files['ws-1/agents/kilo/AGENTS.md']!;

      expect(content, contains('name: Kilo'));
      expect(content, contains('skills:'));
      expect(content, contains('  - dart'));
      expect(content, contains('  - flutter'));
      expect(content, contains('adapter: openai'));
      expect(content, contains('model: gpt-4'));
      expect(content, contains('strictMode: true'));
      expect(content, contains('effort: high'));
      expect(content, contains('contextSize: 8192'));
      expect(content, contains('You are helpful.'));
      expect(content, contains('## Persona'));
      expect(content, contains('Friendly helper'));
    });

    test('generates minimal AGENTS.md when no optional fields', () async {
      final fs = FakeFilesystemPort();
      final useCase = CreateAgentUseCase(
        repository: repository,
        filesystemService: fs,
      );

      const command = CreateAgentCommand(
        name: 'Minimal',
        title: 'Minimal Agent',
        skills: [],
        workspaceId: 'ws-1',
      );

      await useCase.execute(command);
      final content = fs.files['ws-1/agents/minimal/AGENTS.md']!;

      expect(content, contains('name: Minimal'));
      expect(content, contains('# Minimal Agent'));
      expect(content, contains('**Minimal**'));
    });

    test('succeeds without filesystem service', () async {
      final useCase = CreateAgentUseCase(repository: repository);

      const command = CreateAgentCommand(
        name: 'NoFs',
        title: 'No Fs Agent',
        skills: [],
        workspaceId: 'ws-1',
      );

      final agent = await useCase.execute(command);

      expect(agent.agentMdPath, '');
      expect(agent.name, 'NoFs');
    });

    test('refuses to create an agent without a workspace', () async {
      final useCase = CreateAgentUseCase(repository: repository);

      const command = CreateAgentCommand(
        name: 'Orphan',
        title: 'Orphan Agent',
        skills: [],
      );

      await expectLater(
        () => useCase.execute(command),
        throwsA(isA<ArgumentError>()),
      );
      expect(repository.saved, isEmpty);
    });
  });
}
