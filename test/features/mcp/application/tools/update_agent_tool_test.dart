import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/value_objects/agent_skills.dart';
import 'package:cc_infra/src/ports/workspace_filesystem_port.dart';
import 'package:cc_mcp/src/tools/update_agent_tool.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAgentRepository implements AgentRepository {
  final List<Agent> _agents = [];
  final _controller = StreamController<List<Agent>>.broadcast();

  List<Agent> get saved => List.unmodifiable(_agents);

  @override
  Stream<List<Agent>> watchAll() => _controller.stream;

  @override
  Stream<List<Agent>> watchByWorkspace(String workspaceId) =>
      _controller.stream.map(
        (list) => list.where((a) => a.workspaceId == workspaceId).toList(),
      );

  @override
  Future<Agent?> getById(String id) async {
    try {
      return _agents.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Agent?> findByWorkspaceAndName(
    String workspaceId,
    String name,
  ) async {
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
  Future<void> delete(String id) async {
    _agents.removeWhere((a) => a.id == id);
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
  Future<Directory> workspaceDir(String workspaceId) async {
    return Directory('/fake/$workspaceId');
  }

  @override
  Future<Directory> conversationsDir(String workspaceId) async =>
      Directory('/fake/$workspaceId/conversations');

  @override
  Future<Directory> conversationDir(
    String workspaceId,
    String conversationId,
  ) async =>
      Directory('/fake/$workspaceId/conversations/$conversationId');

  @override
  Future<Directory> ensureConversationDir(
    String workspaceId,
    String conversationId,
  ) async =>
      Directory('/fake/$workspaceId/conversations/$conversationId');

    @override
  Future<Directory> skillsDir(String workspaceId) async {
    return Directory('/fake/$workspaceId/skills');
  }

  @override
  Future<Directory> skillDir(String workspaceId, String skillSlug) async {
    return Directory('/fake/$workspaceId/skills/$skillSlug');
  }

  @override
  Future<String> skillFilePath(String workspaceId, String skillSlug) async {
    return '/fake/$workspaceId/skills/$skillSlug/SKILL.md';
  }

  @override
  Future<Directory> agentsDir(String workspaceId) async {
    return Directory('/fake/$workspaceId/agents');
  }

  @override
  Future<Directory> agentDir(String workspaceId, String agentSlug) async {
    return Directory('/fake/$workspaceId/agents/$agentSlug');
  }

  @override
  Future<String> agentFilePath(String workspaceId, String agentSlug) async {
    return '/fake/$workspaceId/agents/$agentSlug/AGENTS.md';
  }

  @override
  Future<Directory> agentSkillsLinkDir(
    String workspaceId,
    String agentSlug,
  ) async {
    return Directory('/fake/$workspaceId/agents/$agentSlug/.agents/skills');
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
  Future<void> ensureMcpSymlink(String workspaceId, String agentSlug) async {}

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
  Future<File?> readSkillFile(String workspaceId, String skillSlug) async =>
      null;

  @override
  Future<void> deleteSkillDir(String workspaceId, String skillSlug) async {}

  @override
  Future<List<String>> listSkillSlugs(String workspaceId) async => [];

  @override
  Future<String?> persistLogo(String workspaceId, String sourcePath) async =>
      null;

  @override
  Future<Directory> prCloneDir(
    String workspaceId,
    String owner,
    String repo,
  ) async =>
      Directory('/fake/$workspaceId/pr_clones/${owner}__$repo');

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
        containsAll(['workspace_id', 'agent_id', 'name', 'adapter', 'model', 'skills', 'persona', 'title']),
      );
    });

    test('returns error when agent not found', () async {
      final result =
          await tool.call({'workspace_id': 'ws-1', 'agent_id': 'nonexistent'});

      expect(result.isError, isTrue);
    });

    test('rejects an agent from a different workspace', () async {
      await repository.upsert(_agent(id: 'a-1', name: 'coder'));
      final result = await tool.call(
          {'workspace_id': 'other-ws', 'agent_id': 'a-1', 'title': 'X'});

      expect(result.isError, isTrue);
      expect(result.content.first.text, contains('different workspace'));
      expect(repository.saved.first.title, 'Test Agent');
    });

    test('updates title', () async {
      await repository.upsert(_agent(id: 'a-1', name: 'coder'));
      final result = await tool
          .call({'workspace_id': 'ws-1', 'agent_id': 'a-1', 'title': 'New Title'});

      expect(result.isError, isFalse);
      final data = jsonDecode(result.content.first.text) as Map<String, dynamic>;
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
      final data = jsonDecode(result.content.first.text) as Map<String, dynamic>;
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
      final data = jsonDecode(result.content.first.text) as Map<String, dynamic>;
      expect(data['skills'], ['dart', 'rust']);
    });

    test('preserves existing fields when not provided', () async {
      await repository.upsert(_agent(
        id: 'a-1',
        name: 'original',
        title: 'Original Title',
        reportsTo: 'ceo',
      ));

      await tool.call(
          {'workspace_id': 'ws-1', 'agent_id': 'a-1', 'title': 'Updated Title'});

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
