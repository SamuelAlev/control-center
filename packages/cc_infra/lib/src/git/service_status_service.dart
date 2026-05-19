import 'package:cc_domain/features/service_status/domain/entities/github_service_status.dart';
import 'package:dio/dio.dart';

/// URL for the GitHub status summary endpoint (Statuspage v2 API).
const String githubStatusSummaryUrl =
    'https://www.githubstatus.com/api/v2/summary.json';

/// URL for the Claude status summary endpoint (Statuspage v2 API, same shape
/// as githubstatus.com — status.claude.com is Statuspage-hosted).
const String claudeStatusSummaryUrl =
    'https://status.claude.com/api/v2/summary.json';

/// URL for the OpenAI status summary endpoint (Statuspage v2 API —
/// status.openai.com carries the Codex components).
const String openaiStatusSummaryUrl =
    'https://status.openai.com/api/v2/summary.json';

/// URL for the Moonshot AI status summary endpoint (Statuspage v2 API —
/// status.moonshot.cn carries the Kimi components).
const String kimiStatusSummaryUrl =
    'https://status.moonshot.cn/api/v2/summary.json';

/// Fetches Statuspage v2 summaries (githubstatus.com, status.claude.com,
/// status.openai.com, status.moonshot.cn).
class ServiceStatusService {
  /// Creates a [ServiceStatusService] using the given [Dio] client, fetching
  /// [summaryUrl] (githubstatus.com by default; pass [claudeStatusSummaryUrl],
  /// [openaiStatusSummaryUrl], or [kimiStatusSummaryUrl] for the AI
  /// providers).
  ServiceStatusService(this._dio, {this.summaryUrl = githubStatusSummaryUrl});

  final Dio _dio;

  /// The Statuspage `summary.json` endpoint this instance fetches.
  final String summaryUrl;

  /// Fetches the current GitHub status summary, parsed into the domain entity.
  Future<GitHubServiceStatus> fetch() async =>
      GitHubServiceStatus.fromSummaryJson(await fetchSummaryJson());

  /// Fetches the raw Statuspage `summary.json` map. The `github.serviceStatus`
  /// / `claude.serviceStatus` RPC ops return this verbatim so the thin client
  /// parses it with the shared [GitHubServiceStatus.fromSummaryJson] factory
  /// (the client holds no Dio and the browser cannot fetch the status pages
  /// cross-origin).
  Future<Map<String, dynamic>> fetchSummaryJson() async {
    final response = await _dio.getUri<Map<String, dynamic>>(
      Uri.parse(summaryUrl),
    );
    return response.data ?? const <String, dynamic>{};
  }
}
