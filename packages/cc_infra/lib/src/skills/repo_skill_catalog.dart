import 'dart:io';

import 'package:cc_domain/features/skills/domain/ports/skill_scan_port.dart';
import 'package:cc_domain/features/skills/domain/scanner/skill_scan_types.dart';
import 'package:cc_harness_runtime/cc_harness_runtime.dart';
import 'package:path/path.dart' as p;

/// One skill a repo in the space ships, with the repo it came from.
class RepoSkillEntry {
  /// Creates a [RepoSkillEntry].
  const RepoSkillEntry({
    required this.repo,
    required this.slug,
    required this.name,
    required this.description,
    required this.dir,
  });

  /// The repo directory name under `<spaceRoot>/repos/`.
  final String repo;

  /// The skill's directory name.
  final String slug;

  /// Frontmatter `name`, falling back to [slug].
  final String name;

  /// Frontmatter `description`.
  final String description;

  /// Absolute path to the skill directory inside the worktree.
  final String dir;

  /// Absolute path to the skill's `SKILL.md`.
  String get path => p.join(dir, 'SKILL.md');

  /// The name a human types to invoke this skill explicitly, qualified by its
  /// repo so two repos may each ship a `testing`.
  ///
  /// Mirrors the directory-qualified form the wider ecosystem settled on
  /// (`apps/web:deploy`), so the disambiguation looks familiar rather than
  /// invented here.
  String get qualifiedName => '$repo:$name';
}

/// What every repo in a space ships, behind the supply-chain scan gate.
///
/// Shared by the two things that need it and must never disagree: the projector
/// that materializes ONE repo's skills for the agent, and the RPC that lists
/// ALL of them for the composer's slash palette. If they used separate gates,
/// the palette could offer a name the server then refuses to load — the exact
/// failure mode the workspace skills already had.
///
/// The asymmetry between the two is deliberate. An agent gets only the repo it
/// is working in, because an always-present index costs context on every turn
/// and a sibling service's `testing` skill is actively misleading. A human
/// naming a skill is an explicit act with no such cost, so the composer reaches
/// any repo — qualified by repo name when it needs disambiguating.
class RepoSkillCatalog {
  /// Creates a [RepoSkillCatalog].
  ///
  /// [scanner] is the mandatory gate: a repo is cloned content and its skills
  /// reach a prompt, so they pass the same verdict an installed skill does.
  /// Null yields nothing at all rather than ungated content.
  RepoSkillCatalog({
    required this.workspaceId,
    required this.reposDir,
    SkillScanPort? scanner,
    void Function(String message)? onWarning,
  }) : _scanner = scanner,
       _onWarning = onWarning;

  /// The workspace the space belongs to; scopes the scanner's result cache.
  final String workspaceId;

  /// The space's shared worktree directory (`<spaceRoot>/repos`).
  final String reposDir;

  final SkillScanPort? _scanner;
  final void Function(String message)? _onWarning;

  /// Verdict memo, keyed by `<repo>/<slug>`. Without it a run that moves back
  /// and forth between two repos re-scans the same unchanged files on every
  /// switch.
  final Map<String, bool> _admitted = {};

  /// The repo directory names checked out in this space.
  List<String> repos() {
    try {
      return [
        for (final entity in Directory(reposDir).listSync(followLinks: false))
          if (entity is Directory) p.basename(entity.path),
      ]..sort();
    } on FileSystemException catch (e) {
      _onWarning?.call('RepoSkillCatalog: cannot list $reposDir: $e');
      return const [];
    }
  }

  /// Every admitted skill across every repo in the space.
  Future<List<RepoSkillEntry>> listAll() async {
    final all = <RepoSkillEntry>[];
    for (final repo in repos()) {
      all.addAll(await forRepo(repo));
    }
    return all;
  }

  /// [repo]'s admitted skills, and the slugs the gate withheld.
  Future<({List<RepoSkillEntry> admitted, List<String> withheld})> inspect(
    String repo,
  ) async {
    final root = Directory(p.join(reposDir, repo));
    if (!root.existsSync()) {
      return (admitted: const <RepoSkillEntry>[], withheld: const <String>[]);
    }
    final admitted = <RepoSkillEntry>[];
    final withheld = <String>[];
    for (final entry in await _discover(repo, root.path)) {
      if (await _admits(entry)) {
        admitted.add(entry);
      } else {
        withheld.add(entry.slug);
      }
    }
    return (admitted: admitted, withheld: withheld);
  }

  /// [repo]'s admitted skills.
  Future<List<RepoSkillEntry>> forRepo(String repo) async =>
      (await inspect(repo)).admitted;

  /// Resolves a name to one skill, or null.
  ///
  /// Accepts the qualified `<repo>:<name>` form, and a bare name when exactly
  /// one repo ships it — an ambiguous bare name resolves to nothing rather than
  /// silently picking a repo, because the two are different instructions and
  /// guessing wrong is worse than saying so.
  Future<RepoSkillEntry?> resolve(String name) async {
    final colon = name.indexOf(':');
    if (colon > 0) {
      final repo = name.substring(0, colon);
      final skill = name.substring(colon + 1);
      for (final entry in await forRepo(repo)) {
        if (entry.name == skill || entry.slug == skill) {
          return entry;
        }
      }
      return null;
    }
    final matches = [
      for (final entry in await listAll())
        if (entry.name == name || entry.slug == name) entry,
    ];
    return matches.length == 1 ? matches.single : null;
  }

  /// The skills [repoRoot] ships, across every convention the scanner knows
  /// (`.agents/skills`, `.claude/skills`, `.opencode/skills`, `skills`).
  ///
  /// A repo commonly carries `.claude/skills → ../.agents/skills`, so the same
  /// skill is reachable under two spellings; the scanner's first-wins dedupe
  /// collapses them, and the slug dedupe here catches the case where two
  /// spellings disagree about a skill's frontmatter name.
  ///
  /// Links are gated to [repoRoot]: a skill entry pointing outside the worktree
  /// is not this repo's to contribute.
  Future<List<RepoSkillEntry>> _discover(String repo, String repoRoot) async {
    final infos = await const HarnessSkillScanner().scan(
      [repoRoot],
      permittedLinkRoots: [repoRoot],
    );
    final found = <String, RepoSkillEntry>{};
    for (final info in infos) {
      final dir = p.dirname(info.path);
      final slug = p.basename(dir);
      found.putIfAbsent(
        slug,
        () => RepoSkillEntry(
          repo: repo,
          slug: slug,
          name: info.name,
          description: info.description,
          dir: dir,
        ),
      );
    }
    return found.values.toList();
  }

  /// Whether the scan gate admits [entry]. Fail-closed: no scanner, or a
  /// scanner that throws, admits nothing.
  Future<bool> _admits(RepoSkillEntry entry) async {
    final scanner = _scanner;
    if (scanner == null) {
      return false;
    }
    final key = '${entry.repo}/${entry.slug}';
    final memo = _admitted[key];
    if (memo != null) {
      return memo;
    }
    var verdict = false;
    try {
      final result = await scanner.scan(
        SkillBundle(slug: entry.slug, files: _bundleFiles(entry.dir)),
        workspaceId: workspaceId,
        // Provenance only: the operator linked this repo, which is why its
        // skills are eligible at all. Never a reason to skip the scan.
        trustTier: SkillTrustTier.workspace,
        // Layers 1-2 only, matching the `create_skill` gate. This runs on the
        // dispatch path and again on every repo switch; an LLM review there
        // would put a model call in front of the agent's next turn.
        runLlmReview: false,
      );
      verdict = result.verdict.installable;
    } on Object catch (e) {
      _onWarning?.call(
        'RepoSkillCatalog: scan failed for ${entry.slug}, withholding: $e',
      );
      verdict = false;
    }
    _admitted[key] = verdict;
    return verdict;
  }

  /// The skill's files as the scanner wants them, bundle-relative.
  static Map<String, String> _bundleFiles(String dir) {
    final files = <String, String>{};
    for (final entity in Directory(
      dir,
    ).listSync(recursive: true, followLinks: false)) {
      if (entity is! File) {
        continue;
      }
      try {
        files[p.relative(entity.path, from: dir)] = entity.readAsStringSync();
      } on Object {
        // A binary or unreadable asset contributes no text to scan; the
        // verdict is about the instructions.
        continue;
      }
    }
    return files;
  }
}
