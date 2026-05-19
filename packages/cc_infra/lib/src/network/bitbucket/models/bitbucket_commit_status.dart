import 'package:cc_infra/src/network/bitbucket/models/bitbucket_json.dart';
import 'package:cc_infra/src/network/models/date_parser.dart';

/// A build status published against a commit
/// (`GET /repositories/{workspace}/{repo}/commit/{sha}/statuses`).
///
/// This is Bitbucket's entire CI surface as far as a pull request is
/// concerned: a result, a description and a link out. There is no step-level
/// structure and no log endpoint behind it — Bitbucket Pipelines publishes one
/// of these per run, and so does every third-party CI integration.
class BitbucketCommitStatus {
  /// Creates a [BitbucketCommitStatus].
  const BitbucketCommitStatus({
    required this.key,
    required this.name,
    required this.state,
    this.description = '',
    this.url = '',
    this.refname = '',
    this.createdOn,
    this.updatedOn,
  });

  /// Decodes a Bitbucket `commitstatus` object.
  factory BitbucketCommitStatus.fromJson(Map<String, dynamic> json) =>
      BitbucketCommitStatus(
        key: json['key'] as String? ?? '',
        name: json['name'] as String? ?? '',
        state: json['state'] as String? ?? '',
        description: json['description'] as String? ?? '',
        url: json['url'] as String? ?? linkHref(json['links'], 'self'),
        refname: json['refname'] as String? ?? '',
        createdOn: parseDate(json['created_on']),
        updatedOn: parseDate(json['updated_on']),
      );

  /// The reporter's stable identifier for this status (`BUILD-1`,
  /// `PIPELINE-…`). Unique per commit, so it is the context a status update
  /// overwrites — the closest equivalent of a GitHub status context.
  final String key;

  /// Human-readable status name. May be empty; [key] is then the only label.
  final String name;

  /// `SUCCESSFUL`, `FAILED`, `INPROGRESS` or `STOPPED`.
  final String state;

  /// Human-readable detail.
  final String description;

  /// The URL the status points at (the build page, or a deploy preview).
  final String url;

  /// The ref the build ran against. Often empty.
  final String refname;

  /// When the status was first published.
  final DateTime? createdOn;

  /// When the status last moved.
  final DateTime? updatedOn;

  /// Whether the state is terminal (nothing more will happen to this status).
  bool get isTerminal {
    final upper = state.toUpperCase();
    return upper == 'SUCCESSFUL' || upper == 'FAILED' || upper == 'STOPPED';
  }
}
