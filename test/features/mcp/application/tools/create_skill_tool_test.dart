import 'dart:convert';
import 'dart:io';

import 'package:control_center/core/domain/ports/workspace_filesystem_port.dart';
import 'package:control_center/features/mcp/application/tools/create_skill_tool.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeFilesystem implements WorkspaceFilesystemPort {
  final Map<String, String> _writtenSkills = {};
  final List<String> _ensuredDirs = [];

  Map<String, String> get writtenSkills => Map.unmodifiable(_writtenSkills);
  List<String> get ensuredDirs => List.unmodifiable(_ensuredDirs);

  @override
  Future<void> writeSkillFile(
    String workspaceId,
    String skillSlug,
    String content,
  ) async {
    _writtenSkills['$workspaceId/$skillSlug'] = content;
  }

  @override
  Future<void> ensureWorkspaceDirs(String workspaceId) async {
    _ensuredDirs.add(workspaceId);
  }

  @override
  Future<List<String>> listSkillSlugs(String workspaceId) async =>
      _writtenSkills.keys
          .where((k) => k.startsWith('$workspaceId/'))
          .map((k) => k.split('/').last)
          .toList();

  @override
  Future<Directory> workspaceDir(String workspaceId) async =>
      Directory('/fake/$workspaceId');

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
  Future<Directory> skillsDir(String workspaceId) async =>
      Directory('/fake/$workspaceId/skills');

  @override
  Future<Directory> skillDir(String workspaceId, String skillSlug) async =>
      Directory('/fake/$workspaceId/skills/$skillSlug');

  @override
  Future<String> skillFilePath(String workspaceId, String skillSlug) async =>
      '/fake/$workspaceId/skills/$skillSlug/SKILL.md';

  @override
  Future<Directory> agentsDir(String workspaceId) async =>
      Directory('/fake/$workspaceId/agents');

  @override
  Future<Directory> agentDir(String workspaceId, String agentSlug) async =>
      Directory('/fake/$workspaceId/agents/$agentSlug');

  @override
  Future<String> agentFilePath(String workspaceId, String agentSlug) async =>
      '/fake/$workspaceId/agents/$agentSlug/AGENTS.md';

  @override
  Future<Directory> agentSkillsLinkDir(
    String workspaceId,
    String agentSlug,
  ) async =>
      Directory('/fake/$workspaceId/agents/$agentSlug/.agents/skills');

  @override
  Future<void> ensureAgentDir(String workspaceId, String agentSlug) async {}

  @override
  Future<void> ensureMcpSymlink(String workspaceId, String agentSlug) async {}

  @override
  Future<void> writeAgentFile(
    String workspaceId,
    String agentSlug,
    String content,
  ) async {}

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
  Future<File?> readSkillFile(String workspaceId, String skillSlug) async =>
      null;

  @override
  Future<void> deleteSkillDir(String workspaceId, String skillSlug) async {}

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
  group('CreateSkillTool', () {
    late _FakeFilesystem filesystem;
    late CreateSkillTool tool;

    setUp(() {
      filesystem = _FakeFilesystem();
      tool = CreateSkillTool(filesystem: filesystem);
    });

    test('has correct name', () {
      expect(tool.name, 'create_skill');
    });

    test('has valid inputSchema', () {
      final schema = tool.inputSchema;
      expect(schema['type'], 'object');
      expect(
        schema['required'],
        containsAll(['workspace_id', 'slug', 'content']),
      );
    });

    test('creates skill with required fields', () async {
      final result = await tool.call({
        'workspace_id': 'ws-1',
        'slug': 'code-review',
        'content': '---\nname: code-review\n---\n\n# Code Review',
      });

      expect(result.isError, isFalse);
      final data = jsonDecode(result.content.first.text) as Map<String, dynamic>;
      expect(data['slug'], 'code-review');
      expect(data['status'], 'created');
    });

    test('writes skill file to filesystem', () async {
      const content = '---\nname: testing\n---\n\n# Testing';
      await tool.call({
        'workspace_id': 'ws-1',
        'slug': 'testing',
        'content': content,
      });

      expect(filesystem.writtenSkills['ws-1/testing'], content);
    });

    test('ensures workspace dirs before writing', () async {
      await tool.call({
        'workspace_id': 'ws-1',
        'slug': 'planning',
        'content': '# Planning',
      });

      expect(filesystem.ensuredDirs, contains('ws-1'));
    });
  });
}
