/// A skill listing from a registry (PRD 23 §1). Every field here is UNTRUSTED,
/// display-only metadata: the registry is never a scan substitute, and the only
/// fact Control Center trusts is the content hash it computes over the bytes it
/// fetches. Publisher names, install counts, and a "verified" flag are evidence
/// shown to the operator, never a gate shortcut.
class SkillListing {
  /// Creates a [SkillListing].
  const SkillListing({
    required this.slug,
    required this.name,
    this.description = '',
    this.author = '',
    this.version = '',
    this.installCount = 0,
    this.verifiedPublisher = false,
  });

  /// Registry slug (used to resolve the bundle).
  final String slug;

  /// Human-facing name (untrusted display text).
  final String name;

  /// Short description (untrusted).
  final String description;

  /// Publisher/author label (untrusted evidence, never a trust grant).
  final String author;

  /// Latest published version string (untrusted).
  final String version;

  /// Reported install count (untrusted popularity signal).
  final int installCount;

  /// Registry's "verified publisher" flag — provenance evidence only, NEVER a
  /// scan or policy shortcut.
  final bool verifiedPublisher;

  @override
  bool operator ==(Object other) =>
      other is SkillListing && other.slug == slug && other.version == version;

  @override
  int get hashCode => Object.hash(slug, version);
}

/// A skill resolved to concrete, fetchable bytes (PRD 23 §1). The [files] map is
/// what the scan gate scans and Control Center hashes — the trusted artifact.
class ResolvedSkill {
  /// Creates a [ResolvedSkill].
  const ResolvedSkill({
    required this.slug,
    required this.files,
    this.version = '',
    this.publisher = '',
    this.verifiedPublisher = false,
  });

  /// The skill slug.
  final String slug;

  /// Bundle-relative path → file content (the artifact CC hashes + scans).
  final Map<String, String> files;

  /// The resolved version.
  final String version;

  /// Publisher label (untrusted evidence).
  final String publisher;

  /// Registry verified-publisher flag (evidence only).
  final bool verifiedPublisher;
}

/// Read-only access to a skills registry (skills.sh first — PRD 23 §1). Lives
/// server-side; clients reach it over the `skills.*` RPC ops only. Every result
/// is untrusted metadata except the bytes returned by [resolve], which still
/// pass the mandatory scan gate before install.
abstract interface class SkillRegistryPort {
  /// Searches the registry for [query], returning up to [limit] listings.
  Future<List<SkillListing>> search(String query, {int limit = 25});

  /// Resolves [slug] (optionally at [version]) to fetchable bytes.
  Future<ResolvedSkill> resolve(String slug, {String? version});
}
