import 'package:cc_infra/src/network/bitbucket/models/bitbucket_json.dart';
import 'package:cc_infra/src/network/bitbucket/models/bitbucket_user.dart';
import 'package:cc_infra/src/network/models/date_parser.dart';

/// A pull request comment
/// (`GET /repositories/{workspace}/{repo}/pullrequests/{id}/comments`).
///
/// Bitbucket returns inline (file-anchored) and top-level conversation
/// comments through the SAME endpoint; the presence of an `inline` object is
/// the only thing that separates them. Threading is by [parentId] — a comment
/// with a parent is a reply.
///
/// The anchor is a `{from, to}` pair naming a line on the pre-image and the
/// post-image respectively; exactly one is normally set. There is no
/// commit-sha anchoring: a Bitbucket inline comment is pinned to the pull
/// request's current diff, not to a revision of it.
class BitbucketComment {
  /// Creates a [BitbucketComment].
  const BitbucketComment({
    required this.id,
    required this.rawContent,
    this.htmlContent,
    this.createdOn,
    this.updatedOn,
    this.user,
    this.parentId,
    this.inlinePath,
    this.inlineFrom,
    this.inlineTo,
    this.inlineOutdated = false,
    this.deleted = false,
    this.htmlUrl = '',
  });

  /// Decodes a Bitbucket `pullrequest_comment` object.
  factory BitbucketComment.fromJson(Map<String, dynamic> json) {
    final content = asJsonMap(json['content']);
    final user = asJsonMap(json['user']);
    final inline = asJsonMap(json['inline']);
    return BitbucketComment(
      id: (json['id'] as num?)?.toInt() ?? 0,
      rawContent: content?['raw'] as String? ?? '',
      htmlContent: content?['html'] as String?,
      createdOn: parseDate(json['created_on']),
      updatedOn: parseDate(json['updated_on']),
      user: user == null ? null : BitbucketUser.fromJson(user),
      parentId: (asJsonMap(json['parent'])?['id'] as num?)?.toInt(),
      inlinePath: inline?['path'] as String?,
      inlineFrom: (inline?['from'] as num?)?.toInt(),
      inlineTo: (inline?['to'] as num?)?.toInt(),
      inlineOutdated: inline?['outdated'] as bool? ?? false,
      deleted: json['deleted'] as bool? ?? false,
      htmlUrl: linkHref(json['links'], 'html'),
    );
  }

  /// Comment id, unique within the repository.
  final int id;

  /// Raw markdown body. Empty for a deleted comment, whose content Bitbucket
  /// withholds.
  final String rawContent;

  /// Server-rendered HTML body, when Bitbucket returned one.
  final String? htmlContent;

  /// Creation timestamp.
  final DateTime? createdOn;

  /// Last-edit timestamp.
  final DateTime? updatedOn;

  /// The author. Null for a deleted account.
  final BitbucketUser? user;

  /// Id of the comment this one replies to. Null for a thread root.
  final int? parentId;

  /// Anchored file path. Null for a top-level conversation comment.
  final String? inlinePath;

  /// Anchor line on the pre-image (the removed/"old" side). Null when the
  /// comment sits on the post-image.
  final int? inlineFrom;

  /// Anchor line on the post-image (the added/"new" side). Null when the
  /// comment sits on the pre-image.
  final int? inlineTo;

  /// Whether the anchored line no longer exists in the current diff.
  final bool inlineOutdated;

  /// Whether the comment was deleted (Bitbucket keeps the row and blanks the
  /// content).
  final bool deleted;

  /// Web URL for the comment.
  final String htmlUrl;

  /// Whether this is a file-anchored (inline) comment rather than a top-level
  /// conversation comment.
  bool get isInline => inlinePath != null && inlinePath!.isNotEmpty;

  /// Whether this comment is a reply to another.
  bool get isReply => parentId != null;
}
