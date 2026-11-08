import 'dart:io';

/// The watcher. `$@` is the command; `$0` only names it in `ps`.
///
/// A background job only gets a group of its own under job control (`set -m`)
/// or `setsid`, and macOS has no `setsid`. Either way `$!` is the group id,
/// which is what `kill -- -$child` addresses. stdio is released after the spawn
/// so that this shell holds no end of a pipe the server is waiting on.
const String _watcher = r'''
server=$PPID
self=$$
if command -v setsid >/dev/null 2>&1; then
  setsid "$@" <&0 &
else
  set -m
  "$@" <&0 &
  set +m
fi
child=$!
exec </dev/null >/dev/null 2>&1
reap() {
  kill -TERM -"$child" 2>/dev/null || kill -TERM "$child" 2>/dev/null
  /bin/sleep 5
  kill -KILL -"$child" 2>/dev/null
}
trap '( reap ) &' TERM INT HUP
(
  trap '' TERM INT HUP
  while kill -0 "$self" 2>/dev/null && kill -0 "$server" 2>/dev/null; do
    /bin/sleep 2
  done
  kill -0 "$self" 2>/dev/null && reap
) &
watch=$!
while :; do
  wait "$child"
  code=$?
  kill -0 "$child" 2>/dev/null || break
done
kill "$watch" 2>/dev/null
exit "$code"
''';

/// Whether this host can run the watcher.
bool get canSuperviseProcessGroup => !Platform.isWindows;

/// Runs a command in its own process group, under a small `/bin/sh` watcher,
/// so that everything it started can be stopped with it.
///
/// A signal to one pid stops one process. `claude` starts MCP servers, shells
/// and subagents of its own, and those outlive it when only `claude` is
/// signalled. A server that crashes signals nothing at all, so the whole tree
/// stays behind, holding its worktree and spending. The watcher closes both
/// gaps:
///
/// - a stop reaches the group: TERM, then KILL five seconds later;
/// - when the server dies the watcher notices within two seconds and does the
///   same, because the watcher itself outlives its parent.
///
/// A normal exit deliberately touches nothing. A dev server an agent left
/// running stays up, as it does without the watcher.
///
/// The watcher sits OUTSIDE the OS sandbox, so a command inside cannot signal
/// it, and it polls because `Process.start` cannot pass an extra pipe for the
/// server's death to close. stdin, stdout, stderr and the exit code all pass
/// through; a command killed by signal N exits `128 + N`.
({String executable, List<String> argv}) superviseProcessGroup(
  String executable,
  List<String> argv,
) => (
  executable: '/bin/sh',
  argv: ['-c', _watcher, 'cc-supervisor', executable, ...argv],
);
