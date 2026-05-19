import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:control_center/core/domain/value_objects/sandbox_event.dart';
import 'package:meta/meta.dart';

/// Streams [SandboxViolation]s parsed from OS-level sandbox denial logs.
///
/// On macOS this taps `log stream --predicate 'sender == "Sandbox"'`. On
/// Linux there's no equivalent first-class log feed; the manager attributes
/// violations from stderr `EPERM` text instead, and this class is unused.
///
///  - [isNoise]: a static allowlist of known-irrelevant denials
///    (audio HAL, iCloud daemons, MDM file probes) — these fire on every
///    macOS process and aren't actionable.
///  - dedupe by `(action, target)` within [_dedupeWindow] so a retry storm
///    surfaces once.
class SandboxViolationMonitor {
  SandboxViolationMonitor._(this._process, this.stream);

  final Process _process;

  /// Broadcast stream of every parsed violation.
  final Stream<SandboxViolation> stream;

  static const Duration _dedupeWindow = Duration(seconds: 5);

  /// Starts the log tap. Returns `null` when violation monitoring isn't
  /// available on the current platform (Linux, Windows).
  static Future<SandboxViolationMonitor?> start() async {
    if (!Platform.isMacOS) {
      return null;
    }
    final controller = StreamController<SandboxViolation>.broadcast();
    final process = await Process.start(
      '/usr/bin/log',
      [
        'stream',
        '--style',
        'ndjson',
        '--predicate',
        'sender == "Sandbox" OR subsystem == "com.apple.sandbox"',
      ],
    );

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
      controller.add(v);
    }, onError: (_) {});

    process.stderr.listen((_) {}, onError: (_) {});

    unawaited(process.exitCode.then((_) {
      if (!controller.isClosed) {
        controller.close();
      }
    }));

    return SandboxViolationMonitor._(process, controller.stream);
  }

  /// Kills the underlying `log stream` process.
  Future<void> close() async {
    _process.kill();
    await _process.exitCode;
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
      final message = json['eventMessage'] as String? ?? '';
      // "Sandbox: <proc>(<pid>) deny(1) file-read-data /Library/foo"
      // "Sandbox: <proc>(<pid>) deny file-write-create /Users/foo/bar"
      final procMatch =
          RegExp(r'Sandbox:\s+(\S+?)\((\d+)\)').firstMatch(message);
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
          suggestedCapability: suggestCapability(action, target),
          raw: line,
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
    'pi',
    'sandbox-exec',
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

  /// Suggests a sandbox capability based on the denied action and target.
  @visibleForTesting
  static String? suggestCapability(String action, String target) {
    if (action.startsWith('network')) {
      if (target.contains('github.com')) {
        return 'canCallGitHubApi';
      }
      return 'canAccessNetwork';
    }
    return null;
  }
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
