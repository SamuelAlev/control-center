import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:control_center/core/domain/value_objects/sandbox_event.dart';

/// Streams [SandboxViolation]s parsed from OS-level sandbox denial logs.
///
/// On macOS this taps `log stream --predicate 'sender == "Sandbox"'`. On
/// Linux there's no equivalent first-class log feed; the manager attributes
/// violations from stderr `EPERM` text instead, and this class is unused.
///
/// Two passes filter the firehose before emitting:
///  - [_isNoise]: a static allowlist of known-irrelevant denials
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
      final parsed = _parseLogLine(line);
      if (parsed == null || _isNoise(parsed)) {
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

  static _ParsedLine? _parseLogLine(String line) {
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
      return _ParsedLine(
        processName: processName,
        violation: SandboxViolation(
          action: action,
          target: target,
          suggestedCapability: _suggestCapability(action, target),
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
  static bool _isNoise(_ParsedLine parsed) {
    final v = parsed.violation;

    // Process-name allowlist: drop denials from any other sandboxed app
    // (Cursor, Spotlight, Mail, mdworker, …) that the log stream catches.
    final proc = parsed.processName;
    if (proc == null || !_agentProcesses.contains(proc.toLowerCase())) {
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
      for (final noisy in _noisyReadPaths) {
        if (v.target.startsWith(noisy)) {
          return true;
        }
      }
    }

    return false;
  }

  static const Set<String> _agentProcesses = {
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

  static const List<String> _noisyReadPaths = [
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

  static String? _suggestCapability(String action, String target) {
    if (action.startsWith('network')) {
      if (target.contains('github.com')) {
        return 'canCallGitHubApi';
      }
      return 'canAccessNetwork';
    }
    return null;
  }
}

class _ParsedLine {
  const _ParsedLine({required this.processName, required this.violation});
  final String? processName;
  final SandboxViolation violation;
}
