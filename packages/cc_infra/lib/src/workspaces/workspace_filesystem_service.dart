import 'dart:io';

import 'package:cc_infra/src/ports/workspace_filesystem_port.dart';
import 'package:cc_infra/src/util/cc_paths.dart';
import 'package:path/path.dart' as p;

/// Re-exports `slugify` from the domain layer.
export 'package:cc_domain/core/domain/services/slugify.dart';

/// Concrete implementation of [WorkspaceFilesystemPort] using the local filesystem.
///
/// The port is `dart:io`-free (paths/content as `String`), so all `dart:io`
/// usage is confined to this desktop/server-side implementation.
class WorkspaceFilesystemService implements WorkspaceFilesystemPort {
  /// Creates a service rooted at [_paths] (the app/server on-disk layout).
  WorkspaceFilesystemService(this._paths);

  final CcPaths _paths;

  @override
  Future<String> workspaceDir(String workspaceId) async {
    final cc = await _paths.root();
    return p.join(cc.path, workspaceId);
  }

  @override
  Future<String> conversationsDir(String workspaceId) async {
    final ws = await workspaceDir(workspaceId);
    return p.join(ws, 'conversations');
  }

  @override
  Future<String> conversationDir(
    String workspaceId,
    String conversationId,
  ) async {
    final root = await conversationsDir(workspaceId);
    return p.join(root, conversationId);
  }

  @override
  Future<String> ensureConversationDir(
    String workspaceId,
    String conversationId,
  ) async {
    final path = await conversationDir(workspaceId, conversationId);
    final dir = Directory(path);
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    return path;
  }

  @override
  Future<String> skillsDir(String workspaceId) async {
    final ws = await workspaceDir(workspaceId);
    return p.join(ws, 'skills');
  }

  @override
  Future<String> skillDir(String workspaceId, String skillSlug) async {
    final dir = await skillsDir(workspaceId);
    return p.join(dir, skillSlug);
  }

  @override
  Future<String> skillFilePath(String workspaceId, String skillSlug) async {
    final dir = await skillDir(workspaceId, skillSlug);
    return p.join(dir, 'SKILL.md');
  }

  @override
  Future<String> agentsDir(String workspaceId) async {
    final ws = await workspaceDir(workspaceId);
    return p.join(ws, 'agents');
  }

  @override
  Future<String> agentDir(String workspaceId, String agentSlug) async {
    final dir = await agentsDir(workspaceId);
    return p.join(dir, agentSlug);
  }

  @override
  Future<String> agentFilePath(String workspaceId, String agentSlug) async {
    final dir = await agentDir(workspaceId, agentSlug);
    return p.join(dir, 'AGENTS.md');
  }

  @override
  Future<String> agentSkillsLinkDir(
    String workspaceId,
    String agentSlug,
  ) async {
    final dir = await agentDir(workspaceId, agentSlug);
    return p.join(dir, '.agents', 'skills');
  }

  @override
  Future<void> ensureWorkspaceDirs(String workspaceId) async {
    final wsPath = await workspaceDir(workspaceId);
    final ws = Directory(wsPath);
    if (!ws.existsSync()) {
      await ws.create(recursive: true);
    }
    final skills = Directory(p.join(wsPath, 'skills'));
    if (!skills.existsSync()) {
      await skills.create(recursive: true);
    }
    final agents = Directory(p.join(wsPath, 'agents'));
    if (!agents.existsSync()) {
      await agents.create(recursive: true);
    }
  }

  @override
  Future<void> ensureAgentDir(String workspaceId, String agentSlug) async {
    final dir = Directory(await agentDir(workspaceId, agentSlug));
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    await ensureMcpSymlink(workspaceId, agentSlug);
  }

  @override
  Future<void> ensureMcpSymlink(String workspaceId, String agentSlug) async {
    final dirPath = await agentDir(workspaceId, agentSlug);
    final dir = Directory(dirPath);
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }

    final mcpFile = await _ensureMcpJson(workspaceId);
    final linkPath = p.join(dirPath, '.mcp.json');

    // Use typeSync(followLinks: false) so we detect a pre-existing symlink
    // (broken or otherwise) instead of falling through to `link.create` and
    // hitting `PathExistsException`. Plain `Link.existsSync()` returns false
    // for regular files and for broken symlinks on some platforms.
    final type = FileSystemEntity.typeSync(linkPath, followLinks: false);
    switch (type) {
      case FileSystemEntityType.link:
        final existing = Link(linkPath);
        final existingTarget = await existing.target();
        if (existingTarget == mcpFile.path) {
          return;
        }
        await existing.delete();
      case FileSystemEntityType.file:
        await File(linkPath).delete();
      case FileSystemEntityType.directory:
        // A directory at this path is unexpected — bail out rather than
        // recursively delete what might be user data.
        return;
      case FileSystemEntityType.notFound:
      case FileSystemEntityType.pipe:
      case FileSystemEntityType.unixDomainSock:
        break;
    }

    await Link(linkPath).create(mcpFile.path);
  }

  Future<File> _ensureMcpJson(String workspaceId) async {
    final wsPath = await workspaceDir(workspaceId);
    final root = Directory(wsPath).parent;
    final file = File(p.join(root.path, 'mcp.json'));
    if (!file.existsSync()) {
      await file.writeAsString(_defaultMcpJson);
    }
    return file;
  }

  static const _defaultMcpJson = '''
{
  "mcpServers": {
    "control-center": {
      "type": "http",
      "url": "http://127.0.0.1:9020/mcp"
    }
  }
}''';

  @override
  Future<void> writeAgentFile(
    String workspaceId,
    String agentSlug,
    String content,
  ) async {
    await ensureAgentDir(workspaceId, agentSlug);
    final path = await agentFilePath(workspaceId, agentSlug);
    await File(path).writeAsString(content);
  }

  @override
  Future<void> deleteAgentDir(String workspaceId, String agentSlug) async {
    final dir = Directory(await agentDir(workspaceId, agentSlug));
    if (dir.existsSync()) {
      await dir.delete(recursive: true);
    }
  }

  @override
  Future<List<String>> listAgentSlugs(String workspaceId) async {
    final dir = Directory(await agentsDir(workspaceId));
    if (!dir.existsSync()) {
      return [];
    }

    final entries = dir.listSync();
    return entries
        .whereType<Directory>()
        .map((d) => p.basename(d.path))
        .toList();
  }

  @override
  Future<void> syncAgentSkillLinks(
    String workspaceId,
    String agentSlug,
    List<String> skillSlugs,
  ) async {
    final linksDirPath = await agentSkillsLinkDir(workspaceId, agentSlug);
    final linksDir = Directory(linksDirPath);
    if (!linksDir.existsSync()) {
      await linksDir.create(recursive: true);
    }

    final existing = linksDir.listSync().whereType<Link>().map(
      (l) => p.basename(l.path),
    );
    final existingSet = existing.toSet();
    final wantedSet = skillSlugs.toSet();

    for (final slug in existingSet.difference(wantedSet)) {
      final link = Link(p.join(linksDirPath, slug));
      if (link.existsSync()) {
        await link.delete();
      }
    }

    for (final slug in wantedSet) {
      final link = Link(p.join(linksDirPath, slug));
      final target = await skillDir(workspaceId, slug);
      if (!link.existsSync()) {
        await link.create(target);
      }
    }
  }

  @override
  Future<void> writeSkillFile(
    String workspaceId,
    String skillSlug,
    String content,
  ) async {
    final dir = Directory(await skillDir(workspaceId, skillSlug));
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    final file = File(await skillFilePath(workspaceId, skillSlug));
    await file.writeAsString(content);
  }

  @override
  Future<String?> readSkillFile(String workspaceId, String skillSlug) async {
    final path = await skillFilePath(workspaceId, skillSlug);
    final file = File(path);
    if (file.existsSync()) {
      return file.readAsString();
    }

    return null;
  }

  @override
  Future<void> deleteSkillDir(String workspaceId, String skillSlug) async {
    final dir = Directory(await skillDir(workspaceId, skillSlug));
    if (dir.existsSync()) {
      await dir.delete(recursive: true);
    }
  }

  @override
  Future<List<String>> listSkillSlugs(String workspaceId) async {
    final dir = Directory(await skillsDir(workspaceId));
    if (!dir.existsSync()) {
      return [];
    }

    final entries = dir.listSync();
    return entries
        .whereType<Directory>()
        .where((d) {
          final fp = p.join(d.path, 'SKILL.md');
          return File(fp).existsSync();
        })
        .map((d) => p.basename(d.path))
        .toList();
  }

  @override
  Future<String> prCloneDir(
    String workspaceId,
    String owner,
    String repo,
  ) async {
    final ws = await workspaceDir(workspaceId);
    // Sanitize owner/repo to avoid path injection; replace any non-alphanumeric
    // characters (except `-` and `.`) with `_`.
    final safeName = '${_sanitize(owner)}__${_sanitize(repo)}';
    return p.join(ws, 'pr_clones', safeName);
  }

  static String _sanitize(String s) =>
      s.replaceAll(RegExp(r'[^a-zA-Z0-9\-.]'), '_');

  @override
  Future<String?> persistLogo(String workspaceId, String sourcePath) async {
    if (sourcePath.isEmpty) {
      return null;
    }
    final source = File(sourcePath);
    if (!source.existsSync()) {
      return null;
    }
    final wsPath = await workspaceDir(workspaceId);
    final ws = Directory(wsPath);
    if (!ws.existsSync()) {
      await ws.create(recursive: true);
    }
    // Lowercase the extension to keep filenames stable across platforms; if
    // none is present, drop the dot so we just write `logo` (rare for picked
    // images, but handle it defensively).
    final ext = p.extension(sourcePath).toLowerCase();
    final destName = ext.isEmpty ? 'logo' : 'logo$ext';
    final dest = File(p.join(wsPath, destName));
    await source.copy(dest.path);
    return dest.path;
  }

  @override
  Future<void> ensureDir(String path) async {
    final dir = Directory(path);
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
  }

  @override
  Future<void> writeString(String path, String content) async {
    final file = File(path);
    if (!file.parent.existsSync()) {
      await file.parent.create(recursive: true);
    }
    await file.writeAsString(content);
  }
}
