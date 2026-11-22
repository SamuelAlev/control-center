import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;
import 'dart:math';

import 'package:cc_infra/src/log/cc_infra_log.dart';
import 'package:cc_infra/src/process/child_process.dart';

/// The environment variable that marks every process of one command's tree.
///
/// A process keeps its environment across `fork`, `exec`, `setsid` and a
/// double fork, so a daemon the command started still carries the marker
/// after it left the command's parent chain, group and session.
const String processTreeMarkerVariable = 'CC_COMMAND_TREE';

/// One row of the host process table. `sess` is 0 where `ps` does not give
/// the session id (macOS).
typedef ProcessTableRow = ({
  int pid,
  int ppid,
  int pgid,
  int sess,
  bool zombie,
});

/// Reads the host process table; an empty map when it cannot be read.
typedef ProcessTableReader = Future<Map<int, ProcessTableRow>> Function();

/// Reads the pids whose environment holds
/// `$processTreeMarkerVariable=<marker>`.
typedef MarkedProcessReader = Future<Set<int>> Function(String marker);

/// Sends a signal to one pid; false when it is already gone.
typedef ProcessSignalSender = bool Function(int pid, io.ProcessSignal signal);

/// Kills one command's tree ([killProcessTree] through `ChildProcess.killTree`
/// in production; a test counts the calls).
typedef ProcessTreeKill =
    Future<void> Function(
      int rootPid, {
      required bool Function() exited,
      String? marker,
    });

/// How long one read of the process table may take. A read that takes longer
/// counts as an empty table.
const Duration processTableReadTimeout = Duration(seconds: 1);

/// A fresh marker value for one command ([processTreeMarkerVariable]).
String newProcessTreeMarker({Random? random}) {
  final r = random ?? Random.secure();
  const digits = '0123456789abcdefghijklmnopqrstuvwxyz';
  return String.fromCharCodes([
    for (var i = 0; i < 20; i++) digits.codeUnitAt(r.nextInt(digits.length)),
  ]);
}

/// Parses `ps -A -o pid= -o ppid= -o pgid= -o sess= -o stat=` output.
Map<int, ProcessTableRow> parseProcessTable(String output) {
  final rows = <int, ProcessTableRow>{};
  final line = RegExp(r'^\s*(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s*(\S*)');
  for (final raw in const LineSplitter().convert(output)) {
    final m = line.firstMatch(raw);
    if (m == null) {
      continue;
    }
    final pid = int.parse(m.group(1)!);
    rows[pid] = (
      pid: pid,
      ppid: int.parse(m.group(2)!),
      pgid: int.parse(m.group(3)!),
      sess: int.parse(m.group(4)!),
      zombie: m.group(5)!.startsWith('Z'),
    );
  }
  return rows;
}

/// The pids of `ps -A -E -ww -o pid= -o command=` output (macOS: the command
/// line, then the environment) whose environment holds the [marker].
Set<int> parseMarkedProcesses(String output, String marker) {
  final entry = RegExp(
    '(^|\\s)${RegExp.escape('$processTreeMarkerVariable=$marker')}(\\s|\$)',
  );
  final line = RegExp(r'^\s*(\d+)\s(.*)$');
  return {
    for (final raw in const LineSplitter().convert(output))
      if (line.firstMatch(raw) case final m? when entry.hasMatch(m.group(2)!))
        int.parse(m.group(1)!),
  };
}

/// Every live process of the tree under [seeds], and of the [marked]
/// processes: their descendants, every member of a process group or a
/// session one of them leads or holds (a group outlives its leader and keeps
/// what the leader left behind, even after it was re-parented), and the same
/// again for what that adds.
///
/// Never the server itself, never a member of the server's own group or
/// session leader set, never pid 1, and never a zombie: a child started in
/// the normal mode shares the server's group, and signalling it would reach
/// the server's other children. The walk still goes through such a process
/// to what it started.
Set<int> processTreeTargets(
  Map<int, ProcessTableRow> rows,
  Iterable<int> seeds, {
  required int serverPid,
  Set<int> groups = const {},
  Set<int> sessions = const {},
  Set<int> marked = const {},
}) {
  final server = rows[serverPid];
  final children = <int, List<int>>{};
  for (final row in rows.values) {
    (children[row.ppid] ??= []).add(row.pid);
  }
  final found = <int>{};
  final queue = [...seeds, ...marked.where(rows.containsKey)];
  void walk() {
    while (queue.isNotEmpty) {
      final next = queue.removeLast();
      if (next == serverPid || next <= 1 || !found.add(next)) {
        continue;
      }
      queue.addAll(children[next] ?? const []);
    }
  }

  walk();
  var size = -1;
  while (found.length != size) {
    size = found.length;
    final leaders = <int>{
      ...groups,
      for (final p in found)
        if (rows[p] case final row? when row.pgid == p) p,
    }..removeWhere((g) => g <= 1 || g == server?.pgid);
    final held = <int>{
      ...sessions,
      for (final p in found)
        if (rows[p] case final row? when row.sess > 1) row.sess,
    }..removeWhere((s) => s <= 1 || s == server?.sess);
    for (final row in rows.values) {
      if (leaders.contains(row.pgid) || held.contains(row.sess)) {
        queue.add(row.pid);
      }
    }
    walk();
  }
  return found..removeWhere((p) {
    final row = rows[p];
    return row == null ||
        row.zombie ||
        p == serverPid ||
        (server != null && row.pgid == server.pgid);
  });
}

/// Kills [rootPid] and everything it started: TERM to the whole tree, then
/// KILL to whatever is still alive after [grace]. Completes once nothing of
/// the tree is alive, or once the KILL went out.
///
/// [exited] says whether the root's exit was already seen. A pid whose exit
/// was seen may belong to another process by now, so the root is signalled
/// only while its exit is unseen and the process table lists it as the
/// server's own child; once it exited, only the processes that carry
/// [marker] in their environment are still found (a command's daemons, see
/// [processTreeMarkerVariable]).
///
/// On macOS and Linux the tree is read from `ps` (descendants, the process
/// groups and sessions they lead, and the marked processes), and re-read
/// while waiting so a process forked during the TERM gets one too and is
/// caught by the KILL. A pid that left the group it had when it was first
/// found is not signalled again. With no process table only the root can be
/// told apart. On Windows `taskkill /T /F` ends the tree while the root's
/// exit is unseen.
///
/// When something carrying [marker] is still alive a moment after the KILL,
/// one warning names it ([warn], [CcInfraLog.warning] by default); the kill
/// does not wait for that check.
Future<void> killProcessTree(
  int rootPid, {
  Duration grace = const Duration(seconds: 2),
  bool Function()? exited,
  String? marker,
  ProcessTableReader? table,
  MarkedProcessReader? markedReader,
  ProcessSignalSender? signal,
  int? serverPid,
  void Function(String message)? warn,
}) async {
  bool rootExited() => exited?.call() ?? false;
  if (io.Platform.isWindows && table == null) {
    if (rootExited()) {
      return;
    }
    try {
      await ChildProcess.run('taskkill', ['/PID', '$rootPid', '/T', '/F']);
    } on Object {
      // Nothing more to do on Windows: taskkill is how a tree ends there.
    }
    return;
  }
  final read = table ?? readProcessTable;
  final readMarked = markedReader ?? readMarkedProcesses;
  final send = signal ?? _sendSignal;
  final self = serverPid ?? io.pid;
  var rows = await read();
  if (rows.isEmpty) {
    // No process table: only our own child can be told apart from the rest,
    // and only while its exit is unseen.
    if (rootExited()) {
      return;
    }
    send(rootPid, io.ProcessSignal.sigterm);
    await Future<void>.delayed(grace);
    if (!rootExited()) {
      send(rootPid, io.ProcessSignal.sigkill);
    }
    return;
  }
  var marked = marker == null ? const <int>{} : await readMarked(marker);
  bool rootIsOurs() =>
      !rootExited() &&
      rows[rootPid] != null &&
      rows[rootPid]!.ppid == self &&
      !rows[rootPid]!.zombie;
  // Each target's group when it was first found: a pid found in another
  // group later is no longer the process that was found.
  final firstGroup = <int, int>{};
  final groups = <int>{};
  final sessions = <int>{};
  Set<int> pass() {
    final known = [
      for (final MapEntry(key: p, value: g) in firstGroup.entries)
        if (rows[p]?.pgid == g) p,
    ];
    final found = processTreeTargets(
      rows,
      [if (rootIsOurs()) rootPid, ...known],
      serverPid: self,
      groups: groups,
      sessions: sessions,
      marked: marked,
    ).where((p) => (firstGroup[p] ??= rows[p]!.pgid) == rows[p]!.pgid).toSet();
    for (final p in found) {
      final row = rows[p]!;
      if (row.pgid == p) {
        groups.add(p);
      }
      if (row.sess > 1) {
        sessions.add(row.sess);
      }
    }
    return found;
  }

  var targets = pass();
  final termed = <int>{};
  void term(Iterable<int> pids) {
    for (final p in pids) {
      if (termed.add(p)) {
        send(p, io.ProcessSignal.sigterm);
      }
    }
  }

  term(targets);
  // The root itself sits in the server's group (the watcher of
  // `superviseProcessGroup`), so it is not a target: its command's own group
  // is. A root that has not started its command yet is all there is to stop.
  var rootTermed = false;
  if (targets.isEmpty && rootIsOurs()) {
    send(rootPid, io.ProcessSignal.sigterm);
    rootTermed = true;
  }
  final deadline = DateTime.now().add(grace);
  while ((targets.isNotEmpty || (rootTermed && rootIsOurs())) &&
      DateTime.now().isBefore(deadline)) {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    rows = await read();
    if (rows.isEmpty) {
      break;
    }
    targets = pass();
    term(targets);
  }
  if (rows.isEmpty) {
    // The table went away while waiting: nothing found earlier can be told
    // apart from a process that reused its pid, except our own child.
    if (rootTermed && !rootExited()) {
      send(rootPid, io.ProcessSignal.sigkill);
    }
    return;
  }
  if (marker != null) {
    marked = await readMarked(marker);
    rows = await read();
    if (rows.isNotEmpty) {
      targets = pass();
    }
  }
  for (final p in targets) {
    send(p, io.ProcessSignal.sigkill);
  }
  if (rootTermed && rootIsOurs()) {
    send(rootPid, io.ProcessSignal.sigkill);
  }
  if (marker != null && termed.isNotEmpty) {
    unawaited(_reportSurvivors(marker, self, read, readMarked, warn));
  }
}

/// Logs, once, what still carries [marker] a moment after the KILL went out.
Future<void> _reportSurvivors(
  String marker,
  int self,
  ProcessTableReader read,
  MarkedProcessReader readMarked,
  void Function(String message)? warn,
) async {
  await Future<void>.delayed(const Duration(milliseconds: 300));
  final marked = await readMarked(marker);
  final rows = marked.isEmpty ? const <int, ProcessTableRow>{} : await read();
  final left = processTreeTargets(
    rows,
    const [],
    serverPid: self,
    marked: marked,
  );
  if (left.isEmpty) {
    return;
  }
  final names = await _commandsOf(left);
  (warn ?? CcInfraLog.warning)(
    'A command left processes alive after its tree was killed: '
    '${[for (final p in left) 'pid $p (${names[p] ?? '?'})'].join(', ')}',
  );
}

/// Reads the host process table with `ps`; an empty map when `ps` fails or
/// takes longer than [processTableReadTimeout].
Future<Map<int, ProcessTableRow>> readProcessTable() async {
  final out = await _ps([
    '-A',
    '-o',
    'pid=',
    '-o',
    'ppid=',
    '-o',
    'pgid=',
    '-o',
    'sess=',
    '-o',
    'stat=',
  ]);
  return out == null ? const {} : parseProcessTable(out);
}

/// The pids whose environment holds `$processTreeMarkerVariable=$marker`:
/// read with `ps -E` on macOS and from `/proc/<pid>/environ` on Linux. Empty
/// when neither can be read in [processTableReadTimeout].
Future<Set<int>> readMarkedProcesses(String marker) async {
  if (io.Platform.isLinux) {
    return _markedFromProc(
      marker,
    ).timeout(processTableReadTimeout, onTimeout: () => const {});
  }
  final out = await _ps(['-A', '-E', '-ww', '-o', 'pid=', '-o', 'command=']);
  return out == null ? const {} : parseMarkedProcesses(out, marker);
}

Future<Set<int>> _markedFromProc(String marker) async {
  final entry = utf8.encode('$processTreeMarkerVariable=$marker');
  final found = <int>{};
  try {
    await for (final e in io.Directory('/proc').list(followLinks: false)) {
      final pid = int.tryParse(
        e.uri.pathSegments.lastWhere((s) => s.isNotEmpty),
      );
      if (pid == null) {
        continue;
      }
      try {
        final bytes = await io.File('/proc/$pid/environ').readAsBytes();
        if (_holdsEntry(bytes, entry)) {
          found.add(pid);
        }
      } on Object {
        // Gone, or another user's: not ours either way.
      }
    }
  } on Object {
    return found;
  }
  return found;
}

/// Whether the NUL-separated [environ] holds [entry] as one whole variable.
bool _holdsEntry(List<int> environ, List<int> entry) {
  var start = 0;
  for (var i = 0; i <= environ.length; i++) {
    if (i == environ.length || environ[i] == 0) {
      if (i - start == entry.length) {
        var same = true;
        for (var j = 0; j < entry.length && same; j++) {
          same = environ[start + j] == entry[j];
        }
        if (same) {
          return true;
        }
      }
      start = i + 1;
    }
  }
  return false;
}

Future<Map<int, String>> _commandsOf(Set<int> pids) async {
  final out = await _ps(['-o', 'pid=', '-o', 'comm=', '-p', pids.join(',')]);
  final line = RegExp(r'^\s*(\d+)\s+(.*)$');
  return {
    for (final raw in const LineSplitter().convert(out ?? ''))
      if (line.firstMatch(raw) case final m?)
        int.parse(m.group(1)!): m.group(2)!.trim(),
  };
}

/// Runs `ps` with [args]; null when it fails or runs past
/// [processTableReadTimeout] (it is killed then).
Future<String?> _ps(List<String> args) async {
  try {
    final process = await ChildProcess.start('ps', args);
    final out = process.stdout.transform(utf8.decoder).join();
    unawaited(process.stderr.drain<void>());
    final code = await process.exitCode.timeout(
      processTableReadTimeout,
      onTimeout: () {
        // Dart's own kill: a no-op once `ps` has exited.
        process.kill(io.ProcessSignal.sigkill);
        return -1;
      },
    );
    if (code != 0) {
      return null;
    }
    return await out.timeout(processTableReadTimeout, onTimeout: () => '');
  } on Object {
    return null;
  }
}

bool _sendSignal(int pid, io.ProcessSignal signal) {
  try {
    return io.Process.killPid(pid, signal);
  } on Object {
    return false;
  }
}
