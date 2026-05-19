import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/core/domain/value_objects/agent_capabilities.dart';
import 'package:cc_domain/features/dispatch/domain/entities/agent_process_event.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';
import 'package:cc_infra/src/util/command_redaction.dart';
import 'package:path/path.dart' as p;

/// Writes agent run events to an NDJSON log file with coalescing of
/// high-frequency event types like "thinking" and "text".
class RunLogWriter {
  /// Creates a [RunLogWriter] with configurable log coalescing settings.
  RunLogWriter({
    this.coalesceableLogTypes = const {'thinking', 'text'},
    this.logCoalesceWindow = const Duration(milliseconds: 1000),
    this.logCoalesceMaxChars = 4000,
  });

  /// Event types whose log entries may be coalesced to reduce output volume.
  final Set<String> coalesceableLogTypes;

  /// Maximum time window within which coalesceable log entries are merged.
  final Duration logCoalesceWindow;

  /// Maximum total character count before coalesceable log entries are flushed.
  final int logCoalesceMaxChars;

  IOSink? _sink;
  String? _logPath;

  /// Path to the NDJSON log file, or `null` if [open] has not been called.
  String? get logPath => _logPath;

  String? _bufType;
  DateTime? _bufFirstTs;
  final StringBuffer _bufContent = StringBuffer();
  Timer? _bufFlushTimer;

  /// Opens the run log file in the given agent directory and writes a
  /// "start" event with metadata.
  Future<void> open({
    required String agentDirHostPath,
    String? agentId,
    String? workspaceId,
    String? conversationId,
    String? ticketId,
    required String cliName,
    String? modelId,
    required AgentCapabilities capabilities,
  }) async {
    try {
      _bufFlushTimer?.cancel();
      _bufFlushTimer = null;
      _bufType = null;
      _bufFirstTs = null;
      _bufContent.clear();

      final runsDir = Directory('$agentDirHostPath/runs');
      if (!runsDir.existsSync()) {
        runsDir.createSync(recursive: true);
      }
      final runId =
          '${DateTime.now().millisecondsSinceEpoch}-'
          '${agentId ?? "agent"}';
      _logPath = p.absolute(runsDir.path, '$runId.ndjson');
      _sink = File(_logPath!).openWrite(mode: FileMode.write);
      _sink!.writeln(
        jsonEncode({
          'type': 'start',
          'ts': DateTime.now().toIso8601String(),
          'runId': runId,
          'agentId': agentId,
          'workspaceId': workspaceId,
          'conversationId': conversationId,
          'ticketId': ticketId,
          'cliName': cliName,
          'modelId': modelId,
          'capabilities': capabilities.toJson(),
        }),
      );
    } catch (_) {
      await _sink?.close();
      _sink = null;
      _logPath = null;
    }
  }

  /// Logs a process event, coalescing high-frequency types or flushing
  /// immediately for other types.
  void logEvent(AgentProcessEvent event) {
    final sink = _sink;
    if (sink == null) {
      return;
    }
    final type = event.type.name;
    final content = redactSecrets(event.content);

    if (!coalesceableLogTypes.contains(type)) {
      flushBuffer();
      try {
        // Metadata (e.g. a tool result's raw `outputs`) can duplicate a token
        // that `content` already redacts, so scrub it too before persisting.
        final metadata = _redactMetadata(event.metadata);
        sink.writeln(
          jsonEncode({
            'type': 'event',
            'ts': DateTime.now().toIso8601String(),
            'eventType': type,
            'content': content,
            if (metadata != null && metadata.isNotEmpty) 'metadata': metadata,
          }),
        );
      } catch (_) {
        CcInfraLog.warning('Failed to write log event');
      }
      return;
    }

    if (_bufType != null) {
      final firstTs = _bufFirstTs;
      final tooOld =
          firstTs != null &&
          DateTime.now().difference(firstTs) >= logCoalesceWindow;
      final tooLong = _bufContent.length + content.length > logCoalesceMaxChars;
      if (_bufType != type || tooOld || tooLong) {
        flushBuffer();
      }
    }

    if (_bufType == null) {
      _bufType = type;
      _bufFirstTs = DateTime.now();
    }
    _bufContent.write(content);

    _bufFlushTimer?.cancel();
    _bufFlushTimer = Timer(logCoalesceWindow, flushBuffer);
  }

  /// Returns a copy of [metadata] with any secret-shaped values scrubbed.
  ///
  /// Walks the structure and redacts string leaves directly, rather than
  /// `jsonEncode → regex → jsonDecode`. That round trip cost two full JSON
  /// codecs over an unbounded payload (a tool result echoing a large file is
  /// one of these) on the isolate that also has to answer RPCs — and it was
  /// less thorough, because JSON escaping hides `"token": "…"` from the
  /// quoted-key patterns while the raw leaf matches them.
  Map<String, dynamic>? _redactMetadata(Map<String, dynamic>? metadata) {
    if (metadata == null || metadata.isEmpty) {
      return metadata;
    }
    try {
      return redactSecretsInJsonValue(metadata)! as Map<String, dynamic>;
    } catch (_) {
      // Unwalkable metadata — drop it rather than risk persisting a secret.
      return null;
    }
  }

  /// Flushes any coalesced log entries from the buffer to the log file.
  void flushBuffer() {
    _bufFlushTimer?.cancel();
    _bufFlushTimer = null;
    final type = _bufType;
    final firstTs = _bufFirstTs;
    if (type == null || firstTs == null || _bufContent.isEmpty) {
      _bufType = null;
      _bufFirstTs = null;
      _bufContent.clear();
      return;
    }
    final content = _bufContent.toString();
    _bufType = null;
    _bufFirstTs = null;
    _bufContent.clear();
    final sink = _sink;
    if (sink == null) {
      return;
    }
    try {
      sink.writeln(
        jsonEncode({
          'type': 'event',
          'ts': firstTs.toIso8601String(),
          'eventType': type,
          'content': content,
        }),
      );
    } catch (_) {
      CcInfraLog.warning('Failed to flush log buffer');
    }
  }

  /// Closes the run log, writing any remaining buffered events and a final
  /// "end" event with optional [exitCode] and [error].
  Future<void> close({int? exitCode, Object? error}) async {
    flushBuffer();
    final sink = _sink;
    _sink = null;
    if (sink == null) {
      return;
    }
    try {
      sink.writeln(
        jsonEncode({
          'type': 'end',
          'ts': DateTime.now().toIso8601String(),
          'exitCode': exitCode,
          // Redact: an exception's message/stack can echo a token (e.g. a failed
          // authenticated git/HTTP call) and this line is persisted verbatim.
          if (error != null) 'error': redactSecrets(error.toString()),
        }),
      );
      await sink.flush();
      await sink.close();
    } catch (_) {
      CcInfraLog.warning('Failed to close run log');
    }
  }
}
