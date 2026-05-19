import 'dart:async';
import 'dart:io';

/// Foreground-process title detection for server-hosted terminal PTYs.
///
/// A bare `zsh -il` never retitles its terminal while a command runs — OSC 0/2
/// titles only appear when the shell (or the running program) is configured to
/// emit them. Native terminals (ghostty, wezterm, VS Code) therefore fall back
/// to the PTY's *foreground process*: while `pnpm dev serve` runs, the tab says
/// so, no shell integration required. The PTY lives on the server, so the
/// polling lives here: `ps -o tpgid=` yields the foreground process group of
/// the shell's controlling terminal, and the group leader's command line
/// becomes the tab title (empty when the shell itself is foreground — a
/// prompt). macOS + Linux only; on Windows the sampler reports no title.

/// Shells whose bare invocation means "a prompt, not a job". When the
/// foreground command is one of these with only flag arguments (`zsh -il`),
/// the title clears instead of reading "zsh" forever — which would otherwise
/// happen under PTY wrappers (bwrap) where the shell is not the PTY child
/// itself and the pid comparison alone can't identify the prompt.
const Set<String> _promptShells = {
  'zsh',
  'bash',
  'sh',
  'dash',
  'fish',
  'csh',
  'tcsh',
  'ksh',
};

/// Interpreters that launch the *interesting* process as their first
/// non-flag argument: `node …/pnpm dev serve` should title as "pnpm dev
/// serve", ghostty-style, not "node".
const Set<String> _interpreters = {
  'node',
  'python',
  'python3',
  'ruby',
  'perl',
  'sh',
  'bash',
  'zsh',
  'dart',
  'deno',
  'bun',
};

/// Max title length pushed over the wire; the tab strip ellipsizes visually,
/// this only bounds the payload.
const int _maxTitleLength = 60;

/// Turns a raw `ps -o command=` line into a concise tab title: path tokens are
/// basenamed (`/usr/bin/git status` → `git status`), a login-shell dash is
/// dropped (`-zsh` → `zsh`), a leading interpreter launching a script is
/// dropped (`node …/pnpm dev serve` → `pnpm dev serve`), a bare prompt shell
/// (`zsh -il`) collapses to '', and the result is length-capped.
String prettyCommandTitle(String command) {
  final tokens = command
      .trim()
      .split(RegExp(r'\s+'))
      .where((t) => t.isNotEmpty)
      .toList();
  if (tokens.isEmpty) {
    return '';
  }
  String base(String token) =>
      token.contains('/') ? token.split('/').last : token;
  final parts = [for (final t in tokens) base(t)];
  if (parts.first.startsWith('-') && parts.first.length > 1) {
    // Login shells report argv[0] as "-zsh".
    parts[0] = parts.first.substring(1);
  }
  // A shell sitting at its prompt (only flag args) is "no job running".
  if (_promptShells.contains(parts.first) &&
      parts.skip(1).every((t) => t.startsWith('-'))) {
    return '';
  }
  // `node …/pnpm dev serve` → `pnpm dev serve`; keep the interpreter when its
  // next token is a flag (`python -m http.server` stays intact).
  if (parts.length > 1 &&
      _interpreters.contains(parts.first) &&
      !parts[1].startsWith('-')) {
    parts.removeAt(0);
  }
  var title = parts.join(' ');
  if (title.length > _maxTitleLength) {
    title = '${title.substring(0, _maxTitleLength - 1)}…';
  }
  return title;
}

/// Pure per-session state machine turning `(tpgid, command)` poll samples into
/// title-change events. Feed one sample per tick via [onSample]; it returns
/// the new title when the foreground process group *changed* (`''` = the shell
/// is back at its prompt) and null when nothing changed — so a program that
/// then retitles itself via OSC (vim, claude) is not clobbered by later ticks
/// of the same job.
class TerminalForegroundTracker {
  /// Creates a tracker for the PTY whose direct child is [shellPid].
  TerminalForegroundTracker({required this.shellPid});

  /// The PTY child's pid (the shell, or its sandbox wrapper).
  final int shellPid;

  int? _lastFgPgid;
  String _lastTitle = '';

  /// The current title (`''` when the shell is at its prompt) — replayed to a
  /// late subscriber so a client attaching mid-run sees the running job.
  String get currentTitle => _lastTitle;

  /// Digests one poll sample. [tpgid] is the foreground process group of the
  /// shell's controlling terminal (null = the sample failed; state is kept),
  /// [command] the group leader's `ps -o command=` line ('' when unknown).
  String? onSample({required int? tpgid, required String command}) {
    if (tpgid == null) {
      return null;
    }
    if (tpgid == _lastFgPgid) {
      return null;
    }
    _lastFgPgid = tpgid;
    final title = tpgid == shellPid ? '' : prettyCommandTitle(command);
    _lastTitle = title;
    return title;
  }
}

/// Runs one `ps`-backed foreground sample for [tracker] and returns the title
/// change, if any. Returns null (and keeps state) when unsupported (Windows)
/// or when `ps` answered but the pid is gone; a failure to *execute* `ps`
/// (e.g. no `ps` on this host) propagates so the caller can stop polling.
/// [runProcess] is injectable for tests and defaults to [Process.run].
Future<String?> sampleForegroundTitle(
  TerminalForegroundTracker tracker, {
  Future<ProcessResult> Function(String, List<String>) runProcess = Process.run,
}) async {
  if (Platform.isWindows) {
    return null;
  }
  final tp = await runProcess('ps', [
    '-o',
    'tpgid=',
    '-p',
    '${tracker.shellPid}',
  ]);
  final tpgid = int.tryParse((tp.stdout as String).trim());
  var command = '';
  if (tpgid != null && tpgid != tracker.shellPid) {
    final cmd = await runProcess('ps', ['-o', 'command=', '-p', '$tpgid']);
    command = (cmd.stdout as String).trim().split('\n').first;
  }
  return tracker.onSample(tpgid: tpgid, command: command);
}
