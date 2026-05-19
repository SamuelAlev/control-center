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
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Repo && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
