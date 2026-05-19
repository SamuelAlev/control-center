import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/ports/workspace_filesystem_port.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/value_objects/agent_skills.dart';
import 'package:cc_domain/features/workspaces/domain/constants/ceo_agent_skills.dart';
import 'package:cc_infra/src/workspaces/create_ceo_agent.dart';
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
  group('CreateCeoAgentUseCase.execute', () {
    test(
      'creates the CEO when none exists; writes files; seeds skills',
      () async {
        final repo = _RecordingRepo();
        final fs = _RecordingFs();
        final uc = CreateCeoAgentUseCase(
          agentRepository: repo,
          filesystemService: fs,
        );

        final agent = await uc.execute('ws');

        expect(agent.name, 'ceo');
        expect(agent.title, 'Chief Executive Officer');
        expect(agent.workspaceId, 'ws');
        expect(agent.agentMdPath, '/ws/ceo/AGENTS.md');
        expect(agent.skills.toList(), ceoSkillSlugs);
        expect(repo.upserted, hasLength(1));
        expect(repo.upserted.single.id, agent.id);

        // Filesystem side effects.
        expect(fs.ensuredDirs, ['ws']);
        expect(fs.agentFiles.single.slug, 'ceo');
        expect(fs.agentFiles.single.content, ceoAgentMdContent);
        // Every CEO skill content was written (none existed on disk).
        expect(fs.ensuredSkillSlugs.toSet(), ceoSkillContentMap.keys.toSet());
        // Skill links synced for the ceo slug.
        expect(fs.synced.single.slug, 'ceo');
        expect(fs.synced.single.skills, ceoSkillContentMap.keys.toList());
      },
    );

    test(
      'returns existing CEO unchanged (idempotent at the row level)',
      () async {
        final repo = _RecordingRepo();
        final existing = Agent(
          id: 'old-ceo',
          name: 'ceo',
          title: 'Old CEO',
          agentMdPath: '/ws/ceo/AGENTS.md',
          workspaceId: 'ws',
          skills: AgentSkills(const []),
          createdAt: DateTime.utc(2025, 1, 1),
        );
        repo.byWorkspaceAndName['ws|ceo'] = existing;
        final fs = _RecordingFs();
        final uc = CreateCeoAgentUseCase(
          agentRepository: repo,
          filesystemService: fs,
        );

        final agent = await uc.execute('ws');

        expect(agent.id, 'old-ceo');
        expect(agent.title, 'Old CEO');
        // Not re-upserted.
        expect(repo.upserted, isEmpty);
        // But filesystem seeding still ran (idempotent repair on disk).
        expect(fs.ensuredDirs, ['ws']);
        expect(fs.agentFiles.single.slug, 'ceo');
      },
    );

    test('stamps adapterId/modelId on the created CEO', () async {
      final repo = _RecordingRepo();
      final fs = _RecordingFs();
      final uc = CreateCeoAgentUseCase(
        agentRepository: repo,
        filesystemService: fs,
      );

      final agent = await uc.execute(
        'ws',
        adapterId: 'anthropic',
        modelId: 'claude-opus',
      );

      expect(agent.adapterId, 'anthropic');
      expect(agent.modelId, 'claude-opus');
    });

    test('writes only missing skill files', () async {
      final repo = _RecordingRepo();
      // Pretend one skill already exists on disk.
      final firstSkill = ceoSkillContentMap.keys.first;
      final fs = _RecordingFs(knownSkillSlugs: [firstSkill]);
      final uc = CreateCeoAgentUseCase(
        agentRepository: repo,
        filesystemService: fs,
      );

      await uc.execute('ws');

      expect(fs.ensuredSkillSlugs, isNot(contains(firstSkill)));
      expect(
        fs.ensuredSkillSlugs.toSet(),
        ceoSkillContentMap.keys.toSet().difference({firstSkill}),
      );
    });
  });
}
