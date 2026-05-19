import 'dart:async';
import 'dart:convert';

import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/value_objects/agent_skills.dart';
import 'package:cc_infra/src/ports/workspace_filesystem_port.dart';
import 'package:cc_mcp/src/tools/update_agent_tool.dart';
import 'package:test/test.dart';

class _FakeAgentRepository implements AgentRepository {
  final List<Agent> _agents = [];
  final _controller = StreamController<List<Agent>>.broadcast();

  List<Agent> get saved => List.unmodifiable(_agents);

  @override
  Stream<List<Agent>> watchAll() => _controller.stream;

  @override
  Stream<List<Agent>> watchByWorkspace(String workspaceId) => _controller.stream
      .map((list) => list.where((a) => a.workspaceId == workspaceId).toList());

  @override
  Future<Agent?> getById(String workspaceId, String id) async {
    try {
      // Scoped, not id-only: an agent id owned by another workspace must not
      // resolve, mirroring the per-workspace database file.
      return _agents.firstWhere(
        (a) => a.id == id && a.workspaceId == workspaceId,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Agent?> findByWorkspaceAndName(String workspaceId, String name) async {
    for (final a in _agents) {
      if (a.workspaceId == workspaceId && a.name == name) {
        return a;
      }
    }
    return null;
  }

  @override
  Future<void> upsert(Agent agent) async {
    final index = _agents.indexWhere((a) => a.id == agent.id);
    if (index >= 0) {
      _agents[index] = agent;
    } else {
      _agents.add(agent);
    }
    _controller.add(List.unmodifiable(_agents));
  }

  @override
  Future<void> delete(String workspaceId, String id) async {
    _agents.removeWhere((a) => a.id == id && a.workspaceId == workspaceId);
    _controller.add(List.unmodifiable(_agents));
  }

  void dispose() => _controller.close();
}

class _FakeFilesystem implements WorkspaceFilesystemPort {
  final List<String> _createdDirs = [];
  final Map<String, String> _files = {};

  List<String> get createdDirs => List.unmodifiable(_createdDirs);
  Map<String, String> get files => Map.unmodifiable(_files);

  @override
  Future<String> workspaceDir(String workspaceId) async {
    return '/fake/$workspaceId';
  }

  @override
  Future<String> conversationsDir(String workspaceId) async =>
      '/fake/$workspaceId/conversations';

  @override
  Future<String> conversationDir(
    String workspaceId,
    String conversationId,
  ) async => '/fake/$workspaceId/conversations/$conversationId';

  @override
  Future<String> ensureConversationDir(
    String workspaceId,
    String conversationId,
  ) async => '/fake/$workspaceId/conversations/$conversationId';

  @override
  Future<String> skillsDir(String workspaceId) async {
    return '/fake/$workspaceId/skills';
  }

  @override
  Future<String> skillDir(String workspaceId, String skillSlug) async {
    return '/fake/$workspaceId/skills/$skillSlug';
  }

  @override
  Future<String> skillFilePath(String workspaceId, String skillSlug) async {
    return '/fake/$workspaceId/skills/$skillSlug/SKILL.md';
  }

  @override
  Future<String> agentsDir(String workspaceId) async {
    return '/fake/$workspaceId/agents';
  }

  @override
  Future<String> agentDir(String workspaceId, String agentSlug) async {
    return '/fake/$workspaceId/agents/$agentSlug';
  }

  @override
  Future<String> agentFilePath(String workspaceId, String agentSlug) async {
    return '/fake/$workspaceId/agents/$agentSlug/AGENTS.md';
  }

  @override
  Future<String> agentSkillsLinkDir(
    String workspaceId,
    String agentSlug,
  ) async {
    return '/fake/$workspaceId/agents/$agentSlug/.agents/skills';
  }

  @override
  Future<void> ensureWorkspaceDirs(String workspaceId) async {
    _createdDirs.addAll([
      workspaceId,
      '$workspaceId/skills',
      '$workspaceId/agents',
    ]);
  }

  @override
  Future<void> ensureAgentDir(String workspaceId, String agentSlug) async {
    _createdDirs.add('$workspaceId/agents/$agentSlug');
  }

  @override
  Future<void> writeAgentFile(
    String workspaceId,
    String agentSlug,
    String content,
  ) async {
    _files['$workspaceId/agents/$agentSlug/AGENTS.md'] = content;
  }

  @override
  Future<void> deleteAgentDir(String workspaceId, String agentSlug) async {}

  @override
  Future<List<String>> listAgentSlugs(String workspaceId) async => [];

  @override
  Future<void> syncAgentSkillLinks(
    String workspaceId,
    String agentSlug,
    List<String> skillSlugs,
  ) async {}

  @override
  Future<void> writeSkillFile(
    String workspaceId,
    String skillSlug,
    String content,
  ) async {}

  @override
  Future<String?> readSkillFile(String workspaceId, String skillSlug) async =>
      null;

  @override
  Future<void> deleteSkillDir(String workspaceId, String skillSlug) async {}

  @override
  Future<List<String>> listSkillSlugs(String workspaceId) async => [];

  @override
  Future<String?> persistLogo(String workspaceId, String sourcePath) async =>
      null;

  @override
  Future<String?> persistLogoBytes(
    String workspaceId,
    List<int> bytes,
    String extension,
  ) async => null;

  @override
  Future<String> prCloneDir(
    String workspaceId,
    String owner,
    String repo,
  ) async => '/fake/$workspaceId/pr_clones/${owner}__$repo';

  @override
  Future<void> ensureDir(String path) async {}

  @override
  Future<void> writeString(String path, String content) async {}
}

void main() {
  group('UpdateAgentTool', () {
    late _FakeAgentRepository repository;
    late _FakeFilesystem filesystem;
    late UpdateAgentTool tool;

    setUp(() {
      repository = _FakeAgentRepository();
      filesystem = _FakeFilesystem();
      tool = UpdateAgentTool(repository: repository, filesystem: filesystem);
    });

    test('has correct name', () {
      expect(tool.name, 'update_agent');
    });

    test('has non-empty description', () {
      expect(tool.description, isNotEmpty);
    });

    test('has valid inputSchema', () {
      final schema = tool.inputSchema;
      expect(schema['type'], 'object');
      expect(schema['required'], ['workspace_id', 'agent_id']);
      expect(
        (schema['properties'] as Map).keys,
        containsAll([
          'workspace_id',
          'agent_id',
          'name',
          'adapter',
          'model',
          'skills',
          'persona',
          'title',
        ]),
      );
    });

    test('returns error when agent not found', () async {
      final result = await tool.call({
        'workspace_id': 'ws-1',
        'agent_id': 'nonexistent',
      });

      expect(result.isError, isTrue);
    });

    test('an agent from a different workspace is simply not found', () async {
      await repository.upsert(_agent(id: 'a-1', name: 'coder'));
      final result = await tool.call({
        'workspace_id': 'other-ws',
        'agent_id': 'a-1',
        'title': 'X',
      });

      expect(result.isError, isTrue);
      // The workspace selects the database, so a foreign id resolves to no row
      // and the update cannot reach across the isolation boundary.
      expect(result.content.first.text, contains('not found'));
      expect(repository.saved.first.title, 'Test Agent');
    });

    test('updates title', () async {
      await repository.upsert(_agent(id: 'a-1', name: 'coder'));
      final result = await tool.call({
        'workspace_id': 'ws-1',
        'agent_id': 'a-1',
        'title': 'New Title',
      });

      expect(result.isError, isFalse);
      final data =
          jsonDecode(result.content.first.text) as Map<String, dynamic>;
      expect(data['title'], 'New Title');
      expect(data['status'], 'updated');
      expect(repository.saved.first.title, 'New Title');
    });

    test('updates adapter and model', () async {
      await repository.upsert(_agent(id: 'a-1'));
      final result = await tool.call({
        'workspace_id': 'ws-1',
        'agent_id': 'a-1',
        'adapter': 'pi',
        'model': 'gpt-4',
      });

      expect(result.isError, isFalse);
      final data =
          jsonDecode(result.content.first.text) as Map<String, dynamic>;
      expect(data['adapter'], 'pi');
      expect(data['model'], 'gpt-4');
      expect(repository.saved.first.adapterId, 'pi');
      expect(repository.saved.first.modelId, 'gpt-4');
    });

    test('updates skills', () async {
      await repository.upsert(_agent(id: 'a-1'));
      final result = await tool.call({
        'workspace_id': 'ws-1',
        'agent_id': 'a-1',
        'skills': ['dart', 'rust'],
      });

      expect(result.isError, isFalse);
      final data =
          jsonDecode(result.content.first.text) as Map<String, dynamic>;
      expect(data['skills'], ['dart', 'rust']);
    });

    test('preserves existing fields when not provided', () async {
      await repository.upsert(
        _agent(
          id: 'a-1',
          name: 'original',
          title: 'Original Title',
          reportsTo: 'ceo',
        ),
      );

      await tool.call({
        'workspace_id': 'ws-1',
        'agent_id': 'a-1',
        'title': 'Updated Title',
      });

      final updated = repository.saved.first;
      expect(updated.name, 'original');
      expect(updated.reportsTo, 'ceo');
    });

    test('writes agent_md_content to filesystem', () async {
      await repository.upsert(_agent(id: 'a-1'));
      await tool.call({
        'workspace_id': 'ws-1',
        'agent_id': 'a-1',
        'agent_md_content': '# Updated Agent',
      });

      expect(filesystem.files.values, contains('# Updated Agent'));
    });
  });
}

Agent _agent({
  String id = 'a-1',
  String name = 'test-agent',
  String title = 'Test Agent',
  String workspaceId = 'ws-1',
  String? reportsTo,
}) {
  return Agent(
    id: id,
    name: name,
    title: title,
    agentMdPath: '/fake/$workspaceId/agents/$name/AGENTS.md',
    workspaceId: workspaceId,
    reportsTo: reportsTo,
    skills: AgentSkills(const []),
    createdAt: DateTime(2026, 1, 1),
  );
}
