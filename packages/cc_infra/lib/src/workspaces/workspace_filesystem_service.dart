import 'dart:io';

import 'package:cc_infra/src/ports/workspace_filesystem_port.dart';
import 'package:cc_infra/src/util/cc_paths.dart';
import 'package:path/path.dart' as p;

/// Re-exports `slugify` from the domain layer.
export 'package:cc_domain/core/domain/services/slugify.dart';

/// Decides whether [skillSlug] may be symlinked into an agent's prompt-visible
/// `.agents/skills` dir. Wired by the server to the skills-antivirus quarantine
/// verdicts; returning false drops the slug from the reconcile, which both
/// refuses to create its link and DELETES an existing one (PRD 23 §6
/// enforcement at the chokepoint — no caller can link a quarantined skill).
typedef SkillLinkFilter =
    Future<bool> Function(String workspaceId, String skillSlug);

/// Concrete implementation of [WorkspaceFilesystemPort] using the local filesystem.
///
/// The port is `dart:io`-free (paths/content as `String`), so all `dart:io`
/// usage is confined to this desktop/server-side implementation.
class WorkspaceFilesystemService implements WorkspaceFilesystemPort {
  /// Creates a service rooted at [_paths] (the app/server on-disk layout).
  /// [linkFilter] optionally gates which skills may be agent-linked.
  WorkspaceFilesystemService(this._paths, {SkillLinkFilter? linkFilter})
    : _linkFilter = linkFilter;

  final CcPaths _paths;
  SkillLinkFilter? _linkFilter;

  /// The quarantine gate for agent skill links. Attachable post-construction
  /// because the verdict source (`SkillBundleService`) is itself constructed
  /// over this service — the runtime wires it once the lock reader exists
  /// (same late-attach shape as `SkillScannerAdapter.llmReview`).
  set linkFilter(SkillLinkFilter? filter) => _linkFilter = filter;

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
  }

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

    // Quarantine chokepoint: filter BEFORE reconciling, so a refused slug both
    // never gains a link and loses one it already has.
    var allowed = skillSlugs;
    final filter = _linkFilter;
    if (filter != null) {
      final permitted = <String>[];
      for (final slug in skillSlugs) {
        if (await filter(workspaceId, slug)) {
          permitted.add(slug);
        }
      }
      allowed = permitted;
    }

    // followLinks:false is REQUIRED: with following on (the default), a
    // symlink to a skill DIRECTORY is yielded as a Directory, not a Link, so
    // `whereType<Link>` would see nothing and stale links would never be
    // deleted.
    final existing = linksDir
        .listSync(followLinks: false)
        .whereType<Link>()
        .map((l) => p.basename(l.path));
    final existingSet = existing.toSet();
    final wantedSet = allowed.toSet();

    for (final slug in existingSet.difference(wantedSet)) {
      final path = p.join(linksDirPath, slug);
      // Identify the link WITHOUT following it: a dangling link reports
      // existsSync() == false (the target is gone) and would otherwise be
      // leaked forever.
      if (FileSystemEntity.typeSync(path, followLinks: false) ==
          FileSystemEntityType.link) {
        await Link(path).delete();
      }
    }

    for (final slug in wantedSet) {
      final link = Link(p.join(linksDirPath, slug));
      final target = await skillDir(workspaceId, slug);
      if (FileSystemEntity.typeSync(link.path, followLinks: false) ==
          FileSystemEntityType.notFound) {
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
  Future<String?> persistLogoBytes(
    String workspaceId,
    List<int> bytes,
    String extension,
  ) async {
    if (bytes.isEmpty) {
      return null;
    }
    final wsPath = await workspaceDir(workspaceId);
    final ws = Directory(wsPath);
    if (!ws.existsSync()) {
      await ws.create(recursive: true);
    }
    final ext = extension.toLowerCase();
    final destName = ext.isEmpty ? 'logo' : 'logo$ext';
    final dest = File(p.join(wsPath, destName));
    await dest.writeAsBytes(bytes, flush: true);
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
