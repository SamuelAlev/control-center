/// Diff side.
enum DiffSide {
  /// Left side of the diff.
  left('LEFT'),

  /// Right side of the diff.
  right('RIGHT');

  const DiffSide(this.label);

  /// Human-readable label for the side.
  final String label;
}

/// File status in a diff.
enum FileStatus {
  /// File was added.
  added('added'),

  /// File was removed.
  removed('removed'),

  /// File was modified.
  modified('modified'),

  /// File was renamed.
  renamed('renamed'),

  /// File was copied.
  copied('copied');

  const FileStatus(this.label);

  /// Human-readable label for the status.
  final String label;
}

