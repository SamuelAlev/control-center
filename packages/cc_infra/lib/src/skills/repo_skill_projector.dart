import 'dart:io';

import 'package:cc_domain/features/skills/domain/ports/skill_scan_port.dart';
import 'package:cc_harness_runtime/cc_harness_runtime.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';
import 'package:cc_infra/src/skills/repo_skill_catalog.dart';
import 'package:path/path.dart' as p;

/// The outcome of one projection: what the active repo now contributes.
class RepoSkillProjection {
  /// Creates a [RepoSkillProjection].
  const RepoSkillProjection({
    required this.repo,
    required this.skills,
    required this.quarantined,
  });

  /// An empty projection — no repo is active, or it ships no skills.
  static const RepoSkillProjection none = RepoSkillProjection(
    repo: null,
    skills: [],
    quarantined: [],
  );

  /// The repo directory name these skills came from, or null when none is
  /// active.
  final String? repo;

  /// The projected skills, as the agent will see them.
  final List<HarnessSkillInfo> skills;

  /// Slugs the scan gate refused. Kept so the refusal can be logged and shown
  /// rather than silently looking like "this repo has no skills".
  final List<String> quarantined;

  /// Whether anything was projected.
  bool get isEmpty => skills.isEmpty;

  /// The block announcing this projection to a running agent.
  ///
  /// Written to supersede rather than accumulate: the previous repo's index is
  /// still sitting in the history and cannot be unsaid, so this says plainly
  /// that it no longer applies.
  String get announcement {
    final repoName = repo;
    if (repoName == null) {
      return '';
    }
    final buffer = StringBuffer(
      'You are now working in `repos/$repoName`. Its skills are listed '
      'below and are the ones that apply. Any repo skills announced '
      'earlier in this conversation belong to a different repo and no '
      'longer apply.\n',
    );
    if (skills.isEmpty) {
      buffer.write('\n(This repo ships no skills.)');
    }
    for (final skill in skills) {
      final desc = skill.description.isEmpty ? '' : ' — ${skill.description}';
      buffer.write('\n- ${skill.name}$desc (${skill.path})');
    }
    if (quarantined.isNotEmpty) {
      buffer.write(
        '\n\nWithheld by the skill scanner: ${quarantined.join(', ')}.',
      );
    }
    return buffer.toString();
  }
}

/// Materializes ONE repo's skills into the agent's overlay, so every adapter
/// sees them through the discovery path it already has.
///
/// The agent's cwd is its overlay (`<spaceRoot>/agents/<slug>/`) and the repos
/// are checked out two levels away behind a `repos → ../../repos` symlink, so
/// no adapter finds what a repo ships for agents: Claude Code looks in
/// `.claude/skills` at the cwd and its parents, OpenCode in `.opencode/skills`,
/// the built-in harness scans a fixed list of bases, and Codex reads only the
/// `AGENTS.md` chain from the git root down. Writing the active repo's skills
/// into the overlay puts them on all four paths at once, with no per-adapter
/// flags — and Claude Code watches its project skills directory, so a swap
/// lands mid-session without restarting the CLI.
///
/// Only the ACTIVE repo is ever projected. Listing every repo's skills at once
/// is both wrong (a `testing` skill from one service does not describe another)
/// and expensive: the index sits in context permanently while the bodies do
/// not, and a handful of repos is enough to push it past the size where tool
/// and skill selection stays reliable.
class RepoSkillProjector {
  /// Creates a [RepoSkillProjector].
  ///
  /// [scanner] is the mandatory supply-chain gate. A repo is cloned content
  /// and its skill frontmatter is autoloaded into a prompt, so it goes through
  /// the same verdict every installed skill does. Null disables projection
  /// entirely rather than projecting ungated content.
  RepoSkillProjector({
    required this.workspaceId,
    required this.overlayDir,
    required this.reposDir,
    SkillScanPort? scanner,
    void Function(String message)? onWarning,
  }) : _onWarning = onWarning,
       catalog = RepoSkillCatalog(
         workspaceId: workspaceId,
         reposDir: reposDir,
         scanner: scanner,
         onWarning: onWarning,
       );

  /// The workspace the run belongs to; scopes the scanner's result cache.
  final String workspaceId;

  /// The agent's overlay — its working directory, and where the projected
  /// skills dirs are written.
  final String overlayDir;

  /// The space's shared worktree directory (`<spaceRoot>/repos`).
  final String reposDir;

  /// What the space's repos ship, behind the scan gate. Exposed so the session
  /// can resolve a human's explicitly-named `<repo>:<skill>` against the SAME
  /// gate and the SAME memo the projection uses.
  final RepoSkillCatalog catalog;

  final void Function(String message)? _onWarning;

  String? _projected;

  /// The overlay's `AGENTS.md` as the provisioner left it (a symlink to the
  /// agent's global profile), captured before the first compose.
  ///
  /// Cached because the composed file REPLACES that symlink: re-reading it on
  /// the second switch of a run would fold the previous repo's section back in
  /// and compound on every switch after that.
  String? _baseProfile;

  /// Whether this projector wrote the overlay's `AGENTS.md`, so a later switch
  /// may rewrite it. Without this, the second projection of a run would see a
  /// real file and refuse to touch its own output.
  bool _ownsAgentsMd = false;

  /// Cap on the repo section. Codex concatenates its whole `AGENTS.md` chain
  /// under a 32 KiB budget, so one repo's instructions must not consume it.
  static const int _maxRepoInstructionBytes = 24000;

  /// The directories the projection is written into, in the order the adapters
  /// read them.
  ///
  /// Deliberately NOT `.agents/skills`: in the overlay that path is itself a
  /// symlink to the agent's GLOBAL config dir, which is shared by every space
  /// the agent works in. Writing there would leak one space's repo skills into
  /// all the others and collide with `syncAgentSkillLinks`.
  static const List<String> projectedDirs = [
    '.claude/skills',
    '.opencode/skills',
  ];

  /// Projects [activeRepo]'s skills, replacing whatever was projected before.
  ///
  /// A null [activeRepo] clears the projection. Idempotent: re-projecting the
  /// same repo re-verifies the links and rewrites nothing else.
  Future<RepoSkillProjection> project(String? activeRepo) async {
    if (activeRepo == null || activeRepo.isEmpty) {
      await _clear();
      _writeAgentsMd(null, const []);
      _projected = null;
      return RepoSkillProjection.none;
    }
    final repoRoot = Directory(p.join(reposDir, activeRepo));
    if (!repoRoot.existsSync()) {
      _onWarning?.call('RepoSkillProjector: no worktree at ${repoRoot.path}');
      await _clear();
      _writeAgentsMd(null, const []);
      _projected = null;
      return RepoSkillProjection.none;
    }

    final inspected = await catalog.inspect(activeRepo);
    final admitted = inspected.admitted;
    final quarantined = inspected.withheld;

    await _clear();
    final projected = <HarnessSkillInfo>[];
    for (final dir in projectedDirs) {
      final target = Directory(p.join(overlayDir, dir))
        ..createSync(recursive: true);
      for (final skill in admitted) {
        final linkPath = p.join(target.path, skill.slug);
        try {
          Link(linkPath).createSync(skill.dir);
        } on FileSystemException catch (e) {
          _onWarning?.call(
            'RepoSkillProjector: could not link ${skill.slug}: $e',
          );
          continue;
        }
        if (dir == projectedDirs.first) {
          projected.add(
            HarnessSkillInfo(
              name: skill.name,
              description: skill.description,
              path: p.join(linkPath, 'SKILL.md'),
            ),
          );
        }
      }
    }
    _writeAgentsMd(activeRepo, projected);
    _projected = activeRepo;
    if (quarantined.isNotEmpty) {
      CcInfraLog.warning(
        'RepoSkillProjector: withheld ${quarantined.length} skill(s) from '
        '$activeRepo: ${quarantined.join(', ')}',
      );
    }
    return RepoSkillProjection(
      repo: activeRepo,
      skills: projected,
      quarantined: quarantined,
    );
  }

  /// The repo currently projected, or null.
  String? get projectedRepo => _projected;

  /// The permitted-link roots the context loaders need in order to follow what
  /// this projector writes (the links point into the worktrees).
  List<String> get permittedLinkRoots => [reposDir];

  /// Rewrites the overlay's `AGENTS.md` as a REAL file carrying the agent's
  /// profile plus the active repo's instructions and skill index.
  ///
  /// This is the Codex lane, and it cannot be served by the projected skills
  /// dirs: Codex has no notion of a skill at all. It builds its instructions by
  /// concatenating the `AGENTS.md` chain from the git root down to the cwd, and
  /// the overlay is not inside a git repo — so the ONE file it will ever read
  /// here is this one. The other adapters are unaffected: the harness reads it
  /// too (a superset of what it had), and Claude Code and OpenCode take the
  /// skills from their own directories.
  ///
  /// Replacing the provisioner's symlink is safe and self-healing:
  /// `_ensureSymlink` deletes a plain file and re-links on the next dispatch,
  /// which runs before this does.
  void _writeAgentsMd(String? repo, List<HarnessSkillInfo> skills) {
    final file = File(p.join(overlayDir, 'AGENTS.md'));
    // Only ever replace the provisioner's SYMLINK, an absent file, or a file
    // this projector already wrote. Anything else is a real file somebody else
    // owns — on the fallback dispatch path the "overlay" IS the agent's global
    // config dir, where this name holds the agent's own profile and
    // overwriting it would destroy it for every space. That path never reaches
    // here today (it has no worktrees, so no projector is built), but the cost
    // of being wrong is data loss, so the guard is explicit rather than
    // inherited from a caller's control flow.
    if (!_ownsAgentsMd &&
        FileSystemEntity.typeSync(file.path, followLinks: false) ==
            FileSystemEntityType.file) {
      _onWarning?.call(
        'RepoSkillProjector: ${file.path} is a real file this projector did '
        'not write; leaving it alone',
      );
      return;
    }
    final base = _baseProfile ??= _readBaseProfile(file);
    final buffer = StringBuffer(base);
    if (repo != null) {
      if (base.isNotEmpty) {
        buffer.write('\n\n');
      }
      buffer.write('# Active repository: $repo\n\n');
      buffer.write(
        'You are working in `repos/$repo`. The instructions and skills below '
        'are that repo\'s and are the ones that apply. Other repos checked out '
        'in this space have their own and they do not apply here.\n',
      );
      final instructions = _repoInstructions(repo);
      if (instructions.isNotEmpty) {
        buffer.write('\n$instructions\n');
      }
      if (skills.isNotEmpty) {
        buffer.write('\n## Skills in `repos/$repo`\n\n');
        buffer.write('Load one by reading its SKILL.md.\n');
        for (final skill in skills) {
          final desc = skill.description.isEmpty
              ? ''
              : ' — ${skill.description}';
          buffer.write('\n- ${skill.name}$desc (${skill.path})');
        }
        buffer.write('\n');
      }
    }
    try {
      file.parent.createSync(recursive: true);
      // The entry is a SYMLINK to the agent's global profile, and a write
      // follows it — which would edit that profile in place, corrupting it for
      // every other space the agent works in. Unlink first, then write a
      // regular file over the empty name.
      if (FileSystemEntity.isLinkSync(file.path)) {
        Link(file.path).deleteSync();
      }
      file.writeAsStringSync(buffer.toString());
      _ownsAgentsMd = true;
    } on FileSystemException catch (e) {
      _onWarning?.call('RepoSkillProjector: could not write AGENTS.md: $e');
    }
  }

  /// The agent profile the provisioner linked in, read through the symlink.
  static String _readBaseProfile(File file) {
    try {
      return file.existsSync() ? file.readAsStringSync().trimRight() : '';
    } on FileSystemException {
      return '';
    }
  }

  /// The active repo's own root `AGENTS.md`, capped.
  String _repoInstructions(String repo) {
    for (final name in const ['AGENTS.md', 'CLAUDE.md']) {
      final file = File(p.join(reposDir, repo, name));
      if (!file.existsSync()) {
        continue;
      }
      try {
        final content = file.readAsStringSync().trimRight();
        if (content.isEmpty) {
          continue;
        }
        return content.length > _maxRepoInstructionBytes
            ? '${content.substring(0, _maxRepoInstructionBytes)}\n…(truncated)'
            : content;
      } on FileSystemException {
        continue;
      }
    }
    return '';
  }

  /// Removes every previously projected link, leaving any directory the agent
  /// or another mechanism owns untouched.
  Future<void> _clear() async {
    for (final dir in projectedDirs) {
      final target = Directory(p.join(overlayDir, dir));
      if (!target.existsSync()) {
        continue;
      }
      for (final child in target.listSync(followLinks: false)) {
        // Only ever delete LINKS. A real directory here was not put there by
        // this projector and is not ours to remove.
        if (!FileSystemEntity.isLinkSync(child.path)) {
          continue;
        }
        try {
          Link(child.path).deleteSync();
        } on FileSystemException {
          // Best-effort: a link we cannot remove is logged by the next scan.
          continue;
        }
      }
    }
  }
}
