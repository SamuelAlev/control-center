#!/usr/bin/env bash
#
# Builds the bundled native FFI libraries for Windows into build/natives/:
#   - fff (fast file finder)            -> fff_c.dll        (cargo)
#   - tree-sitter runtime               -> tree-sitter.dll  (its own CMake, so
#                                          the ts_* API is exported)
#   - tree-sitter grammars              -> tree-sitter-<lang>.dll (clang; each
#                                          parser.c carries _WIN32 dllexport)
#   - aec (WebRTC AEC3)                  -> aec_ffi.dll      (meson+ninja with
#                                          MSVC; /WHOLEARCHIVE the APM lib and
#                                          /EXPORT each C symbol). Best-effort —
#                                          meetings fall back to the text echo
#                                          filter when absent.
#
# rift is intentionally NOT built on Windows (no MSVC CoW backend) — the app
# falls back to plain `git worktree` there. Best-effort: a failure of any
# library is a warning, never fatal (exit 0). Runs under Git Bash on a Windows
# runner. The pinned commits come from the `*_REF` env vars set by the workflow
# (Renovate-tracked in .github/workflows/release.yml); override locally as needed.
#
# Shares git_clone_pinned + log with the macOS/Linux scripts via
# scripts/natives/lib/natives_common.sh, but not its platform detection (that aborts off
# macOS/Linux) — the Windows build mechanics (CMake export flags, _WIN32
# dllexport) differ enough to stay inline here.
#
# Usage (from a Windows shell with cargo, cmake and clang on PATH):
#   FFF_REF=... TREE_SITTER_REF=... TS_*_REF=... scripts/release/windows_natives.sh
set -uo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"
source "$REPO_ROOT/scripts/natives/lib/natives_common.sh"
RUNNER_TEMP="${RUNNER_TEMP:-$(mktemp -d)}"
mkdir -p build/natives

# --- fff -------------------------------------------------------------------
(
  git_clone_pinned https://github.com/dmtrKovalenko/fff.git "${FFF_REF:?FFF_REF unset}" "$RUNNER_TEMP/fff"
  ( cd "$RUNNER_TEMP/fff/crates/fff-c" && cargo build --release )
  cp "$RUNNER_TEMP/fff/target/release/fff_c.dll" build/natives/ && log "Built fff_c.dll"
) || echo "::warning::fff build failed — file search degrades to Dart"

# --- tree-sitter runtime ---------------------------------------------------
(
  git_clone_pinned https://github.com/tree-sitter/tree-sitter.git "${TREE_SITTER_REF:?TREE_SITTER_REF unset}" "$RUNNER_TEMP/ts"
  # The library's CMakeLists lives at the repo ROOT (it moved out of lib/ in
  # tree-sitter >=0.25, so `-S .../ts/lib` errors with "does not contain
  # CMakeLists.txt"). The public API carries no __declspec(dllexport) — only
  # GCC/Clang visibility pragmas, which are a no-op under MSVC — so
  # CMAKE_WINDOWS_EXPORT_ALL_SYMBOLS is required for the ts_* symbols to be
  # exported from the DLL (otherwise it builds but exports nothing and the
  # loader's lookupFunction fails at runtime).
  cmake -S "$RUNNER_TEMP/ts" -B "$RUNNER_TEMP/ts/build" \
    -DBUILD_SHARED_LIBS=ON -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_WINDOWS_EXPORT_ALL_SYMBOLS=ON
  cmake --build "$RUNNER_TEMP/ts/build" --config Release
  RT=$(find "$RUNNER_TEMP/ts/build" -name 'tree-sitter.dll' | head -1)
  [ -n "$RT" ] && cp "$RT" build/natives/tree-sitter.dll && log "Built tree-sitter.dll"
) || echo "::warning::tree-sitter runtime DLL not built — code graph unavailable on Windows"

# --- tree-sitter grammars --------------------------------------------------
# build_grammar <languageId> <repo-url> <ref> <src-subdir>
build_grammar() {
  # NB: keep `dir` on its own `local` line — folding it onto the line above as
  # `local name="$1" ... dir="$RUNNER_TEMP/g-$name"` expands $name before the
  # assignment lands, which trips `set -u` ("name: unbound variable") and aborts
  # the whole script before any grammar is built.
  local name="$1" repo="$2" ref="$3" sub="$4"
  local dir="$RUNNER_TEMP/g-$name"
  (
    git_clone_pinned "$repo" "$ref" "$dir"
    local src="$dir/$sub"
    [ -f "$src/parser.c" ] || { echo "no parser.c for $name"; exit 1; }
    local srcs="$src/parser.c"
    local compiler="clang"
    [ -f "$src/scanner.c" ] && srcs="$srcs $src/scanner.c"
    # A C++ external scanner needs the C++ driver so the C++ runtime links in.
    # parser.c carries _WIN32 dllexport for tree_sitter_<lang>.
    if [ -f "$src/scanner.cc" ]; then srcs="$srcs $src/scanner.cc"; compiler="clang++"; fi
    # shellcheck disable=SC2086
    "$compiler" -shared -O2 -I "$src" $srcs -o "build/natives/tree-sitter-$name.dll"
    log "Built tree-sitter-$name.dll"
  ) || echo "::warning::grammar $name failed"
}

build_grammar dart       https://github.com/UserNobody14/tree-sitter-dart.git      "${TS_DART_REF:?}"       src
build_grammar javascript https://github.com/tree-sitter/tree-sitter-javascript.git "${TS_JAVASCRIPT_REF:?}" src
build_grammar typescript https://github.com/tree-sitter/tree-sitter-typescript.git "${TS_TYPESCRIPT_REF:?}" typescript/src
build_grammar tsx        https://github.com/tree-sitter/tree-sitter-typescript.git "${TS_TYPESCRIPT_REF:?}" tsx/src
build_grammar php        https://github.com/tree-sitter/tree-sitter-php.git         "${TS_PHP_REF:?}"        php/src

# --- aec (WebRTC AEC3) -----------------------------------------------------
# Mirrors scripts/natives/build_aec.sh but with the MSVC toolchain. WebRTC's
# AEC3 builds on Windows via the same meson webrtc-audio-processing wrap; the
# shim (extern "C", no __declspec) is exported by passing /EXPORT for each C
# symbol to link.exe. Requires meson, ninja, and an MSVC dev environment on PATH
# (the release workflow sets one up, e.g. via ilammy/msvc-dev-cmd). A failure is
# a warning — meetings degrade to the text MeetingEchoFilter.
(
  WAP_REF="${WAP_REF:-d0569cfa50c1858ee279d77b3fc8870be6902441}" # v2.1 (matches build_aec.sh)
  SHIM="$REPO_ROOT/packages/cc_natives/native/aec_ffi.cc"
  command -v meson >/dev/null || { echo "meson not found"; exit 1; }
  command -v ninja >/dev/null || { echo "ninja not found"; exit 1; }
  command -v cl >/dev/null 2>&1 || { echo "cl.exe (MSVC) not on PATH"; exit 1; }
  [ -f "$SHIM" ] || { echo "shim missing: $SHIM"; exit 1; }

  git_clone_pinned https://gitlab.freedesktop.org/pulseaudio/webrtc-audio-processing.git \
    "$WAP_REF" "$RUNNER_TEMP/wap"
  SRC="$RUNNER_TEMP/wap"
  ( cd "$SRC" && meson setup build --vsenv \
      --buildtype=release --default-library=static \
      --force-fallback-for=abseil-cpp )
  # The example target's link may fail (as on macOS) — every archive we need is
  # built before it, so ignore a non-zero ninja exit.
  ( cd "$SRC" && ninja -C build ) || true

  MAIN_LIB=$(find "$SRC/build" -name 'webrtc-audio-processing-2.lib' | head -1)
  [ -n "$MAIN_LIB" ] || { echo "APM .lib not built"; exit 1; }
  ABSEIL_INC=$(find "$SRC/subprojects" -maxdepth 1 -type d -name 'abseil-cpp-*' | head -1)
  [ -n "$ABSEIL_INC" ] || { echo "abseil subproject missing"; exit 1; }

  # Compile the shim, then link a DLL: whole-archive the APM lib and the deps,
  # exporting the six C entry points the FFI loader looks up.
  cl //std:c++17 //O2 //DWEBRTC_WIN //DWEBRTC_APM_DEBUG_DUMP=0 \
    //I "$(cygpath -w "$SRC/webrtc")" //I "$(cygpath -w "$ABSEIL_INC")" \
    //c "$(cygpath -w "$SHIM")" //Fo"$RUNNER_TEMP/aec_ffi.obj"
  OTHER_LIBS=()
  while IFS= read -r l; do
    [ "$l" = "$MAIN_LIB" ] || OTHER_LIBS+=("$(cygpath -w "$l")")
  done < <(find "$SRC/build" -name '*.lib')
  link //DLL //OUT:"build/natives/aec_ffi.dll" "$RUNNER_TEMP/aec_ffi.obj" \
    //WHOLEARCHIVE:"$(cygpath -w "$MAIN_LIB")" "${OTHER_LIBS[@]}" \
    //EXPORT:aec_create //EXPORT:aec_destroy //EXPORT:aec_version \
    //EXPORT:aec_process_reverse //EXPORT:aec_process_capture \
    //EXPORT:aec_get_metrics
  [ -f build/natives/aec_ffi.dll ] && log "Built aec_ffi.dll"
) || echo "::warning::aec_ffi.dll not built — meetings use the text echo filter on Windows"

# --- tree-sitter .scm queries ----------------------------------------------
# The hand-authored queries travel beside the grammar DLLs — GrammarManager
# resolves a language's query from the same dir as its lib (beside the .exe on
# Windows; see loadQuery). queryIdFor maps tsx → typescript, so only 4 ship.
cp -f "$REPO_ROOT/scripts/natives/queries/"*.scm build/natives/ && log "Staged .scm queries"

log "Staged Windows native libraries:"
ls -la build/natives || true
exit 0
