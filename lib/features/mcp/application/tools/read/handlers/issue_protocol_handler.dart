import 'package:control_center/core/errors/app_exceptions.dart';
import 'package:control_center/core/network/github_pr_client.dart';
import 'package:control_center/features/mcp/application/tools/read/internal_url.dart';
import 'package:control_center/features/mcp/application/tools/read/internal_url_router.dart';
import 'package:control_center/features/mcp/domain/ports/mcp_tool_port.dart';

/// Handles `issue://owner/repo/<n>` URLs. Reuses the issue-comments endpoint
/// on [GitHubPrClient] (PRs and issues share that namespace).
class IssueProtocolHandler {
  /// Creates an [IssueProtocolHandler].
  IssueProtocolHandler({required GitHubPrClient client}) : _client = client;

  final GitHubPrClient _client;

  /// Resolves [url] against GitHub and returns a markdown summary.
  Future<CallResult> handle(IssueUrl url, ReadContext context) async {
    final owner = url.owner;
    final repo = url.repo;
    final number = url.number;

    try {
      final comments =
          await _client.listIssueComments(owner, repo, number);
      final body = StringBuffer()
        ..writeln('# $owner/$repo issue #$number')
        ..writeln()
        ..writeln('Comments: ${comments.length}')
        ..writeln();
      for (final c in comments) {
        body
          ..writeln('## ${c.user?.login ?? 'unknown'} '
              '— ${c.createdAt?.toIso8601String() ?? ''}')
          ..writeln()
          ..writeln(c.body)
          ..writeln();
      }
      return CallResult.success(body.toString());
    } on NetworkException catch (e) {
      if (e.statusCode == 404) {
        return CallResult.error(
          'Repository not found or not accessible: $owner/$repo (HTTP 404)\n'
          'This can mean:\n'
          '1. The repository is private — verify you have a GitHub token configured.\n'
          '   Open Settings → GitHub in the Control Center app, or run `gh auth status`.\n'
          '   The token must have the `repo` scope for private repositories.\n'
          '2. The owner or repo name is misspelled (case-sensitive).\n'
          '3. Issue #$number does not exist in this repository.\n'
          'If you confirmed auth is set up, the repository or issue may genuinely not exist.',
        );
      }
      return CallResult.error('${e.message} (HTTP ${e.statusCode})');
    } catch (e) {
      return CallResult.error('$e');
    }
  }
}
