import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cc_persistence/cc_persistence.dart' show workspaceDirPath;
import 'package:cc_server_core/src/fs_confinement.dart';
import 'package:path/path.dart' as p;

/// Reads an agent run's NDJSON log off the SERVER's disk for the run viewer.
///
/// The run log is written by `RunLogWriter` next to the agent's directory
/// (`<agentDir>/runs/<runId>.ndjson`) and its path is stamped on the
/// `agent_run_logs` row. It lives on the server's filesystem, so a thin client
/// cannot read it: the desktop used to open the file directly through its own
/// `dart:io`, which rendered an empty dialog (no error) against any remote
/// server and worked only when client and server happened to share a machine.
///
/// Only the server writes that path (no RPC op accepts `log_path`), and
/// [readRunLogEvents] still opens nothing but an `.ndjson` file whose
/// symlink-resolved location is inside the run's own workspace directory:
/// a path that names another workspace, the server's databases or its secrets
/// reads as an empty log.
class RunLogReader {
  /// Creates a reader over the server's [dataDir].
  const RunLogReader({required this.dataDir, this.maxBytes = 4 << 20});

  /// The server's data directory; each workspace's files live in
  /// `workspaceDirPath(dataDir, workspaceId)`.
  final String dataDir;

  /// Hard cap on how many bytes are read from one log (tail-biased): a runaway
  /// agent can write hundreds of MB and the whole file would otherwise be
  /// decoded on the serving isolate and serialized over the wire.
  final int maxBytes;

  /// The parsed NDJSON events of [workspaceId]'s run log at [logPath].
  ///
  /// Returns `(events, truncated)`. Unparseable lines are surfaced verbatim as
  /// `{'type': 'raw', 'content': …}` (matching what the viewer already renders)
  /// rather than dropped, so a corrupt tail is visible instead of silent.
  Future<({List<Map<String, dynamic>> events, bool truncated})>
  readRunLogEvents(String logPath, {required String workspaceId}) async {
    final resolved = _resolve(logPath, workspaceId);
    if (resolved == null) {
      return (events: const <Map<String, dynamic>>[], truncated: false);
    }
    final file = File(resolved);
    final length = await file.length();
    final truncated = length > maxBytes;
    final bytes = truncated
        ? await file
              .openRead(length - maxBytes)
              .fold<BytesBuilder>(BytesBuilder(), (b, chunk) => b..add(chunk))
              .then((b) => b.takeBytes())
        : await file.readAsBytes();
    // A tail read can start mid-line and mid-rune; tolerate both.
    final text = const Utf8Decoder(allowMalformed: true).convert(bytes);
    final lines = const LineSplitter().convert(text);
    final events = <Map<String, dynamic>>[];
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.isEmpty) {
        continue;
      }
      if (truncated && i == 0) {
        continue; // Partial first line from the tail cut.
      }
      try {
        final decoded = jsonDecode(line);
        if (decoded is Map<String, dynamic>) {
          events.add(decoded);
          continue;
        }
      } on FormatException {
        // Fall through to the raw representation.
      }
      events.add({'type': 'raw', 'content': line});
    }
    return (events: events, truncated: truncated);
  }

  /// The real path to read, or null unless [logPath] is an existing
  /// `.ndjson` file inside [workspaceId]'s directory once every symlink is
  /// resolved.
  String? _resolve(String logPath, String workspaceId) {
    if (!p.isAbsolute(logPath)) {
      return null;
    }
    final real = confinedRealPath(
      workspaceDirPath(dataDir, workspaceId),
      logPath,
    );
    return real != null &&
            p.extension(real) == '.ndjson' &&
            File(real).existsSync()
        ? real
        : null;
  }
}
