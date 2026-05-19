import 'package:cc_infra/src/network/bitbucket/models/bitbucket_comment.dart';
import 'package:cc_infra/src/network/bitbucket/models/bitbucket_json.dart';
import 'package:cc_infra/src/network/bitbucket/models/bitbucket_user.dart';
import 'package:cc_infra/src/network/models/date_parser.dart';

/// What one `activity` entry describes.
///
/// Bitbucket tags an activity entry by which key it carries rather than by a
/// discriminator field, so the decoder probes the four known keys in turn.
enum BitbucketActivityKind {
  /// A pull request update: title, description, branches, state or the
  /// reviewer roster changed. The entry carries the state AFTER the change.
  update,

  /// A participant approved the pull request.
  approval,

  /// A participant requested changes.
  changesRequested,

  /// A comment was posted.
  comment,

  /// A key this decoder does not model.
  unknown,
}

/// One entry of `GET /repositories/{ws}/{repo}/pullrequests/{id}/activity`.
///
/// The feed is returned newest-first and is the only history Bitbucket keeps:
/// there are no discrete "review requested" / "review request removed" events.
/// A reviewer change shows up as an [BitbucketActivityKind.update] entry whose
/// [reviewers] snapshot differs from the previous one, which is why [reviewers]
/// distinguishes "absent" (null) from "empty" (`[]`) — only a snapshot that was
/// actually reported can be diffed against its predecessor.
class BitbucketActivityEntry {
  /// Creates a [BitbucketActivityEntry].
  const BitbucketActivityEntry({
    required this.kind,
    this.date,
    this.actor,
    this.reviewers,
    this.stateAfter = '',
    this.comment,
  });

  /// Decodes one `values` element of the activity feed.
  factory BitbucketActivityEntry.fromJson(Map<String, dynamic> json) {
    final update = asJsonMap(json['update']);
    if (update != null) {
      final rawReviewers = update['reviewers'];
      return BitbucketActivityEntry(
        kind: BitbucketActivityKind.update,
        date: parseDate(update['date']),
        actor: _user(update['author']),
        reviewers: rawReviewers is List
            ? decodeJsonList(rawReviewers, BitbucketUser.fromJson)
            : null,
        stateAfter: update['state'] as String? ?? '',
      );
    }

    final approval = asJsonMap(json['approval']);
    if (approval != null) {
      return BitbucketActivityEntry(
        kind: BitbucketActivityKind.approval,
        date: parseDate(approval['date']),
        actor: _user(approval['user']),
      );
    }

    final changesRequested = asJsonMap(json['changes_requested']);
    if (changesRequested != null) {
      return BitbucketActivityEntry(
        kind: BitbucketActivityKind.changesRequested,
        date: parseDate(changesRequested['date']),
        actor: _user(changesRequested['user']),
      );
    }

    final comment = asJsonMap(json['comment']);
    if (comment != null) {
      final decoded = BitbucketComment.fromJson(comment);
      return BitbucketActivityEntry(
        kind: BitbucketActivityKind.comment,
        date: decoded.createdOn,
        actor: decoded.user,
        comment: decoded,
      );
    }

    return const BitbucketActivityEntry(kind: BitbucketActivityKind.unknown);
  }

  static BitbucketUser? _user(Object? value) {
    final json = asJsonMap(value);
    return json == null ? null : BitbucketUser.fromJson(json);
  }

  /// Which of the known activity shapes this entry is.
  final BitbucketActivityKind kind;

  /// When it happened. Null when Bitbucket omitted the timestamp.
  final DateTime? date;

  /// Who did it.
  final BitbucketUser? actor;

  /// The reviewer roster AFTER an [BitbucketActivityKind.update]. Null when
  /// the entry is not an update, or when the update did not report a roster.
  final List<BitbucketUser>? reviewers;

  /// The pull request state after an [BitbucketActivityKind.update]
  /// (`OPEN`, `MERGED`, `DECLINED`). Empty for every other kind.
  final String stateAfter;

  /// The posted comment, for an [BitbucketActivityKind.comment] entry.
  final BitbucketComment? comment;
}
