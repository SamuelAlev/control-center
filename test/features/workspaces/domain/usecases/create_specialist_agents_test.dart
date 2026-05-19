import 'package:control_center/core/domain/entities/agent.dart';
import 'package:control_center/core/domain/ports/workspace_filesystem_port.dart';
import 'package:control_center/core/domain/repositories/agent_repository.dart';
import 'package:control_center/core/domain/value_objects/agent_skills.dart';
import 'package:control_center/features/workspaces/domain/constants/specialist_agent_seeds.dart';
import 'package:control_center/features/workspaces/domain/usecases/create_specialist_agents.dart';
import 'package:flutter_test/flutter_test.dart';

/// In-memory fake for [AgentRepository].
class _FakeAgentRepository implements AgentRepository {
  final Map<String, Agent> _agents = {};

  void setExisting(Agent agent) => _agents[agent.id] = agent;

  @override
  Future<Agent?> findByWorkspaceAndName(String workspaceId, String name) async {
    for (final a in _agents.values) {
      if (a.workspaceId == workspaceId && a.name == name) {
        return a;
      }
    }
    return null;
  }

  @override
  Future<void> upsert(Agent agent) async {
    _agents[agent.id] = agent;
  }

  @override
  Future<Agent?> getById(String id) async => _agents[id];

  @override
  Stream<List<Agent>> watchAll() => Stream.value(_agents.values.toList());

  @override
  Stream<List<Agent>> watchByWorkspace(String workspaceId) =>
      Stream.value(_agents.values.where((a) => a.workspaceId == workspaceId).toList());

  @override
  Future<void> delete(String id) async => _agents.remove(id);
}

/// In-memory fake for [WorkspaceFilesystemPort].
class _FakeFilesystemPort implements WorkspaceFilesystemPort {
  final List<String> createdDirs = [];
  final List<String> writtenAgentFiles = [];
  final List<String> writtenSkillFiles = [];
  final List<String> syncedAgentLinks = [];
  List<String> existingSkillSlugs = [];

  @override
  Future<void> ensureWorkspaceDirs(String workspaceId) async {
    createdDirs.add(workspaceId);
  }

  @override
  Future<String> agentFilePath(String workspaceId, String agentSlug) async =>
      '/workspaces/$workspaceId/agents/$agentSlug/AGENTS.md';

  @override
  Future<void> writeAgentFile(
    String workspaceId,
    String agentSlug,
    String content,
  ) async {
    writtenAgentFiles.add(agentSlug);
  }

  @override
  Future<void> syncAgentSkillLinks(
    String workspaceId,
    String agentSlug,
    List<String> skillSlugs,
  ) async {
    syncedAgentLinks.add(agentSlug);
  }

  @override
  Future<List<String>> listSkillSlugs(String workspaceId) async => existingSkillSlugs;

  @override
  Future<void> writeSkillFile(
    String workspaceId,
    String skillSlug,
    String content,
  ) async {
    writtenSkillFiles.add(skillSlug);
  }

  // Unused methods — no-op implementations.
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  late _FakeAgentRepository agentRepo;
  late _FakeFilesystemPort filesystem;

  setUp(() {
    agentRepo = _FakeAgentRepository();
    filesystem = _FakeFilesystemPort();
  });

  CreateSpecialistAgentsUseCase createUseCase() =>
      CreateSpecialistAgentsUseCase(
        agentRepository: agentRepo,
        filesystemService: filesystem,
      );

  group('CreateSpecialistAgentsUseCase', () {
    test('seeds all specialist agents into a new workspace', timeout: const Timeout.factor(2), () async {
      final useCase = createUseCase();
      final agents = await useCase.execute(
        'ws-1',
        ceoAgentId: 'ceo-1',
      );

      expect(agents, isNotEmpty);
      // defaultSpecialistAgents has 4 entries (qa, architect, engineer, librarian)
      expect(agents, hasLength(4));
    });

    test('creates agents with correct workspace and reportsTo', timeout: const Timeout.factor(2), () async {
      final useCase = createUseCase();
      final agents = await useCase.execute(
        'ws-1',
        ceoAgentId: 'ceo-uuid',
      );

      for (final agent in agents) {
        expect(agent.workspaceId, 'ws-1');
        expect(agent.reportsTo, 'ceo-uuid');
      }
    });

    test('passes adapterId and modelId to created agents', timeout: const Timeout.factor(2), () async {
      final useCase = createUseCase();
      final agents = await useCase.execute(
        'ws-1',
        ceoAgentId: 'ceo-1',
        adapterId: 'openai',
        modelId: 'gpt-4o',
      );

      for (final agent in agents) {
        expect(agent.adapterId, 'openai');
        expect(agent.modelId, 'gpt-4o');
      }
    });

    test('does not duplicate existing agents (idempotent)', timeout: const Timeout.factor(2), () async {
      // Pre-seed an existing agent for the 'qa' slug
      final existingAgent = Agent(
        id: 'existing-qa',
        name: 'qa',
        title: 'Quality Assurance',
        agentMdPath: '/ws-1/agents/qa/AGENTS.md',
        workspaceId: 'ws-1',
        skills: AgentSkills(['testing']),
        createdAt: DateTime(2024, 1, 1),
      );
      agentRepo.setExisting(existingAgent);

      final useCase = createUseCase();
      final agents = await useCase.execute(
        'ws-1',
        ceoAgentId: 'ceo-1',
      );

      // Should still return 4 agents (including the existing one)
      expect(agents, hasLength(4));

      // The existing agent should be returned as-is
      final qaAgent = agents.firstWhere((a) => a.name == 'qa');
      expect(qaAgent.id, 'existing-qa');
    });

    test('ensures workspace directories', timeout: const Timeout.factor(2), () async {
      final useCase = createUseCase();
      await useCase.execute('ws-1', ceoAgentId: 'ceo-1');
      expect(filesystem.createdDirs, contains('ws-1'));
    });

    test('writes agent files for all specialists', timeout: const Timeout.factor(2), () async {
      final useCase = createUseCase();
      await useCase.execute('ws-1', ceoAgentId: 'ceo-1');

      expect(filesystem.writtenAgentFiles, isNotEmpty);
      expect(filesystem.syncedAgentLinks, isNotEmpty);
    });

    test('writes missing skill files', timeout: const Timeout.factor(2), () async {
      filesystem.existingSkillSlugs = [];

      final useCase = createUseCase();
      await useCase.execute('ws-1', ceoAgentId: 'ceo-1');

      expect(filesystem.writtenSkillFiles, isNotEmpty);
    });

    test('does not overwrite existing skill files', timeout: const Timeout.factor(2), () async {
      // Simulate all skill files already existing
      filesystem.existingSkillSlugs = specialistSkillContentMap.keys.toList();

      final useCase = createUseCase();
      await useCase.execute('ws-1', ceoAgentId: 'ceo-1');

      expect(filesystem.writtenSkillFiles, isEmpty);
    });
  });
}
