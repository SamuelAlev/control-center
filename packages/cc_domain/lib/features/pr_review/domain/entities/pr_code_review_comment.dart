import 'package:cc_domain/features/pr_review/domain/entities/pr_user.dart';
import 'package:cc_domain/features/pr_review/domain/entities/reaction_group.dart';

/// PrCodeReviewComment.
class PrCodeReviewComment {
  /// PrCodeReviewComment.
  const PrCodeReviewComment({
    required this.id,
    required this.body,
    required this.user,
    required this.path,
    required this.position,
    required this.createdAt,
    this.side = 'RIGHT',
    this.inReplyToId,
    this.startLine,
    this.diffHunk = '',
    this.line,
    this.originalLine,
    this.reactions = const [],
    this.reviewId,
    this.threadId,
    this.isResolved = false,
  });

  /// Identifier.
  final int id;

  /// Id of the review submission this comment was posted with (GitHub's
  /// `pull_request_review_id`); null when unknown (legacy cache rows).
  final int? reviewId;

  /// Body.
  final String body;

  /// User who authored the comment.
  final PrUser? user;

  /// File path the comment is on.
  final String path;

  /// Position in the diff.
  final int? position;

  /// Timestamp.
  final DateTime? createdAt;

  /// Side of the diff.
  final String side;

  /// ID of the comment this replies to.
  final int? inReplyToId;

  /// Starting line of the comment.
  final int? startLine;

  /// Diff hunk.
  final String diffHunk;

  /// Line number.
  final int? line;

  /// Original line number.
  final int? originalLine;

  /// Reactions on the comment.
  final List<ReactionGroup> reactions;

  /// Id of the review *thread* this comment belongs to, when the forge models
  /// threads separately (GitHub's GraphQL `PullRequestReviewThread` id). Null
  /// when the forge has no thread object or the state could not be resolved —
  /// the conversation then renders as open and cannot be resolved from here.
  final String? threadId;

  /// Whether the thread this comment belongs to is marked resolved on the
  /// forge. Never inferred from the body; it comes from [threadId]'s thread.
  final bool isResolved;

  /// Anchor line for the comment.
  int? get anchorLine => line ?? originalLine;

  /// First line of the comment's anchored range (a multi-line comment spans
  /// `startLine..anchorLine`), falling back to the anchor for a single line.
  int? get anchorStartLine => startLine ?? anchorLine;

  /// Returns a copy with the enrichment-owned fields replaced.
  ///
  /// Reactions and thread state are what enrichment rewrites after the fact: a
  /// forge returns comment bodies from one endpoint, then a second call
  /// resolves who reacted (so the viewer's own reaction can be highlighted) and
  /// which conversation each comment sits in (so a resolved thread renders
  /// resolved).
  PrCodeReviewComment copyWith({
    List<ReactionGroup>? reactions,
    String? threadId,
    bool? isResolved,
  }) => PrCodeReviewComment(
    id: id,
    body: body,
    user: user,
    path: path,
    position: position,
    createdAt: createdAt,
    side: side,
    inReplyToId: inReplyToId,
    startLine: startLine,
    diffHunk: diffHunk,
    line: line,
    originalLine: originalLine,
    reactions: reactions ?? this.reactions,
    reviewId: reviewId,
    threadId: threadId ?? this.threadId,
    isResolved: isResolved ?? this.isResolved,
  );

  /// Equality comparison.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PrCodeReviewComment &&
          runtimeType == other.runtimeType &&
          id == other.id;

  /// Hash code.
  @override
  int get hashCode => id.hashCode;
}
