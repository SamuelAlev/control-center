import 'package:control_center/features/github_status/domain/entities/github_service_status.dart';
import 'package:dio/dio.dart';

/// URL for the GitHub status summary endpoint (Statuspage v2 API).
const String githubStatusSummaryUrl =
    'https://www.githubstatus.com/api/v2/summary.json';

/// Fetches the GitHub status summary from githubstatus.com.
class GitHubStatusService {
  /// Creates a [GitHubStatusService] using the given [Dio] client.
  GitHubStatusService(this._dio);

  final Dio _dio;

  /// Fetches the current GitHub status summary.
  Future<GitHubServiceStatus> fetch() async {
    final response = await _dio.getUri<Map<String, dynamic>>(
      Uri.parse(githubStatusSummaryUrl),
    );
    final data = response.data ?? const <String, dynamic>{};
    return _parse(data);
  }

  GitHubServiceStatus _parse(Map<String, dynamic> data) {
    final statusBlock =
        (data['status'] as Map<String, dynamic>?) ?? const {};
    final indicator =
        GitHubStatusIndicator.fromApi(statusBlock['indicator'] as String?);
    final description =
        (statusBlock['description'] as String?) ?? 'Unknown status';

    final rawComponents = (data['components'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .where((c) => c['only_show_if_degraded'] != true)
        .where(
          (c) =>
              (c['name'] as String?) !=
              'Visit www.githubstatus.com for more information',
        )
        .toList();

    final components = rawComponents
        .map(
          (c) => GitHubStatusComponent(
            id: (c['id'] as String?) ?? '',
            name: (c['name'] as String?) ?? '',
            status: GitHubComponentStatus.fromApi(c['status'] as String?),
            position: (c['position'] as num?)?.toInt() ?? 0,
          ),
        )
        .toList()
      ..sort((a, b) => a.position.compareTo(b.position));

    final incidents = (data['incidents'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(
          (i) => GitHubStatusIncident(
            id: (i['id'] as String?) ?? '',
            name: (i['name'] as String?) ?? '',
            status: (i['status'] as String?) ?? '',
            shortlink: (i['shortlink'] as String?) ??
                'https://www.githubstatus.com/',
            createdAt: _parseDate(i['created_at']),
            updatedAt: _parseDate(i['updated_at']),
          ),
        )
        .toList();

    return GitHubServiceStatus(
      indicator: indicator,
      description: description,
      components: components,
      incidents: incidents,
      fetchedAt: DateTime.now(),
    );
  }

  DateTime _parseDate(Object? value) {
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
