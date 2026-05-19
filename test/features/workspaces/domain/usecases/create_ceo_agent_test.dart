import 'package:control_center/core/domain/entities/agent.dart';
import 'package:control_center/features/workspaces/domain/usecases/create_ceo_agent.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../fakes/fake_agent_repository.dart';
import '../../../../fakes/fake_filesystem_port.dart';

void main() {
  late FakeAgentRepository agentRepo;
  late FakeFilesystemPort filesystem;
  late CreateCeoAgentUseCase useCase;

  setUp(() {
    agentRepo = FakeAgentRepository();
    filesystem = FakeFilesystemPort();
    useCase = CreateCeoAgentUseCase(
      agentRepository: agentRepo,
      filesystemService: filesystem,
    );
  });

  tearDown(() {
    agentRepo.dispose();
  });

  group('CreateCeoAgentUseCase', () {
    test('creates CEO agent with correct properties', () async {
      final agent = await useCase.execute('ws-1');

      expect(agent, isA<Agent>());
      expect(agent.name, 'ceo');
      expect(agent.title, 'Chief Executive Officer');
      expect(agent.skills.hasSkill('strategy'), isTrue);
      expect(agent.skills.hasSkill('coordination'), isTrue);
      expect(agent.skills.hasSkill('decision-making'), isTrue);
      expect(agent.skills.hasSkill('delegation'), isTrue);
      expect(agent.skills.hasSkill('oversight'), isTrue);
    });

    test('ensures workspace directories are created', () async {
      await useCase.execute('ws-1');

      expect(filesystem.createdDirs, contains('ws-1/.agents'));
      expect(filesystem.createdDirs, contains('ws-1/skills'));
    });

    test('writes agent markdown file', () async {
      await useCase.execute('ws-1');

      final agentFile = filesystem.files['ws-1/agents/ceo/AGENTS.md'];
      expect(agentFile, isNotNull);
      expect(agentFile, contains('# CEO Agent'));
      expect(agentFile, contains('Chief Executive Officer'));
    });

    test('saves agent to repository', () async {
      await useCase.execute('ws-1');

      expect(agentRepo.saved.length, 1);
      expect(agentRepo.saved.first.name, 'ceo');
    });

    test('generates unique agent id', () async {
      final agent1 = await useCase.execute('ws-a');
      final agent2 = await useCase.execute('ws-b');

      expect(agent1.id, isNot(agent2.id));
    });

    test('writes skill files', () async {
      await useCase.execute('ws-1');

      final strategySkill = filesystem.files['ws-1/skills/strategy/SKILL.md'];
      expect(strategySkill, isNotNull);
      expect(strategySkill, contains('# Strategy'));

      final coordinationSkill =
          filesystem.files['ws-1/skills/coordination/SKILL.md'];
      expect(coordinationSkill, isNotNull);
      expect(coordinationSkill, contains('# Coordination'));
    });

    test('writes all 5 skill files', () async {
      await useCase.execute('ws-1');

      final skillFiles =
          filesystem.files.keys.where((k) => k.contains('/skills/'));
      expect(skillFiles.length, 5);
    });

    test('agent has correct skill slugs', () async {
      final agent = await useCase.execute('ws-1');

      final skillList = agent.skills.toList();
      expect(skillList, containsAll([
        'strategy',
        'coordination',
        'decision-making',
        'delegation',
        'oversight',
      ]));
    });

    test('agent path is correct', () async {
      final agent = await useCase.execute('ws-1');

      expect(agent.agentMdPath, '/fake/ws-1/agents/ceo/AGENTS.md');
    });

    test('different workspaces create separate CEOs', () async {
      await useCase.execute('ws-1');
      await useCase.execute('ws-2');

      expect(agentRepo.saved.length, 2);
      expect(agentRepo.saved[0].name, 'ceo');
      expect(agentRepo.saved[1].name, 'ceo');

      final ws1File = filesystem.files['ws-1/agents/ceo/AGENTS.md'];
      final ws2File = filesystem.files['ws-2/agents/ceo/AGENTS.md'];
      expect(ws1File, isNotNull);
      expect(ws2File, isNotNull);
    });
  });
}
