# cc_watcher

Control Center's **native recursive file watcher**, behind the C ABI in
[`cc_watcher.h`](cc_watcher.h). Consumed from Dart by
[`packages/cc_natives/lib/src/watch/`](../../lib/src/watch/) over `dart:ffi`.

This is the **first native whose source lives in this repo and is built with
cargo** — rift and fff are external crates cloned at a pinned ref; pty/aec/lame
are in-repo C. Build it with `scripts/natives/build_watcher.sh`. It is also the
one native with **no fallback** — see "Required, not optional" below.

## Why it exists

`package:watcher`'s `DirectoryWatcher` performs a **full recursive scan of the
tree when it is constructed**, on the calling isolate and cannot be told to
skip `node_modules` / `build` / `.dart_tool`. Measured on a real host — 4 repos
and 72 conversation worktrees — arming the whole set **froze the server isolate
for 65 seconds**: no logs, no RPC and timers (a 2 s debounce, a 10 s timeout)
firing a minute late.

Here, creating a watch is O(1) for the caller: macOS and Windows watch
kernel-recursively (no walk at all) and Linux's per-directory inotify walk runs
on the library's own thread with the ignore list applied _before_ any directory
is opened.

## Per-OS backends

All three go through the [`notify`](https://crates.io/crates/notify) crate, but
not in the same mode:

| OS      | Backend               | Mode                                            | Walk?                                                               |
| ------- | --------------------- | ----------------------------------------------- | ------------------------------------------------------------------- |
| macOS   | FSEvents              | `RecursiveMode::Recursive`                      | none — ignore rules are pure event filtering                        |
| Windows | ReadDirectoryChangesW | `RecursiveMode::Recursive`                      | none — same                                                         |
| Linux   | inotify               | `RecursiveMode::NonRecursive` **per directory** | ignore-aware breadth-first walk on our own thread (`linux_tree.rs`) |

`notify`'s own recursive Linux mode is deliberately **not** used: it walks the
tree unfiltered, which is exactly the cost this library exists to avoid.

Linux specifics worth knowing:

- **watch-then-read**, breadth-first. Watch-then-read is gap-free (a child
  created mid-walk is caught by either the parent's watch or the walk).
  Breadth-first means a `max_watches` budget truncates the deep tail (build
  trees), never the shallow source directories people actually edit.
- Hitting the budget or `ENOSPC` sets `DEGRADED` + a one-shot `RESCAN` and
  **keeps** the partial coverage; it never tears the watch down.

## The ignore contract

The ignore list is a **parameter**, never hardcoded here. Dart passes
`SourceFileWalker.watchIgnoredDirs` as a `\n`-separated list of directory
_names_, so the native filter and the Dart-side `affectsIndex` gate agree by
construction (a test in `source_file_walker_affects_index_test.dart` pins them
together). Root components never count — a checkout parked under a directory
that happens to carry an ignored name still works.

## Delivery: a polling drain, not a push

`cc_watch_drain` is called from one process-wide 500 ms Dart timer. Deliberate:

- the consumer debounces changes for 2 s with a 15 s ceiling, so sub-second
  delivery latency is invisible;
- a drain is inherently **coalescing** — a `git checkout` of a big branch
  becomes one batch instead of thousands of isolate wakeups feeding a debouncer
  that discards all but the last;
- a NativePort push would mean vendoring `dart_api_dl.c` into this crate and
  hand-constructing `Dart_CObject` layouts from `unsafe` Rust — the single
  largest chunk of risk in the design, bought for latency nobody consumes.

An optional `wake_port` (post one `Int64` when a previously-empty queue becomes
non-empty, letting Dart drop the timer) is an additive ABI change if it is ever
wanted.

## Semantics the caller can rely on

- **Paths are rewritten back under the requested root.** FSEvents realpaths
  everything, so a checkout under `/var/…` natively reports `/private/var/…`.
  Every delivered path is rewritten to the prefix the caller asked for; the
  gated FFI test pins this, because it silently breaks temp-dir tests otherwise.
- **Overflow degrades, never drops silently.** Past `queue_cap` distinct paths
  the queue clears (memory stays bounded), raises `RESCAN` and keeps counting
  `dropped`. The consumer treats `RESCAN` exactly like a relevant change, so
  overflow costs one conservative reindex — never a missed one.
- **Directory-level structural events also raise `RESCAN`.** After a directory
  create/remove/rename, descendant coverage is uncertain and reasoning about
  stale descendant paths is precisely the bug class this library refuses to
  hand-roll. Directory renames are rare inside a checkout, so a conservative
  extra debounced reindex is cheap.
- **A vanished root sets `ROOT_GONE`** and the handle is dead; the consumer
  drops the watch and its reconcile sweep re-arms if the path returns.
- **No panic ever crosses the FFI boundary.** Every `extern "C"` body is wrapped
  in `catch_unwind`; a panic becomes a NULL/0 return plus
  `cc_watch_last_error()`. `panic = "unwind"` in the release profile is required
  for that (do not switch it to `abort`).

## Required, not optional

There is **no fallback**. `NativeDirectoryWatcher.create` throws
`WatcherUnavailable` when the dylib is absent or ABI-mismatched, `cc_server`
fails its native preflight and refuses to boot and the watch service logs and
skips (then retries) any individual checkout whose watch cannot be created.

The alternative would be `package:watcher` and that is exactly what this crate
replaced: its `DirectoryWatcher` constructor scans the whole tree and cannot be
told to skip `node_modules`, so keeping it as a "graceful degradation" path
means silently reintroducing the 65-second startup freeze on the hosts least
able to afford it. A loud failure is the better trade.

## ABI versioning

`cc_watch_abi_version()` must equal `ccWatcherAbiVersion` in
`watcher_ffi_bindings.dart`. Bump **both** on any change to the exported
signatures or `CcWatchDrain`'s layout. On a mismatch the Dart side refuses to
bind — surfacing as `WatcherUnavailable` — rather than misreading structs.
