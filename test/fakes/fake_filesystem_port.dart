import 'dart:io';

import 'package:control_center/core/domain/ports/workspace_filesystem_port.dart';

String slugify(String name) {
  return name
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'-+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');
}

class FakeFilesystemPort implements WorkspaceFilesystemPort {
  final Map<String, String> _files = {};
  final List<String> _createdDirs = [];
  String _baseDir = '/fake';

  /// Override the base directory prefix for all generated paths.
  set baseDir(String dir) => _baseDir = dir;

  Map<String, String> get files => Map.unmodifiable(_files);
  List<String> get createdDirs => List.unmodifiable(_createdDirs);

  @override
  Future<Directory> workspaceDir(String workspaceId) async =>
      _workspaceDirOverride ?? Directory('$_baseDir/$workspaceId');

  Directory? _workspaceDirOverride;

  /// Override the workspace directory for tests that need real files.
  set workspaceDirOverride(Directory? dir) => _workspaceDirOverride = dir;

  @override
  Future<Directory> conversationsDir(String workspaceId) async =>
      Directory('$_baseDir/$workspaceId/conversations');

  @override
  Future<Directory> conversationDir(
    String workspaceId,
    String conversationId,
  ) async =>
      Directory('$_baseDir/$workspaceId/conversations/$conversationId');

  @override
  Future<Directory> ensureConversationDir(
    String workspaceId,
    String conversationId,
  ) async {
    final dir = '$_baseDir/$workspaceId/conversations/$conversationId';
    _createdDirs.add(dir);
    return Directory(dir);
  }

  @override
  Future<Directory> skillsDir(String workspaceId) async =>
      Directory('$_baseDir/$workspaceId/skills');

  @override
  Future<Directory> skillDir(String workspaceId, String skillSlug) async =>
      Directory('$_baseDir/$workspaceId/skills/$skillSlug');

  @override
  Future<String> skillFilePath(String workspaceId, String skillSlug) async =>
      '$_baseDir/$workspaceId/skills/$skillSlug/SKILL.md';

  @override
  Future<Directory> agentsDir(String workspaceId) async =>
      Directory('$_baseDir/$workspaceId/agents');

  @override
  Future<Directory> agentDir(String workspaceId, String agentSlug) async =>
      Directory('$_baseDir/$workspaceId/agents/$agentSlug');

  @override
  Future<String> agentFilePath(String workspaceId, String agentSlug) async =>
      '$_baseDir/$workspaceId/agents/$agentSlug/AGENTS.md';

  @override
  Future<Directory> agentSkillsLinkDir(
    String workspaceId,
    String agentSlug,
  ) async => Directory('$_baseDir/$workspaceId/agents/$agentSlug/skills');

  @override
  Future<void> ensureWorkspaceDirs(String workspaceId) async {
    _createdDirs.add('$workspaceId/.agents');
    _createdDirs.add('$workspaceId/skills');
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
  Future<void> deleteAgentDir(String workspaceId, String agentSlug) async {
    _files.removeWhere(
      (k, _) => k.startsWith('$workspaceId/agents/$agentSlug'),
    );
  }

  @override
  Future<List<String>> listAgentSlugs(String workspaceId) async {
    return _files.keys
        .where((k) => k.startsWith('$workspaceId/agents/'))
        .map((k) => k.split('/')[2])
        .toSet()
        .toList();
  }

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
  ) async {
    _files['$workspaceId/skills/$skillSlug/SKILL.md'] = content;
  }

  @override
  Future<File?> readSkillFile(String workspaceId, String skillSlug) async {
    final key = '$workspaceId/skills/$skillSlug/SKILL.md';
    final content = _files[key];
    if (content == null) {
      return null;
    }
    final tempFile = await File(
      '${Directory.systemTemp.path}/fake_skill_${skillSlug}_SKILL.md',
    ).create(recursive: true);
    await tempFile.writeAsString(content);
    return tempFile;
  }

  @override
  Future<void> deleteSkillDir(String workspaceId, String skillSlug) async {
    _files.remove('$workspaceId/skills/$skillSlug/SKILL.md');
  }

  @override
  Future<List<String>> listSkillSlugs(String workspaceId) async => [];

  @override
  Future<String?> persistLogo(String workspaceId, String sourcePath) async {
    if (sourcePath.isEmpty) {
      return null;
    }
    final destPath = '$_baseDir/$workspaceId/logo';
    _files[destPath] = sourcePath;
    return destPath;
  }

  @override
  Future<Directory> prCloneDir(
    String workspaceId,
    String owner,
    String repo,
  ) async =>
      Directory('$_baseDir/$workspaceId/pr_clones/${owner}__$repo');

  @override
  Future<void> ensureDir(String path) async {}

  @override
  Future<void> writeString(String path, String content) async {}
}
