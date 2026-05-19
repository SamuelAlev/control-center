import 'package:cc_domain/features/github_status/domain/entities/github_service_status.dart';
import 'package:dio/dio.dart';

/// URL for the GitHub status summary endpoint (Statuspage v2 API).
const String githubStatusSummaryUrl =
    'https://www.githubstatus.com/api/v2/summary.json';

/// Fetches the GitHub status summary from githubstatus.com.
class GitHubStatusService {
  /// Creates a [GitHubStatusService] using the given [Dio] client.
  GitHubStatusService(this._dio);

  final Dio _dio;

  /// Fetches the current GitHub status summary, parsed into the domain entity.
  Future<GitHubServiceStatus> fetch() async =>
      GitHubServiceStatus.fromSummaryJson(await fetchSummaryJson());

  /// Fetches the raw Statuspage `summary.json` map. The `github.serviceStatus`
  /// RPC op returns this verbatim so the thin client parses it with the shared
  /// [GitHubServiceStatus.fromSummaryJson] factory (the client holds no Dio and
  /// the browser cannot fetch githubstatus.com cross-origin).
  Future<Map<String, dynamic>> fetchSummaryJson() async {
    final response = await _dio.getUri<Map<String, dynamic>>(
      Uri.parse(githubStatusSummaryUrl),
    );
    return response.data ?? const <String, dynamic>{};
  }
}
