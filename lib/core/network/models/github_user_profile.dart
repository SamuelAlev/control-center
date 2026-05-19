import 'package:control_center/core/network/models/date_parser.dart';

class GitHubContributionDay {
  const GitHubContributionDay({
    required this.contributionCount,
    required this.date,
  });

  factory GitHubContributionDay.fromJson(Map<String, dynamic> json) {
    return GitHubContributionDay(
      contributionCount: (json['contributionCount'] as num?)?.toInt() ?? 0,
      date: parseDate(json['date']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'contributionCount': contributionCount,
    'date': date.toIso8601String(),
  };

  final int contributionCount;
  final DateTime date;
}

class GitHubContributionWeek {
  const GitHubContributionWeek({required this.contributionDays});

  factory GitHubContributionWeek.fromJson(Map<String, dynamic> json) {
    final days = json['contributionDays'] as List?;
    return GitHubContributionWeek(
      contributionDays:
          days != null
              ? days
                  .whereType<Map<String, dynamic>>()
                  .map(GitHubContributionDay.fromJson)
                  .toList(growable: false)
              : const <GitHubContributionDay>[],
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'contributionDays': contributionDays.map((d) => d.toJson()).toList(),
  };

  final List<GitHubContributionDay> contributionDays;
}

class GitHubContributionCalendar {
  const GitHubContributionCalendar({
    required this.totalContributions,
    required this.weeks,
    this.restrictedContributions = 0,
  });

  factory GitHubContributionCalendar.fromJson(
    Map<String, dynamic> json, {
    int restrictedContributions = 0,
  }) {
    final weeksList = json['weeks'] as List?;
    return GitHubContributionCalendar(
      totalContributions: (json['totalContributions'] as num?)?.toInt() ?? 0,
      restrictedContributions: restrictedContributions,
      weeks:
          weeksList != null
              ? weeksList
                  .whereType<Map<String, dynamic>>()
                  .map(GitHubContributionWeek.fromJson)
                  .toList(growable: false)
              : const <GitHubContributionWeek>[],
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'totalContributions': totalContributions,
    'restrictedContributions': restrictedContributions,
    'weeks': weeks.map((w) => w.toJson()).toList(),
  };

  /// Public contributions visible to the API viewer (drives the heatmap
  /// cells).
  final int totalContributions;

  /// Contributions to private repos that the API viewer cannot see. GitHub
  /// reports this as a separate count (`restrictedContributionsCount`) on
  /// `contributionsCollection`. The full number GitHub.com shows on a
  /// profile is `totalContributions + restrictedContributions`.
  final int restrictedContributions;

  final List<GitHubContributionWeek> weeks;

  /// All contributions, including private ones invisible to the API viewer.
  int get grandTotal => totalContributions + restrictedContributions;
}

class GitHubOrganization {
  const GitHubOrganization({
    required this.login,
    required this.name,
    required this.avatarUrl,
    required this.url,
  });

  factory GitHubOrganization.fromJson(Map<String, dynamic> json) {
    return GitHubOrganization(
      login: json['login'] as String? ?? '',
      name: json['name'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String? ?? '',
      url: json['url'] as String? ?? '',
    );
  }

  final String login;
  final String name;
  final String avatarUrl;
  final String url;
}

class GitHubUserStatus {
  const GitHubUserStatus({
    required this.isBusy,
    this.message,
    this.emoji,
  });

  factory GitHubUserStatus.fromJson(Map<String, dynamic> json) {
    return GitHubUserStatus(
      isBusy: json['indicatesLimitedAvailability'] as bool? ?? false,
      message: json['message'] as String?,
      emoji: json['emoji'] as String?,
    );
  }

  final bool isBusy;
  final String? message;
  final String? emoji;
}

class GitHubUserProfile {
  const GitHubUserProfile({
    required this.login,
    required this.name,
    required this.avatarUrl,
    this.bio,
    this.location,
    this.company,
    this.websiteUrl,
    this.twitterUsername,
    this.status,
    this.organizations = const <GitHubOrganization>[],
    this.orgTeams = const <String>[],
    this.contributionCalendar,
  });

  factory GitHubUserProfile.fromJson(Map<String, dynamic> json) {
    final collection = json['contributionsCollection'] is Map
        ? json['contributionsCollection'] as Map
        : null;
    final calendarJson = collection != null
        ? collection['contributionCalendar']
        : null;
    final restricted =
        (collection?['restrictedContributionsCount'] as num?)?.toInt() ?? 0;
    final orgsJson = json['organizations'] is Map
        ? (json['organizations'] as Map)['nodes'] as List?
        : null;
    final statusJson = json['status'] is Map<String, dynamic>
        ? json['status'] as Map<String, dynamic>
        : null;
    return GitHubUserProfile(
      login: json['login'] as String? ?? '',
      name: json['name'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String? ?? '',
      bio: json['bio'] as String?,
      location: json['location'] as String?,
      company: json['company'] as String?,
      websiteUrl: json['websiteUrl'] as String?,
      twitterUsername: json['twitterUsername'] as String?,
      status: statusJson != null
          ? GitHubUserStatus.fromJson(statusJson)
          : null,
      organizations: orgsJson != null
          ? orgsJson
              .whereType<Map<String, dynamic>>()
              .map(GitHubOrganization.fromJson)
              .where((o) => o.login.isNotEmpty)
              .toList(growable: false)
          : const <GitHubOrganization>[],
      orgTeams: orgsJson != null
          ? orgsJson
              .whereType<Map<String, dynamic>>()
              .map<String>((o) => o['login'] as String? ?? '')
              .where((l) => l.isNotEmpty)
              .toList(growable: false)
          : const <String>[],
      contributionCalendar:
          calendarJson is Map<String, dynamic>
              ? GitHubContributionCalendar.fromJson(
                  calendarJson,
                  restrictedContributions: restricted,
                )
              : null,
    );
  }

  final String login;
  final String name;
  final String avatarUrl;
  final String? bio;
  final String? location;
  final String? company;
  final String? websiteUrl;
  final String? twitterUsername;
  final GitHubUserStatus? status;
  final List<GitHubOrganization> organizations;
  final List<String> orgTeams;
  final GitHubContributionCalendar? contributionCalendar;
}
