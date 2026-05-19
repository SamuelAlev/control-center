import 'dart:convert';

import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_infra/src/network/github_content_client.dart';
import 'package:cc_mcp/src/tools/read/internal_url.dart';
import 'package:cc_mcp/src/tools/read/internal_url_router.dart';

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
