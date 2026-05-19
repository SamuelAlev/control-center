import 'package:cc_domain/cc_domain.dart' show NetworkException;
import 'package:cc_domain/features/skills/domain/ports/skill_source_port.dart';
import 'package:cc_infra/src/network/github_api_client.dart';

/// [SkillSourcePort] over the GitHub REST API: the skill catalogs of
/// repositories the operator registered as sources.
///
/// A "skill" in a source repository is a directory containing a `SKILL.md`
/// — the same convention the workspace skills dir, the agent-overlay
/// scanners, `.agents/skills`-style repos and Claude plugin marketplaces
/// (`plugins/<plugin>/skills/<slug>`) use — discovered via one recursive
/// git-trees call. Repository metadata is UNTRUSTED display data — the trusted
/// artifact is the bytes [resolve] returns, which the caller still runs
/// through the mandatory scan gate.
///
/// All network traffic is bounded by construction: the skill count per repo
/// ([maxSkills]) and the file count per skill ([maxFilesPerSkill]) are capped,
/// binary files are never fetched, and the `SKILL.md` frontmatter probes run
/// in small parallel batches.
class GitHubSkillSourceAdapter implements SkillSourcePort {
  /// Creates a [GitHubSkillSourceAdapter] over the host's GitHub client.
  GitHubSkillSourceAdapter(this._client);

  final GitHubApiClient _client;

  /// Cap on the number of skills listed per repository.
  static const int maxSkills = 60;

  /// Cap on the files fetched for one skill directory.
  static const int maxFilesPerSkill = 40;

  /// How many `SKILL.md` frontmatter probes fly in parallel.
  static const int _probeBatchSize = 6;

  /// Directory names never scanned for skills (dependency/vendor trees).
  static const Set<String> _skippedDirs = {'node_modules', 'vendor', '.git'};

  /// Whether [dir] (the directory containing a `SKILL.md`) is a skill
  /// directory by one of the ecosystem's layouts:
  ///
  /// - shallow: any grouping up to three levels deep — `skills/<slug>`,
  ///   `document-skills/<slug>`, `.agents/skills/<slug>`, …
  /// - plugin: exactly `<group>/skills/<slug>` at four levels — the Claude
  ///   plugin-marketplace layout (`plugins/<plugin>/skills/<slug>/SKILL.md`).
  ///   Anything else four deep is a monorepo we should not treat as one
  ///   catalog.
  static bool _isSkillDir(String dir) {
    final depth = _dirDepth(dir);
    if (depth >= 1 && depth <= 3) {
      return true;
    }
    if (depth == 4) {
      final segments = dir.split('/');
      return segments[2] == 'skills';
    }
    return false;
  }

  /// Extensions never fetched as part of a skill bundle (binary assets — the
  /// scan gate and the lock hash text, and a skill is documentation and small
  /// scripts, not datasets).
  static const Set<String> _binaryExtensions = {
    '.png', '.jpg', '.jpeg', '.gif', '.webp', '.ico', '.bmp', '.svgz',
    '.pdf', '.zip', '.gz', '.tar', '.tgz', '.bz2', '.7z', '.rar',
    '.woff', '.woff2', '.ttf', '.otf', '.eot',
    '.mp3', '.mp4', '.mov', '.avi', '.webm', '.wav', '.flac',
    '.dylib', '.so', '.dll', '.exe', '.bin', '.wasm', '.class',
    '.onnx', '.db', '.sqlite',
  };

  @override
  Future<SkillSourceRepoSnapshot> repoSnapshot(
    String owner,
    String repo,
  ) async {
    final summary = await _client.content.getRepoSummary(owner, repo);
    return SkillSourceRepoSnapshot(
      owner: owner,
      repo: repo,
      description: summary.description,
      defaultBranch: summary.defaultBranch,
      starCount: summary.starCount,
    );
  }

  @override
  Future<List<SourceSkillListing>> listSkills(
    String owner,
    String repo, {
    String? ref,
  }) async {
    final branch = ref ?? (await repoSnapshot(owner, repo)).defaultBranch;
    if (branch.isEmpty) {
      return const [];
    }
    final tree = await _client.content.listTree(owner, repo, branch);
    final seenSlugs = <String>{};
    final candidates = <_Candidate>[];
    for (final entry in tree) {
      if (entry.type != 'blob' || !_isSkillMdPath(entry.path)) {
        continue;
      }
      final dir = _dirOf(entry.path);
      // A root SKILL.md is the repository's own, not a skill.
      if (dir.isEmpty || !_isSkillDir(dir)) {
        continue;
      }
      if (dir.split('/').any(_skippedDirs.contains)) {
        continue;
      }
      final slug = dir.split('/').last;
      // The same skill can ship at two conventional roots (`.agents/skills/x`
      // and `skills/x`); the install slug is the directory basename, so keep
      // the first occurrence only.
      if (!seenSlugs.add(slug)) {
        continue;
      }
      candidates.add(_Candidate(skillFilePath: entry.path, slug: slug));
      if (candidates.length >= maxSkills) {
        break;
      }
    }
    candidates.sort((a, b) => a.slug.compareTo(b.slug));

    // Probe each candidate's SKILL.md frontmatter in small parallel batches
    // so one listing costs bounded, not bursty, traffic.
    final listings = <SourceSkillListing>[];
    for (var i = 0; i < candidates.length; i += _probeBatchSize) {
      final batch = candidates.skip(i).take(_probeBatchSize);
      final probed = await Future.wait(
        batch.map((c) => _probeListing(owner, repo, c, branch)),
      );
      listings.addAll(probed);
    }
    return listings;
  }

  Future<SourceSkillListing> _probeListing(
    String owner,
    String repo,
    _Candidate candidate,
    String ref,
  ) async {
    var name = candidate.slug;
    var description = '';
    try {
      final content = await _client.content.getFileContent(
        owner,
        repo,
        candidate.skillFilePath,
        ref,
      );
      final front = _parseFrontmatter(content);
      final frontName = front['name'];
      if (frontName != null && frontName.isNotEmpty) {
        name = frontName;
      }
      description = front['description'] ?? '';
    } on Object {
      // The listing keeps its slug-derived defaults — frontmatter is display
      // polish, never worth failing a catalog over.
    }
    return SourceSkillListing(
      slug: candidate.slug,
      name: name,
      description: description,
      skillFilePath: candidate.skillFilePath,
    );
  }

  @override
  Future<SourceSkillFiles> resolve(
    String owner,
    String repo,
    String skillFilePath, {
    String? ref,
  }) async {
    // Pin the fetch to a commit: the latest one touching the skill when the
    // caller did not name a ref, or the caller's ref when it is already a
    // commit SHA.
    var usedRef = ref;
    if (usedRef == null || !_isCommitSha(usedRef)) {
      final latest = await _client.content.getLatestCommitSha(
        owner,
        repo,
        skillFilePath,
        branch: usedRef,
      );
      if (latest != null && latest.isNotEmpty) {
        usedRef = latest;
      } else if (usedRef == null) {
        throw NetworkException(
          'No commit found for $owner/$repo/$skillFilePath',
          code: 'skill_ref_not_found',
        );
      }
    }

    final dir = _dirOf(skillFilePath);
    final files = <String, String>{};
    if (dir.isEmpty) {
      // A repo-root SKILL.md has no directory to bundle — resolve it as the
      // single file it is.
      files['SKILL.md'] = await _client.content.getFileContent(
        owner,
        repo,
        skillFilePath,
        usedRef,
      );
    } else {
      final tree = await _client.content.listTree(owner, repo, usedRef);
      final prefix = '$dir/';
      final wanted = <({String path, String rel})>[];
      for (final entry in tree) {
        if (entry.type != 'blob' || !entry.path.startsWith(prefix)) {
          continue;
        }
        final rel = entry.path.substring(prefix.length);
        if (rel.isEmpty ||
            rel.startsWith('.') ||
            rel == 'skills-lock.json' ||
            _isBinaryPath(rel)) {
          continue;
        }
        wanted.add((path: entry.path, rel: rel));
        if (wanted.length >= maxFilesPerSkill) {
          break;
        }
      }
      for (final w in wanted) {
        files[w.rel] = await _client.content.getFileContent(
          owner,
          repo,
          w.path,
          usedRef,
        );
      }
    }
    if (files['SKILL.md'] == null) {
      throw NetworkException(
        'No SKILL.md found at $owner/$repo/$skillFilePath',
        code: 'skill_md_missing',
      );
    }
    return SourceSkillFiles(
      files: files,
      ref: usedRef,
      readme: _readmeFor(files),
    );
  }

  static String _readmeFor(Map<String, String> files) {
    final readme = files['README.md'] ?? files['readme.md'];
    if (readme != null && readme.trim().isNotEmpty) {
      return stripSkillFrontmatter(readme);
    }
    final skillMd = files['SKILL.md'];
    if (skillMd == null) {
      return '';
    }
    return stripSkillFrontmatter(skillMd);
  }

  static bool _isCommitSha(String ref) =>
      RegExp(r'^[0-9a-f]{40}$').hasMatch(ref);

  static bool _isSkillMdPath(String path) =>
      path == 'SKILL.md' || path.endsWith('/SKILL.md');

  static String _dirOf(String path) {
    final i = path.lastIndexOf('/');
    return i == -1 ? '' : path.substring(0, i);
  }

  static int _dirDepth(String dir) => dir.isEmpty ? 0 : dir.split('/').length;

  static bool _isBinaryPath(String rel) {
    final dot = rel.lastIndexOf('.');
    if (dot == -1) {
      return false;
    }
    return _binaryExtensions.contains(rel.substring(dot).toLowerCase());
  }

  /// Parses the simple `key: value` pairs of a `SKILL.md` frontmatter block.
  /// Deliberately not a YAML parser: the frontmatter this needs is flat
  /// strings, and a malformed block must degrade to defaults, not throw.
  static Map<String, String> _parseFrontmatter(String content) {
    final out = <String, String>{};
    final trimmed = content.trimLeft();
    if (!trimmed.startsWith('---')) {
      return out;
    }
    final end = trimmed.indexOf('\n---', 3);
    if (end == -1) {
      return out;
    }
    for (final line in trimmed.substring(3, end).split('\n')) {
      final idx = line.indexOf(':');
      if (idx <= 0) {
        continue;
      }
      final key = line.substring(0, idx).trim();
      final value = _unquote(line.substring(idx + 1).trim());
      if (value.isNotEmpty) {
        out[key] = value;
      }
    }
    return out;
  }

  static String _unquote(String value) {
    if (value.length >= 2 &&
        ((value.startsWith('"') && value.endsWith('"')) ||
            (value.startsWith("'") && value.endsWith("'")))) {
      return value.substring(1, value.length - 1);
    }
    return value;
  }
}

/// One `SKILL.md` discovered in a repository tree, before its frontmatter is
/// probed.
class _Candidate {
  const _Candidate({required this.skillFilePath, required this.slug});

  final String skillFilePath;
  final String slug;
}
