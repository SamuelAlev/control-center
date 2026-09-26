# cc_watcher

In-repo Rust recursive watcher behind [`cc_watcher.h`](cc_watcher.h), loaded by the Dart `cc_natives` watch adapter. Build it from the repo root with `scripts/natives/build_watcher.sh`. It is a required native, not a fallback for polling: an absent/ABI-mismatched dylib raises `WatcherUnavailable` and blocks `cc_server` boot. Failed watches for individual checkouts are logged and retried by the watch service.

macOS uses FSEvents and Windows uses ReadDirectoryChangesW in recursive mode, with ignore rules applied to events. Linux uses `notify`'s nonrecursive inotify watches and its own ignore-aware breadth-first directory walk on a background thread. Do **not** switch Linux to `notify`'s recursive mode: it walks ignored directories before filtering. Linux watches before reading each directory to avoid missing new children; a `max_watches` budget or `ENOSPC` preserves partial coverage and emits `DEGRADED` plus a one-shot `RESCAN`.

The caller supplies `SourceFileWalker.watchIgnoredDirs` as newline-separated directory **names**, matching Dart's `affectsIndex` gate. Ignore rules never exclude the root solely because an ancestor happens to have an ignored name. The process drains paths every 500 ms; Dart debounces changes for 2 seconds (15-second ceiling). Batching coalesces bulk checkouts without thousands of isolate wakeups.

## Delivery contract

- FSEvents paths are rewritten under the caller's requested root (for example `/var` rather than its resolved `/private/var`).
- Queue overflow clears bounded path storage, counts dropped entries and raises `RESCAN`, so the indexer performs a conservative reindex rather than silently missing changes. Directory create/remove/rename also raises `RESCAN` because descendant coverage is uncertain.
- `ROOT_GONE` invalidates the handle; the consumer drops it and re-arms on a later reconcile sweep if the path returns.
- Every `extern "C"` entry catches panics and returns NULL/0 plus `cc_watch_last_error()`. Keep `panic = "unwind"` in the release profile.
- Any exported signature or `CcWatchDrain` layout change must bump **both** `cc_watch_abi_version()` and Dart's `ccWatcherAbiVersion` in `watcher_ffi_bindings.dart`; Dart refuses to bind mismatched ABIs.
