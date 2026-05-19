import 'package:control_center/core/network/models/date_parser.dart';
import 'package:control_center/core/network/models/github_user.dart';

/// A commit in a pull request.
class GitHubCommit {
  /// Creates a [GitHubCommit].
  const GitHubCommit({
    required this.sha,
    required this.message,
    required this.authorName,
    required this.authorEmail,
    this.author,
    this.committedAt,
  });

  /// Creates a [GitHubCommit] from JSON.
  factory GitHubCommit.fromJson(Map<String, dynamic> json) {
    final commit = json['commit'] as Map<String, dynamic>?;
    final commitAuthor = commit?['author'] as Map<String, dynamic>?;
    final author = json['author'];
    return GitHubCommit(
      sha: json['sha'] as String? ?? '',
      message: commit?['message'] as String? ?? '',
      authorName: commitAuthor?['name'] as String? ?? '',
      authorEmail: commitAuthor?['email'] as String? ?? '',
      author: author is Map<String, dynamic>
          ? GitHubUser.fromJson(author)
          : null,
      committedAt: parseDate(commitAuthor?['date']),
    );
  }

  /// Serializes this commit back to the GitHub JSON shape.
  Map<String, dynamic> toJson() => <String, dynamic>{
    'sha': sha,
    'commit': <String, dynamic>{
      'message': message,
      'author': <String, dynamic>{
        'name': authorName,
        'email': authorEmail,
        'date': committedAt?.toIso8601String(),
      },
    },
    'author': author?.toJson(),
  };

  /// Full SHA.
  final String sha;

  /// Full commit message (first line is treated as title, rest as body).
  final String message;

  /// Name of the commit author (from the git commit).
  final String authorName;

  /// Email of the commit author.
  final String authorEmail;

  /// GitHub profile of the author, if linked.
  final GitHubUser? author;

  /// When the commit was authored.
  final DateTime? committedAt;

  /// Short 7-char SHA.
  String get shortSha => sha.length >= 7 ? sha.substring(0, 7) : sha;

  /// First line of the commit message.
  String get title {
    final newline = message.indexOf('\n');
    return newline == -1 ? message : message.substring(0, newline);
  }

  /// Body of the commit message (everything after the first line).
  String get bodyText {
    final newline = message.indexOf('\n');
    if (newline == -1) {
      return '';
    }

    return message.substring(newline + 1).trim();
  }
}
