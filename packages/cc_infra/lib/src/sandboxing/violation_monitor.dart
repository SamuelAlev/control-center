import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/core/domain/value_objects/sandbox_event.dart';

import 'package:cc_infra/src/process/child_process.dart';
import 'package:meta/meta.dart';

/// Streams [SandboxViolation]s parsed from OS-level sandbox denial logs.
///
/// On macOS this taps `log stream` for the kernel's `Sandbox` sender and the
/// `com.apple.sandbox*` subsystems. Both feeds are needed: the kernel
/// throttles its own lines ("N duplicate reports for …"), and recent macOS
/// reports some denials — a refused `process-exec` among them — only through
/// `sandboxd` (`com.apple.sandbox.reporting`). On Linux there's no equivalent
/// first-class log feed; the manager attributes violations from stderr
/// `EPERM` text instead and this class is unused.
///
///  - [isNoise]: a static allowlist of known-irrelevant denials
///    (audio HAL, iCloud daemons, MDM file probes) — these fire on every
///    macOS process and aren't actionable.
///  - dedupe by `(action, target)` within [_dedupeWindow] so a retry storm
///    surfaces once.
///
/// `log stream` never notices its reader is gone: a server that is killed,
/// crashes or restarts without [close] would leave its tap running under
/// launchd forever, each one a `logd` client filtering the whole machine's
/// log traffic. So the tap runs under [tetherScript], which ends it when the
/// server's end of its stdin closes, as it does however the server dies.
class SandboxViolationMonitor {
  SandboxViolationMonitor._(this._process, this.stream);

  final Process _process;

  /// Broadcast stream of every parsed violation.
  final Stream<SandboxViolation> stream;

  /// The tethering shell's pid; the `log` tap is its child.
  @visibleForTesting
  int get pid => _process.pid;

  static const List<String> _logCommand = [
    '/usr/bin/log',
    'stream',
    '--style',
    'ndjson',
    '--predicate',
    'sender == "Sandbox" OR subsystem BEGINSWITH "com.apple.sandbox"',
  ];

  /// A `/bin/sh -c` program that runs its arguments as a child for exactly
  /// as long as its own stdin stays open, and exits with the child's status.
  ///
  /// The parent never writes to stdin, so stdin reaches EOF only when the
  /// parent closes it or dies; a SIGKILL closes it all the same. A watcher
  /// blocks in `cat` on a saved copy of stdin (an asynchronous list's own
  /// stdin is `/dev/null`) and kills the child at EOF. A child that exits on
  /// its own stops the watcher first, so no stale pid is ever signalled; the
  /// watcher's orphaned `cat` ends when the parent closes stdin.
  @visibleForTesting
  static const String tetherScript = r'''
exec 3<&0
"$@" 3<&- &
child=$!
{ /bin/cat <&3 >/dev/null; kill "$child" 2>/dev/null; } >/dev/null 2>&1 &
watch=$!
exec 3<&-
wait "$child"
status=$?
kill "$watch" 2>/dev/null
exit "$status"
''';

  /// Closes the tether's stdin, which ends the tap.
  static Future<void> _release(Process process) async {
    try {
      await process.stdin.close();
    } on Object catch (_) {
      // Already gone: the tether exited and the pipe is broken.
    }
  }

  static const Duration _dedupeWindow = Duration(seconds: 5);

  /// Sweep the dedupe map once it grows past this. Well above any plausible
  /// number of DISTINCT violations inside one 5s window, so the sweep only
  /// ever runs against accumulated history.
  static const int _dedupeSweepThreshold = 512;

  /// Starts the log tap. Returns `null` when violation monitoring isn't
  /// available on the current platform (Linux, Windows).
  static Future<SandboxViolationMonitor?> start() async {
    if (!Platform.isMacOS) {
      return null;
    }
    final controller = StreamController<SandboxViolation>.broadcast();
    final process = await ChildProcess.start('/bin/sh', [
      '-c',
      tetherScript,
      'sh',
      ..._logCommand,
    ]);

    final recent = <String, DateTime>{};
    process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
          final parsed = parseLogLine(line);
          if (parsed == null || isNoise(parsed)) {
            return;
          }
          final v = parsed.violation;
          final key = '${v.action}::${v.target}';
          final now = DateTime.now();
          final last = recent[key];
          if (last != null && now.difference(last) < _dedupeWindow) {
            return;
          }
          recent[key] = now;
          // The dedupe map is keyed on action+target, which is unbounded over
          // a long-lived server (every distinct blocked path is a new key).
          // Sweeping entries older than the window costs nothing and keeps it
          // proportional to the CURRENT violation rate rather than the total.
          if (recent.length > _dedupeSweepThreshold) {
            recent.removeWhere((_, at) => now.difference(at) >= _dedupeWindow);
          }
          controller.add(v);
        }, onError: (_) {});

    process.stderr.listen((_) {}, onError: (_) {});

    unawaited(
      process.exitCode.then((_) async {
        // Lets the tether's watcher `cat` go too.
        await _release(process);
        if (!controller.isClosed) {
          await controller.close();
        }
      }),
    );

    return SandboxViolationMonitor._(process, controller.stream);
  }

  /// Ends the `log stream` tap and its tether.
  ///
  /// A plain signal to the tether would orphan the tap; closing its stdin is
  /// the same path a dying server takes. The kill only covers a tether that
  /// somehow outlives that, by when the tap has already been told to stop.
  Future<void> close() async {
    await _release(_process);
    try {
      await _process.exitCode.timeout(const Duration(seconds: 5));
    } on TimeoutException {
      _process.kill(ProcessSignal.sigkill);
      await _process.exitCode;
    }
  }

  /// Parses a single sandbox log line into a [ParsedLine], or returns `null`
  /// if the line cannot be recognized.
  @visibleForTesting
  static ParsedLine? parseLogLine(String line) {
    if (line.isEmpty) {
      return null;
    }
    try {
      final json = jsonDecode(line) as Map<String, dynamic>;
      // "Sandbox: <proc>(<pid>) deny(1) file-read-data /Library/foo"
      // "Sandbox: <proc>(<pid>) deny file-write-create /Users/foo/bar"
      // sandboxd's reports continue with a crash-report-style body
      // ("Process: …", "Path: …") on the following lines — the denial is
      // the first line alone.
      final message = LineSplitter.split(
        json['eventMessage'] as String? ?? '',
      ).firstWhere((l) => l.trim().isNotEmpty, orElse: () => '');
      final procMatch = RegExp(
        r'Sandbox:\s+(\S+?)\((\d+)\)',
      ).firstMatch(message);
      final processName = procMatch?.group(1);
      final match = RegExp(r'deny(?:\(\d+\))?\s+').firstMatch(message);
      if (match == null) {
        return null;
      }
      final tail = message.substring(match.end).trim();
      if (tail.isEmpty) {
        return null;
      }
      final parts = tail.split(RegExp(r'\s+'));
      final action = parts.first;
      final target = parts.skip(1).join(' ');
      return ParsedLine(
        processName: processName,
        violation: SandboxViolation(
          action: action,
          target: target,
          raw: line,
          pid: int.tryParse(procMatch?.group(2) ?? ''),
        ),
      );
    } catch (_) {
      return null;
    }
  }

  /// Drops everything that isn't both from an agent-related process AND on
  /// a target we actually care about. Apple's sandbox log is the whole
  /// machine's denial firehose — we filter aggressively because the
  /// remaining stream is what the user sees in chat banners.
  @visibleForTesting
  static bool isNoise(ParsedLine parsed) {
    final v = parsed.violation;

    // A refused exec is never framework noise: it is a command that failed.
    // And the process that asked is whatever the agent's shell ran — `env`
    // (Nix ships it inside a multi-call `coreutils`), `xargs`, `make`, a
    // package manager — which no name list keeps up with. Dropping it on the
    // process name is how a blocked `node` reached the agent as a bare
    // "operation not permitted" and never reached the operator at all.
    if (v.action.startsWith('process-exec')) {
      return false;
    }

    // Process-name allowlist: drop denials from any other sandboxed app
    // (Cursor, Spotlight, Mail, mdworker, …) that the log stream catches.
    final proc = parsed.processName;
    if (proc == null || !agentProcesses.contains(proc.toLowerCase())) {
      return true;
    }

    // mach-lookup is almost never actionable from the user's perspective —
    // it's framework noise. Drop it wholesale.
    if (v.action.startsWith('mach-lookup') ||
        v.action == 'user-preference-write' ||
        v.action.startsWith('system-')) {
      return true;
    }

    // File reads of system paths are framework loads (.dylib, .node, .so)
    // that don't actually fail — the OS allows them via a different rule,
    // but logs the attempt anyway.
    if (v.action.startsWith('file-read')) {
      for (final noisy in noisyReadPaths) {
        if (v.target.startsWith(noisy)) {
          return true;
        }
      }
    }

    return false;
  }

  /// Process names that are considered agent-related for filtering purposes.
  @visibleForTesting
  static const Set<String> agentProcesses = {
    'sandbox-exec',
    'claude',
    'node',
    'python3',
    'python',
    'bash',
    'zsh',
    'sh',
    'git',
    'gh',
    'curl',
    'wget',
  };

  /// File paths whose file-read denials are framework noise, not actionable.
  @visibleForTesting
  static const List<String> noisyReadPaths = [
    // macOS framework loads — `(allow default)` doesn't quite cover the
    // dyld cache lookups, but the actual load succeeds regardless.
    '/System/',
    '/Library/',
    '/Applications/',
    '/usr/lib/',
    '/usr/share/',
    '/usr/bin/',
    '/private/etc/',
    '/private/var/db/',
    '/private/var/folders/',
    '/.fseventsd',
    // Node/Python install dirs probed during native-module load — the
    // module *does* load (the dyld cache resolves it), the deny line in
    // the log is misleading.
    '.node',
    '.dylib',
    '.so',
  ];
}

/// A parsed sandbox log line with optional process name and violation details.
@visibleForTesting
class ParsedLine {
  /// Creates a parsed line with the given [processName] and [violation].
  const ParsedLine({required this.processName, required this.violation});

  /// The process name extracted from the log line, if available.
  final String? processName;

  /// The parsed sandbox violation details.
  final SandboxViolation violation;
}
