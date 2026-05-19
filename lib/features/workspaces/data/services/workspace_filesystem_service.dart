import 'dart:io';

import 'package:control_center/core/domain/ports/workspace_filesystem_port.dart';
import 'package:control_center/core/storage/control_center_paths.dart';
import 'package:path/path.dart' as p;

/// Re-exports `slugify` from the domain layer.
export 'package:control_center/core/domain/services/slugify.dart';

/// Concrete implementation of [WorkspaceFilesystemPort] using the local filesystem.
class WorkspaceFilesystemService implements WorkspaceFilesystemPort {
  @override
  Future<Directory> workspaceDir(String workspaceId) async {
    final cc = await controlCenterRootDir();
    return Directory(p.join(cc.path, workspaceId));
  }

  @override
  Future<Directory> conversationsDir(String workspaceId) async {
    final ws = await workspaceDir(workspaceId);
    return Directory(p.join(ws.path, 'conversations'));
  }

  @override
  Future<Directory> conversationDir(
    String workspaceId,
    String conversationId,
  ) async {
    final root = await conversationsDir(workspaceId);
    return Directory(p.join(root.path, conversationId));
  }

  @override
  Future<Directory> ensureConversationDir(
    String workspaceId,
    String conversationId,
  ) async {
    final dir = await conversationDir(workspaceId, conversationId);
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  @override
  Future<Directory> skillsDir(String workspaceId) async {
    final ws = await workspaceDir(workspaceId);
    return Directory(p.join(ws.path, 'skills'));
  }

  @override
  Future<Directory> skillDir(String workspaceId, String skillSlug) async {
    final dir = await skillsDir(workspaceId);
    return Directory(p.join(dir.path, skillSlug));
  }

  @override
  Future<String> skillFilePath(String workspaceId, String skillSlug) async {
    final dir = await skillDir(workspaceId, skillSlug);
    return p.join(dir.path, 'SKILL.md');
  }

  @override
  Future<Directory> agentsDir(String workspaceId) async {
    final ws = await workspaceDir(workspaceId);
    return Directory(p.join(ws.path, 'agents'));
  }

  @override
  Future<Directory> agentDir(String workspaceId, String agentSlug) async {
    final dir = await agentsDir(workspaceId);
    return Directory(p.join(dir.path, agentSlug));
  }

  @override
  Future<String> agentFilePath(String workspaceId, String agentSlug) async {
    final dir = await agentDir(workspaceId, agentSlug);
    return p.join(dir.path, 'AGENTS.md');
  }

  @override
  Future<Directory> agentSkillsLinkDir(
    String workspaceId,
    String agentSlug,
  ) async {
    final dir = await agentDir(workspaceId, agentSlug);
    return Directory(p.join(dir.path, '.agents', 'skills'));
  }

  @override
  Future<void> ensureWorkspaceDirs(String workspaceId) async {
    final ws = await workspaceDir(workspaceId);
    if (!ws.existsSync()) {
      await ws.create(recursive: true);
    }
    final skills = Directory(p.join(ws.path, 'skills'));
    if (!skills.existsSync()) {
      await skills.create(recursive: true);
    }
    final agents = Directory(p.join(ws.path, 'agents'));
    if (!agents.existsSync()) {
      await agents.create(recursive: true);
    }
  }

  @override
  Future<void> ensureAgentDir(String workspaceId, String agentSlug) async {
    final dir = await agentDir(workspaceId, agentSlug);
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    await ensureMcpSymlink(workspaceId, agentSlug);
  }

  @override
  Future<void> ensureMcpSymlink(String workspaceId, String agentSlug) async {
    final dir = await agentDir(workspaceId, agentSlug);
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }

    final mcpFile = await _ensureMcpJson(workspaceId);
    final linkPath = p.join(dir.path, '.mcp.json');

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
    final ws = await workspaceDir(workspaceId);
    final root = ws.parent;
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
    final dir = await agentDir(workspaceId, agentSlug);
    if (dir.existsSync()) {
      await dir.delete(recursive: true);
    }
  }

  @override
  Future<List<String>> listAgentSlugs(String workspaceId) async {
    final dir = await agentsDir(workspaceId);
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
    final linksDir = await agentSkillsLinkDir(workspaceId, agentSlug);
    if (!linksDir.existsSync()) {
      await linksDir.create(recursive: true);
    }

    final existing = linksDir.listSync().whereType<Link>().map(
      (l) => p.basename(l.path),
    );
    final existingSet = existing.toSet();
    final wantedSet = skillSlugs.toSet();

    for (final slug in existingSet.difference(wantedSet)) {
      final link = Link(p.join(linksDir.path, slug));
      if (link.existsSync()) {
        await link.delete();
      }
    }

    for (final slug in wantedSet) {
      final link = Link(p.join(linksDir.path, slug));
      final target = (await skillDir(workspaceId, slug)).path;
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
    final dir = await skillDir(workspaceId, skillSlug);
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    final file = File(await skillFilePath(workspaceId, skillSlug));
    await file.writeAsString(content);
  }

  @override
  Future<File?> readSkillFile(String workspaceId, String skillSlug) async {
    final path = await skillFilePath(workspaceId, skillSlug);
    final file = File(path);
    if (file.existsSync()) {
      return file;
    }

    return null;
  }

  @override
  Future<void> deleteSkillDir(String workspaceId, String skillSlug) async {
    final dir = await skillDir(workspaceId, skillSlug);
    if (dir.existsSync()) {
      await dir.delete(recursive: true);
    }
  }

  @override
  Future<List<String>> listSkillSlugs(String workspaceId) async {
    final dir = await skillsDir(workspaceId);
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
  Future<Directory> prCloneDir(
    String workspaceId,
    String owner,
    String repo,
  ) async {
    final ws = await workspaceDir(workspaceId);
    // Sanitize owner/repo to avoid path injection; replace any non-alphanumeric
    // characters (except `-` and `.`) with `_`.
    final safeName = '${_sanitize(owner)}__${_sanitize(repo)}';
    final dir = Directory(p.join(ws.path, 'pr_clones', safeName));
    return dir;
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
    final ws = await workspaceDir(workspaceId);
    if (!ws.existsSync()) {
      await ws.create(recursive: true);
    }
    // Lowercase the extension to keep filenames stable across platforms; if
    // none is present, drop the dot so we just write `logo` (rare for picked
    // images, but handle it defensively).
    final ext = p.extension(sourcePath).toLowerCase();
    final destName = ext.isEmpty ? 'logo' : 'logo$ext';
    final dest = File(p.join(ws.path, destName));
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
