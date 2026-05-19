import 'package:cc_domain/core/domain/entities/repo.dart';

/// The reserved prefix marking a repo-scoped memory domain slug.
///
/// A domain slug is either bare (`architecture` — the domain applies to the
/// whole workspace) or repo-qualified (`repo:owner-project/architecture` — the
/// domain is about one repository). Both live in the same `memory_domains`
/// table and the same `(workspaceId, name)` unique index; the prefix is the
/// only thing that distinguishes them.
const String kRepoDomainPrefix = 'repo:';

/// Separator between the repo slug and the bare domain name.
const String _scopeSeparator = '/';

/// A memory domain slug decomposed into its optional repo scope and bare name.
///
/// This class is the ONE place that knows the wire format. Everything else —
/// the resolve/create use case, the access-grant lookup, the MCP tools, the
/// recall boost and the UI — goes through [parse] and [slug] rather than
/// building or splitting the string itself. A second copy of the format is how
/// a repo-scoped domain silently becomes a domain literally named
/// `repo:foo/bar`.
class MemoryDomainScope {
  /// Creates a [MemoryDomainScope].
  ///
  /// [name] must be a bare domain name — it must not itself carry a
  /// [kRepoDomainPrefix] or a `/`. Pass the parts, not a slug; use [parse] to
  /// go the other way.
  const MemoryDomainScope({required this.name, this.repoSlug});

  /// A workspace-wide domain, not tied to any repo.
  const MemoryDomainScope.global(this.name) : repoSlug = null;

  /// The repo this domain is scoped to, or null when it is workspace-wide.
  ///
  /// Never contains a `/`: [repoSlugFor] flattens `owner/repo` to `owner-repo`
  /// precisely so the slug splits unambiguously on its single separator.
  final String? repoSlug;

  /// The bare, kebab-case domain name with any repo prefix stripped
  /// (`architecture`, never `repo:owner-project/architecture`).
  ///
  /// This is what access grants, system-domain checks and the UI label are
  /// keyed on, so one `architecture` grant covers every repo's variant.
  final String name;

  /// True when this domain belongs to a specific repo.
  bool get isRepoScoped => repoSlug != null;

  /// The canonical stored slug — what lands in `memory_domains.name` and in
  /// the `domain` column of every fact and policy.
  String get slug => repoSlug == null
      ? name
      : '$kRepoDomainPrefix$repoSlug$_scopeSeparator$name';

  /// Splits a stored domain slug into its scope and bare name.
  ///
  /// A slug carrying the prefix but no separator (`repo:orphan`) is malformed —
  /// it is returned as a global domain whose name is the whole raw string, so
  /// a hand-written or legacy value is displayed verbatim rather than crashing
  /// or silently losing its text.
  static MemoryDomainScope parse(String slug) {
    if (!slug.startsWith(kRepoDomainPrefix)) {
      return MemoryDomainScope.global(slug);
    }
    final rest = slug.substring(kRepoDomainPrefix.length);
    final cut = rest.indexOf(_scopeSeparator);
    if (cut <= 0 || cut == rest.length - 1) {
      return MemoryDomainScope.global(slug);
    }
    return MemoryDomainScope(
      repoSlug: rest.substring(0, cut),
      name: rest.substring(cut + 1),
    );
  }

  /// Builds a canonical slug from a (possibly messy) domain input and an
  /// optional repo slug.
  ///
  /// The input is slugified FIRST and qualified after, because [slugifyMemoryName]
  /// strips `:` and `/` — running it over an already-qualified slug would
  /// collapse `repo:foo/architecture` to `repofooarchitecture`.
  static String qualify({required String domainInput, String? repoSlug}) {
    final bare = slugifyMemoryName(
      MemoryDomainScope.parse(domainInput.trim()).name,
    );
    final scope = repoSlug == null || repoSlug.isEmpty
        ? null
        : slugifyRepoScope(repoSlug);
    return MemoryDomainScope(
      name: bare,
      repoSlug: (scope == null || scope.isEmpty) ? null : scope,
    ).slug;
  }

  /// The bare name of [slug] — the shorthand for `parse(slug).name`.
  static String bareName(String slug) => parse(slug).name;

  /// The repo slug of [slug], or null when it is workspace-wide.
  static String? repoSlugOf(String slug) => parse(slug).repoSlug;

  /// True when [slug] is scoped to [repoSlug].
  static bool matchesRepo(String slug, String? repoSlug) =>
      repoSlug != null && parse(slug).repoSlug == repoSlug;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MemoryDomainScope &&
          runtimeType == other.runtimeType &&
          repoSlug == other.repoSlug &&
          name == other.name;

  @override
  int get hashCode => Object.hash(repoSlug, name);

  @override
  String toString() => slug;
}

/// The canonical memory scope slug for [repo].
///
/// Derived from [Repo.name] (which defaults to `owner/repo`) rather than the
/// bare remote name, so two repos owned by different accounts but sharing a
/// short name do not silently share one memory scope. The `/` is flattened to
/// `-` so the resulting slug has exactly one separator when it is qualified.
String repoSlugFor(Repo repo) {
  final fromName = slugifyRepoScope(repo.name);
  if (fromName.isNotEmpty) {
    return fromName;
  }
  // A repo with no usable name still needs a stable, unique scope.
  final fromRemote = slugifyRepoScope(repo.remoteName);
  return fromRemote.isNotEmpty ? fromRemote : slugifyRepoScope(repo.id);
}

/// Normalizes a repo identifier (`owner/repo`, `Owner/My-Repo`, a path) into a
/// scope slug.
///
/// Unlike [slugifyMemoryName], path separators become `-` instead of being
/// DELETED. That difference is load-bearing: plain slugification turns
/// `acme/api` into `acmeapi`, which collides with a repo genuinely named
/// `acmeapi` and reads as a typo everywhere it is displayed. The two functions
/// stay separate because [slugifyMemoryName] governs domain names, whose
/// existing slugs must keep resolving exactly as they always have.
String slugifyRepoScope(String input) =>
    slugifyMemoryName(input.replaceAll(RegExp(r'[/\\]+'), '-'));

/// Whether the stored domain [slug] satisfies a caller's `domain` [filter].
///
/// An UNQUALIFIED filter (`architecture`) matches that domain in every scope —
/// the workspace-wide one and each repo's. Exact-matching instead would make
/// the filter silently return nothing the moment a domain became repo-scoped,
/// which reads as "there are no architecture policies" rather than "you asked
/// the wrong question". A QUALIFIED filter (`repo:owner-project/architecture`)
/// means the caller already knows the scope they want, so it matches exactly.
bool matchesDomainFilter(String slug, String filter) {
  final wanted = MemoryDomainScope.parse(filter.trim());
  if (wanted.isRepoScoped) {
    return slug ==
        MemoryDomainScope(
          repoSlug: slugifyRepoScope(wanted.repoSlug!),
          name: slugifyMemoryName(wanted.name),
        ).slug;
  }
  return MemoryDomainScope.bareName(slug) == slugifyMemoryName(wanted.name);
}

/// Reorders [items] so those scoped to [repoSlug] come first, preserving the
/// relative order within each group.
///
/// A stable partition rather than a `sort`, for two reasons: `List.sort` is not
/// stable in Dart, so it would scramble the relevance ordering the caller
/// already paid for; and this must never DROP anything — repo affinity is a
/// ranking signal, so another repo's memories and workspace-wide ones still
/// come back, just later.
List<T> sortByRepoAffinity<T>(
  Iterable<T> items,
  String? repoSlug, {
  required String Function(T) domainOf,
}) {
  final all = items.toList();
  if (repoSlug == null || repoSlug.isEmpty) {
    return all;
  }
  final matching = <T>[];
  final rest = <T>[];
  for (final item in all) {
    if (MemoryDomainScope.matchesRepo(domainOf(item), repoSlug)) {
      matching.add(item);
    } else {
      rest.add(item);
    }
  }
  return [...matching, ...rest];
}

/// Normalizes a free-form string into a kebab-case memory slug segment.
///
/// Shared by the domain-resolution path and [MemoryDomainScope.qualify] so a
/// domain minted by an agent and one minted by a harvester land on the same
/// slug. Strips everything outside `[a-z0-9-]`, which is why the repo prefix
/// must be applied to the result rather than passed through it.
String slugifyMemoryName(String input) {
  return input
      .toLowerCase()
      .trim()
      .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
      .replaceAll(RegExp(r'[\s_]+'), '-')
      .replaceAll(RegExp(r'-+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');
}
