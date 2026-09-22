import 'dart:io';

import 'package:cc_domain/features/skills/domain/ports/skill_scan_port.dart';
import 'package:cc_harness_runtime/cc_harness_runtime.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';
import 'package:cc_infra/src/skills/repo_skill_catalog.dart';
import 'package:path/path.dart' as p;

/// The name Claude Code's Skill tool registers for one projected skill.
///
/// Each child of `.claude/skills` is one skill, and Claude names it after that
/// child. A slug only one repository ships keeps that slug (`rest-endpoints`).
/// A slug two repositories both ship is prefixed (`app-server:testing`) — the
/// spelling a directory-scoped skill already uses — so the bare name cannot
/// silently run the other repository's instructions. Windows file names cannot
/// contain `:`, so that host uses `repo__slug`; the prompt lists whichever
/// name was actually linked.
String repoSkillInvocationName({
  required String repo,
  required String slug,
  required bool shared,
}) {
  if (!shared) {
    return slug;
  }
  final separator = Platform.isWindows ? '__' : ':';
  return '$repo$separator$slug';
}

/// One skill linked into the overlay, under the name the Skill tool accepts.
class _LinkedSkill {
  const _LinkedSkill({required this.entry, required this.linkName});

  final RepoSkillEntry entry;
  final String linkName;

  HarnessSkillInfo infoAt(String linkPath) => HarnessSkillInfo(
    name: linkName,
    description: entry.description,
    path: p.join(linkPath, 'SKILL.md'),
  );
}

/// The outcome of one projection: what the space's repos now contribute.
class RepoSkillProjection {
  /// Creates a [RepoSkillProjection].
  const RepoSkillProjection({
    required this.repo,
    required this.skills,
    required this.quarantined,
  });

  /// An empty projection — the space has no repos, or none of them ship skills.
  static const RepoSkillProjection none = RepoSkillProjection(
    repo: null,
    skills: [],
    quarantined: [],
  );

  /// The repo whose instructions were inlined, or null when none is active.
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
  /// Written to supersede rather than accumulate: the previous repo's
  /// instructions are still sitting in the history and cannot be unsaid, so
  /// this says plainly that they no longer apply. Skills stay listed, because
  /// a skill from another checked-out repo is still invocable.
  String get announcement {
    if (repo == null && skills.isEmpty && quarantined.isEmpty) {
      return '';
    }
    final buffer = StringBuffer();
    final repoName = repo;
    if (repoName != null) {
      buffer.write(
        'You are now working in `repos/$repoName`. Its instructions apply. '
        'Instructions announced earlier for a different repository no longer '
        'apply.\n',
      );
    }
    buffer.write('\n${RepoSkillProjector.invocationBlurb}\n');
    if (skills.isEmpty) {
      buffer.write('\n(This space\'s repositories ship no skills.)');
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

/// Projects every checked-out repo's skills into the agent's overlay
/// (`.claude/skills`). Claude Code's Skill tool only loads that directory in
/// the working directory — a skill that lives under `repos/<name>/` is reached
/// through a symlink that leaves the overlay, and Claude refuses to load it.
/// Linking it here is what makes `rest-endpoints` resolvable in a space that
/// also has another repo checked out.
///
/// A slug only one repo ships is linked under that slug. A slug two repos both
/// ship is linked as `repo:slug`, so the bare name cannot run the wrong
/// repo's instructions. The active repo still decides whose root instructions
/// are inlined into `AGENTS.md`; it does not decide which skills exist.
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

  /// Cap on the repo section so one repo's instructions cannot consume the
  /// whole overlay `AGENTS.md`.
  static const int _maxRepoInstructionBytes = 24000;

  /// How a skill name in the prompt maps onto the Skill tool. Shared by the
  /// overlay `AGENTS.md` and the steering announcement so they cannot drift.
  static const String invocationBlurb =
      'Invoke a skill with the Skill tool using exactly the name shown, or '
      'by reading its SKILL.md. A skill only one repository ships keeps its '
      'own name — do not prefix it with the repository. A name shared by '
      'more than one repository is prefixed with that repository.';

  /// The directories the projection is written into, in the order the adapters
  /// read them.
  ///
  /// Deliberately NOT `.agents/skills`: in the overlay that path is itself a
  /// symlink to the agent's GLOBAL config dir, which is shared by every space
  /// the agent works in. Writing there would leak one space's repo skills into
  /// all the others and collide with `syncAgentSkillLinks`.
  static const List<String> projectedDirs = ['.claude/skills'];

  /// Links every repo's skills into the overlay, and inlines [activeRepo]'s
  /// instructions.
  ///
  /// A null or unknown [activeRepo] still links the skills; it only means no
  /// repository's root instructions are the ones that apply. Idempotent:
  /// re-projecting re-verifies the links.
  Future<RepoSkillProjection> project(String? activeRepo) async {
    final repoNames = catalog.repos();
    if (repoNames.isEmpty) {
      await _clear();
      _writeAgentsMd(null, const []);
      _projected = null;
      return RepoSkillProjection.none;
    }
    final active = repoNames.contains(activeRepo) ? activeRepo : null;
    if (activeRepo != null && activeRepo.isNotEmpty && active == null) {
      _onWarning?.call(
        'RepoSkillProjector: no worktree named $activeRepo under $reposDir',
      );
    }

    final admitted = <RepoSkillEntry>[];
    final quarantined = <String>[];
    for (final repo in repoNames) {
      final inspected = await catalog.inspect(repo);
      admitted.addAll(inspected.admitted);
      quarantined.addAll(inspected.withheld);
    }
    final slugCounts = <String, int>{};
    for (final skill in admitted) {
      slugCounts[skill.slug] = (slugCounts[skill.slug] ?? 0) + 1;
    }
    final linked =
        [
          for (final skill in admitted)
            _LinkedSkill(
              entry: skill,
              linkName: repoSkillInvocationName(
                repo: skill.repo,
                slug: skill.slug,
                shared: (slugCounts[skill.slug] ?? 0) > 1,
              ),
            ),
        ]..sort((a, b) {
          final byRepo = a.entry.repo.compareTo(b.entry.repo);
          if (byRepo != 0) {
            return byRepo;
          }
          return a.linkName.compareTo(b.linkName);
        });

    await _clear();
    final projected = <HarnessSkillInfo>[];
    final written = <_LinkedSkill>[];
    for (final dir in projectedDirs) {
      final target = Directory(p.join(overlayDir, dir))
        ..createSync(recursive: true);
      for (final skill in linked) {
        final linkPath = p.join(target.path, skill.linkName);
        try {
          Link(linkPath).createSync(skill.entry.dir);
        } on FileSystemException catch (e) {
          _onWarning?.call(
            'RepoSkillProjector: could not link ${skill.linkName}: $e',
          );
          continue;
        }
        if (dir == projectedDirs.first) {
          projected.add(skill.infoAt(linkPath));
          written.add(skill);
        }
      }
    }
    _writeAgentsMd(active, written);
    _projected = active;
    if (quarantined.isNotEmpty) {
      CcInfraLog.warning(
        'RepoSkillProjector: withheld ${quarantined.length} skill(s): '
        '${quarantined.join(', ')}',
      );
    }
    return RepoSkillProjection(
      repo: active,
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
  /// The built-in harness and Claude Code both read this file. Replacing the
  /// provisioner's symlink is safe and self-healing: `_ensureSymlink` deletes
  /// a plain file and re-links on the next dispatch, which runs before this
  /// does.
  void _writeAgentsMd(String? repo, List<_LinkedSkill> skills) {
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
    if (repo != null || skills.isNotEmpty) {
      if (base.isNotEmpty) {
        buffer.write('\n\n');
      }
    }
    if (repo != null) {
      buffer.write('# Active repository: $repo\n\n');
      buffer.write(
        'You are working in `repos/$repo`. The instructions below are that '
        'repository\'s. Skills from every repository checked out in this '
        'space are listed after them and stay invocable whichever repository '
        'is active.\n',
      );
      final instructions = _repoInstructions(repo);
      if (instructions.isNotEmpty) {
        buffer.write('\n$instructions\n');
      }
    }
    if (skills.isNotEmpty) {
      buffer.write('\n## Skills\n\n');
      buffer.write('${RepoSkillProjector.invocationBlurb}\n');
      String? currentRepo;
      for (final skill in skills) {
        if (skill.entry.repo != currentRepo) {
          currentRepo = skill.entry.repo;
          buffer.write('\n### ${skill.entry.repo}\n');
        }
        final desc = skill.entry.description.isEmpty
            ? ''
            : ' — ${skill.entry.description}';
        final path = p.join(
          overlayDir,
          projectedDirs.first,
          skill.linkName,
          'SKILL.md',
        );
        buffer.write('\n- ${skill.linkName}$desc ($path)');
      }
      buffer.write('\n');
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
