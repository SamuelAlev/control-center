import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

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
/// The caller resolves the path from the DB row — never from a client argument
/// — so there is no path-traversal surface here; [readRunLogEvents] still
/// refuses a path outside [allowedRoot] as a second line of defence.
class RunLogReader {
  /// Creates a reader rooted at [allowedRoot] (the server's data directory).
  const RunLogReader({required this.allowedRoot, this.maxBytes = 4 << 20});

  /// Absolute path every readable run log must live under.
  final String allowedRoot;

  /// Hard cap on how many bytes are read from one log (tail-biased): a runaway
  /// agent can write hundreds of MB and the whole file would otherwise be
  /// decoded on the serving isolate and serialized over the wire.
  final int maxBytes;

  /// The parsed NDJSON events of the run log at [logPath].
  ///
  /// Returns `(events, truncated)`. Unparseable lines are surfaced verbatim as
  /// `{'type': 'raw', 'content': …}` (matching what the viewer already renders)
  /// rather than dropped, so a corrupt tail is visible instead of silent.
  Future<({List<Map<String, dynamic>> events, bool truncated})>
  readRunLogEvents(String logPath) async {
    final resolved = _resolve(logPath);
    if (resolved == null) {
      return (events: const <Map<String, dynamic>>[], truncated: false);
    }
    final file = File(resolved);
    if (!file.existsSync()) {
      return (events: const <Map<String, dynamic>>[], truncated: false);
    }
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

  /// The absolute path to read, or null when [logPath] escapes [allowedRoot].
  String? _resolve(String logPath) {
    if (logPath.isEmpty) {
      return null;
    }
    final absolute = p.isAbsolute(logPath)
        ? p.normalize(logPath)
        : p.normalize(p.join(allowedRoot, logPath));
    final root = p.normalize(allowedRoot);
    return p.equals(absolute, root) || p.isWithin(root, absolute)
        ? absolute
        : null;
  }
}
