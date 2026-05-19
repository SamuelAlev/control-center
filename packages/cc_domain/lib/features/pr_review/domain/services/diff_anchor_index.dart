// Which lines of a pull request a review comment can actually be anchored to.
//
// Two problems share one answer. A finding must be *tied to the changed code*
// to be worth posting at all — a reviewer that wanders into untouched code is
// reviewing the repository, not the pull request. And GitHub only accepts an
// inline comment on a line that appears in the diff, so a finding anchored
// anywhere else is rejected at submit time and silently folded into the body.
//
// Building the set of commentable lines once answers both: it is the admission
// test AND the re-verification against the current head, because the index is
// built from the diff as it stands right now.

import 'package:cc_domain/features/pr_review/domain/services/diff_parser.dart';

/// The lines of each changed file that a comment may anchor to.
class DiffAnchorIndex {
  /// Creates a [DiffAnchorIndex] over an already-computed map.
  const DiffAnchorIndex(this._byPath);

  const DiffAnchorIndex._permissive() : _byPath = const {};

  /// Builds an index from each changed file's unified-diff patch.
  ///
  /// A file with no patch (a binary, or one GitHub truncated) contributes an
  /// empty line set rather than being absent, so [isKnownFile] can tell "this
  /// file did not change" from "this file changed but we cannot place a line
  /// in it" — the first is a reviewer mistake, the second is not.
  factory DiffAnchorIndex.fromPatches(Map<String, String?> patchesByPath) {
    final byPath = <String, Set<int>>{};
    for (final entry in patchesByPath.entries) {
      final lines = <int>{};
      final patch = entry.value;
      if (patch != null && patch.isNotEmpty) {
        for (final line in parseUnifiedDiff(patch)) {
          // Added and context lines both carry a new-side number and are both
          // commentable. Removed lines have none, which is correct: a comment
          // on a deleted line has nowhere to live on the new side.
          final n = line.newLine;
          if (n != null && line.kind != DiffLineKind.hunkHeader) {
            lines.add(n);
          }
        }
      }
      byPath[entry.key] = lines;
    }
    return DiffAnchorIndex(byPath);
  }

  /// An index that admits everything.
  ///
  /// The honest fallback for when the diff could not be fetched: an empty
  /// index would silently demote every finding in the review, turning a
  /// transient API failure into a review that found nothing.
  static const DiffAnchorIndex permissive = DiffAnchorIndex._permissive();

  final Map<String, Set<int>> _byPath;

  /// Whether this index knows anything at all. False for [permissive].
  bool get isEmpty => _byPath.isEmpty;

  /// Whether [path] is among the pull request's changed files.
  bool isKnownFile(String path) => _byPath.containsKey(path);

  /// Whether a comment anchored at [path]:[line] falls on changed code.
  ///
  /// Spans admit on ANY overlapping line: a finding about a five-line block
  /// where only the middle line changed is still a finding about the change.
  bool admits(String path, int? line, {int? lineEnd}) {
    if (isEmpty) {
      return true;
    }
    final lines = _byPath[path];
    if (lines == null) {
      return false;
    }
    if (line == null) {
      // A file-level finding on a file that genuinely changed. Nothing to
      // place, but nothing wrong with it either.
      return true;
    }
    final end = lineEnd == null || lineEnd < line ? line : lineEnd;
    for (var candidate = line; candidate <= end; candidate++) {
      if (lines.contains(candidate)) {
        return true;
      }
    }
    return false;
  }

  /// The changed files this index covers.
  Iterable<String> get paths => _byPath.keys;
}
