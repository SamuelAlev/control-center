/// The connected server's build identity, as advertised by its `initialize`
/// capabilities. This is the client-side half of the stale-binary /
/// compatibility story: the client compares [version] against its own
/// `BuildInfo.buildVersion` (an older *server* is the common case — the
/// desktop spawns a prebuilt `cc_server` that can lag the app) and surfaces
/// a warning, never a hard block; only the wire-protocol min/max range is
/// allowed to refuse a connection.
class ServerBuild {
  /// Creates a [ServerBuild].
  const ServerBuild({this.version, this.gitSha, this.catalogVersion});

  /// Parses the `initialize` result envelope:
  /// `{..., 'capabilities': {'serverVersion': '1.2.3', 'gitSha': 'abc1234',
  /// 'repoRpc': {'catalogVersion': 19}}}`.
  factory ServerBuild.fromInitializeResult(Map<String, dynamic> result) {
    final rawCaps = result['capabilities'];
    final caps = rawCaps is Map ? rawCaps : const <String, dynamic>{};
    final rawRepoRpc = caps['repoRpc'];
    final repoRpc = rawRepoRpc is Map ? rawRepoRpc : null;
    return ServerBuild(
      version: caps['serverVersion'] as String?,
      gitSha: caps['gitSha'] as String?,
      catalogVersion: repoRpc?['catalogVersion'] as int?,
    );
  }

  /// The server's release version, or null when it did not advertise one
  /// (a server built before this field existed).
  final String? version;

  /// The server's build git sha, or null when absent.
  final String? gitSha;

  /// The repo-RPC op catalog version the server speaks, or null when the
  /// server serves no repo-RPC surface.
  final int? catalogVersion;

  @override
  bool operator ==(Object other) =>
      other is ServerBuild &&
      other.version == version &&
      other.gitSha == gitSha &&
      other.catalogVersion == catalogVersion;

  @override
  int get hashCode => Object.hash(version, gitSha, catalogVersion);

  @override
  String toString() =>
      'ServerBuild($version, $gitSha, catalog $catalogVersion)';
}
