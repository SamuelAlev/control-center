import 'package:cc_infra/src/network/models/date_parser.dart';

/// A GitLab commit, as returned by `GET .../merge_requests/:iid/commits` and
/// `GET /projects/:id/repository/commits/:sha`.
///
/// Note what is *not* here: a linked user account. GitLab's commit payload
/// carries only the git author name and email, never the GitLab user they
/// resolve to, so the mapper has no avatar or handle to work with.
class GitLabCommit {
  /// Creates a [GitLabCommit].
  const GitLabCommit({
    required this.id,
    required this.title,
    required this.message,
    this.shortId = '',
    this.authorName = '',
    this.authorEmail = '',
    this.committerName = '',
    this.authoredDate,
    this.committedDate,
    this.createdAt,
    this.webUrl = '',
  });

  /// Reads a [GitLabCommit] off a decoded JSON object.
  factory GitLabCommit.fromJson(Map<String, dynamic> json) => GitLabCommit(
    id: json['id'] as String? ?? '',
    title: json['title'] as String? ?? '',
    message: json['message'] as String? ?? '',
    shortId: json['short_id'] as String? ?? '',
    authorName: json['author_name'] as String? ?? '',
    authorEmail: json['author_email'] as String? ?? '',
    committerName: json['committer_name'] as String? ?? '',
    authoredDate: parseDate(json['authored_date']),
    committedDate: parseDate(json['committed_date']),
    createdAt: parseDate(json['created_at']),
    webUrl: json['web_url'] as String? ?? '',
  );

  /// Full commit SHA.
  final String id;

  /// First line of the commit message.
  final String title;

  /// Full commit message.
  final String message;

  /// Abbreviated SHA.
  final String shortId;

  /// Git author name.
  final String authorName;

  /// Git author email.
  final String authorEmail;

  /// Git committer name.
  final String committerName;

  /// When the change was authored.
  final DateTime? authoredDate;

  /// When the commit was written.
  final DateTime? committedDate;

  /// Creation timestamp (mirrors [committedDate] on most payloads).
  final DateTime? createdAt;

  /// Link to the commit page.
  final String webUrl;
}
