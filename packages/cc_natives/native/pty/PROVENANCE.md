# Vendored: flutter_pty native sources

These C sources are vendored from
[`flutter_pty` 0.4.2](https://pub.dev/packages/flutter_pty) (`src/`), under its
original license (see `LICENSE`). The Windows source is verbatim. The Unix
sources carry the [local changes](#local-changes) a long-lived server needs.

## Why vendored

`flutter_pty` is a Flutter **ffiPlugin** — its native code is compiled and
bundled only by `flutter build`. The pure-Dart `cc_server` binary (built with
`dart build cli`) has no Flutter build step, so it cannot use the plugin.

We compile this C into a loose `libccpty` dylib via
`scripts/natives/build_pty.sh` (the same runtime-dylib pattern as rift / fff /
tree-sitter / aec) and load it at runtime through `cc_natives`'
`tryOpenFirst` / `nativeLibraryCandidates`. The Dart side (`pty.dart`) is a
trimmed, Flutter-free port of `flutter_pty.dart` — the upstream `.dart` already
imports only `dart:ffi`/`dart:io`/`dart:isolate`/`package:ffi`, so the port only
swaps the hard-coded `DynamicLibrary.open('flutter_pty.framework/...')` lookup
for the cc_natives loader.

The native ABI (`pty_create` / `pty_write` / `pty_resize` / `pty_getpid` /
`pty_ack_read` / `pty_error`, talking back over `Dart_Port` via the Dart Native
API DL) is unchanged. `Dart_InitializeApiDL` + `Dart_PostCObject_DL` work in the
standalone Dart VM, not just under Flutter — which is what makes the headless
server PTY possible.

## Local changes

`forkpty.c` and `flutter_pty_unix.c` differ from upstream. Each change fixes
something a server that starts terminals for days cannot live with, and
`test/pty_test.dart` ("a terminal in a long-lived host") holds every one:

- **No signal crosses the fork.** Until it execs, the child is a copy of the
  host, signal handlers included. A signal that reached it in that window ran
  the host's handler in the child: the host was told about a signal it never
  got (a `SIGTERM` watcher saw a shutdown request), and the child lived on
  after its kill. Every signal is blocked across the fork, and the child
  resets its handlers to the defaults before it unblocks them.
- **A child that cannot start ends.** A failed `chdir` (exit 126) or `execvp`
  (exit 127) prints why on the terminal and exits. Upstream returned from the
  fork into the host's own code, as a second copy of the host.
- **Nothing stays open.** The host closes its copy of the terminal's other end
  after the fork, and the reader closes the master when the session is over.
  Upstream kept both, and a reader thread, for every terminal ever started.
- **The last output comes before the exit.** The exit is posted once the
  reader handed over what the child wrote, or after 500 ms when a descendant
  still holds the terminal. A session ends with its child: the reader stops
  then, so a descendant left behind loses the terminal, as it does when a
  terminal window closes.
- **Input after the end goes nowhere.** `pty_write` and `pty_resize` check the
  master under a lock, and a write is repeated until the terminal took all of
  it.
- **An exit is always reported**, as -1 when the status could not be read.

## Updating

Re-apply the local changes above after a bump: the tests fail without them.

Bump by re-copying `src/{flutter_pty*.c,flutter_pty.h,forkpty.*,include/}` from a
newer `flutter_pty` release and re-running `scripts/natives/build_pty.sh`.
