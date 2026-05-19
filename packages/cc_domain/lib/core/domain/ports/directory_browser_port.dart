import 'package:cc_domain/core/domain/entities/directory_listing.dart';

/// Port for browsing the SERVER's filesystem one directory at a time, scoped to
/// a configured set of allow-listed roots.
///
/// A thin/web client has no local filesystem, so it cannot offer a native
/// folder picker for the repo path (which must resolve on the machine hosting
/// the server). Instead the host exposes this port over RPC so the client can
/// render a navigable folder browser of the server's own directories and pick a
/// git checkout to register via `repos.addFromPath`.
///
/// Implementations MUST refuse to list (or escape to) any path outside the
/// configured roots — see the workspace/host-isolation invariants.
abstract interface class DirectoryBrowserPort {
  /// Lists the immediate subdirectories of [path] on the server's filesystem.
  ///
  /// When [path] is `null`, the first configured root is listed. The returned
  /// [DirectoryListing] carries the resolved path, its parent (or `null` at a
  /// root boundary), whether the path itself is a git work tree, the configured
  /// roots, and the child folders (each flagged when it contains a `.git`).
  ///
  /// Throws [DirectoryAccessException] when [path] falls outside the configured
  /// roots or is not an accessible directory.
  Future<DirectoryListing> browse({String? path});
}

/// Thrown when a [DirectoryBrowserPort] is asked to list a path outside its
/// allow-listed roots, or a path that is not an accessible directory.
///
/// The [message] is authored to be client-safe (no leaking of which roots
/// exist or of unrelated filesystem detail).
class DirectoryAccessException implements Exception {
  /// Creates a [DirectoryAccessException] with [message].
  const DirectoryAccessException(this.message);

  /// Human-readable, client-safe failure reason.
  final String message;

  @override
  String toString() => message;
}
