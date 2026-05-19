import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:control_center/core/domain/entities/agent.dart';
import 'package:control_center/core/domain/ports/workspace_filesystem_port.dart';
import 'package:control_center/core/domain/repositories/agent_repository.dart';
import 'package:control_center/features/agents/domain/usecases/hire_agent_use_case.dart';
import 'package:control_center/features/mcp/application/tools/hire_agent_tool.dart';
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
  group('HireAgentTool', () {
    late _FakeAgentRepository repository;
    late _FakeFilesystem filesystem;
    late HireAgentTool tool;

    setUp(() {
      repository = _FakeAgentRepository();
      filesystem = _FakeFilesystem();
      tool = HireAgentTool(
        hireAgent: HireAgentUseCase(
          repository: repository,
          filesystem: filesystem,
        ),
      );
    });

    test('has correct name', () {
      expect(tool.name, 'hire_agent');
    });

    test('has non-empty description', () {
      expect(tool.description, isNotEmpty);
    });

    test('has valid inputSchema', () {
      final schema = tool.inputSchema;
      expect(schema['type'], 'object');
      expect(
        schema['required'],
        containsAll(['workspace_id', 'name', 'title', 'agent_md_content']),
      );
    });

    test('creates agent with required fields only', () async {
      final result = await tool.call({
        'workspace_id': 'ws-1',
        'name': 'architect',
        'title': 'System Architect',
        'agent_md_content': '# Architect',
      });

      expect(result.isError, isFalse);
      final data = jsonDecode(result.content.first.text) as Map<String, dynamic>;
      expect(data['name'], 'architect');
      expect(data['title'], 'System Architect');
      expect(data['status'], 'created');
      expect(data['skills'], []);
    });

    test('creates agent with skills', () async {
      final result = await tool.call({
        'workspace_id': 'ws-1',
        'name': 'coder',
        'title': 'Code Agent',
        'agent_md_content': '# Coder',
        'skills': ['dart', 'flutter', 'testing'],
      });

      expect(result.isError, isFalse);
      final data = jsonDecode(result.content.first.text) as Map<String, dynamic>;
      expect(data['name'], 'coder');
      expect(data['skills'], ['dart', 'flutter', 'testing']);
    });

    test('creates agent with persona', () async {
      final result = await tool.call({
        'workspace_id': 'ws-1',
        'name': 'helper',
        'title': 'Helpful Agent',
        'agent_md_content': '# Helper',
        'persona': 'Friendly and supportive',
      });

      expect(result.isError, isFalse);
      final data = jsonDecode(result.content.first.text) as Map<String, dynamic>;
      expect(data['name'], 'helper');
    });

    test('persists agent to repository', () async {
      await tool.call({
        'workspace_id': 'ws-1',
        'name': 'kilo',
        'title': 'Kilo Agent',
        'agent_md_content': '# Kilo',
        'reports_to': 'ceo',
      });

      expect(repository.saved.length, 1);
      expect(repository.saved.first.name, 'kilo');
      expect(repository.saved.first.title, 'Kilo Agent');
      expect(repository.saved.first.workspaceId, 'ws-1');
      expect(repository.saved.first.reportsTo, 'ceo');
    });

    test('writes agent markdown file', () async {
      await tool.call({
        'workspace_id': 'ws-1',
        'name': 'kilo',
        'title': 'Kilo Agent',
        'agent_md_content': '# Kilo Agent\n\nTest content.',
      });

      expect(filesystem.files['ws-1/agents/kilo/AGENTS.md'], '# Kilo Agent\n\nTest content.');
    });

    test('generates unique UUID for each agent', () async {
      await tool.call({
        'workspace_id': 'ws-1',
        'name': 'agent1',
        'title': 'Agent 1',
        'agent_md_content': '# A1',
      });
      await tool.call({
        'workspace_id': 'ws-1',
        'name': 'agent2',
        'title': 'Agent 2',
        'agent_md_content': '# A2',
      });

      expect(repository.saved.length, 2);
      expect(repository.saved[0].id, isNot(repository.saved[1].id));
    });

    test('response includes agent ID', () async {
      final result = await tool.call({
        'workspace_id': 'ws-1',
        'name': 'tester',
        'title': 'Test Agent',
        'agent_md_content': '# Tester',
      });

      final data = jsonDecode(result.content.first.text) as Map<String, dynamic>;
      expect(data['id'], isNotEmpty);
      expect(data['id'], repository.saved.first.id);
    });
  });
}
