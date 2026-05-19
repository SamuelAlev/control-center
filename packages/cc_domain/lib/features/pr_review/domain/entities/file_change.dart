/// File change.
class FileChange {
  /// Creates a [FileChange] with the given properties.
  const FileChange({
    required this.path,
    this.additions = 0,
    this.deletions = 0,
    this.isNew = false,
    this.isDeleted = false,
  });

  /// File path.
  final String path;

  /// Additions.
  final int additions;

  /// Deletions.
  final int deletions;

  /// isNew.
  final bool isNew;

  /// isDeleted.
  final bool isDeleted;

  /// Equality comparison.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FileChange &&
          runtimeType == other.runtimeType &&
          path == other.path &&
          additions == other.additions &&
          deletions == other.deletions &&
          isNew == other.isNew &&
          isDeleted == other.isDeleted;

  /// Hash code.
  @override
  int get hashCode => Object.hash(path, additions, deletions, isNew, isDeleted);

  /// String representation.
  @override
  String toString() => 'FileChange($path, +$additions -$deletions)';
}
