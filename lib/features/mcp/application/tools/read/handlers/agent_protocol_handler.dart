import 'dart:convert';
import 'dart:io';

import 'package:control_center/core/domain/repositories/agent_run_log_repository.dart';
import 'package:control_center/features/mcp/application/tools/read/internal_url.dart';
import 'package:control_center/features/mcp/application/tools/read/internal_url_router.dart';
import 'package:control_center/features/mcp/application/tools/read/json_query.dart';
import 'package:control_center/features/mcp/domain/ports/mcp_tool_port.dart';

/// Handles `agent://<id>[/<json-path>]` URLs by resolving an agent output
/// artifact and optionally extracting a JSON field.
class AgentProtocolHandler {
  /// Creates an [AgentProtocolHandler].
  AgentProtocolHandler({required AgentRunLogRepository runLogs})
    : _runLogs = runLogs;

  final AgentRunLogRepository _runLogs;

  /// Resolves [url] by locating the agent run log and extracting content.
  Future<CallResult> handle(AgentUrl url, ReadContext context) async {
    final id = url.id;

    // Try to find by run log ID first.
    final log = await _runLogs.getById(id);

    if (log == null || log.logPath == null) {
      // Try to find by agent ID — return the most recent completed run.
      final logs = await _runLogs.watchByAgent(id).first;
      final completed = logs.where(
        (l) => l.isCompleted && l.logPath != null,
      );
      if (completed.isEmpty) {
        final allIds = logs.map((l) => l.id).toList();
        return CallResult.error(
          'Agent output not found: $id\n'
          'Available run log IDs: ${allIds.isNotEmpty ? allIds.join(", ") : "none"}',
        );
      }
      final latest = completed.reduce(
        (a, b) => a.startedAt.isAfter(b.startedAt) ? a : b,
      );
      return _readLogFile(latest.logPath!, url.jsonPath);
    }

    return _readLogFile(log.logPath!, url.jsonPath);
  }

  Future<CallResult> _readLogFile(
    String logPath,
    String? jsonPath,
  ) async {
    final file = File(logPath);
    if (!await file.exists()) {
      return CallResult.error(
        'Log file not found on disk: $logPath',
      );
    }

    final rawContent = await file.readAsString();

    if (jsonPath == null || jsonPath.isEmpty) {
      return CallResult.success(
        jsonEncode({
          'log_path': logPath,
          'content': rawContent,
        }),
      );
    }

    // JSON field extraction.
    final query = pathToQuery(jsonPath);
    if (query.isEmpty) {
      return CallResult.success(
        jsonEncode({
          'log_path': logPath,
          'content': rawContent,
        }),
      );
    }

    dynamic jsonValue;
    try {
      jsonValue = jsonDecode(rawContent);
    } catch (e) {
      return CallResult.error(
        'Agent output at $logPath is not valid JSON: $e',
      );
    }

    final extracted = applyQuery(jsonValue, query);

    return CallResult.success(
      jsonEncode({
        'log_path': logPath,
        'query': query,
        'content': extracted,
      }),
    );
  }
}
