import 'dart:convert';

import 'package:control_center/core/network/github_content_client.dart';
import 'package:control_center/features/mcp/application/tools/read/internal_url.dart';
import 'package:control_center/features/mcp/application/tools/read/internal_url_router.dart';
import 'package:control_center/features/mcp/domain/ports/mcp_tool_port.dart';

/// Handles `gh://owner/repo/blob/<ref>/<path>` URLs. Replaces the dedicated
/// `get_github_file_content` tool.
class GhProtocolHandler {
  /// Creates a [GhProtocolHandler].
  GhProtocolHandler({required GitHubContentClient client}) : _client = client;

  final GitHubContentClient _client;

  /// Resolves [url] against GitHub and returns the file contents.
  Future<CallResult> handle(GhBlobUrl url, ReadContext context) async {
    final content = await _client.getFileContent(
      url.owner,
      url.repo,
      url.path,
      url.ref,
    );
    return CallResult.success(
      jsonEncode({
        'owner': url.owner,
        'repo': url.repo,
        'ref': url.ref,
        'path': url.path,
        'content': content,
      }),
    );
  }
}
