# cc_natives

Dart FFI bindings, loaders and path resolution for Control Center's runtime-loaded libraries. Build scripts supply the dylibs; this package does not compile them during `flutter build`. **Missing required natives are broken installs, not a degraded runtime mode:** loaders throw, the server's boot preflight fails and packaging refuses an incomplete artifact. The only platform exception is rift on Windows, where plain `git worktree` is the intended backend. On other platforms rift's CoW provision requires the data dir and source repo on the same CoW volume.

The required set is defined in `scripts/lib/natives.sh`: `rift_ffi` (CoW worktrees), `fff_c` (file search), `tree-sitter` and language grammars (indexing), `cc_watcher` (recursive watch), `ccpty` (terminal), `aec_ffi` (echo cancellation), `lame_ffi` (MP3), `cc_inference` (embeddings/speech/diarization) and `cc_saml` (SAML verification). `test/tooling/native_matrix_test.dart` checks that matrix against server preflight; grammar IDs must also match `lib/src/code_index/code_languages.dart`. `NativeLibraryUnavailable` marks missing libraries; rift uses `RiftException.isUnavailable` instead. A missing **model**, unlike a missing native, can leave embedding search FTS-only until the model downloads. See [ARCH.md](../../ARCH.md) for indexing and isolation invariants.

Rift writes a persistent `.rift` marker into each managed source repo. All copies
must share `<dataDir>/rift.sqlite` (`CcPaths.riftRegistryPath()`); a second
registry cannot recognize that marker. After a data-dir reset, repair a stale
marker via `RiftClient.clearMarker` and re-initialize through
`RiftRepoIsolationAdapter`, rather than leaving the repo unprovisionable.

## Build and load

```sh
# from the repo root; build all required libraries before a CLI bundle
scripts/natives/build_natives.sh
# or targeted builds: build_rift.sh, build_watcher.sh, build_inference.sh,
# build_saml.sh (each under scripts/natives/)
cd apps/cc_server && fvm dart build cli
```

The build scripts stage in `<repo>/build/natives/` and install dev copies in app support next to `global.db`. `hook/build.dart` bundles staged assets into a native CLI bundle. Release packaging places them under `Contents/Frameworks/` on macOS, `<bundle>/lib/` on Linux or beside the executable on Windows; Windows stages them with `scripts/release/windows_natives.sh`. For a different staging directory, put its path in repo-root `.cc_natives_prebuilt_dir`: the hooks runner does not forward the calling process's environment. An empty repo-root `.cc_natives_allow_missing` downgrades the missing-staged-assets build-hook error to a warning **only for compile-only workflows that never run the result**. No such escape applies to a running server.

`lib/src/native_library.dart` owns candidate ordering (explicit environment override, app-support dev install, packaged release paths) and `tryOpenFirst` returns a probe result; callers must turn a missing required library into an error. `cc_natives` does not import `control_center`: hosts inject `NativeLog` and `NativeDirResolver` for logging and app-support/grammar paths.

`build_inference.sh` verifies the pinned sherpa-onnx static archive SHA-256 from `scripts/lib/native_pins.env` before cargo, then checks that the built library exposes only `cc_*` ABI symbols. See [inference provenance](native/inference/PROVENANCE.md) for bundled ONNX Runtime licenses, version updates and bindings. Upstream native versions are pinned in the scripts and `renovate.json`; the in-repo Rust crates are [watcher](native/watcher/README.md), [inference](native/inference/README.md) and [SAML](native/saml/README.md). The vendored PTY source and license are recorded in [PTY provenance](native/pty/PROVENANCE.md).

This is a plain Dart package, **not** a Flutter `ffiPlugin`: release assets and language-specific grammar libraries are staged outside Flutter builds. `test/core/architecture_constraints_test.dart` guards that boundary.
