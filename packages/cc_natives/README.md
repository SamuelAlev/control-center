# cc_natives

The Dart FFI surface for Control Center's **runtime-loaded native libraries**.
This package owns only the Dart side — bindings, loaders, and path-resolution
policy. It builds **no** native code; the shared libraries are produced by
`scripts/natives/*.sh` and loaded at runtime via `dart:ffi`, degrading
gracefully when absent.

## The four natives

| Library | Base name | Purpose | Fallback when absent |
|---|---|---|---|
| **rift** | `rift_ffi` | Copy-on-write git worktrees (APFS clonefile / reflink) | plain `git worktree` |
| **fff** | `fff_c` | Fast file search with frecency ranking | pure-Dart `DartFileSearch` |
| **tree-sitter** | `tree-sitter` (+ `tree-sitter-<lang>`) | Code indexing / AST extraction | code graph skipped |
| **aec** | `aec_ffi` | Acoustic echo cancellation (WebRTC AEC3) for meetings | text-based echo filter |

Every native is **best-effort**: a missing dylib is not an error — the loader
returns `null` and the caller falls back. Nothing here ever fails an app build.

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
  `scripts/natives/build_*.sh` installs it. This is the *only* dev location —
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
scripts/natives/build_natives.sh            # all four → <repo>/build/natives + app-support
scripts/natives/build_rift.sh               # one at a time
```

Upstream sources are fetched at pinned SHAs (Renovate-managed); see the scripts
and `renovate.json`.

## NOT a Flutter plugin

This is intentionally a plain Dart package, **not** an `ffiPlugin`. Converting it
would move native compilation into `flutter build` (no `continue-on-error`
there), make cargo/meson/ninja/a C++ toolchain mandatory for every contributor
and every build, collapse tree-sitter to a single build-time dylib (killing the
runtime grammar-download feature), and destroy the fast install-to-app-support
dev loop. The `architecture_constraints_test.dart` guard fails if anyone adds an
`ffiPlugin` declaration here.
