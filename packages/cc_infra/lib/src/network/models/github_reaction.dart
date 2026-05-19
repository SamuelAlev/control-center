import 'package:cc_infra/src/network/models/github_user.dart';

/// Summary of reaction counts on a comment, issue, or PR (e.g. 👍 3, ❤️ 1).
class GitHubReactionSummary {
  /// Creates a [GitHubReactionSummary].
  const GitHubReactionSummary({
    this.totalCount = 0,
    this.plusOne = 0,
    this.minusOne = 0,
    this.laugh = 0,
    this.hooray = 0,
    this.confused = 0,
    this.heart = 0,
    this.rocket = 0,
    this.eyes = 0,
  });

  /// Creates a [GitHubReactionSummary] from JSON.
  factory GitHubReactionSummary.fromJson(Map<String, dynamic> json) {
    return GitHubReactionSummary(
      totalCount: (json['total_count'] as num?)?.toInt() ?? 0,
      plusOne: (json['+1'] as num?)?.toInt() ?? 0,
      minusOne: (json['-1'] as num?)?.toInt() ?? 0,
      laugh: (json['laugh'] as num?)?.toInt() ?? 0,
      hooray: (json['hooray'] as num?)?.toInt() ?? 0,
      confused: (json['confused'] as num?)?.toInt() ?? 0,
      heart: (json['heart'] as num?)?.toInt() ?? 0,
      rocket: (json['rocket'] as num?)?.toInt() ?? 0,
      eyes: (json['eyes'] as num?)?.toInt() ?? 0,
    );
  }

  /// Serializes to the GitHub JSON shape.
  Map<String, dynamic> toJson() => <String, dynamic>{
    'total_count': totalCount,
    '+1': plusOne,
    '-1': minusOne,
    'laugh': laugh,
    'hooray': hooray,
    'confused': confused,
    'heart': heart,
    'rocket': rocket,
    'eyes': eyes,
  };

  /// Total number of reactions.
  final int totalCount;
  /// Number of 👍 (+1) reactions.
  final int plusOne;
  /// Number of 👎 (-1) reactions.
  final int minusOne;
  /// Number of 😄 reactions.
  final int laugh;
  /// Number of 🎉 reactions.
  final int hooray;
  /// Number of 😕 reactions.
  final int confused;
  /// Number of ❤️ reactions.
  final int heart;
  /// Number of 🚀 reactions.
  final int rocket;
  /// Number of 👀 reactions.
  final int eyes;
}

/// A single reaction on a comment, issue, or PR.
class GitHubReaction {
  /// Creates a [GitHubReaction].
  const GitHubReaction({
    required this.id,
    required this.content,
    this.user,
  });

  /// Creates a [GitHubReaction] from JSON.
  factory GitHubReaction.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    return GitHubReaction(
      id: (json['id'] as num?)?.toInt() ?? 0,
      content: json['content'] as String? ?? '',
      user: user is Map<String, dynamic> ? GitHubUser.fromJson(user) : null,
    );
  }

  /// Unique identifier for the reaction.
  final int id;
  /// Reaction content type (e.g. `+1`, `-1`, `laugh`).
  final String content;
  /// The user who created the reaction.
  final GitHubUser? user;
}
