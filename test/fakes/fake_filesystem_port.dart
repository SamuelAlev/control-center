import 'package:cc_infra/src/ports/workspace_filesystem_port.dart';

String slugify(String name) {
  return name
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'-+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');
}

/// In-memory [WorkspaceFilesystemPort] double. Path accessors return the path
/// they WOULD compute (as a `String`, matching the real port) without touching
/// the disk unless [baseDir] points at a real temp dir — tests that need real
/// files set [baseDir] to a temp directory and the provisioner/service create
/// the real subtrees under it.
class FakeFilesystemPort implements WorkspaceFilesystemPort {
  final Map<String, String> _files = {};
  final List<String> _createdDirs = [];
  String _baseDir = '/fake';
  String? _workspaceDirOverride;

  /// Override the base directory prefix for all generated paths.
  set baseDir(String dir) => _baseDir = dir;

  /// Overrides [workspaceDir]'s return value (every workspace id) — used by
  /// tests that need [workspaceDir] to resolve to a real temp directory path.
  set workspaceDirOverride(String path) => _workspaceDirOverride = path;

  Map<String, String> get files => Map.unmodifiable(_files);
  List<String> get createdDirs => List.unmodifiable(_createdDirs);

  @override
  Future<String> workspaceDir(String workspaceId) async =>
      _workspaceDirOverride ?? '$_baseDir/$workspaceId';

  @override
  Future<String> spacesDir(String workspaceId) async =>
      '$_baseDir/$workspaceId/spaces';

  @override
  Future<String> spaceDir(String workspaceId, String spaceId) async =>
      '$_baseDir/$workspaceId/spaces/$spaceId';

  @override
  Future<String> ensureSpaceDir(String workspaceId, String spaceId) async {
    final dir = '$_baseDir/$workspaceId/spaces/$spaceId';
    _createdDirs.add(dir);
    return dir;
  }

  @override
  Future<String> skillsDir(String workspaceId) async =>
      '$_baseDir/$workspaceId/skills';

  @override
  Future<String> skillDir(String workspaceId, String skillSlug) async =>
      '$_baseDir/$workspaceId/skills/$skillSlug';

  @override
  Future<String> skillFilePath(String workspaceId, String skillSlug) async =>
      '$_baseDir/$workspaceId/skills/$skillSlug/SKILL.md';

  @override
  Future<String> agentsDir(String workspaceId) async =>
      '$_baseDir/$workspaceId/agents';

  @override
  Future<String> agentDir(String workspaceId, String agentSlug) async =>
      '$_baseDir/$workspaceId/agents/$agentSlug';

  @override
  Future<String> agentFilePath(String workspaceId, String agentSlug) async =>
      '$_baseDir/$workspaceId/agents/$agentSlug/AGENTS.md';

  @override
  Future<String> agentSkillsLinkDir(
    String workspaceId,
    String agentSlug,
  ) async => '$_baseDir/$workspaceId/agents/$agentSlug/.agents/skills';

  @override
  Future<void> ensureWorkspaceDirs(String workspaceId) async {
    _createdDirs.add('$_baseDir/$workspaceId/.agents');
    _createdDirs.add('$_baseDir/$workspaceId/skills');
    _createdDirs.add('$_baseDir/$workspaceId/agents');
  }

  @override
  Future<void> ensureAgentDir(String workspaceId, String agentSlug) async {
    _createdDirs.add('$_baseDir/$workspaceId/agents/$agentSlug');
  }

  @override
  Future<void> writeAgentFile(
    String workspaceId,
    String agentSlug,
    String content,
  ) async {
    _files['$_baseDir/$workspaceId/agents/$agentSlug/AGENTS.md'] = content;
  }

  @override
  Future<void> deleteAgentDir(String workspaceId, String agentSlug) async {
    _files.removeWhere(
      (k, _) => k.startsWith('$_baseDir/$workspaceId/agents/$agentSlug'),
    );
  }

  @override
  Future<List<String>> listAgentSlugs(String workspaceId) async {
    final prefix = '$_baseDir/$workspaceId/agents/';
    return _files.keys
        .where((k) => k.startsWith(prefix))
        .map((k) => k.substring(prefix.length).split('/').first)
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
    _files['$_baseDir/$workspaceId/skills/$skillSlug/SKILL.md'] = content;
  }

  @override
  Future<String?> readSkillFile(String workspaceId, String skillSlug) async {
    return _files['$_baseDir/$workspaceId/skills/$skillSlug/SKILL.md'];
  }

  @override
  Future<void> deleteSkillDir(String workspaceId, String skillSlug) async {
    _files.remove('$_baseDir/$workspaceId/skills/$skillSlug/SKILL.md');
  }

  @override
  Future<List<String>> listSkillSlugs(String workspaceId) async {
    final prefix = '$_baseDir/$workspaceId/skills/';
    return _files.keys
        .where((k) => k.startsWith(prefix))
        .map((k) => k.substring(prefix.length).split('/').first)
        .toSet()
        .toList();
  }

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
  Future<String?> persistLogoBytes(
    String workspaceId,
    List<int> bytes,
    String extension,
  ) async {
    if (bytes.isEmpty) {
      return null;
    }
    final destPath = '$_baseDir/$workspaceId/logo$extension';
    // The fake only records that a write happened at destPath (content is a
    // String map); store a marker rather than the raw bytes.
    _files[destPath] = '<${bytes.length} bytes>';
    return destPath;
  }

  @override
  Future<String> prCloneDir(
    String workspaceId,
    String owner,
    String repo,
  ) async => '$_baseDir/$workspaceId/pr_clones/${owner}__$repo';

  @override
  Future<void> ensureDir(String path) async {
    _createdDirs.add(path);
  }

  @override
  Future<void> writeString(String path, String content) async {
    _files[path] = content;
  }
}
