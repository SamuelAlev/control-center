/// Value objects describing a GitHub pull-request review ready to be submitted:
/// the overall event, a summary body, and the line-anchored inline comments.
///
/// Produced by `BuildGitHubReviewUseCase` from the workspace's structured
/// review nodes and posted by the data-layer review publisher. Kept free of
/// any network/infrastructure dependency so the mapping is unit-testable.
library;

/// A single line-anchored review comment, mirroring the GitHub reviews
/// `comments[]` shape.
class GitHubInlineComment {
  /// Creates a [GitHubInlineComment].
  const GitHubInlineComment({
    required this.path,
    required this.line,
    required this.body,
    this.side = 'RIGHT',
    this.startLine,
    this.startSide,
  });

  /// Repository-relative file path the comment anchors to.
  final String path;

  /// The (end) line the comment anchors to, in the file's post-change state
  /// when [side] is `RIGHT`.
  final int line;

  /// Markdown body of the comment.
  final String body;

  /// `RIGHT` (post-change) or `LEFT` (pre-change). Defaults to `RIGHT`.
  final String side;

  /// Start line for a multi-line anchor. Null for a single-line comment.
  final int? startLine;

  /// Start side for a multi-line anchor. Defaults to [side] when omitted.
  final String? startSide;

  /// Whether this is a multi-line anchor.
  bool get isMultiLine => startLine != null && startLine != line;

  /// Serializes to the GitHub reviews `comments[]` entry shape.
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'path': path,
      'line': line,
      'side': side,
      'body': body,
    };
    if (isMultiLine) {
      json['start_line'] = startLine;
      json['start_side'] = startSide ?? side;
    }
    return json;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GitHubInlineComment &&
          runtimeType == other.runtimeType &&
          path == other.path &&
          line == other.line &&
          body == other.body &&
          side == other.side &&
          startLine == other.startLine &&
          startSide == other.startSide;

  @override
  int get hashCode =>
      Object.hash(path, line, body, side, startLine, startSide);
}

/// A fully-resolved review ready to submit to GitHub: the event, the summary
/// body, and the inline comments.
class GitHubReviewPlan {
  /// Creates a [GitHubReviewPlan].
  const GitHubReviewPlan({
    required this.event,
    required this.body,
    required this.inlineComments,
  });

  /// `APPROVE`, `REQUEST_CHANGES`, or `COMMENT`.
  final String event;

  /// Summary body, including the verdict banner and any findings that could
  /// not be anchored to a diff line.
  final String body;

  /// Line-anchored inline comments.
  final List<GitHubInlineComment> inlineComments;

  /// A flattened plan that folds every inline comment into the body. Used as
  /// the fallback when GitHub rejects a line anchor that is not part of the
  /// diff (422), so the findings are never silently dropped.
  GitHubReviewPlan flattenedToBody() {
    if (inlineComments.isEmpty) {
      return this;
    }
    final buf = StringBuffer(body.trimRight())
      ..writeln()
      ..writeln()
      ..writeln('## Inline findings')
      ..writeln();
    for (final c in inlineComments) {
      final anchor = c.isMultiLine
          ? '`${c.path}:${c.startLine}-${c.line}`'
          : '`${c.path}:${c.line}`';
      buf
        ..writeln('### $anchor')
        ..writeln()
        ..writeln(c.body.trim())
        ..writeln();
    }
    return GitHubReviewPlan(
      event: event,
      body: buf.toString().trimRight(),
      inlineComments: const [],
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GitHubReviewPlan &&
          runtimeType == other.runtimeType &&
          event == other.event &&
          body == other.body &&
          _listEquals(inlineComments, other.inlineComments);

  @override
  int get hashCode => Object.hash(event, body, Object.hashAll(inlineComments));

  static bool _listEquals(
    List<GitHubInlineComment> a,
    List<GitHubInlineComment> b,
  ) {
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
}
