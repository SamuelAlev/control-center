import 'package:cc_infra/src/network/bitbucket/models/bitbucket_json.dart';
import 'package:cc_infra/src/network/bitbucket/models/bitbucket_participant.dart';
import 'package:cc_infra/src/network/bitbucket/models/bitbucket_user.dart';
import 'package:cc_infra/src/network/models/date_parser.dart';

/// A Bitbucket Cloud pull request
/// (`GET /repositories/{workspace}/{repo}/pullrequests/{id}`).
///
/// Two shape notes that drive the whole adapter:
///
/// * [id] is scoped to the repository (PR #1 exists in every repo), so it is
///   the domain's per-repo *number*. Bitbucket publishes no globally unique
///   opaque id, which is why the adapter synthesizes one.
/// * The branch tips live under `source`/`destination` and are frequently
///   returned abbreviated (12 hex chars), not as full 40-char SHAs.
class BitbucketPullRequest {
  /// Creates a [BitbucketPullRequest].
  const BitbucketPullRequest({
    required this.id,
    required this.title,
    required this.description,
    required this.state,
    required this.htmlUrl,
    this.author,
    this.createdOn,
    this.updatedOn,
    this.descriptionHtml,
    this.sourceBranch = '',
    this.sourceCommitHash = '',
    this.destinationBranch = '',
    this.destinationCommitHash = '',
    this.mergeCommitHash = '',
    this.closeSourceBranch = false,
    this.commentCount = 0,
    this.taskCount = 0,
    this.reason = '',
    this.reviewers = const <BitbucketUser>[],
    this.participants = const <BitbucketParticipant>[],
  });

  /// Decodes a Bitbucket `pullrequest` object.
  factory BitbucketPullRequest.fromJson(Map<String, dynamic> json) {
    final author = asJsonMap(json['author']);
    final source = asJsonMap(json['source']);
    final destination = asJsonMap(json['destination']);
    final summary = asJsonMap(json['summary']);
    return BitbucketPullRequest(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      state: json['state'] as String? ?? '',
      htmlUrl: linkHref(json['links'], 'html'),
      author: author == null ? null : BitbucketUser.fromJson(author),
      createdOn: parseDate(json['created_on']),
      updatedOn: parseDate(json['updated_on']),
      // `summary` is the server-rendered form of `description`. Bitbucket
      // returns it on the detail endpoint only, so it stays null for a PR read
      // off a list page.
      descriptionHtml: summary?['html'] as String?,
      sourceBranch: asJsonMap(source?['branch'])?['name'] as String? ?? '',
      sourceCommitHash: asJsonMap(source?['commit'])?['hash'] as String? ?? '',
      destinationBranch:
          asJsonMap(destination?['branch'])?['name'] as String? ?? '',
      destinationCommitHash:
          asJsonMap(destination?['commit'])?['hash'] as String? ?? '',
      mergeCommitHash:
          asJsonMap(json['merge_commit'])?['hash'] as String? ?? '',
      closeSourceBranch: json['close_source_branch'] as bool? ?? false,
      commentCount: (json['comment_count'] as num?)?.toInt() ?? 0,
      taskCount: (json['task_count'] as num?)?.toInt() ?? 0,
      reason: json['reason'] as String? ?? '',
      reviewers: decodeJsonList(json['reviewers'], BitbucketUser.fromJson),
      participants: decodeJsonList(
        json['participants'],
        BitbucketParticipant.fromJson,
      ),
    );
  }

  /// Pull request id, unique within the repository only.
  final int id;

  /// Title.
  final String title;

  /// Raw markdown description.
  final String description;

  /// Server-rendered HTML description (`summary.html`), when the endpoint
  /// returned one.
  final String? descriptionHtml;

  /// `OPEN`, `MERGED`, `DECLINED` or `SUPERSEDED`.
  final String state;

  /// Web URL (`links.html.href`).
  final String htmlUrl;

  /// The account that opened the pull request.
  final BitbucketUser? author;

  /// Creation timestamp.
  final DateTime? createdOn;

  /// Last-modified timestamp. Bitbucket publishes no `merged_on`, so for a
  /// `MERGED` pull request this doubles as the merge time.
  final DateTime? updatedOn;

  /// Source branch name.
  final String sourceBranch;

  /// Source branch tip, often abbreviated to 12 hex characters.
  final String sourceCommitHash;

  /// Destination branch name.
  final String destinationBranch;

  /// Destination branch tip, often abbreviated to 12 hex characters.
  final String destinationCommitHash;

  /// Merge commit hash. Empty until the pull request merges.
  final String mergeCommitHash;

  /// Whether merging deletes the source branch.
  final bool closeSourceBranch;

  /// Total comment count (inline plus top-level).
  final int commentCount;

  /// Open task count.
  final int taskCount;

  /// Decline/merge reason text. Empty when Bitbucket gave none.
  final String reason;

  /// The accounts whose review was requested.
  final List<BitbucketUser> reviewers;

  /// Everyone touching the pull request, carrying their approval verdict.
  final List<BitbucketParticipant> participants;

  /// Whether the pull request merged.
  bool get isMerged => state.toUpperCase() == 'MERGED';
}
