import 'dart:convert';
import 'dart:io';

import 'package:control_center/core/domain/ports/workspace_filesystem_port.dart';
import 'package:control_center/features/mcp/application/tools/read/handlers/skill_protocol_handler.dart';
import 'package:control_center/features/mcp/application/tools/read/internal_url.dart';
import 'package:control_center/features/mcp/application/tools/read/internal_url_router.dart';
import 'package:flutter_test/flutter_test.dart';

/// Minimal fake filesystem for tests.
class _FakeFilesystem implements WorkspaceFilesystemPort {
  final Map<String, String> _skillFiles = {};

  void setSkill(String workspaceId, String slug, String content) {
    _skillFiles['$workspaceId/$slug'] = content;
  }

  @override
  Future<File?> readSkillFile(String workspaceId, String skillSlug) async {
    final content = _skillFiles['$workspaceId/$skillSlug'];
    if (content == null) return null;
    final tmp = File(
      '/tmp/test_skill_${skillSlug}_${DateTime.now().millisecondsSinceEpoch}.md',
    );
    await tmp.writeAsString(content);
    return tmp;
  }

  @override
  Future<Directory> workspaceDir(String workspaceId) async =>
      Directory('/tmp/fake/$workspaceId');

  @override
  Future<Directory> conversationsDir(String workspaceId) async =>
      Directory('/tmp/fake/$workspaceId/conversations');

  @override
  Future<Directory> conversationDir(
    String workspaceId,
    String conversationId,
  ) async =>
      Directory('/tmp/fake/$workspaceId/conversations/$conversationId');

  @override
  Future<Directory> ensureConversationDir(
    String workspaceId,
    String conversationId,
  ) async =>
      Directory('/tmp/fake/$workspaceId/conversations/$conversationId');

  @override
  Future<void> writeSkillFile(String w, String s, String c) async {}
  @override
  Future<void> ensureWorkspaceDirs(String w) async {}
  @override
  Future<List<String>> listSkillSlugs(String w) async => [];
  @override
  Future<Directory> skillsDir(String w) async =>
      Directory('/tmp/fake/$w/skills');
  @override
  Future<Directory> skillDir(String w, String s) async =>
      Directory('/tmp/fake/$w/skills/$s');
  @override
  Future<String> skillFilePath(String w, String s) async =>
      '/tmp/fake/$w/skills/$s/SKILL.md';
  @override
  Future<Directory> agentsDir(String w) async =>
      Directory('/tmp/fake/$w/agents');
  @override
  Future<Directory> agentDir(String w, String a) async =>
      Directory('/tmp/fake/$w/agents/$a');
  @override
  Future<String> agentFilePath(String w, String a) async =>
      '/tmp/fake/$w/agents/$a/AGENTS.md';
  @override
  Future<Directory> agentSkillsLinkDir(String w, String a) async =>
      Directory('/tmp/fake/$w/agents/$a/.agents/skills');
  @override
  Future<void> ensureAgentDir(String w, String a) async {}
  @override
  Future<void> ensureMcpSymlink(String w, String a) async {}
  @override
  Future<void> writeAgentFile(String w, String a, String c) async {}
  @override
  Future<void> deleteAgentDir(String w, String a) async {}
  @override
  Future<List<String>> listAgentSlugs(String w) async => [];
  @override
  Future<void> syncAgentSkillLinks(
    String w,
    String a,
    List<String> s,
  ) async {}
  @override
  Future<void> deleteSkillDir(String w, String s) async {}
  @override
  Future<String?> persistLogo(String w, String p) async => null;

  @override
  Future<Directory> prCloneDir(String w, String o, String r) async =>
      Directory('/fake/$w/pr_clones/${o}__$r');

  @override
  Future<void> ensureDir(String path) async {}

  @override
  Future<void> writeString(String path, String content) async {}
}

void main() {
  group('SkillProtocolHandler', () {
    late _FakeFilesystem filesystem;
    late SkillProtocolHandler handler;

    setUp(() {
      filesystem = _FakeFilesystem();
      handler = SkillProtocolHandler(filesystem: filesystem);
    });

    test('returns skill content with workspace context', () async {
      filesystem.setSkill('ws-1', 'code-review', '# Code Review\n\nSteps here.');

      const url = SkillUrl(slug: 'code-review');
      final result = await handler.handle(
        url,
        const ReadContext(workspaceId: 'ws-1'),
      );

      expect(result.isError, isFalse);
      final data = jsonDecode(result.content.first.text) as Map<String, dynamic>;
      expect(data['skill_slug'], 'code-review');
      expect(data['workspace_id'], 'ws-1');
      expect(data['content'], contains('Code Review'));
    });

    test('returns error without workspace context', () async {
      const url = SkillUrl(slug: 'code-review');
      final result = await handler.handle(url, const ReadContext());

      expect(result.isError, isTrue);
      expect(result.content.first.text, contains('workspace_id'));
    });

    test('returns error for missing skill', () async {
      const url = SkillUrl(slug: 'nonexistent');
      final result = await handler.handle(
        url,
        const ReadContext(workspaceId: 'ws-1'),
      );

      expect(result.isError, isTrue);
      expect(result.content.first.text, contains('not found'));
    });
  });
}
