import 'package:cc_infra/src/network/gitlab/models/gitlab_user.dart';
import 'package:cc_infra/src/network/models/date_parser.dart';

/// One award emoji — GitLab's reaction primitive, as returned by
/// `GET .../merge_requests/:iid/award_emoji` and
/// `GET .../merge_requests/:iid/notes/:note_id/award_emoji`.
///
/// Each award is a separate object owned by one user, so removing a reaction
/// means finding *your* award and deleting it by [id]; there is no
/// "delete by emoji name" verb.
class GitLabAwardEmoji {
  /// Creates a [GitLabAwardEmoji].
  const GitLabAwardEmoji({
    required this.id,
    required this.name,
    this.user,
    this.createdAt,
    this.updatedAt,
    this.awardableId = 0,
    this.awardableType = '',
  });

  /// Reads a [GitLabAwardEmoji] off a decoded JSON object.
  factory GitLabAwardEmoji.fromJson(Map<String, dynamic> json) =>
      GitLabAwardEmoji(
        id: (json['id'] as num?)?.toInt() ?? 0,
        name: json['name'] as String? ?? '',
        user: GitLabUser.maybeFromJson(json['user']),
        createdAt: parseDate(json['created_at']),
        updatedAt: parseDate(json['updated_at']),
        awardableId: (json['awardable_id'] as num?)?.toInt() ?? 0,
        awardableType: json['awardable_type'] as String? ?? '',
      );

  /// Award id — what a DELETE addresses.
  final int id;

  /// GitLab emoji shortcode (`thumbsup`, `tada`, `rocket`, …). Note this is
  /// GitLab's vocabulary, not GitHub's; the mapper translates.
  final String name;

  /// Who left it.
  final GitLabUser? user;

  /// When it was left.
  final DateTime? createdAt;

  /// When it last changed.
  final DateTime? updatedAt;

  /// Id of the thing it is attached to.
  final int awardableId;

  /// Type of the thing it is attached to (`MergeRequest`, `Note`).
  final String awardableType;
}
