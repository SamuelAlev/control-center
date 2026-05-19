/// Immutable model of one level of the SERVER's filesystem, returned by a
/// `DirectoryBrowserPort` so a thin/web client (which has no local filesystem)
/// can navigate the host's folders and pick a git checkout to register.
///
/// Browsing is constrained to a configured set of allow-listed roots; the
/// browser never surfaces (and refuses to list) anything above them.
library;

/// A single immediate subdirectory of the directory being browsed.
class DirectoryEntry {
  /// Creates a [DirectoryEntry].
  const DirectoryEntry({
    required this.name,
    required this.path,
    required this.isGitRepo,
  });

  /// The folder's display name (its last path segment).
  final String name;

  /// Absolute path to the folder on the SERVER's machine.
  final String path;

  /// Whether the folder contains a `.git` entry (a git work tree). A hint for
  /// the UI — the server still fully validates the checkout on registration.
  final bool isGitRepo;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DirectoryEntry &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          path == other.path &&
          isGitRepo == other.isGitRepo;

  @override
  int get hashCode => Object.hash(name, path, isGitRepo);
}

/// One navigable level of the server's filesystem within the allow-listed roots.
class DirectoryListing {
  /// Creates a [DirectoryListing].
  const DirectoryListing({
    required this.path,
    required this.parent,
    required this.isGitRepo,
    required this.roots,
    required this.entries,
  });

  /// Absolute path of the directory being listed.
  final String path;

  /// The parent directory's absolute path, or `null` when [path] is itself one
  /// of the allow-listed [roots] (navigating above a root is not permitted).
  final String? parent;

  /// Whether [path] itself is a git work tree — lets the UI offer to register
  /// the folder the user has navigated into.
  final bool isGitRepo;

  /// The configured allow-listed roots, so a UI can offer to jump between them.
  final List<String> roots;

  /// The immediate subdirectories of [path], sorted by name.
  final List<DirectoryEntry> entries;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DirectoryListing &&
          runtimeType == other.runtimeType &&
          path == other.path &&
          parent == other.parent &&
          isGitRepo == other.isGitRepo &&
          _listEquals(roots, other.roots) &&
          _listEquals(entries, other.entries);

  @override
  int get hashCode => Object.hash(
        path,
        parent,
        isGitRepo,
        Object.hashAll(roots),
        Object.hashAll(entries),
      );
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) {
    return true;
  }
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}
