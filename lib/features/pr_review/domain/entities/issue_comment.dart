import 'package:control_center/features/pr_review/domain/entities/pr_user.dart';
import 'package:control_center/features/pr_review/domain/entities/reaction_group.dart';

/// Issue comment.
class IssueComment {
  /// IssueComment.
  const IssueComment({
    required this.id,
    required this.body,
    required this.user,
    required this.createdAt,
    this.reactions = const [],
  });

  /// Identifier.
  final int id;

  /// Body.
  final String body;

  /// User who created the comment.
  final PrUser? user;

  /// Timestamp.
  final DateTime? createdAt;

  /// Reactions on the comment.
  final List<ReactionGroup> reactions;

  /// Equality comparison.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IssueComment &&
          runtimeType == other.runtimeType &&
          id == other.id;

  /// Hash code.
  @override
  int get hashCode => id.hashCode;
}
