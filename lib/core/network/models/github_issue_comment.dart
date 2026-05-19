import 'package:control_center/core/network/models/date_parser.dart';
import 'package:control_center/core/network/models/github_reaction.dart';
import 'package:control_center/core/network/models/github_user.dart';

/// A general issue / pull request comment (the conversation timeline, not
/// inline diff comments).
class GitHubIssueComment {
  /// Creates a [GitHubIssueComment].
  const GitHubIssueComment({
    required this.id,
    required this.body,
    this.user,
    this.createdAt,
    this.updatedAt,
    this.reactions,
    this.bodyHtml,
  });

  /// Creates a [GitHubIssueComment] from JSON.
  factory GitHubIssueComment.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    return GitHubIssueComment(
      id: (json['id'] as num?)?.toInt() ?? 0,
      body: json['body'] as String? ?? '',
      user: user is Map<String, dynamic> ? GitHubUser.fromJson(user) : null,
      createdAt: parseDate(json['created_at']),
      updatedAt: parseDate(json['updated_at']),
      reactions: json['reactions'] is Map<String, dynamic>
          ? GitHubReactionSummary.fromJson(json['reactions'] as Map<String, dynamic>)
          : null,
      bodyHtml: json['body_html'] as String?,
    );
  }

  /// Serializes this comment back to the GitHub JSON shape.
  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'body': body,
    'user': user?.toJson(),
    'created_at': createdAt?.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
    if (reactions != null) 'reactions': reactions!.toJson(),
    if (bodyHtml != null) 'body_html': bodyHtml,
  };

  final int id;

  final String body;

  /// Comment body rendered to HTML by GitHub (`full+json` media type).
  /// Carries pre-signed URLs for private user-attachments.
  final String? bodyHtml;

  final GitHubUser? user;

  final DateTime? createdAt;

  final DateTime? updatedAt;

  final GitHubReactionSummary? reactions;
}
