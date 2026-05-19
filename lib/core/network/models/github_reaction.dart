import 'package:control_center/core/network/models/github_user.dart';

class GitHubReactionSummary {
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

  final int totalCount;
  final int plusOne;
  final int minusOne;
  final int laugh;
  final int hooray;
  final int confused;
  final int heart;
  final int rocket;
  final int eyes;
}

class GitHubReaction {
  const GitHubReaction({
    required this.id,
    required this.content,
    this.user,
  });

  factory GitHubReaction.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    return GitHubReaction(
      id: (json['id'] as num?)?.toInt() ?? 0,
      content: json['content'] as String? ?? '',
      user: user is Map<String, dynamic> ? GitHubUser.fromJson(user) : null,
    );
  }

  final int id;
  final String content;
  final GitHubUser? user;
}
