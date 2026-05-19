import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/ports/workspace_filesystem_port.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/value_objects/agent_role.dart';
import 'package:cc_infra/src/usecases/hire_agent_use_case.dart';
import 'package:test/test.dart';

class _RecordingRepo implements AgentRepository {
  Agent? upserted;

  @override
  Future<void> upsert(Agent agent) async => upserted = agent;

  @override
  Future<Agent?> getById(String workspaceId, String id) async => null;

  @override
  Future<Agent?> findByWorkspaceAndName(
    String workspaceId,
    String name,
  ) async => null;

  @override
  Stream<List<Agent>> watchByWorkspace(String workspaceId) =>
      const Stream<List<Agent>>.empty();

  @override
  Future<void> delete(String workspaceId, String id) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _RecordingFs implements WorkspaceFilesystemPort {
  final List<String> ensuredDirs = [];
  final List<({String slug, String content})> written = [];
  final List<({String slug, List<String> skills})> synced = [];
  String agentFilePathReturn = '/ws/agents/a/AGENTS.md';

  @override
  Future<void> ensureWorkspaceDirs(String workspaceId) async =>
      ensuredDirs.add(workspaceId);

  @override
  Future<void> writeAgentFile(
    String workspaceId,
    String agentSlug,
    String content,
  ) async => written.add((slug: agentSlug, content: content));

  @override
  Future<String> agentFilePath(String workspaceId, String agentSlug) async =>
      agentFilePathReturn;

  @override
  Future<void> syncAgentSkillLinks(
    String workspaceId,
    String agentSlug,
    List<String> skillSlugs,
  ) async => synced.add((slug: agentSlug, skills: skillSlugs));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('HireAgentUseCase', () {
    test('writes AGENTS.md, syncs skills, persists agent', () async {
      final repo = _RecordingRepo();
      final fs = _RecordingFs();
      final uc = HireAgentUseCase(repository: repo, filesystem: fs);

      final agent = await uc.hire(
        workspaceId: 'ws',
        name: 'Mira',
        title: 'Engineer',
        agentMdContent: '# Mira\n\nYou write code.',
        skills: const ['codex', 'git'],
        reportsTo: 'ceo-1',
        persona: 'Stoic and precise.',
      );

      expect(repo.upserted, isNotNull);
      expect(agent.workspaceId, 'ws');
      expect(agent.name, 'Mira');
      expect(agent.title, 'Engineer');
      expect(agent.agentMdPath, '/ws/agents/a/AGENTS.md');
      expect(agent.reportsTo, 'ceo-1');
      expect(agent.skills.toList(), ['codex', 'git']);
      expect(agent.persona, 'Stoic and precise.');
      expect(agent.id, isNotEmpty);

      expect(fs.ensuredDirs, ['ws']);
      expect(fs.written.single.slug, isNotEmpty);
      expect(fs.written.single.content, contains('# Mira'));
      expect(fs.synced.single.skills, ['codex', 'git']);
    });

    test('skips skill sync when skills is empty', () async {
      final repo = _RecordingRepo();
      final fs = _RecordingFs();
      final uc = HireAgentUseCase(repository: repo, filesystem: fs);

      await uc.hire(
        workspaceId: 'ws',
        name: 'Solo',
        title: 'T',
        agentMdContent: 'x',
      );

      expect(fs.synced, isEmpty);
      expect(repo.upserted, isNotNull);
      expect(repo.upserted!.skills.toList(), isEmpty);
    });

    test('accepts an explicit role', () async {
      final repo = _RecordingRepo();
      final fs = _RecordingFs();
      final uc = HireAgentUseCase(repository: repo, filesystem: fs);

      final agent = await uc.hire(
        workspaceId: 'ws',
        name: 'Boss',
        title: 'CEO',
        agentMdContent: 'x',
        role: AgentRole.coder,
      );

      expect(agent.role, AgentRole.coder);
    });

    test('null persona is preserved as null', () async {
      final repo = _RecordingRepo();
      final fs = _RecordingFs();
      final uc = HireAgentUseCase(repository: repo, filesystem: fs);

      final agent = await uc.hire(
        workspaceId: 'ws',
        name: 'Plain',
        title: 'T',
        agentMdContent: 'x',
      );

      expect(agent.persona, isNull);
    });
  });
}
