/// A file changed in a pull request.
class GitHubPullRequestFile {
  /// Creates a [GitHubPullRequestFile].
  const GitHubPullRequestFile({
    required this.filename,
    required this.status,
    required this.additions,
    required this.deletions,
    required this.changes,
    required this.patch,
    this.previousFilename,
    this.sha = '',
    this.blobUrl = '',
  });

  /// Creates a [GitHubPullRequestFile] from JSON.
  factory GitHubPullRequestFile.fromJson(Map<String, dynamic> json) {
    return GitHubPullRequestFile(
      filename: json['filename'] as String? ?? '',
      status: json['status'] as String? ?? '',
      additions: (json['additions'] as num?)?.toInt() ?? 0,
      deletions: (json['deletions'] as num?)?.toInt() ?? 0,
      changes: (json['changes'] as num?)?.toInt() ?? 0,
      patch: json['patch'] as String? ?? '',
      previousFilename: json['previous_filename'] as String?,
      sha: json['sha'] as String? ?? '',
      blobUrl: json['blob_url'] as String? ?? '',
    );
  }

  /// Serializes this file back to the GitHub JSON shape.
  Map<String, dynamic> toJson() => <String, dynamic>{
    'filename': filename,
    'status': status,
    'additions': additions,
    'deletions': deletions,
    'changes': changes,
    'patch': patch,
    'previous_filename': previousFilename,
    'sha': sha,
    'blob_url': blobUrl,
  };

  /// Path of the file in the head branch.
  final String filename;

  /// One of `added`, `modified`, `removed`, `renamed`, `copied`, `changed`,
  /// `unchanged`.
  final String status;

  /// Lines added.
  final int additions;

  /// Lines deleted.
  final int deletions;

  /// Total line changes.
  final int changes;

  /// Unified diff patch for this file. May be empty for binary files or files
  /// over GitHub's size threshold.
  final String patch;

  /// Previous filename when [status] is `renamed`.
  final String? previousFilename;

  /// Blob SHA.
  final String sha;

  /// URL to view the file at this revision.
  final String blobUrl;

  /// File extension without the leading dot (e.g. `ts`, `dart`).
  String get extension {
    final dot = filename.lastIndexOf('.');
    if (dot == -1 || dot == filename.length - 1) {
      return '';
    }

    return filename.substring(dot + 1).toLowerCase();
  }
}
