/// The code-hosting service ("forge") a repository lives on.
///
/// A repo belongs to exactly one forge and every forge-touching operation
/// resolves its adapter, credentials and URL vocabulary through this value.
/// A single workspace may mix forges freely: aggregating surfaces (the inbox,
/// the PR queue, the needs-my-review count) group their repos by [ForgeHost]
/// and fan out per group.
///
/// [wire] is the single serialized spelling — it is simultaneously the `repos`
/// table column value, the RPC argument value and the adapter-registry key, so
/// a forge never has two names to keep in sync (the `TicketSyncAdapter.vendorId`
/// convention, applied to the PR side).
enum ForgeHost {
  /// GitHub (github.com).
  github(
    wire: 'github',
    displayName: 'GitHub',
    gitHost: 'github.com',
    webBaseUrl: 'https://github.com',
    apiBaseUrl: 'https://api.github.com',
  ),

  /// GitLab (gitlab.com).
  gitlab(
    wire: 'gitlab',
    displayName: 'GitLab',
    gitHost: 'gitlab.com',
    webBaseUrl: 'https://gitlab.com',
    apiBaseUrl: 'https://gitlab.com/api/v4',
  ),

  /// Bitbucket Cloud (bitbucket.org).
  bitbucket(
    wire: 'bitbucket',
    displayName: 'Bitbucket',
    gitHost: 'bitbucket.org',
    webBaseUrl: 'https://bitbucket.org',
    apiBaseUrl: 'https://api.bitbucket.org/2.0',
  ),

  /// A checkout whose `origin` remote is not on any supported forge (or has no
  /// remote at all).
  ///
  /// Repo registration rejects these today, so this is the defensive value for
  /// a row that predates a forge or was hand-edited — never a state the product
  /// creates. Resolving an adapter for it yields the empty/no-op repository
  /// rather than an exception.
  local(
    wire: 'local',
    displayName: 'Local',
    gitHost: '',
    webBaseUrl: '',
    apiBaseUrl: '',
  );

  const ForgeHost({
    required this.wire,
    required this.displayName,
    required this.gitHost,
    required this.webBaseUrl,
    required this.apiBaseUrl,
  });

  /// The serialized spelling (DB column value, RPC value, registry key).
  final String wire;

  /// Human-readable product name, for UI. Not localized: these are proper
  /// nouns and stay identical in every locale.
  final String displayName;

  /// The git remote host this forge is recognized by (`github.com`, …).
  final String gitHost;

  /// Base URL of the forge's web UI, without a trailing slash.
  final String webBaseUrl;

  /// Base URL of the forge's REST API, without a trailing slash.
  final String apiBaseUrl;

  /// The forges a repository can actually be hosted on — everything except
  /// [local]. Iterate this (never `values`) when building per-forge UI,
  /// credential rows or adapter registrations.
  static const List<ForgeHost> supported = [github, gitlab, bitbucket];

  /// Parses a [wire] value back into a [ForgeHost].
  ///
  /// Returns [local] for anything unrecognized — an unknown forge degrades to
  /// "no forge operations available" rather than throwing, so one bad row can
  /// never take a workspace's repo list down.
  static ForgeHost fromWire(String? wire) {
    for (final host in ForgeHost.values) {
      if (host.wire == wire) {
        return host;
      }
    }
    return ForgeHost.local;
  }

  /// The forge serving [gitHost], or `null` when the host is not a known forge.
  ///
  /// Matches the bare host and its `www.` form; port and userinfo must already
  /// be stripped.
  static ForgeHost? fromGitHost(String host) {
    final normalized = host.toLowerCase().replaceFirst(RegExp(r'^www\.'), '');
    for (final forge in supported) {
      if (forge.gitHost == normalized) {
        return forge;
      }
    }
    return null;
  }

  /// Whether this forge supports real operations (everything but [local]).
  bool get isSupported => this != ForgeHost.local;

  /// What a change proposal is called on this forge. GitLab calls it a merge
  /// request; the rest call it a pull request.
  ///
  /// Used for user-facing copy that names the concept in a forge's own
  /// vocabulary. The domain model itself stays "pull request" throughout.
  String get changeRequestNoun =>
      this == ForgeHost.gitlab ? 'merge request' : 'pull request';

  /// The abbreviated form of [changeRequestNoun] (`MR` / `PR`).
  String get changeRequestAbbreviation =>
      this == ForgeHost.gitlab ? 'MR' : 'PR';
}
