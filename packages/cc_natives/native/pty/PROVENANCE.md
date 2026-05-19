# Vendored: flutter_pty native sources

These C sources are vendored **verbatim** from
[`flutter_pty` 0.4.2](https://pub.dev/packages/flutter_pty) (`src/`), under its
original license (see `LICENSE`).

## Why vendored

`flutter_pty` is a Flutter **ffiPlugin** — its native code is compiled and
bundled only by `flutter build`. The pure-Dart `cc_server` binary (built with
`dart build cli`) has no Flutter build step, so it cannot use the plugin.

We compile the **identical** C into a loose `libccpty` dylib via
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

## Updating

Bump by re-copying `src/{flutter_pty*.c,flutter_pty.h,forkpty.*,include/}` from a
newer `flutter_pty` release and re-running `scripts/natives/build_pty.sh`.
