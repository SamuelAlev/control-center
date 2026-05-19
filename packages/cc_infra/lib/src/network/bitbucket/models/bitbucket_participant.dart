import 'package:cc_infra/src/network/bitbucket/models/bitbucket_json.dart';
import 'package:cc_infra/src/network/bitbucket/models/bitbucket_user.dart';
import 'package:cc_infra/src/network/models/date_parser.dart';

/// One entry of a pull request's `participants` array — Bitbucket's whole
/// review model in a single object.
///
/// Bitbucket has no "review" resource: there is no review id, no review body
/// and no submission history. A reviewer's verdict is a mutable flag on their
/// participation row, so the newest verdict is the only one the API remembers.
class BitbucketParticipant {
  /// Creates a [BitbucketParticipant].
  const BitbucketParticipant({
    required this.role,
    required this.approved,
    required this.state,
    this.user,
    this.participatedOn,
  });

  /// Decodes a Bitbucket `participant` object.
  factory BitbucketParticipant.fromJson(Map<String, dynamic> json) {
    final user = asJsonMap(json['user']);
    return BitbucketParticipant(
      role: json['role'] as String? ?? '',
      approved: json['approved'] as bool? ?? false,
      state: json['state'] as String? ?? '',
      user: user == null ? null : BitbucketUser.fromJson(user),
      participatedOn: parseDate(json['participated_on']),
    );
  }

  /// `REVIEWER` for someone whose review was requested, `PARTICIPANT` for
  /// someone who joined by commenting or approving unprompted.
  final String role;

  /// Whether this participant currently approves the pull request.
  final bool approved;

  /// `approved`, `changes_requested`, or `''` when the participant has given
  /// no verdict yet.
  final String state;

  /// The account. Null when Bitbucket omitted it (a deleted account).
  final BitbucketUser? user;

  /// When the verdict was last set. Null while no verdict has been given.
  final DateTime? participatedOn;

  /// Whether this participant was explicitly asked to review.
  bool get isReviewer => role.toUpperCase() == 'REVIEWER';

  /// Whether this participant is currently blocking the pull request.
  bool get hasRequestedChanges => state == 'changes_requested';

  /// Whether this participant has expressed any verdict at all — the test for
  /// "this is a submitted review" as opposed to "this review is still awaited".
  bool get hasVerdict => approved || hasRequestedChanges;
}
