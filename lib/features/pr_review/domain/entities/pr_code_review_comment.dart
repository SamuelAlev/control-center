import 'package:control_center/features/pr_review/domain/entities/pr_user.dart';
import 'package:control_center/features/pr_review/domain/entities/reaction_group.dart';

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
  });

  /// Identifier.
  final int id;

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

  /// Anchor line for the comment.
  int? get anchorLine => line ?? originalLine;

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
