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
  final PrUser? user;
  final DateTime? createdAt;
  final List<ReactionGroup> reactions;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IssueComment &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

