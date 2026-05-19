/// Read-only access to the skill catalogs of GitHub repositories the operator
/// registered as skill sources. Lives server-side; clients reach it over the
/// `skills.source*` RPC ops only.
///
/// SECURITY NOTE: a source repository is UNTRUSTED, exactly like the registry
/// it replaced. Every field of a [SourceSkillListing] is display-only metadata
/// (the repository author controls it); the trusted artifact is the bytes
/// [resolve] returns, which always pass the mandatory scan gate before an
/// install writes anything. Trust content hashes, not repository descriptions.
abstract interface class SkillSourcePort {
  /// Repo-level metadata for [owner]/[repo] (default branch, description,
  /// stars). Also the existence probe: throws when the repo is unknown or
  /// inaccessible with the host's credentials.
  Future<SkillSourceRepoSnapshot> repoSnapshot(String owner, String repo);

  /// Every skill directory found in [owner]/[repo] (a directory containing a
  /// `SKILL.md`, up to a bounded depth/count). Metadata is parsed from each
  /// `SKILL.md`'s frontmatter and is untrusted display data.
  Future<List<SourceSkillListing>> listSkills(
    String owner,
    String repo, {
    String? ref,
  });

  /// Resolves the skill at [skillFilePath] (a repo-relative path to a
  /// `SKILL.md`) to the FULL file set of its containing directory, fetched at
  /// [ref] — the latest commit touching the skill when null. The returned
  /// [SourceSkillFiles.files] is the artifact the scan gate scans and the
  /// install hashes.
  Future<SourceSkillFiles> resolve(
    String owner,
    String repo,
    String skillFilePath, {
    String? ref,
  });
}

/// Repo-level metadata for a registered skill source (untrusted display data).
class SkillSourceRepoSnapshot {
  /// Creates a [SkillSourceRepoSnapshot].
  const SkillSourceRepoSnapshot({
    required this.owner,
    required this.repo,
    required this.defaultBranch,
    this.description = '',
    this.starCount = 0,
  });

  /// Repository owner (user or org login).
  final String owner;

  /// Repository name.
  final String repo;

  /// The repo's default branch (used as the browsing ref).
  final String defaultBranch;

  /// Repository description (untrusted).
  final String description;

  /// Star count (untrusted popularity signal).
  final int starCount;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SkillSourceRepoSnapshot &&
          runtimeType == other.runtimeType &&
          owner == other.owner &&
          repo == other.repo &&
          defaultBranch == other.defaultBranch &&
          description == other.description &&
          starCount == other.starCount;

  @override
  int get hashCode => Object.hash(owner, repo, defaultBranch, description, starCount);
}

/// One skill discovered inside a source repository. Every field except the
/// paths is untrusted metadata parsed from the skill's own `SKILL.md`.
class SourceSkillListing {
  /// Creates a [SourceSkillListing].
  const SourceSkillListing({
    required this.slug,
    required this.name,
    required this.description,
    required this.skillFilePath,
  });

  /// The local install slug: the skill directory's basename.
  final String slug;

  /// Human-facing name (frontmatter `name`, untrusted).
  final String name;

  /// Short description (frontmatter `description`, untrusted).
  final String description;

  /// Repo-relative path to the skill's `SKILL.md` — the install/update key.
  final String skillFilePath;

  /// The skill directory containing [skillFilePath] ('' when at repo root).
  String get dirPath {
    final i = skillFilePath.lastIndexOf('/');
    return i == -1 ? '' : skillFilePath.substring(0, i);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SourceSkillListing &&
          runtimeType == other.runtimeType &&
          skillFilePath == other.skillFilePath &&
          name == other.name &&
          description == other.description;

  @override
  int get hashCode => Object.hash(skillFilePath, name, description);
}

/// A resolved multi-file skill bundle: directory-relative path → content, the
/// commit SHA it was fetched at and the README markdown for the detail view.
class SourceSkillFiles {
  /// Creates a [SourceSkillFiles].
  const SourceSkillFiles({
    required this.files,
    required this.ref,
    this.readme = '',
  });

  /// Directory-relative path → file content. Always contains `SKILL.md`.
  final Map<String, String> files;

  /// The commit SHA the files were fetched at (the install pin).
  final String ref;

  /// README markdown for the detail view: the skill directory's `README.md`
  /// when present, otherwise the `SKILL.md` body with its frontmatter
  /// stripped.
  final String readme;

  /// The `SKILL.md` content.
  String get skillMd => files['SKILL.md'] ?? '';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SourceSkillFiles &&
          runtimeType == other.runtimeType &&
          ref == other.ref &&
          files.length == other.files.length &&
          files.entries.every(
            (e) => other.files[e.key] == e.value,
          );

  @override
  int get hashCode => Object.hash(ref, Object.hashAllUnordered(files.keys));
}

/// Strips a leading YAML frontmatter block from a `SKILL.md`/`README.md`
/// body so only markdown remains for rendering.
String stripSkillFrontmatter(String content) {
  final trimmed = content.trimLeft();
  if (!trimmed.startsWith('---')) {
    return content.trim();
  }
  final end = trimmed.indexOf('\n---', 3);
  if (end == -1) {
    return content.trim();
  }
  return trimmed.substring(end + 4).trim();
}
