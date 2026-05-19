import 'package:cc_domain/core/domain/value_objects/forge_host.dart';

/// Immutable metadata about a locally-checked-out Git repository.
///
/// Created by inspecting a repo path and parsing its remote origin.
class GitRepoInfo {
  /// Creates a [GitRepoInfo] from parsed remote and local path data.
  const GitRepoInfo({
    required this.path,
    required this.forge,
    required this.owner,
    required this.repoName,
    required this.branch,
  });

  /// Absolute path to the repository on disk.
  final String path;

  /// The forge the `origin` remote points at.
  final ForgeHost forge;

  /// Owner path (GitHub owner, Bitbucket workspace, GitLab namespace — the
  /// latter may contain slashes).
  final String owner;

  /// Repository name on the forge.
  final String repoName;

  /// Current checked-out branch.
  final String branch;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GitRepoInfo &&
          runtimeType == other.runtimeType &&
          path == other.path &&
          forge == other.forge &&
          owner == other.owner &&
          repoName == other.repoName &&
          branch == other.branch;

  @override
  int get hashCode => Object.hash(path, forge, owner, repoName, branch);
}

/// Thrown when a repo cannot be inspected or its remote is unrecognised.
class GitRepoInspectionException implements Exception {
  /// Creates a [GitRepoInspectionException] with [message].
  const GitRepoInspectionException(this.message);

  /// Human-readable failure reason.
  final String message;

  @override
  String toString() => message;
}

/// A git remote resolved to a forge coordinate.
typedef ForgeRemote = ({ForgeHost forge, String owner, String name});

/// Parses a git remote [url] (SSH, `scp`-style or HTTPS) into its forge and
/// `owner/name` coordinate.
///
/// Returns `null` when the URL does not point at a supported forge, has no
/// recognizable host, or carries too few path segments to name a repository.
///
/// `owner` is everything before the final segment, so GitLab's arbitrarily
/// nested namespaces (`group/subgroup/project`) round-trip intact. GitHub and
/// Bitbucket do not nest, so a deeper path there is not a repository URL (a
/// tree/blob link, say) and is rejected rather than silently truncated.
ForgeRemote? parseForgeRemote(String url) {
  final trimmed = url.trim();
  if (trimmed.isEmpty) {
    return null;
  }

  final (host, rawPath) = _splitHostAndPath(trimmed);
  if (host == null || rawPath == null) {
    return null;
  }

  final forge = ForgeHost.fromGitHost(host);
  if (forge == null) {
    return null;
  }

  var path = rawPath;
  if (path.endsWith('/')) {
    path = path.substring(0, path.length - 1);
  }
  if (path.endsWith('.git')) {
    path = path.substring(0, path.length - 4);
  }

  final segments = path.split('/').where((s) => s.isNotEmpty).toList();
  if (segments.length < 2) {
    return null;
  }
  // Only GitLab nests namespaces; on the others a longer path is some other
  // kind of link, not a repo.
  if (forge != ForgeHost.gitlab && segments.length != 2) {
    return null;
  }

  final name = segments.removeLast();
  return (forge: forge, owner: segments.join('/'), name: name);
}

/// Splits a git remote into `(host, path)`, handling the three shapes git
/// accepts: `scheme://[user@]host[:port]/path`, `[user@]host:path` (scp-like)
/// and a bare `host/path`.
(String?, String?) _splitHostAndPath(String url) {
  final schemeMatch = RegExp(r'^([a-zA-Z][a-zA-Z0-9+.-]*)://').firstMatch(url);
  if (schemeMatch != null) {
    final rest = url.substring(schemeMatch.end);
    final slash = rest.indexOf('/');
    if (slash <= 0) {
      return (null, null);
    }
    return (_stripAuthority(rest.substring(0, slash)), rest.substring(slash));
  }

  // scp-like `git@host:owner/repo.git`. The colon separates host from path,
  // but a bare `host:port/path` would too — a port is all digits, which no
  // owner is, so treat a numeric prefix as a port and keep scanning.
  final colon = url.indexOf(':');
  if (colon > 0) {
    final authority = url.substring(0, colon);
    final path = url.substring(colon + 1);
    return (_stripAuthority(authority), path);
  }

  final slash = url.indexOf('/');
  if (slash > 0) {
    return (_stripAuthority(url.substring(0, slash)), url.substring(slash));
  }
  return (null, null);
}

/// Strips `user[:password]@` and a trailing `:port` from an authority.
String _stripAuthority(String authority) {
  var host = authority;
  final at = host.lastIndexOf('@');
  if (at >= 0) {
    host = host.substring(at + 1);
  }
  final colon = host.indexOf(':');
  if (colon >= 0) {
    host = host.substring(0, colon);
  }
  return host;
}
