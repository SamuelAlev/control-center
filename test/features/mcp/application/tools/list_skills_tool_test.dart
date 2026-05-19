import 'dart:convert';
import 'dart:io';

import 'package:control_center/core/domain/ports/workspace_filesystem_port.dart';
import 'package:control_center/features/mcp/application/tools/list_skills_tool.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeFilesystem implements WorkspaceFilesystemPort {
  List<String> _skillSlugs = [];

  void setSkillSlugs(List<String> slugs) {
    _skillSlugs = slugs;
  }

  @override
  Future<List<String>> listSkillSlugs(String workspaceId) async => _skillSlugs;

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
  Future<void> ensureWorkspaceDirs(String workspaceId) async {}

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
  group('ListSkillsTool', () {
    late _FakeFilesystem filesystem;
    late ListSkillsTool tool;

    setUp(() {
      filesystem = _FakeFilesystem();
      tool = ListSkillsTool(filesystem: filesystem);
    });

    test('has correct name', () {
      expect(tool.name, 'list_skills');
    });

    test('has valid inputSchema', () {
      final schema = tool.inputSchema;
      expect(schema['type'], 'object');
      expect(schema['required'], contains('workspace_id'));
    });

    test('returns empty skills list', () async {
      filesystem.setSkillSlugs([]);

      final result = await tool.call({'workspace_id': 'ws-1'});

      expect(result.isError, isFalse);
      final data = jsonDecode(result.content.first.text) as Map<String, dynamic>;
      expect(data['skills'], isEmpty);
      expect(data['count'], 0);
    });

    test('returns skill slugs', () async {
      filesystem.setSkillSlugs(['code-review', 'testing', 'strategy']);

      final result = await tool.call({'workspace_id': 'ws-1'});

      expect(result.isError, isFalse);
      final data = jsonDecode(result.content.first.text) as Map<String, dynamic>;
      expect(data['count'], 3);
      expect(data['skills'], ['code-review', 'testing', 'strategy']);
    });
  });
}
