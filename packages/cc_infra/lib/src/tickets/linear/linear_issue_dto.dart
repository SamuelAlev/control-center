/// Typed representation of a Linear issue. Adapter-internal — nothing outside
/// `lib/features/ticketing/data/providers/linear/` may import this.
class LinearIssueDto {
  /// Creates a [LinearIssueDto].
  const LinearIssueDto({
    required this.id,
    required this.identifier,
    required this.title,
    required this.description,
    required this.stateName,
    required this.priority,
    required this.teamName,
    this.url,
    this.labels = const [],
    this.assigneeId,
  });

  /// Creates a [LinearIssueDto] from a JSON map.
  factory LinearIssueDto.fromJson(Map<String, dynamic> json) {
    final state = json['state'] as Map<String, dynamic>?;
    final team = json['team'] as Map<String, dynamic>?;
    final assignee = json['assignee'] as Map<String, dynamic>?;
    final labelsMap = json['labels'] as Map<String, dynamic>?;
    final labelNodes = labelsMap?['nodes'];
    return LinearIssueDto(
      id: json['id'] as String? ?? '',
      identifier: json['identifier'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      stateName: state?['name'] as String? ?? '',
      priority: json['priority'] as int? ?? 0,
      teamName: team?['name'] as String? ?? '',
      url: json['url'] as String?,
      assigneeId: assignee?['id'] as String?,
      labels: labelNodes is List
          ? labelNodes
              .map((e) => e is Map<String, dynamic> ? e['name'] as String? : null)
              .whereType<String>()
              .toList()
          : const [],
    );
  }

  /// Issue ID.
  final String id;

  /// Human-readable identifier (e.g. LIN-123).
  final String identifier;

  /// Issue title.
  final String title;

  /// Issue description.
  final String description;

  /// Name of the issue state.
  final String stateName;

  /// Priority (0=None, 1=Urgent, 2=High, 3=Medium, 4=Low).
  final int priority;

  /// Name of the team.
  final String teamName;

  /// Web URL.
  final String? url;

  /// Label names.
  final List<String> labels;

  /// Assignee user id.
  final String? assigneeId;
}
