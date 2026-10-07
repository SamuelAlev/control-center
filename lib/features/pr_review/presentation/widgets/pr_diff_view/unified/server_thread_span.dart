import 'package:cc_domain/features/pr_review/domain/entities/pr_code_review_comment.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_diff_view/unified/outdated_comments.dart';
import 'package:flutter/foundation.dart';

/// One server-side review conversation resolved against the current diff: the
/// synthesised thread id, the LINE RANGE it anchors to and its forge state.
///
/// The range is the part that is easy to lose. A forge anchors a multi-line
/// comment at its LAST line and carries the first separately, so a thread keyed
/// only by its anchor highlights the last row of a seven-row comment and
/// diffs a suggestion against one line of source. Everything that reads
/// "which rows does this conversation cover" goes through [covers].
@immutable
class ServerThreadSpan {
  /// Creates a span; [startLine]..[endLine] is inclusive on [side].
  const ServerThreadSpan({
    required this.id,
    required this.side,
    required this.startLine,
    required this.endLine,
    required this.serverResolved,
    required this.threadId,
    required this.comments,
  });

  /// How many lines of one conversation's range get indexed by line.
  ///
  /// Real ranges are a handful of lines. The cap exists so a malformed
  /// `start_line` can't make the index proportional to the file.
  static const int maxIndexedLines = 512;

  /// Synthesised thread id (`server-<first comment id>`), stable across
  /// refreshes so a collapse survives a poll.
  final String id;

  /// `LEFT` (pre-change) or `RIGHT` (post-change).
  final String side;

  /// First and last covered line, inclusive, in [side]'s numbering.
  final int startLine;

  /// Last covered line, inclusive — where the card anchors.
  final int endLine;

  /// The forge's resolved flag; the optimistic override sits above it.
  final bool serverResolved;

  /// The forge's thread id, or null when it could not be resolved.
  final String? threadId;

  /// The conversation's comments, oldest first.
  final List<PrCodeReviewComment> comments;

  /// Whether this conversation covers [line] on [s].
  bool covers(String s, int line) =>
      s == side && line >= startLine && line <= endLine;
}

/// Groups [serverComments] on [filename] into one [ServerThreadSpan] per
/// anchored conversation, comments sorted oldest first. Comments the current
/// diff can no longer place (no anchor line) are skipped here; callers surface
/// them through `partitionServerCommentsForFile(...).outdated`.
List<ServerThreadSpan> buildServerThreadSpans(
  List<PrCodeReviewComment> serverComments,
  String filename,
) {
  final anchored = partitionServerCommentsForFile(
    serverComments,
    filename,
  ).anchored;
  final out = <ServerThreadSpan>[];
  for (final group in anchored.values) {
    if (group.isEmpty) {
      continue;
    }
    final sorted = [...group]
      ..sort((a, b) {
        final ad = a.createdAt;
        final bd = b.createdAt;
        if (ad != null && bd != null) {
          return ad.compareTo(bd);
        }
        return a.id.compareTo(b.id);
      });
    final first = sorted.first;
    final end = first.anchorLine;
    if (end == null) {
      continue;
    }
    // The RANGE comes off the thread's FIRST comment: GitHub anchors a
    // multi-line comment at its last line and carries the first in
    // `start_line`, and replies repeat the anchor without the range.
    final start = (first.anchorStartLine ?? end).clamp(1, end);
    out.add(
      ServerThreadSpan(
        id: 'server-${first.id}',
        side: first.side,
        startLine: start,
        endLine: end,
        serverResolved: first.isResolved,
        threadId: first.threadId,
        comments: sorted,
      ),
    );
  }
  return out;
}

/// `"<side>-<line>" → conversation` for every line [spans] cover, so a
/// highlight pass stays one map lookup per row. At most
/// [ServerThreadSpan.maxIndexedLines] lines of each range are indexed.
Map<String, ServerThreadSpan> indexServerThreadSpansByLine(
  List<ServerThreadSpan> spans,
) => {
  for (final span in spans) ...{
    // The END line is always indexed, cap or not: it is where the card
    // anchors, so a range the cap truncated would otherwise lose its
    // conversation entirely rather than just part of its highlight.
    '${span.side}-${span.endLine}': span,
    for (
      var line = span.startLine;
      line <= span.endLine &&
          line - span.startLine < ServerThreadSpan.maxIndexedLines;
      line++
    )
      '${span.side}-$line': span,
  },
};
