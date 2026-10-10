import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/core/domain/entities/agent_shell_process.dart';
import 'package:cc_domain/core/domain/ports/agent_shell_process_port.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';
import 'package:cc_infra/src/rigs/host_shell_listeners.dart';

/// Commands younger than this are left out of the list: a quick `ls` would
/// otherwise flash a row in and out. What the list is for is the command that
/// is still there after the agent moved on, or that never came back.
const Duration kAgentShellMinAge = Duration(seconds: 5);

/// How long a stopped command gets to exit on SIGTERM before its remaining
/// processes are sent SIGKILL.
const Duration kAgentShellKillGrace = Duration(seconds: 3);

/// The harness `bash` commands running in THIS server process.
///
/// The harness loop runs in-process, so its shells are children of the server
/// itself — there is no per-run root to walk from. The command runner records
/// each spawn here instead, with the workspace and space it ran for.
class HarnessShellRegistry {
  /// The registry the server's harness runners record into by default.
  static final HarnessShellRegistry shared = HarnessShellRegistry();

  final Map<int, AgentShellProcess> _byPid = {};

  /// Records a spawned command. Returns the callback that removes it, called
  /// when the command exits. A spawn with no workspace or space is not
  /// recorded: no list could ever show it.
  void Function() register({
    required int pid,
    required String? workspaceId,
    required String? spaceId,
    required String? agentId,
    required String command,
  }) {
    if (pid <= 0 ||
        workspaceId == null ||
        workspaceId.isEmpty ||
        spaceId == null ||
        spaceId.isEmpty) {
      return () {};
    }
    final entry = AgentShellProcess(
      pid: pid,
      workspaceId: workspaceId,
      spaceId: spaceId,
      agentId: agentId ?? '',
      command: command,
      startedAt: DateTime.now(),
      origin: AgentShellOrigin.harness,
    );
    _byPid[pid] = entry;
    return () {
      if (identical(_byPid[pid], entry)) {
        _byPid.remove(pid);
      }
    };
  }

  /// The running commands recorded for [workspaceId] / [spaceId].
  List<AgentShellProcess> forSpace(String workspaceId, String spaceId) => [
    for (final p in _byPid.values)
      if (p.workspaceId == workspaceId && p.spaceId == spaceId) p,
  ];
}

/// Reads the host process table: `ps` text in, or empty where there is none.
typedef PsSnapshot = Future<String> Function();

/// Sends [signal] to [pid]; false when the process is already gone.
typedef PidSignaller = bool Function(int pid, ProcessSignal signal);

/// Lists and stops the shell commands agents left running in a space.
///
/// Two sources, both scoped to the space:
/// - harness `bash` commands, from [HarnessShellRegistry];
/// - external CLI commands (Claude Code, Codex, …), found by walking the
///   process tree under each running run's recorded pid. A CLI spawns every
///   command as a shell (`zsh -c …`, `bash -lc …`) directly under itself, so
///   the shells whose parent is the agent CLI are its commands; everything
///   under one of them is that command's.
class AgentShellProcessService implements AgentShellProcessPort {
  /// Creates an [AgentShellProcessService].
  AgentShellProcessService({
    required this._runLogs,
    HarnessShellRegistry? harnessShells,
    PsSnapshot? psSnapshot,
    PidSignaller? signal,
    DateTime Function()? now,
    int? serverPid,
  }) : _harness = harnessShells ?? HarnessShellRegistry.shared,
       _ps = psSnapshot ?? _defaultPs,
       _signal = signal ?? _defaultSignal,
       _now = now ?? DateTime.now,
       _serverPid = serverPid ?? pid;

  final AgentRunLogRepository _runLogs;
  final HarnessShellRegistry _harness;
  final PsSnapshot _ps;
  final PidSignaller _signal;
  final DateTime Function() _now;
  final int _serverPid;

  @override
  Future<List<AgentShellProcess>> list({
    required String workspaceId,
    required String spaceId,
  }) async {
    final table = await _table(workspaceId, spaceId);
    return table.found;
  }

  @override
  Future<bool> kill({
    required String workspaceId,
    required String spaceId,
    required int pid,
  }) async {
    // Re-derived, never trusted from the caller: the pid must be one this
    // space's list reports right now, or it is not stopped.
    final table = await _table(workspaceId, spaceId);
    if (!table.found.any((p) => p.pid == pid)) {
      return false;
    }
    final tree = descendantPidsFromPs(table.ps, pid);
    final targets = tree.isEmpty ? {pid} : tree;
    for (final p in targets) {
      _signal(p, ProcessSignal.sigterm);
    }
    // Whatever ignored the TERM gets KILL once the grace is up. Not awaited:
    // the caller's row should clear on the next list, not after the grace.
    unawaited(
      Future<void>.delayed(kAgentShellKillGrace, () {
        for (final p in targets) {
          _signal(p, ProcessSignal.sigkill);
        }
      }),
    );
    return true;
  }

  Future<({List<AgentShellProcess> found, String ps})> _table(
    String workspaceId,
    String spaceId,
  ) async {
    final now = _now();
    final found = <AgentShellProcess>[
      for (final p in _harness.forSpace(workspaceId, spaceId))
        if (now.difference(p.startedAt) >= kAgentShellMinAge) p,
    ];
    final runs = (await _runLogs.watchActiveBySpace(workspaceId, spaceId).first)
        .where((r) {
          final rootPid = r.pid;
          // The server's own pid never roots a walk: its tree is every
          // space's processes, not this run's.
          return r.isRunning &&
              rootPid != null &&
              rootPid > 0 &&
              rootPid != _serverPid;
        })
        .toList();
    var ps = '';
    if (runs.isNotEmpty && !Platform.isWindows) {
      ps = await _ps();
      final rows = parsePsRows(ps);
      for (final run in runs) {
        final root = rows[run.pid];
        // A recycled pid: the recorded process is gone and the number now
        // belongs to something that started before this run did.
        if (root == null ||
            now
                .subtract(root.elapsed)
                .isBefore(run.startedAt.subtract(const Duration(minutes: 1)))) {
          continue;
        }
        for (final shell in cliCommandShells(rows, run.pid!)) {
          if (shell.elapsed < kAgentShellMinAge) {
            continue;
          }
          found.add(
            AgentShellProcess(
              pid: shell.pid,
              workspaceId: workspaceId,
              spaceId: spaceId,
              agentId: run.agentId,
              runId: run.id,
              command: agentCommandOf(shell.command) ?? shell.command,
              startedAt: now.subtract(shell.elapsed),
              origin: AgentShellOrigin.cli,
            ),
          );
        }
      }
    } else if (found.isNotEmpty && !Platform.isWindows) {
      // Harness kills walk the tree too.
      ps = await _ps();
    }
    found.sort((a, b) => a.startedAt.compareTo(b.startedAt));
    return (found: found, ps: ps);
  }

  static Future<String> _defaultPs() async {
    try {
      final result = await Process.run('ps', [
        '-axww',
        '-o',
        'pid=,ppid=,etime=,command=',
      ], stdoutEncoding: const Utf8Codec(allowMalformed: true));
      return result.exitCode == 0 ? '${result.stdout}' : '';
    } on Object catch (e) {
      CcInfraLog.warning('agent shells: ps failed: $e');
      return '';
    }
  }

  static bool _defaultSignal(int pid, ProcessSignal signal) {
    try {
      return Process.killPid(pid, signal);
    } on Object {
      return false;
    }
  }
}

/// One row of `ps -axww -o pid=,ppid=,etime=,command=`.
class PsRow {
  /// Creates a [PsRow].
  const PsRow({
    required this.pid,
    required this.ppid,
    required this.elapsed,
    required this.command,
  });

  /// Process id.
  final int pid;

  /// Parent process id.
  final int ppid;

  /// Time since the process started.
  final Duration elapsed;

  /// The full command line.
  final String command;
}

/// Parses `ps -axww -o pid=,ppid=,etime=,command=` text, keyed by pid.
/// Malformed lines are skipped.
Map<int, PsRow> parsePsRows(String output) {
  final rows = <int, PsRow>{};
  final line = RegExp(r'^\s*(\d+)\s+(\d+)\s+(\S+)\s+(.*)$');
  for (final raw in const LineSplitter().convert(output)) {
    final m = line.firstMatch(raw);
    if (m == null) {
      continue;
    }
    final pid = int.parse(m.group(1)!);
    final elapsed = parseEtime(m.group(3)!);
    if (pid <= 0 || elapsed == null) {
      continue;
    }
    rows[pid] = PsRow(
      pid: pid,
      ppid: int.parse(m.group(2)!),
      elapsed: elapsed,
      command: m.group(4)!,
    );
  }
  return rows;
}

/// Parses ps's `etime` (`[[dd-]hh:]mm:ss`), or null when it is not one.
Duration? parseEtime(String etime) {
  final m = RegExp(r'^(?:(?:(\d+)-)?(\d+):)?(\d+):(\d+)$').firstMatch(etime);
  if (m == null) {
    return null;
  }
  int part(int i) => int.tryParse(m.group(i) ?? '') ?? 0;
  return Duration(
    days: part(1),
    hours: part(2),
    minutes: part(3),
    seconds: part(4),
  );
}

const _shells = {'sh', 'bash', 'zsh', 'dash', 'fish', 'ksh'};

/// What a CLI's command line starts with before the agent itself: shells
/// that `cd` and exec it, and the OS sandbox / env wrappers.
const _launchers = {
  ..._shells,
  'sandbox-exec',
  'bwrap',
  'env',
  'nice',
  'nohup',
};

/// The agent CLIs whose children are their commands. A `node` launch is
/// matched on its script (`node …/bin/claude`, `node …/codex.js`).
const _agentBinaries = {
  'amp',
  'auggie',
  'claude',
  'codex',
  'codex-acp',
  'copilot',
  'crush',
  'cursor-agent',
  'droid',
  'gemini',
  'goose',
  'kimi',
  'opencode',
  'qwen',
};

String _basename(String path) {
  final i = path.lastIndexOf('/');
  return i < 0 ? path : path.substring(i + 1);
}

List<String> _argv(String command) =>
    command.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();

/// Whether [command] is a shell running a command string (`-c`, `-lc`, …).
bool isShellCommand(String command) {
  final argv = _argv(command);
  if (argv.length < 2 || !_shells.contains(_basename(argv.first))) {
    return false;
  }
  for (final arg in argv.skip(1)) {
    if (!arg.startsWith('-')) {
      return false;
    }
    if (arg.length > 1 && !arg.startsWith('--') && arg.contains('c')) {
      return true;
    }
  }
  return false;
}

bool _isAgentBinary(String command) {
  final argv = _argv(command);
  if (argv.isEmpty) {
    return false;
  }
  final exe = _basename(argv.first);
  if (_agentBinaries.contains(exe)) {
    return true;
  }
  if ((exe == 'node' || exe == 'bun' || exe == 'deno') && argv.length > 1) {
    final script = _basename(
      argv.skip(1).firstWhere((a) => !a.startsWith('-'), orElse: () => ''),
    ).replaceFirst(RegExp(r'\.(c|m)?js$'), '');
    return _agentBinaries.contains(script);
  }
  return false;
}

/// The agent's command shells in the tree under [rootPid]: shell processes
/// whose parent is the agent CLI itself.
///
/// The agent is a known CLI binary in the tree; failing that, the first
/// process under the launch shells and sandbox wrappers. Only direct shell
/// children count, so a shell an MCP server's `npx` runs, or one a command
/// runs inside itself, is never listed on its own.
List<PsRow> cliCommandShells(Map<int, PsRow> rows, int rootPid) {
  final children = <int, List<PsRow>>{};
  for (final r in rows.values) {
    if (r.pid != r.ppid) {
      (children[r.ppid] ??= []).add(r);
    }
  }
  final tree = <PsRow>[];
  final stack = [rootPid];
  final seen = <int>{};
  while (stack.isNotEmpty) {
    final p = stack.removeLast();
    if (!seen.add(p)) {
      continue;
    }
    final row = rows[p];
    if (row != null) {
      tree.add(row);
    }
    for (final c in children[p] ?? const <PsRow>[]) {
      stack.add(c.pid);
    }
  }
  var agents = {
    for (final r in tree)
      if (_isAgentBinary(r.command)) r.pid,
  };
  if (agents.isEmpty) {
    // Walk down through the launch chain to the first real program.
    agents = {};
    final queue = [rootPid];
    while (queue.isNotEmpty) {
      final p = queue.removeLast();
      final row = rows[p];
      if (row == null) {
        continue;
      }
      final exe = _basename(_argv(row.command).firstOrNull ?? '');
      if (_launchers.contains(exe)) {
        queue.addAll((children[p] ?? const <PsRow>[]).map((c) => c.pid));
      } else {
        agents.add(p);
      }
    }
  }
  return [
    for (final r in tree)
      if (r.pid != rootPid &&
          agents.contains(r.ppid) &&
          isShellCommand(r.command))
        r,
  ];
}

/// The command an agent asked for, out of the shell line its CLI wraps it in.
///
/// Claude Code runs `zsh -c source SNAPSHOT && … && eval 'COMMAND'
/// < /dev/null && pwd -P >| FILE`; other CLIs run `bash -lc COMMAND`. Null
/// when the line is neither.
String? agentCommandOf(String shellLine) {
  // ps renders a newline inside an argument as `\012`.
  final line = shellLine.replaceAll(r'\012', '\n');
  final evalAt = line.lastIndexOf(" eval '");
  if (evalAt >= 0) {
    final word = _readShellWord(line, evalAt + 6);
    if (word != null && word.trim().isNotEmpty) {
      return word.trim();
    }
  }
  final m = RegExp(
    r'^\S+\s+(?:-\S*\s+)*?-[a-z]*c[a-z]*\s+(.+)$',
    dotAll: true,
  ).firstMatch(line.trim());
  final rest = m?.group(1)?.trim();
  return rest == null || rest.isEmpty ? null : rest;
}

/// Reads one POSIX shell word starting at [start]: concatenated single-quoted,
/// double-quoted and backslash-escaped pieces, up to unquoted whitespace.
String? _readShellWord(String s, int start) {
  final out = StringBuffer();
  var i = start;
  while (i < s.length) {
    final c = s[i];
    if (c == "'") {
      final end = s.indexOf("'", i + 1);
      if (end < 0) {
        return null;
      }
      out.write(s.substring(i + 1, end));
      i = end + 1;
    } else if (c == '"') {
      final end = s.indexOf('"', i + 1);
      if (end < 0) {
        return null;
      }
      out.write(s.substring(i + 1, end));
      i = end + 1;
    } else if (c == r'\' && i + 1 < s.length) {
      out.write(s[i + 1]);
      i += 2;
    } else if (c == ' ' || c == '\t' || c == '\n') {
      break;
    } else {
      out.write(c);
      i++;
    }
  }
  return out.toString();
}
