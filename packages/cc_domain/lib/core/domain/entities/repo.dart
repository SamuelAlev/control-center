import 'package:cc_domain/core/domain/value_objects/forge_host.dart';

/// A repository registered in a workspace.
///
/// Repos are **workspace-scoped**: a checkout is registered into one workspace
/// (Settings → Repositories, per workspace) and its row lives in that
/// workspace's own database. Registering the same checkout in a second
/// workspace produces a SECOND repo with its own [id], so repo identity across
/// workspaces is by [path] (or forge + owner/name) — never by id.
///
/// A repo also carries the [forge] it is hosted on. One workspace may mix
/// forges freely, so **never assume a workspace is single-forge**: anything
/// that talks to a forge API resolves its adapter and credentials from
/// `repo.forge`, and anything that aggregates across repos groups by it.
class Repo {
  /// Creates a new [Repo].
  Repo({
    required this.id,
    required this.name,
    required this.path,
    required this.remoteOwner,
    required this.remoteName,
    required this.createdAt,
    required this.updatedAt,
    this.forge = ForgeHost.github,
    this.linkedBy = '',
    this.forgeRepoId = '',
  }) {
    if (name.isEmpty) {
      throw ArgumentError('Repo name must not be empty');
    }
    if (path.isEmpty) {
      throw ArgumentError('Repo path must not be empty');
    }
  }

  /// Unique identifier.
  final String id;

  /// Human-readable name (defaults to `owner/repo`).
  final String name;

  /// Absolute path to the local working tree.
  final String path;

  /// The code-hosting service this repo lives on, parsed from its `origin`
  /// remote at registration time.
  final ForgeHost forge;

  /// Owner path parsed from the `origin` remote — a GitHub owner, a Bitbucket
  /// workspace, or a GitLab namespace.
  ///
  /// May contain slashes: GitLab namespaces nest arbitrarily deep
  /// (`group/subgroup`), which is why this is a path rather than a single
  /// segment. Never interpolate it into a URL path segment without escaping.
  final String remoteOwner;

  /// Repository name parsed from the `origin` remote (the last path segment).
  final String remoteName;

  /// The user who linked [path] into the workspace. Only the server owner
  /// may link a checkout outside the workspace's own storage, so readers
  /// check it against the owner. Empty for a row whose linker was never
  /// recorded: such a path is served only from the workspace's own storage.
  final String linkedBy;

  /// The forge's durable id for the repository this row was linked as (a
  /// GitHub repository id, a GitLab project id, a Bitbucket repository
  /// uuid), read with an authorized token when it was linked, or on the
  /// first authorized read of a row linked before the id was kept. A
  /// repository renamed or transferred keeps it; another repository created
  /// at [remoteOwner]/[remoteName] does not, and receives nothing. Empty
  /// until it is first read.
  final String forgeRepoId;

  /// Creation timestamp.
  final DateTime createdAt;

  /// Last update timestamp.
  final DateTime updatedAt;

  /// True when this repo resolves to a real forge coordinate.
  bool get hasForgeRemote =>
      forge.isSupported && remoteOwner.isNotEmpty && remoteName.isNotEmpty;

  /// `owner/repo` when known, otherwise the local path.
  String get fullName => hasForgeRemote ? '$remoteOwner/$remoteName' : path;

  /// Copy with.
  Repo copyWith({
    String? id,
    String? name,
    String? path,
    ForgeHost? forge,
    String? remoteOwner,
    String? remoteName,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? linkedBy,
    String? forgeRepoId,
  }) {
    return Repo(
      id: id ?? this.id,
      name: name ?? this.name,
      path: path ?? this.path,
      forge: forge ?? this.forge,
      remoteOwner: remoteOwner ?? this.remoteOwner,
      remoteName: remoteName ?? this.remoteName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      linkedBy: linkedBy ?? this.linkedBy,
      forgeRepoId: forgeRepoId ?? this.forgeRepoId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Repo && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Splits an `owner/name` full name at its LAST `/`, so a GitLab nested
/// namespace (`group/sub/project`) keeps `group/sub` as its owner. Null when
/// either half is empty.
({String owner, String name})? splitRepoFullName(String fullName) {
  final cut = fullName.lastIndexOf('/');
  if (cut <= 0 || cut == fullName.length - 1) {
    return null;
  }
  return (owner: fullName.substring(0, cut), name: fullName.substring(cut + 1));
}
