import 'dart:convert';
import 'dart:io';

import 'package:control_center/core/domain/repositories/agent_run_log_repository.dart';
import 'package:control_center/features/mcp/application/tools/read/internal_url.dart';
import 'package:control_center/features/mcp/application/tools/read/internal_url_router.dart';
import 'package:control_center/features/mcp/domain/ports/mcp_tool_port.dart';

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

    // Try direct run log ID match first.
    final log = await _runLogs.getById(id);

    if (log == null || log.logPath == null) {
      // List all available log IDs.
      final allLogs = await _runLogs.watchAll().first;
      final available = allLogs
          .where((l) => l.logPath != null)
          .map((l) => l.id)
          .toList();
      return CallResult.error(
        'Artifact not found: $id\n'
        'Available: ${available.isNotEmpty ? available.join(", ") : "none"}',
      );
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
