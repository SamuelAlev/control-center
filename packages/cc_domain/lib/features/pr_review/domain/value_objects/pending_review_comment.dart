/// One inline comment queued for a review that has not been submitted yet.
///
/// A reviewer writing five comments on a PR is making one statement, not five.
/// Posting each as it is written notifies the author five times and shows them
/// a partial opinion; batching them into the review means the author reads the
/// whole verdict at once. That is what this carries: a comment the reviewer has
/// written, held locally until the verdict goes out with it.
///
/// The field names mirror the forge anchor vocabulary the ports already speak
/// ([line]/[side] anchor, [startLine]/[startSide] extend to a range), and
/// [toWire] emits the GitHub reviews `comments[]` entry shape — which the other
/// adapters unbundle rather than send.
class PendingReviewComment {
  /// Creates a [PendingReviewComment].
  const PendingReviewComment({
    required this.path,
    required this.line,
    required this.body,
    this.side = 'RIGHT',
    this.startLine,
    this.startSide,
  });

  /// Reads one back off the wire.
  factory PendingReviewComment.fromJson(Map<String, dynamic> json) =>
      PendingReviewComment(
        path: json['path'] as String? ?? '',
        line: (json['line'] as num?)?.toInt() ?? 0,
        body: json['body'] as String? ?? '',
        side: json['side'] as String? ?? 'RIGHT',
        startLine: (json['start_line'] as num?)?.toInt(),
        startSide: json['start_side'] as String?,
      );

  /// Repository-relative path of the commented file.
  final String path;

  /// The line the comment anchors to — the LAST line of a range, matching how
  /// forges anchor a multi-line comment.
  final int line;

  /// Markdown body (a ```suggestion fence included, when it is a suggestion).
  final String body;

  /// `RIGHT` (post-change) or `LEFT` (pre-change).
  final String side;

  /// First line of a multi-line anchor; null for a single line.
  final int? startLine;

  /// Side of [startLine]; defaults to [side].
  final String? startSide;

  /// Whether the anchor spans more than one line.
  bool get isMultiLine => startLine != null && startLine != line;

  /// Serializes to the forge `comments[]` entry shape (also the RPC wire form).
  Map<String, dynamic> toWire() => <String, dynamic>{
    'path': path,
    'line': line,
    'side': side,
    'body': body,
    if (isMultiLine) 'start_line': startLine,
    if (isMultiLine) 'start_side': startSide ?? side,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PendingReviewComment &&
          runtimeType == other.runtimeType &&
          path == other.path &&
          line == other.line &&
          body == other.body &&
          side == other.side &&
          startLine == other.startLine &&
          startSide == other.startSide;

  @override
  int get hashCode => Object.hash(path, line, body, side, startLine, startSide);

  @override
  String toString() =>
      'PendingReviewComment($path:${isMultiLine ? '$startLine-$line' : line})';
}
