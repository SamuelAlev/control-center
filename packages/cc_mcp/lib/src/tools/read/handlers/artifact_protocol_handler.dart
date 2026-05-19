import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_mcp/src/tools/read/internal_url.dart';
import 'package:cc_mcp/src/tools/read/internal_url_router.dart';

/// Handles `artifact://<id>` URLs — raw captured artifacts
/// (logs, traces, tool outputs). Reads from the agent run log
/// `logPath` file on disk.
class ArtifactProtocolHandler {
  /// Creates an [ArtifactProtocolHandler].
  ArtifactProtocolHandler({required AgentRunLogRepository runLogs})
    : _runLogs = runLogs;

  final AgentRunLogRepository _runLogs;

  /// Resolves [url] by locating the artifact on disk.
  Future<CallResult> handle(ArtifactUrl url, ReadContext context) async {
    final id = url.id.toString();
    final workspaceId = context.workspaceId;

    // VULN-005: only resolve when bound to a workspace AND the log belongs to
    // it. No cross-workspace id enumeration — a foreign/missing id is simply
    // "not found".
    final byId = await _runLogs.getById(id);
    final log = (byId != null &&
            byId.logPath != null &&
            workspaceId != null &&
            byId.workspaceId == workspaceId)
        ? byId
        : null;

    if (log == null) {
      return CallResult.error('Artifact not found: $id');
    }

    final file = File(log.logPath!);
    if (!file.existsSync()) {
      return CallResult.error(
        'Artifact file not found on disk: ${log.logPath}',
      );
    }

    final content = file.readAsStringSync();

    return CallResult.success(
      jsonEncode({
        'artifact_id': id,
        'log_path': log.logPath,
        'content': content,
      }),
    );
  }
}
