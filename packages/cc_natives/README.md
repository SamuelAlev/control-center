# cc_natives

The Dart FFI surface for Control Center's **runtime-loaded native libraries**.
This package owns only the Dart side — bindings, loaders and path-resolution
policy. The shared libraries are produced by `scripts/natives/*.sh` and loaded at
runtime via `dart:ffi`.

**Every native is REQUIRED. There is no degraded mode.** A missing dylib is a
broken install, never a runtime condition: loaders throw, `cc_server` refuses to
boot, the build scripts abort and the packaging scripts refuse to produce an
artifact. A "graceful" fallback here would hide a broken native behind a slower
working path indefinitely — search that finds less, worktrees that are no longer
copy-on-write, a code graph missing a language — and the only symptom is that
things quietly got worse.

## The natives

| Library          | Base name                               | Purpose                                                                           | Missing ⇒                             |
| ---------------- | --------------------------------------- | --------------------------------------------------------------------------------- | ------------------------------------- |
| **rift**         | `rift_ffi`                              | Copy-on-write git worktrees (APFS clonefile / reflink)                            | `RiftException(code: 'unavailable')`¹ |
| **fff**          | `fff_c`                                 | Fast file search with frecency ranking                                            | `FffUnavailable`                      |
| **tree-sitter**  | `tree-sitter` + `tree-sitter-<lang>` ×5 | Code indexing / AST extraction                                                    | `TreeSitterUnavailable`               |
| **cc_watcher**   | `cc_watcher`                            | Recursive file watching (FSEvents / ReadDirectoryChangesW / ignore-aware inotify) | `WatcherUnavailable`                  |
| **pty**          | `ccpty`                                 | Pseudo-terminal for the Flutter-free agent executor                               | `PtyUnavailable`                      |
| **aec**          | `aec_ffi`                               | Acoustic echo cancellation (WebRTC AEC3) for meetings                             | `AecUnavailable`                      |
| **lame**         | `lame_ffi`                              | MP3 encoding for the generative soundscape                                        | `LameUnavailable`                     |
| **cc_inference** | `cc_inference`                          | Embeddings (semantic search) + transcription, diarization, VAD, dictation         | boot refused                          |

¹ rift is the **one platform exemption**: Windows has no MSVC copy-on-write
backend, so it is deliberately not built there and plain `git worktree` is the
_backend_ rather than a degradation. Everywhere else a missing `librift_ffi` is a
hard failure. See `RiftRepoIsolationAdapter.missingRiftIsExpected`.

All the `*Unavailable` types implement the
[`NativeLibraryUnavailable`](lib/src/native_unavailable.dart) marker; rift signals
the same condition through `RiftException.isUnavailable`, its FFI surface being
error-code based. `tryOpenFirst` returning `null` is a **probe result**, not a
licence to degrade — every caller converts it into one of those throws.

### The one fallback that legitimately remains

It is **environment**-driven, never build-driven, so it cannot mask a broken
install: an on-device embedding **model** that has not been downloaded yet
(`EmbeddingService.isReady`) → FTS-only search. Models are the only artifacts the
server fetches at runtime; the dylibs all ship in the bundle.

A second one used to sit here — a filesystem without copy-on-write support
(`RiftException.isCowUnavailable`) degrading to plain `git worktree` — and it was
removed. `git worktree add` writes the branch, a `.git/worktrees/<name>`
registration and FETCH_HEAD into the **source repo**, i.e. the operator's own
checkout, and a linked worktree shares that repo's ref namespace so teardown
rescue labels land there too. "Correct and permanent" in the environment sense,
but it silently filled real repos with `conv/*` and `rescue/*` branches. CoW is
now the sole backend wherever rift ships, and a `cow_unavailable` provision
fails with the fix named (put the data dir on the same CoW volume as the repo).

### One rift registry per host (the marker rule)

rift records a managed source by writing a `.rift` marker **into that source
repo**, holding the id of its entry in the registry SQLite file. The marker
therefore lives outside our data dir and never expires, which makes two rules
non-negotiable:

- **All managed copies share ONE registry file** (`<dataDir>/rift.sqlite`,
  `CcPaths.riftRegistryPath()`). A second registry looking at the same repo sees
  a marker it does not know (`marker_mismatch` on `init`, `unknown_marker` on
  `create`) and every provision for that repo fails. Conversation worktrees and
  PR worktrees used to keep separate registries, so whichever surface reached a
  repo first silently locked the other out of CoW.
- **An unrecognised marker is repaired, not failed on.**
  `RiftException.isStaleMarker` (also raised when a data-dir reset wipes the
  registry but leaves the marker) is healed by `RiftClient.clearMarker` + a
  re-`init` in `RiftRepoIsolationAdapter`. Without the repair that repo would be
  locked out of CoW permanently, since nothing ever clears the marker — and
  since CoW is the only backend, permanently unprovisionable.

### Where the matrix is written down

The same required set is stated four times, for four audiences. Change them
together:

| File                                                                                 | Audience                   |
| ------------------------------------------------------------------------------------ | -------------------------- |
| `packages/cc_server_core/lib/src/cc_server_runtime.dart` (`nativeRequirement` table) | the running server         |
| `packages/cc_server_core/lib/src/native_preflight.dart`                              | how the table is evaluated |
| `scripts/release/cc_server_package.sh` (`require_native`)                            | the server archive         |
| `scripts/release/verify_natives.sh`                                                  | the desktop bundles        |

`cc_watcher` is also the one native whose _source_ lives in this repo
(`native/watcher/`, a Rust cdylib over the `notify` crate, cargo-built by
`scripts/natives/build_watcher.sh`). Its `package:watcher` alternative was
deliberately deleted rather than kept as a fallback: it scans the whole tree per
checkout and cannot skip `node_modules`, which froze the server isolate for a
measured 65 seconds on a real worktree fleet. See
[`native/watcher/README.md`](native/watcher/README.md).

## How loading works

The single source of truth for "where might this dylib live" is
[`lib/src/native_library.dart`](lib/src/native_library.dart):

- `nativeLibraryCandidates(baseName, {appSupportRoot, envVar})` — the full
  ordered list: an env override → the app-support install → the bundled
  release paths.
- `bundledLibraryCandidates(baseName)` — the packaged-release locations
  (`@executable_path/../Frameworks` on macOS, `<exeDir>/lib` on Linux, beside
  the exe on Windows).
- `tryOpenFirst(candidates)` — opens the first that loads, else `null`.

There are exactly **two locations a given dylib lives**, by context:

- **Dev:** the app-support root next to `control_center.db`
  (`~/Library/Application Support/com.alev.control-center/` on macOS), where
  `scripts/natives/build_*.sh` installs it. This is the _only_ dev location —
  there is no repo-local `macos/Frameworks/` copy.
- **Release:** inside the signed app bundle's `Contents/Frameworks/` (macOS),
  `<bundle>/lib/` (Linux), or beside the exe (Windows). The release packaging
  (`scripts/release/macos_package.sh` et al.) copies the staged dylibs there
  and code-signs them.

## Leaf package — host injects its concerns

`cc_natives` has **no `package:control_center` dependency**. The host app
injects what the package can't know:

- `NativeLog` — a logging sink (`onLog`), defaulting to silent.
- `NativeDirResolver` — resolves the app-support / grammars directory.

See `FffFileSearch` and `GrammarManager` constructors. This boundary is enforced
by `test/core/architecture_constraints_test.dart` in the app.

## Building the dylibs

```bash
scripts/natives/build_natives.sh            # all of them → <repo>/build/natives + app-support
scripts/natives/build_rift.sh               # one at a time
scripts/natives/build_watcher.sh            # the in-repo Rust watcher crate
scripts/natives/build_inference.sh          # the in-repo Rust inference crate
```

`build_inference.sh` pre-fetches the prebuilt sherpa-onnx **static** archive,
verifies it against the sha256 pinned in `scripts/lib/native_pins.env` and hands
it to cargo via `SHERPA_ONNX_LIB_DIR`. Left to itself the `sherpa-onnx-sys` build
script downloads that archive unverified at build time; since it is linked into a
shipped artifact, we pin it instead. The script then asserts the built dylib
exports the `cc_*` ABI **and nothing else** — an escaped `OrtGetApiBase` or
`SherpaOnnx*` symbol could interpose on another ONNX Runtime in the same process,
which is the hazard this native exists to remove.

All of these **fail hard**: the aggregator aborts on the first failure instead of
warning past it, because there is no degraded mode left for a warning to
describe. On Windows every native comes from
`scripts/release/windows_natives.sh` instead (rift excepted).

A fresh clone must run both scripts before `dart build cli` — the build hook fails
without staged natives rather than producing a server that cannot boot. For
compile-only workflows that never run the binary, create an empty
`.cc_natives_allow_missing` at the repo root to downgrade that to a warning. It is
a FILE rather than an env var because the hooks runner spawns the hook as its own
process and does not forward the caller's environment (the same reason the old
`CC_NATIVES_PREBUILT_DIR` override never worked; `.cc_natives_prebuilt_dir`, whose
contents are a staging path, replaces it).

Upstream sources are fetched at pinned SHAs (Renovate-managed); see the scripts
and `renovate.json`. `cc_watcher` has no upstream — its source is in
`native/watcher/` and its `notify` dependency is tracked by Renovate's cargo
manager via `native/watcher/Cargo.toml`.

## NOT a Flutter plugin

This is intentionally a plain Dart package, **not** an `ffiPlugin`. Converting it
would move native compilation into `flutter build`, make cargo/meson/ninja/a
C++ toolchain mandatory for every contributor
and every build, collapse tree-sitter to a single build-time dylib (killing the
runtime grammar-download feature) and destroy the fast install-to-app-support
dev loop. The `architecture_constraints_test.dart` guard fails if anyone adds an
`ffiPlugin` declaration here.
