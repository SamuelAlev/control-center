import 'package:control_center/core/network/models/date_parser.dart';
import 'package:control_center/core/network/models/github_reaction.dart';
import 'package:control_center/core/network/models/github_user.dart';

/// An inline review comment attached to a line in a pull request diff.
class GitHubReviewComment {
  /// Creates a [GitHubReviewComment].
  const GitHubReviewComment({
    required this.id,
    required this.body,
    required this.path,
    required this.diffHunk,
    this.line,
    this.originalLine,
    this.startLine,
    this.side = 'RIGHT',
    this.inReplyToId,
    this.user,
    this.createdAt,
    this.updatedAt,
    this.reactions,
    this.bodyHtml,
  });

  /// Creates a [GitHubReviewComment] from JSON.
  factory GitHubReviewComment.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    return GitHubReviewComment(
      id: (json['id'] as num?)?.toInt() ?? 0,
      body: json['body'] as String? ?? '',
      path: json['path'] as String? ?? '',
      diffHunk: json['diff_hunk'] as String? ?? '',
      line: (json['line'] as num?)?.toInt(),
      originalLine: (json['original_line'] as num?)?.toInt(),
      startLine: (json['start_line'] as num?)?.toInt(),
      side: json['side'] as String? ?? 'RIGHT',
      inReplyToId: (json['in_reply_to_id'] as num?)?.toInt(),
      user: user is Map<String, dynamic> ? GitHubUser.fromJson(user) : null,
      createdAt: parseDate(json['created_at']),
      updatedAt: parseDate(json['updated_at']),
      reactions: json['reactions'] is Map<String, dynamic>
          ? GitHubReactionSummary.fromJson(json['reactions'] as Map<String, dynamic>)
          : null,
      bodyHtml: json['body_html'] as String?,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'body': body,
    'path': path,
    'diff_hunk': diffHunk,
    'line': line,
    'original_line': originalLine,
    'start_line': startLine,
    'side': side,
    'in_reply_to_id': inReplyToId,
    'user': user?.toJson(),
    'created_at': createdAt?.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
    if (reactions != null) 'reactions': reactions!.toJson(),
    if (bodyHtml != null) 'body_html': bodyHtml,
  };

  final int id;

  /// Markdown comment body (raw).
  final String body;

  /// Comment body rendered to HTML by GitHub (`full+json` media type).
  /// Carries pre-signed URLs for private user-attachments.
  final String? bodyHtml;

  /// Path of the file the comment is attached to.
  final String path;

  /// Diff hunk that the comment was written against.
  final String diffHunk;

  /// Line in the diff this comment is anchored to (latest revision).
  final int? line;

  /// Original line at the time the comment was created.
  final int? originalLine;

  /// Start line for a multi-line comment.
  final int? startLine;

  /// `LEFT` (old side) or `RIGHT` (new side).
  final String side;

  /// If this comment is a reply, the id of the parent comment.
  final int? inReplyToId;

  /// Author of the comment.
  final GitHubUser? user;

  /// Creation timestamp.
  final DateTime? createdAt;

  /// Last update timestamp.
  final DateTime? updatedAt;

  final GitHubReactionSummary? reactions;

  int? get anchorLine => line ?? originalLine;
}
