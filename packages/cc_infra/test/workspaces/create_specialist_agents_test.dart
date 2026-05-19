import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/ports/workspace_filesystem_port.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/value_objects/agent_skills.dart';
import 'package:cc_domain/features/workspaces/domain/constants/specialist_agent_seeds.dart';
import 'package:cc_infra/src/workspaces/create_specialist_agents.dart';
import 'package:test/test.dart';

class _RecordingRepo implements AgentRepository {
  final Map<String, Agent> byWorkspaceAndName = {};
  final List<Agent> upserted = [];

  @override
  Future<Agent?> findByWorkspaceAndName(String workspaceId, String name) async {
    return byWorkspaceAndName['$workspaceId|$name'];
  }

  @override
  Future<void> upsert(Agent agent) async {
    upserted.add(agent);
    byWorkspaceAndName['${agent.workspaceId}|${agent.name}'] = agent;
  }

  @override
  Future<Agent?> getById(String workspaceId, String id) async => null;

  @override
  Stream<List<Agent>> watchByWorkspace(String workspaceId) =>
      const Stream<List<Agent>>.empty();

  @override
  Future<void> delete(String workspaceId, String id) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _RecordingFs implements WorkspaceFilesystemPort {
  _RecordingFs({this.knownSkillSlugs = const []});

  final List<String> ensuredDirs = [];
  final List<String> ensuredSkillSlugs = [];
  final List<String> knownSkillSlugs;
  final List<({String slug, String content})> agentFiles = [];
  final List<({String slug, List<String> skills})> synced = [];

  @override
  Future<void> ensureWorkspaceDirs(String workspaceId) async =>
      ensuredDirs.add(workspaceId);

  @override
  Future<List<String>> listSkillSlugs(String workspaceId) async =>
      knownSkillSlugs;

  @override
  Future<void> writeSkillFile(
    String workspaceId,
    String slug,
    String content,
  ) async {
    ensuredSkillSlugs.add(slug);
  }

  @override
  Future<void> writeAgentFile(
    String workspaceId,
    String slug,
    String content,
  ) async {
    agentFiles.add((slug: slug, content: content));
  }

  @override
  Future<void> syncAgentSkillLinks(
    String workspaceId,
    String slug,
    List<String> skillSlugs,
  ) async {
    synced.add((slug: slug, skills: skillSlugs));
  }

  @override
  Future<String> agentFilePath(String workspaceId, String slug) async =>
      '/ws/$slug/AGENTS.md';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('CreateSpecialistAgentsUseCase.execute', () {
    test('seeds every default specialist and writes its files', () async {
      final repo = _RecordingRepo();
      final fs = _RecordingFs();
      final uc = CreateSpecialistAgentsUseCase(
        agentRepository: repo,
        filesystemService: fs,
      );

      final created = await uc.execute('ws', ceoAgentId: 'ceo-1');

      expect(created, hasLength(defaultSpecialistAgents.length));
      // Each specialist was upserted.
      expect(repo.upserted, hasLength(defaultSpecialistAgents.length));
      // Each specialist reports to the CEO.
      for (final a in created) {
        expect(a.reportsTo, 'ceo-1');
        expect(a.workspaceId, 'ws');
      }
      // Workspace dirs ensured.
      expect(fs.ensuredDirs, ['ws']);
      // Agent files written for each slug.
      final slugs = fs.agentFiles.map((f) => f.slug).toSet();
      for (final spec in defaultSpecialistAgents) {
        expect(slugs, contains(spec.slug));
      }
    });

    test('writes missing skill files only', () async {
      final repo = _RecordingRepo();
      // Pretend 'testing' already exists on disk.
      final fs = _RecordingFs(knownSkillSlugs: const ['testing']);
      final uc = CreateSpecialistAgentsUseCase(
        agentRepository: repo,
        filesystemService: fs,
      );

      await uc.execute('ws', ceoAgentId: 'ceo-1');

      // Every specialistSkillContentMap key except 'testing' should be written.
      expect(fs.ensuredSkillSlugs, isNot(contains('testing')));
      expect(
        fs.ensuredSkillSlugs.toSet(),
        specialistSkillContentMap.keys.toSet().difference({'testing'}),
      );
    });

    test('returns existing agent unchanged when slug already exists', () async {
      final repo = _RecordingRepo();
      final existing = Agent(
        id: 'old-id',
        name: 'qa',
        title: 'Old QA',
        agentMdPath: '/ws/qa/AGENTS.md',
        workspaceId: 'ws',
        skills: AgentSkills(const []),
        createdAt: DateTime.utc(2025, 1, 1),
      );
      repo.byWorkspaceAndName['ws|qa'] = existing;
      final fs = _RecordingFs();
      final uc = CreateSpecialistAgentsUseCase(
        agentRepository: repo,
        filesystemService: fs,
      );

      final created = await uc.execute('ws', ceoAgentId: 'ceo-1');
      final qa = created.firstWhere((a) => a.name == 'qa');
      expect(qa.id, 'old-id');
      expect(qa.title, 'Old QA');
      // The existing row was NOT re-upserted.
      expect(repo.upserted.where((a) => a.name == 'qa'), isEmpty);
    });

    test('stamps adapterId/modelId on created agents', () async {
      final repo = _RecordingRepo();
      final fs = _RecordingFs();
      final uc = CreateSpecialistAgentsUseCase(
        agentRepository: repo,
        filesystemService: fs,
      );

      final created = await uc.execute(
        'ws',
        ceoAgentId: 'ceo-1',
        adapterId: 'openai',
        modelId: 'gpt-4',
      );

      for (final a in created) {
        expect(a.adapterId, 'openai');
        expect(a.modelId, 'gpt-4');
      }
    });

    test('syncs each specialist skill links', () async {
      final repo = _RecordingRepo();
      final fs = _RecordingFs();
      final uc = CreateSpecialistAgentsUseCase(
        agentRepository: repo,
        filesystemService: fs,
      );

      await uc.execute('ws', ceoAgentId: 'ceo-1');

      final syncedBySlug = {for (final s in fs.synced) s.slug: s.skills};
      for (final spec in defaultSpecialistAgents) {
        expect(syncedBySlug[spec.slug], spec.skillSlugs);
      }
    });
  });
}
