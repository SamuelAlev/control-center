import 'package:control_center/core/network/models/date_parser.dart';

/// A single day of GitHub contribution activity.
class GitHubContributionDay {
  /// Creates a [GitHubContributionDay] with the given [contributionCount]
  /// and [date].
  const GitHubContributionDay({
    required this.contributionCount,
    required this.date,
  });

  /// Creates a [GitHubContributionDay] from a JSON map.
  factory GitHubContributionDay.fromJson(Map<String, dynamic> json) {
    return GitHubContributionDay(
      contributionCount: (json['contributionCount'] as num?)?.toInt() ?? 0,
      date: parseDate(json['date']) ?? DateTime.now(),
    );
  }

  /// Converts this [GitHubContributionDay] to a JSON map.
  Map<String, dynamic> toJson() => <String, dynamic>{
    'contributionCount': contributionCount,
    'date': date.toIso8601String(),
  };

  /// The number of contributions on this day.
  final int contributionCount;
  /// The date of this contribution day.
  final DateTime date;
}

/// A week of GitHub contribution days.
class GitHubContributionWeek {
  /// Creates a [GitHubContributionWeek] with the given [contributionDays].
  const GitHubContributionWeek({required this.contributionDays});

  /// Creates a [GitHubContributionWeek] from a JSON map.
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

  /// Converts this [GitHubContributionWeek] to a JSON map.
  Map<String, dynamic> toJson() => <String, dynamic>{
    'contributionDays': contributionDays.map((d) => d.toJson()).toList(),
  };

  /// The contribution days in this week.
  final List<GitHubContributionDay> contributionDays;
}

/// A GitHub contribution calendar containing weeks of contribution data.
class GitHubContributionCalendar {
  /// Creates a [GitHubContributionCalendar].
  const GitHubContributionCalendar({
    required this.totalContributions,
    required this.weeks,
    this.restrictedContributions = 0,
  });

  /// Creates a [GitHubContributionCalendar] from a JSON map.
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

  /// Converts this [GitHubContributionCalendar] to a JSON map.
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

  /// The weeks of contribution data.
  final List<GitHubContributionWeek> weeks;

  /// All contributions, including private ones invisible to the API viewer.
  int get grandTotal => totalContributions + restrictedContributions;
}

/// A GitHub organization the user belongs to.
class GitHubOrganization {
  /// Creates a [GitHubOrganization].
  const GitHubOrganization({
    required this.login,
    required this.name,
    required this.avatarUrl,
    required this.url,
  });

  /// Creates a [GitHubOrganization] from a JSON map.
  factory GitHubOrganization.fromJson(Map<String, dynamic> json) {
    return GitHubOrganization(
      login: json['login'] as String? ?? '',
      name: json['name'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String? ?? '',
      url: json['url'] as String? ?? '',
    );
  }

  /// The organization's login name.
  final String login;
  /// The organization's display name.
  final String name;
  /// The URL of the organization's avatar.
  final String avatarUrl;
  /// The GitHub URL for the organization.
  final String url;
}

/// The user's GitHub status.
class GitHubUserStatus {
  /// Creates a [GitHubUserStatus].
  const GitHubUserStatus({
    required this.isBusy,
    this.message,
    this.emoji,
  });

  /// Creates a [GitHubUserStatus] from a JSON map.
  factory GitHubUserStatus.fromJson(Map<String, dynamic> json) {
    return GitHubUserStatus(
      isBusy: json['indicatesLimitedAvailability'] as bool? ?? false,
      message: json['message'] as String?,
      emoji: json['emoji'] as String?,
    );
  }

  /// Whether the user has indicated limited availability.
  final bool isBusy;
  /// The status message, if any.
  final String? message;
  /// The emoji representing the status, if any.
  final String? emoji;
}

/// A GitHub user profile with organizations, status, and contribution data.
class GitHubUserProfile {
  /// Creates a [GitHubUserProfile] with the given fields.
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

  /// Creates a [GitHubUserProfile] from a JSON map.
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

  /// The user's login name.
  final String login;
  /// The user's display name.
  final String name;
  /// The URL of the user's avatar.
  final String avatarUrl;
  /// The user's biography.
  final String? bio;
  /// The user's location.
  final String? location;
  /// The user's company.
  final String? company;
  /// The user's website URL.
  final String? websiteUrl;
  /// The user's Twitter username.
  final String? twitterUsername;
  /// The user's current GitHub status.
  final GitHubUserStatus? status;
  /// The organizations the user belongs to.
  final List<GitHubOrganization> organizations;
  /// The organization team names the user belongs to.
  final List<String> orgTeams;
  /// The user's contribution calendar.
  final GitHubContributionCalendar? contributionCalendar;
}
