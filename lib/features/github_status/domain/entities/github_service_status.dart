/// Overall health of GitHub services.
enum GitHubStatusIndicator {
  /// All systems operational.
  none,

  /// Minor issues (e.g. partial degradation).
  minor,

  /// Major issues (degraded performance, partial outage).
  major,

  /// Critical issues (major outage).
  critical,

  /// Maintenance is in progress.
  maintenance,

  /// Indicator is unknown / could not be parsed.
  unknown;

  /// Parses the `indicator` field returned by the GitHub status API.
  static GitHubStatusIndicator fromApi(String? value) {
    switch (value) {
      case 'none':
        return GitHubStatusIndicator.none;
      case 'minor':
        return GitHubStatusIndicator.minor;
      case 'major':
        return GitHubStatusIndicator.major;
      case 'critical':
        return GitHubStatusIndicator.critical;
      case 'maintenance':
        return GitHubStatusIndicator.maintenance;
      default:
        return GitHubStatusIndicator.unknown;
    }
  }
}

/// Status of an individual GitHub component.
enum GitHubComponentStatus {
  /// The component is healthy.
  operational,

  /// The component has degraded performance.
  degradedPerformance,

  /// The component is partially down.
  partialOutage,

  /// The component is fully down.
  majorOutage,

  /// The component is under planned maintenance.
  underMaintenance,

  /// The component status could not be parsed.
  unknown;

  /// Parses the `status` field of a component from the GitHub status API.
  static GitHubComponentStatus fromApi(String? value) {
    switch (value) {
      case 'operational':
        return GitHubComponentStatus.operational;
      case 'degraded_performance':
        return GitHubComponentStatus.degradedPerformance;
      case 'partial_outage':
        return GitHubComponentStatus.partialOutage;
      case 'major_outage':
        return GitHubComponentStatus.majorOutage;
      case 'under_maintenance':
        return GitHubComponentStatus.underMaintenance;
      default:
        return GitHubComponentStatus.unknown;
    }
  }
}

/// A single GitHub service component (Git Operations, API Requests, etc.).
class GitHubStatusComponent {
  /// Creates a [GitHubStatusComponent].
  const GitHubStatusComponent({
    required this.id,
    required this.name,
    required this.status,
    required this.position,
  });

  /// Stable component identifier.
  final String id;

  /// Human-readable component name.
  final String name;

  /// Current component status.
  final GitHubComponentStatus status;

  /// Sort position from the API (used to keep the original ordering).
  final int position;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GitHubStatusComponent &&
          other.id == id &&
          other.name == name &&
          other.status == status &&
          other.position == position;

  @override
  int get hashCode => Object.hash(id, name, status, position);
}

/// An active GitHub incident.
class GitHubStatusIncident {
  /// Creates a [GitHubStatusIncident].
  const GitHubStatusIncident({
    required this.id,
    required this.name,
    required this.status,
    required this.shortlink,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Stable incident identifier.
  final String id;

  /// Incident headline.
  final String name;

  /// Current status string (e.g. "investigating", "identified", "monitoring").
  final String status;

  /// Short link to the incident page on githubstatus.com.
  final String shortlink;

  /// Time the incident was first reported.
  final DateTime createdAt;

  /// Time the incident was last updated.
  final DateTime updatedAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GitHubStatusIncident &&
          other.id == id &&
          other.name == name &&
          other.status == status &&
          other.shortlink == shortlink &&
          other.createdAt == createdAt &&
          other.updatedAt == updatedAt;

  @override
  int get hashCode =>
      Object.hash(id, name, status, shortlink, createdAt, updatedAt);
}

/// Aggregated GitHub service status returned by the public status API.
class GitHubServiceStatus {
  /// Creates a [GitHubServiceStatus].
  const GitHubServiceStatus({
    required this.indicator,
    required this.description,
    required this.components,
    required this.incidents,
    required this.fetchedAt,
  });

  /// Overall indicator (none / minor / major / critical / maintenance).
  final GitHubStatusIndicator indicator;

  /// Human-readable summary (e.g. "All Systems Operational").
  final String description;

  /// Per-component statuses, sorted by `position`.
  final List<GitHubStatusComponent> components;

  /// Currently open incidents (resolved incidents are excluded by the API).
  final List<GitHubStatusIncident> incidents;

  /// When this snapshot was fetched.
  final DateTime fetchedAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GitHubServiceStatus &&
          other.indicator == indicator &&
          other.description == description &&
          _listEquals(other.components, components) &&
          _listEquals(other.incidents, incidents) &&
          other.fetchedAt == fetchedAt;

  @override
  int get hashCode => Object.hash(
        indicator,
        description,
        Object.hashAll(components),
        Object.hashAll(incidents),
        fetchedAt,
      );
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) {
    return true;
  }
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}
