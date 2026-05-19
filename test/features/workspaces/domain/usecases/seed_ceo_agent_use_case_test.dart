import 'dart:async';
import 'dart:io';

import 'package:control_center/core/domain/entities/agent.dart';
import 'package:control_center/core/domain/entities/workspace.dart';
import 'package:control_center/core/domain/ports/workspace_filesystem_port.dart';
import 'package:control_center/core/domain/repositories/agent_repository.dart';
import 'package:control_center/core/domain/value_objects/agent_skills.dart';
import 'package:control_center/features/workspaces/domain/constants/ceo_agent_skills.dart';
import 'package:control_center/features/workspaces/domain/usecases/seed_ceo_agent_use_case.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fake [AgentRepository].
class _FakeAgentRepo implements AgentRepository {
  _FakeAgentRepo({this.agents = const []});
  final List<Agent> agents;
  final List<Agent> upserted = [];

  @override
  Stream<List<Agent>> watchAll() => Stream.value(agents);

  @override
  Stream<List<Agent>> watchByWorkspace(String workspaceId) =>
      Stream.value(agents.where((a) => a.workspaceId == workspaceId).toList());

  @override
  Future<Agent?> getById(String id) async =>
      agents.where((a) => a.id == id).firstOrNull;

  @override
  Future<Agent?> findByWorkspaceAndName(String workspaceId, String name) async =>
      agents.where((a) => a.workspaceId == workspaceId && a.name == name).firstOrNull;

  @override
  Future<void> upsert(Agent agent) async => upserted.add(agent);

  @override
  Future<void> delete(String id) async {}
}

/// Fake [WorkspaceFilesystemPort] with all required methods.
class _FakeFilesystem implements WorkspaceFilesystemPort {

  _FakeFilesystem({this.existingSkills = const {}});
  final Set<String> existingSkills;
  final List<String> writtenSkills = [];
  String? syncedWorkspace;
  String? syncedAgent;
  List<String>? syncedSlugs;

  @override
  Future<void> ensureWorkspaceDirs(String workspaceId) async {}

  @override
  Future<List<String>> listSkillSlugs(String workspaceId) async =>
      existingSkills.toList();

  @override
  Future<void> writeSkillFile(
      String workspaceId, String slug, String content) async {
    writtenSkills.add(slug);
  }

  @override
  Future<void> syncAgentSkillLinks(
      String workspaceId, String agentSlug, List<String> skillSlugs) async {
    syncedWorkspace = workspaceId;
    syncedAgent = agentSlug;
    syncedSlugs = skillSlugs;
  }

  @override
  Future<String?> persistLogo(String workspaceId, String sourcePath) async => null;

  // Remaining required interface methods — stubs
  @override
  Future<Directory> workspaceDir(String workspaceId) async =>
      Directory('/tmp/$workspaceId');

  @override
  Future<Directory> conversationsDir(String workspaceId) async =>
      Directory('/tmp/$workspaceId/conversations');

  @override
  Future<Directory> conversationDir(String workspaceId, String conversationId) async =>
      Directory('/tmp/$workspaceId/conversations/$conversationId');

  @override
  Future<Directory> ensureConversationDir(
      String workspaceId, String conversationId) async =>
      Directory('/tmp/$workspaceId/conversations/$conversationId');

  @override
  Future<Directory> skillsDir(String workspaceId) async =>
      Directory('/tmp/$workspaceId/skills');

  @override
  Future<Directory> skillDir(String workspaceId, String skillSlug) async =>
      Directory('/tmp/$workspaceId/skills/$skillSlug');

  @override
  Future<String> skillFilePath(String workspaceId, String skillSlug) async =>
      '/tmp/$workspaceId/skills/$skillSlug/skill.md';

  @override
  Future<Directory> agentsDir(String workspaceId) async =>
      Directory('/tmp/$workspaceId/agents');

  @override
  Future<Directory> agentDir(String workspaceId, String agentSlug) async =>
      Directory('/tmp/$workspaceId/agents/$agentSlug');

  @override
  Future<String> agentFilePath(String workspaceId, String agentSlug) async =>
      '/tmp/$workspaceId/agents/$agentSlug/agent.md';

  @override
  Future<Directory> agentSkillsLinkDir(String workspaceId, String agentSlug) async =>
      Directory('/tmp/$workspaceId/agents/$agentSlug/skills');

  @override
  Future<void> ensureAgentDir(String workspaceId, String agentSlug) async {}

  @override
  Future<void> ensureMcpSymlink(String workspaceId, String agentSlug) async {}

  @override
  Future<void> writeAgentFile(
      String workspaceId, String agentSlug, String content) async {}

  @override
  Future<void> deleteAgentDir(String workspaceId, String agentSlug) async {}

  @override
  Future<List<String>> listAgentSlugs(String workspaceId) async => [];

  @override
  Future<File?> readSkillFile(String workspaceId, String skillSlug) async => null;

  @override
  Future<void> deleteSkillDir(String workspaceId, String skillSlug) async {}

  @override
  Future<Directory> prCloneDir(
      String workspaceId, String owner, String repo) async =>
      Directory('/tmp/$workspaceId/pr_clones/${owner}__$repo');

  @override
  Future<void> ensureDir(String path) async {}

  @override
  Future<void> writeString(String path, String content) async {}
}

Agent _ceoAgent(String workspaceId) => Agent(
      id: 'ceo-id',
      workspaceId: workspaceId,
      name: 'ceo',
      title: 'CEO',
      agentMdPath: '/tmp/ceo.md',
      skills: AgentSkills([]),
      createdAt: DateTime(2025),
    );

Agent _otherAgent(String workspaceId) => Agent(
      id: 'other-id',
      workspaceId: workspaceId,
      name: 'dev',
      title: 'Developer',
      agentMdPath: '/tmp/dev.md',
      skills: AgentSkills([]),
      createdAt: DateTime(2025),
    );

Workspace _ws(String id) => Workspace(
      id: id,
      name: 'Workspace $id',
      createdAt: DateTime(2025),
      updatedAt: DateTime(2025),
    );

void main() {
  group('SeedCeoAgentUseCase', () {
    late _FakeAgentRepo agentRepo;
    late _FakeFilesystem fs;
    final Map<String, bool> seededFlags = {};

    Future<bool?> getFlag(String key) async => seededFlags[key];
    Future<void> setFlag(String key, {required bool value}) async {
      seededFlags[key] = value;
    }

    setUp(() {
      agentRepo = _FakeAgentRepo();
      fs = _FakeFilesystem();
      seededFlags.clear();
    });

    SeedCeoAgentUseCase useCase() => SeedCeoAgentUseCase(
          agentRepository: agentRepo,
          filesystemService: fs,
        );

    test('skips workspaces already seeded', () async {
      seededFlags['ceo_agent_seeded:ws1'] = true;
      await useCase().execute(
        workspaces: [_ws('ws1')],
        agents: [],
        getSeededFlag: getFlag,
        setSeededFlag: setFlag,
      );

      expect(agentRepo.upserted, isEmpty);
      expect(fs.writtenSkills, isEmpty);
    });

    test('skips already seeded but processes unseeded', () async {
      seededFlags['ceo_agent_seeded:ws1'] = true;
      agentRepo = _FakeAgentRepo(agents: [_otherAgent('ws2')]);

      await useCase().execute(
        workspaces: [_ws('ws1'), _ws('ws2')],
        agents: [_otherAgent('ws2')],
        getSeededFlag: getFlag,
        setSeededFlag: setFlag,
      );

      // ws1 skipped, ws2 processed (CreateCeoAgentUseCase will add an agent)
      expect(seededFlags['ceo_agent_seeded:ws1'], isTrue);
      expect(seededFlags['ceo_agent_seeded:ws2'], isTrue);
      expect(agentRepo.upserted.length, greaterThanOrEqualTo(1));
    });

    test('when ceo exists without skills, seeds skills and updates agent',
        () async {
      agentRepo = _FakeAgentRepo(agents: [_ceoAgent('ws1')]);

      await useCase().execute(
        workspaces: [_ws('ws1')],
        agents: [_ceoAgent('ws1')],
        getSeededFlag: getFlag,
        setSeededFlag: setFlag,
      );

      expect(seededFlags['ceo_agent_seeded:ws1'], isTrue);
      expect(fs.writtenSkills.length, equals(ceoSkillContentMap.length));
      expect(fs.syncedAgent, 'ceo');
      expect(agentRepo.upserted.length, 1);
      final updated = agentRepo.upserted.first;
      expect(updated.skills.toList().toSet(), containsAll(ceoSkillSlugs));
    });

    test('skips writing skills that already exist', () async {
      fs = _FakeFilesystem(existingSkills: ceoSkillContentMap.keys.toSet());
      agentRepo = _FakeAgentRepo(agents: [_ceoAgent('ws1')]);

      await useCase().execute(
        workspaces: [_ws('ws1')],
        agents: [_ceoAgent('ws1')],
        getSeededFlag: getFlag,
        setSeededFlag: setFlag,
      );

      expect(fs.writtenSkills, isEmpty);
      expect(fs.syncedAgent, 'ceo');
    });

    test('writes only missing skills when some exist', () async {
      final existingSlug = ceoSkillContentMap.keys.first;
      fs = _FakeFilesystem(existingSkills: {existingSlug});
      agentRepo = _FakeAgentRepo(agents: [_ceoAgent('ws1')]);

      await useCase().execute(
        workspaces: [_ws('ws1')],
        agents: [_ceoAgent('ws1')],
        getSeededFlag: getFlag,
        setSeededFlag: setFlag,
      );

      expect(fs.writtenSkills.length, ceoSkillContentMap.length - 1);
      expect(fs.writtenSkills, isNot(contains(existingSlug)));
    });

    test('creates CEO agent when not present', () async {
      agentRepo = _FakeAgentRepo(agents: [_otherAgent('ws1')]);

      await useCase().execute(
        workspaces: [_ws('ws1')],
        agents: [_otherAgent('ws1')],
        getSeededFlag: getFlag,
        setSeededFlag: setFlag,
      );

      expect(seededFlags['ceo_agent_seeded:ws1'], isTrue);
      expect(agentRepo.upserted.length, greaterThanOrEqualTo(1));
    });

    test('processes multiple workspaces', () async {
      agentRepo = _FakeAgentRepo(agents: [
        _ceoAgent('ws1'),
        _ceoAgent('ws2'),
      ]);

      await useCase().execute(
        workspaces: [_ws('ws1'), _ws('ws2')],
        agents: [_ceoAgent('ws1'), _ceoAgent('ws2')],
        getSeededFlag: getFlag,
        setSeededFlag: setFlag,
      );

      expect(seededFlags['ceo_agent_seeded:ws1'], isTrue);
      expect(seededFlags['ceo_agent_seeded:ws2'], isTrue);
    });

    test('processes workspace with no agents', () async {
      await useCase().execute(
        workspaces: [_ws('ws1')],
        agents: [],
        getSeededFlag: getFlag,
        setSeededFlag: setFlag,
      );

      expect(seededFlags['ceo_agent_seeded:ws1'], isTrue);
      expect(agentRepo.upserted.length, greaterThanOrEqualTo(1));
    });

    test('ceo with existing full skill set is not updated', () async {
      final fullCeo = _ceoAgent('ws1').copyWith(
        skills: AgentSkills(ceoSkillSlugs.toList()),
      );
      agentRepo = _FakeAgentRepo(agents: [fullCeo]);

      await useCase().execute(
        workspaces: [_ws('ws1')],
        agents: [fullCeo],
        getSeededFlag: getFlag,
        setSeededFlag: setFlag,
      );

      expect(agentRepo.upserted, isEmpty);
    });

    test('ceo with partial skills gets new ones added', () async {
      final partialCeo = _ceoAgent('ws1').copyWith(
        skills: AgentSkills([ceoSkillSlugs.first]),
      );
      agentRepo = _FakeAgentRepo(agents: [partialCeo]);

      await useCase().execute(
        workspaces: [_ws('ws1')],
        agents: [partialCeo],
        getSeededFlag: getFlag,
        setSeededFlag: setFlag,
      );

      expect(agentRepo.upserted.length, 1);
      final updatedSkills = agentRepo.upserted.first.skills.toList().toSet();
      expect(updatedSkills, containsAll(ceoSkillSlugs));
    });
  });
}
