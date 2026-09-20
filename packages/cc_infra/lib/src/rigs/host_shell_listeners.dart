// Process-tree listen discovery for a host-shell terminal.
//
// Containment is the whole point: we never `lsof` the machine. A server that
// this session's PTY started is visible; a sibling space's server on the same
// host port number is not, even though both sit on the Mac. The tree is
// rooted at the session's `pty.pid` (already on `_Session`); everything else
// is out of scope.

import 'dart:convert';
import 'dart:io';

import 'package:cc_infra/src/rigs/rig_ports.dart';

/// The most listeners published per host-shell session. Matches
/// `kMaxAutoForwards` on an exec rig: a handful of dev servers is expected,
/// a scan is not.
const int kMaxHostShellListeners = 16;

/// Builds the set of pids in the process tree rooted at [rootPid] from
/// `ps -axo pid=,ppid=` output.
///
/// Includes [rootPid] itself. A pid whose parent is not in the tree (a
/// sibling shell, an unrelated daemon) is excluded — that is the isolation
/// this parser exists to pin.
Set<int> descendantPidsFromPs(String output, int rootPid) {
  if (rootPid <= 0) {
    return const {};
  }
  final children = <int, List<int>>{};
  for (final line in const LineSplitter().convert(output)) {
    final parts = line.trim().split(RegExp(r'\s+'));
    if (parts.length < 2) {
      continue;
    }
    final pid = int.tryParse(parts[0]);
    final ppid = int.tryParse(parts[1]);
    if (pid == null || ppid == null || pid <= 0) {
      continue;
    }
    (children[ppid] ??= []).add(pid);
  }
  final tree = <int>{};
  final stack = [rootPid];
  while (stack.isNotEmpty) {
    final pid = stack.removeLast();
    if (!tree.add(pid)) {
      continue;
    }
    final kids = children[pid];
    if (kids != null) {
      stack.addAll(kids);
    }
  }
  return tree;
}

/// Parses `lsof -nP -iTCP -sTCP:LISTEN` text, keeping only rows whose pid is
/// in [treePids].
///
/// Tolerant: a malformed line is skipped. Duplicate ports (IPv4 + IPv6 of the
/// same listener) collapse to one. Capped so a session that somehow binds
/// thousands of ports cannot balloon the host's bookkeeping.
List<RigOpenPort> parseLsofListen(
  String output,
  Set<int> treePids, {
  int cap = kMaxHostShellListeners,
}) {
  if (treePids.isEmpty) {
    return const [];
  }
  final byPort = <int, RigOpenPort>{};
  for (final line in const LineSplitter().convert(output)) {
    if (byPort.length >= cap) {
      break;
    }
    if (!line.contains('(LISTEN)')) {
      continue;
    }
    final parts = line.trim().split(RegExp(r'\s+'));
    if (parts.length < 9) {
      continue;
    }
    final pid = int.tryParse(parts[1]);
    if (pid == null || !treePids.contains(pid)) {
      continue;
    }
    final portMatch = RegExp(r':(\d+)\s+\(LISTEN\)\s*$').firstMatch(line);
    if (portMatch == null) {
      continue;
    }
    final port = int.tryParse(portMatch.group(1)!);
    if (port == null || port <= 0 || port > 65535) {
      continue;
    }
    if (byPort.containsKey(port)) {
      continue;
    }
    final comm = parts[0];
    byPort[port] = RigOpenPort(
      port: port,
      pid: pid,
      process: comm.isEmpty ? null : comm,
    );
  }
  final ports = byPort.values.toList()..sort((a, b) => a.port.compareTo(b.port));
  if (ports.length > cap) {
    return ports.sublist(0, cap);
  }
  return ports;
}

/// Discovers TCP listeners whose owning pid sits in [rootPid]'s process tree.
///
/// Empty on Windows (no `ps`/`lsof` tree we trust) and on any probe failure
/// — a missing `lsof` must not take the terminal down.
Future<List<RigOpenPort>> discoverHostShellListeners(int rootPid) async {
  if (rootPid <= 0 || Platform.isWindows) {
    return const [];
  }
  try {
    final ps = await Process.run('ps', ['-axo', 'pid=,ppid=']);
    if (ps.exitCode != 0) {
      return const [];
    }
    final tree = descendantPidsFromPs('${ps.stdout}', rootPid);
    if (tree.isEmpty) {
      return const [];
    }
    final lsof = await Process.run('lsof', [
      '-nP',
      '-iTCP',
      '-sTCP:LISTEN',
    ]);
    if (lsof.exitCode != 0 && '${lsof.stdout}'.isEmpty) {
      return const [];
    }
    return parseLsofListen('${lsof.stdout}', tree);
  } on Object {
    return const [];
  }
}
