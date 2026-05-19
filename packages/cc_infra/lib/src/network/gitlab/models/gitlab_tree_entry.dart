/// One entry of `GET /projects/:id/repository/tree`.
///
/// Used to discover the merge-request templates a project ships; the tree
/// listing carries no content, so each blob is fetched separately.
class GitLabTreeEntry {
  /// Creates a [GitLabTreeEntry].
  const GitLabTreeEntry({
    required this.name,
    required this.path,
    required this.type,
    this.id = '',
    this.mode = '',
  });

  /// Reads a [GitLabTreeEntry] off a decoded JSON object.
  factory GitLabTreeEntry.fromJson(Map<String, dynamic> json) =>
      GitLabTreeEntry(
        name: json['name'] as String? ?? '',
        path: json['path'] as String? ?? '',
        type: json['type'] as String? ?? '',
        id: json['id'] as String? ?? '',
        mode: json['mode'] as String? ?? '',
      );

  /// Entry name within its directory.
  final String name;

  /// Full repository path of the entry.
  final String path;

  /// `blob` for a file, `tree` for a directory.
  final String type;

  /// Object SHA.
  final String id;

  /// File mode.
  final String mode;

  /// Whether this entry is a file.
  bool get isBlob => type == 'blob';
}
