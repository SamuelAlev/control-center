import 'package:cc_infra/src/network/bitbucket/models/bitbucket_json.dart';

/// One entry of a Bitbucket `diffstat` response — the per-file summary of a
/// pull request or a commit.
///
/// Deliberately carries no patch text: unlike GitHub's files endpoint,
/// Bitbucket's diffstat returns only counts and paths. The per-file hunks have
/// to come from the sibling unified-diff endpoint.
class BitbucketDiffstatEntry {
  /// Creates a [BitbucketDiffstatEntry].
  const BitbucketDiffstatEntry({
    required this.status,
    required this.linesAdded,
    required this.linesRemoved,
    this.oldPath,
    this.newPath,
  });

  /// Decodes a Bitbucket `diffstat` object.
  factory BitbucketDiffstatEntry.fromJson(Map<String, dynamic> json) =>
      BitbucketDiffstatEntry(
        status: json['status'] as String? ?? '',
        linesAdded: (json['lines_added'] as num?)?.toInt() ?? 0,
        linesRemoved: (json['lines_removed'] as num?)?.toInt() ?? 0,
        oldPath: asJsonMap(json['old'])?['path'] as String?,
        newPath: asJsonMap(json['new'])?['path'] as String?,
      );

  /// `added`, `removed`, `modified`, `renamed` or `merge conflict`.
  final String status;

  /// Lines added.
  final int linesAdded;

  /// Lines removed.
  final int linesRemoved;

  /// Path before the change. Null for an added file.
  final String? oldPath;

  /// Path after the change. Null for a removed file.
  final String? newPath;

  /// The path this entry is keyed by: the post-change path when the file still
  /// exists, otherwise the pre-change one. Matches how a unified diff names the
  /// same file, which is what lets the two responses be joined.
  String get path => newPath ?? oldPath ?? '';

  /// Whether this entry describes a rename.
  bool get isRename =>
      status == 'renamed' ||
      (oldPath != null && newPath != null && oldPath != newPath);
}
