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
  final PrUser? user;
  final String path;
  final int? position;
  final DateTime? createdAt;
  final String side;
  final int? inReplyToId;
  final int? startLine;
  final String diffHunk;
  final int? line;
  final int? originalLine;
  final List<ReactionGroup> reactions;

  int? get anchorLine => line ?? originalLine;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PrCodeReviewComment &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

