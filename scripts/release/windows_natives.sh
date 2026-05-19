#!/usr/bin/env bash
#
# Builds the bundled native FFI libraries for Windows into build/natives/:
#   - fff (fast file finder)            -> fff_c.dll        (cargo)
#   - cc_watcher (file watcher)         -> cc_watcher.dll   (cargo; first-party
#                                          in-repo source under
#                                          packages/cc_natives/native/watcher/)
#   - pty (vendored flutter_pty)        -> ccpty.dll        (MSVC over the same
#                                          umbrella .c build_pty.sh compiles;
#                                          flutter_pty_win.c drives ConPTY).
#                                          BOOT-REQUIRED, see below.
#   - tree-sitter runtime               -> tree-sitter.dll  (its own CMake, so
#                                          the ts_* API is exported)
#   - tree-sitter grammars              -> tree-sitter-<lang>.dll (clang; each
#                                          parser.c carries _WIN32 dllexport)
#   - aec (WebRTC AEC3)                  -> aec_ffi.dll      (meson+ninja with
#                                          MSVC; /WHOLEARCHIVE the APM lib and
#                                          /EXPORT each C symbol)
#   - lame (MP3 encoder)                -> lame_ffi.dll     (MSVC shim over a
#                                          STATIC libmp3lame from vcpkg;
#                                          /EXPORT each C symbol)
#   - cc_inference (speech + embeddings)-> cc_inference.dll (cargo; first-party
#                                          in-repo source under
#                                          packages/cc_natives/native/inference/,
#                                          statically linking sherpa-onnx and ONE
#                                          onnxruntime). BOOT-REQUIRED.
#
# rift is the ONE intentional Windows gap: there is no MSVC copy-on-write
# backend, so plain `git worktree` is the BACKEND here (not a degradation) and
# the boot preflight exempts librift_ffi on Windows only. See
# `RiftRepoIsolationAdapter.missingRiftIsExpected`.
#
# FAIL-HARD: every library above is REQUIRED. cc_server's boot preflight refuses
# to start when one cannot be loaded and cc_server_package.sh refuses to produce
# an archive without it, so a warning would only defer the same failure to a user.
# The first failure aborts the run; see "How a block reports failure" below.
# Runs under Git Bash on a Windows runner. The pinned commits come from the
# pinned refs from scripts/lib/native_pins.env (Renovate-tracked in
# .github/workflows/release.yml); override locally as needed.
#
# Shares git_clone_pinned + log with the macOS/Linux scripts via
# scripts/natives/lib/natives_common.sh, but not its platform detection (that aborts off
# macOS/Linux) — the Windows build mechanics (CMake export flags, _WIN32
# dllexport) differ enough to stay inline here.
#
# Pins come from scripts/lib/native_pins.env; an env var still overrides one for
# a bisect. Needs a Windows shell with cargo, cmake, clang and an MSVC dev
# environment on PATH, plus vcpkg for LAME (or LAME_PREFIX pointing at your own).
#
# Usage:
#   scripts/release/windows_natives.sh
#   FFF_REF=<sha> scripts/release/windows_natives.sh   # override one pin
set -euo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"
source "$REPO_ROOT/scripts/natives/lib/natives_common.sh"
# Every pinned source (fff, tree-sitter + grammars, webrtc-audio-processing,
# LAME) comes from scripts/lib/native_pins.env — the same file the unix build
# scripts read, so a Renovate bump lands on both platforms at once. This used
# to arrive as a hand-maintained `env:` block in release.yml, which made every
# ref a second copy (and WAP_REF a third).
load_native_pins
RUNNER_TEMP="${RUNNER_TEMP:-$(mktemp -d)}"
mkdir -p build/natives

# --- MSVC's link.exe must win over Git's ------------------------------------
# Git for Windows ships its own `link.exe` — the coreutils hardlink tool — in
# C:\Program Files\Git\usr\bin, and Git Bash puts /usr/bin ahead of everything
# vcvarsall (ilammy/msvc-dev-cmd) prepended. Both rustc and the bare `link`
# calls below resolve the linker BY NAME, so every single link picked up
# coreutils instead of the MSVC linker and the build died on the first crate:
#
#   error: linking with `link.exe` failed: exit code: 1
#     = note: "C:\Program Files\Git\usr\bin\link.exe" "/NOLOGO" …
#     = note: /usr/bin/link: extra operand '…build_script_build….rcgu.o'
#   note: the Visual Studio build tools may need to be repaired…
#
# The trailing rustc note sends you off repairing a perfectly good MSVC install;
# the actual fault is PATH order. cl.exe is unique to MSVC and link.exe sits
# beside it, so resolving cl and prepending its directory fixes rustc, `cl` and
# `link` at once — and the assertion below keeps a future PATH change from
# quietly reintroducing the same 4-minute-to-fail build.
command -v cl >/dev/null 2>&1 || {
  echo "ERROR: cl.exe (MSVC) not on PATH — set up an MSVC dev environment first (the release workflow uses ilammy/msvc-dev-cmd)" >&2
  exit 1
}
MSVC_BIN="$(dirname "$(command -v cl)")"
export PATH="$MSVC_BIN:$PATH"
LINK_DIR="$(dirname "$(command -v link 2>/dev/null || echo /nonexistent/link)")"
[ "$LINK_DIR" = "$MSVC_BIN" ] || {
  echo "ERROR: link.exe resolves to '$LINK_DIR', not MSVC's '$MSVC_BIN' — the linker every native build needs is being shadowed" >&2
  exit 1
}
log "MSVC toolchain: $MSVC_BIN"

# --- How a block reports failure, and why it is NOT `( … ) || { echo …; }` ---
# bash ignores `set -e` inside any command whose status is being tested, and that
# includes a subshell on the left of `||` — *even if the subshell sets -e itself*
# ("If a compound command … executes in a context where -e is being ignored, none
# of the commands executed within … will be affected by the -e setting, even if
# -e is set"). So the old guards ran every remaining command after the first
# failure and reported whatever broke LAST: a tar that could not open its archive
# surfaced three minutes later as a sherpa-onnx-sys panic about a missing
# SHERPA_ONNX_LIB_DIR, which is a symptom of the tar failure and reads like a bad
# pin.
#
# Each block is therefore a PLAIN subshell — errexit live, so it stops at the
# command that actually failed with that command's own error last on stdout —
# carrying an EXIT trap that adds the human-facing "this native is required"
# line. The parent still aborts, because a failing plain subshell trips this
# script's own `set -e`. Pinned by test/tooling/native_scripts_test.dart.

# --- fff -------------------------------------------------------------------
(
  trap '[ $? -eq 0 ] || echo "ERROR: fff_c.dll not built — cc_server REFUSES TO BOOT without it (fuzzy file search has no fallback)" >&2' EXIT
  git_clone_pinned https://github.com/dmtrKovalenko/fff.git "${FFF_REF:?FFF_REF unset}" "$RUNNER_TEMP/fff"
  ( cd "$RUNNER_TEMP/fff/crates/fff-c" && cargo build --release )
  cp "$RUNNER_TEMP/fff/target/release/fff_c.dll" build/natives/ && log "Built fff_c.dll"
)

# --- cc_watcher (first-party, in-repo source) --------------------------------
(
  trap '[ $? -eq 0 ] || echo "ERROR: cc_watcher.dll not built — cc_server REFUSES TO BOOT without it (code-graph file watching has no fallback)" >&2' EXIT
  CARGO_TARGET_DIR="$RUNNER_TEMP/cc_watcher_target" \
    cargo build --release --locked \
    --manifest-path packages/cc_natives/native/watcher/Cargo.toml
  cp "$RUNNER_TEMP/cc_watcher_target/release/cc_watcher.dll" build/natives/ \
    && log "Built cc_watcher.dll"
)

# --- cc_inference (first-party, in-repo source; boot-REQUIRED) ---------------
# Speech (ASR / VAD / diarization / voiceprints) AND semantic embeddings, both
# statically linked against ONE onnxruntime.
#
# Static linking matters most here: the Windows loader satisfies a DLL
# dependency from already-loaded modules BY BASE NAME, so a process can only
# ever hold one `onnxruntime.dll`. There is exactly one, inside this library.
#
# CRT NOTE: the pinned sherpa archive is the `-MT-` (static CRT) build, so the
# Rust side must link the static CRT too — mixing it with Rust's default /MD is
# a duplicate-CRT link error, which is loud rather than subtle.
(
  trap '[ $? -eq 0 ] || echo "ERROR: cc_inference.dll not built — cc_server REFUSES TO BOOT without it (semantic embeddings and the whole speech stack have no fallback)" >&2' EXIT
  : "${SHERPA_ONNX_VERSION:?SHERPA_ONNX_VERSION unset}"
  archive="sherpa-onnx-v${SHERPA_ONNX_VERSION}-win-x64-static-MT-Release-lib.tar.bz2"
  url="https://github.com/k2-fsa/sherpa-onnx/releases/download/v${SHERPA_ONNX_VERSION}/${archive}"
  cache="$RUNNER_TEMP/sherpa-onnx"
  libdir="$cache/sherpa-onnx-v${SHERPA_ONNX_VERSION}-win-x64-static-MT-Release-lib/lib"
  if [ ! -d "$libdir" ]; then
    mkdir -p "$cache"
    curl -fSL "$url" -o "$cache/$archive"
    got="$(sha256_of "$cache/$archive")"
    [ "$got" = "${SHERPA_ONNX_LIB_SHA256_WIN_X64:?}" ] \
      || { echo "ERROR: sherpa-onnx archive sha256 mismatch: got $got" >&2; exit 1; }
    # The archive is read from STDIN, not named with -f, and that is load-bearing
    # on Windows: GNU tar treats an -f argument containing a colon as a REMOTE
    # archive (`host:path`, the rsh convention). $RUNNER_TEMP is `D:\a\_temp`, so
    # `tar xjf D:\a\_temp/…` went looking for a machine called `D`:
    #   tar (child): Cannot connect to D: resolve failed
    #   tar: Child returned status 128
    # bzip2 then got an empty stream and reported the archive as corrupt, which
    # sent the diagnosis after a perfectly good download. On stdin there is no -f
    # argument to misparse (`--force-local` also fixes it, but is GNU-only).
    #
    # The -C value needs the same care for a different reason: the same tar
    # refuses the Windows-style directory outright — `tar xj -C D:\a\_temp/…`
    # died with
    #   tar: D\:\a\\_temp/sherpa-onnx: Cannot open: No such file or directory
    # (bash's own mkdir/cd/redirects accept that spelling; MSYS tar does not),
    # and bzip2 once again blamed the stream when tar's pipe closed. cygpath -u
    # turns it into the /d/a/_temp/… form so tar only ever sees a POSIX path.
    tar xj -C "$(cygpath -u "$cache")" <"$cache/$archive" \
      || { echo "ERROR: failed to extract $archive" >&2; exit 1; }
    # The layout is part of the pin: sherpa-onnx-sys reads SHERPA_ONNX_LIB_DIR and
    # panics with its own message if it is missing, three minutes of cargo build
    # later. Fail here, where the archive is still the obvious suspect.
    [ -d "$libdir" ] \
      || { echo "ERROR: $archive extracted but $libdir is missing — the upstream archive layout changed" >&2; exit 1; }
  fi
  SHERPA_ONNX_LIB_DIR="$libdir" \
  RUSTFLAGS="-Ctarget-feature=+crt-static" \
  CARGO_TARGET_DIR="$RUNNER_TEMP/cc_inference_target" \
    cargo build --release --locked \
    --manifest-path packages/cc_natives/native/inference/Cargo.toml
  cp "$RUNNER_TEMP/cc_inference_target/release/cc_inference.dll" build/natives/ \
    && log "Built cc_inference.dll"
)

# --- pty (vendored flutter_pty; boot-REQUIRED) --------------------------------
# The pseudo-terminal native behind the `terminal.*` RPC ops and the sandboxed
# agent shells. Mirrors scripts/natives/build_pty.sh — the SAME vendored umbrella
# source (packages/cc_natives/native/pty/flutter_pty.c, which #includes
# flutter_pty_win.c + dart_api_dl.c under _WIN32) — with the MSVC toolchain.
# There is no fallback: without ccpty.dll `Pty.isAvailable` is false and
# cc_server's preflight refuses to boot, so this is not a "nice to have" on
# Windows the way aec/lame are.
#
# Three Windows-only compile requirements:
#
#   * /DDART_SHARED_LIB — dart_api.h only decorates DART_EXPORT with
#     __declspec(dllexport) under this define, and the Dart side looks
#     `Dart_InitializeApiDL` up FROM THIS DLL (pty_ffi_bindings.dart). Without
#     it the DLL still builds and still exports the pty_* ABI (flutter_pty.h
#     carries its own _WIN32 dllexport) — it just fails at runtime on that one
#     symbol. This is what upstream flutter_pty's windows/CMakeLists.txt does.
#   * /MT — the standalone cc_server zip ships no VC++ runtime, so link the CRT
#     statically instead of depending on vcruntime140.dll being installed on the
#     host. Safe here: no allocation crosses the FFI boundary (Dart frees only
#     what Dart allocated, and `pty_error` returns a static buffer).
#   * /FIstdlib.h /FIstring.h + /we4013 — the vendored .c calls malloc/free/strlen
#     having included only <stdio.h> and <Windows.h>, relying on the latter's
#     transitive includes. An implicitly-declared malloc is assumed to return
#     `int`, which SILENTLY TRUNCATES the pointer on x64, so force-include the
#     two headers and promote C4013 (implicit declaration) to an error rather
#     than bet a boot-required native on an SDK implementation detail.
#
# Deliberately does NOT define _WIN32_WINNT: ConPTY (CreatePseudoConsole) is
# declared behind `NTDDI_VERSION >= NTDDI_WIN10_RS5`, and defining _WIN32_WINNT
# alone makes sdkddkver.h derive a LOWER NTDDI than the default (latest SDK),
# which hides the API and breaks the build.
(
  trap '[ $? -eq 0 ] || echo "ERROR: ccpty.dll not built — cc_server REFUSES TO BOOT without it on Windows (no terminal/PTY fallback exists)" >&2' EXIT
  PTY_SRC="$REPO_ROOT/packages/cc_natives/native/pty"
  command -v cl >/dev/null 2>&1 || { echo "cl.exe (MSVC) not on PATH"; exit 1; }
  [ -f "$PTY_SRC/flutter_pty.c" ] || { echo "vendored PTY umbrella missing: $PTY_SRC/flutter_pty.c"; exit 1; }

  cl //nologo //std:c11 //O2 //MT //DDART_SHARED_LIB \
    //FIstdlib.h //FIstring.h //we4013 \
    //I "$(cygpath -w "$PTY_SRC")" \
    //c "$(cygpath -w "$PTY_SRC/flutter_pty.c")" \
    //Fo"$(cygpath -w "$RUNNER_TEMP/ccpty.obj")" \
    || { echo "PTY compile failed"; exit 1; }
  # An MSVC option value must never contain a forward slash: Git Bash only
  # rewrites `//opt` to `/opt` when the remainder is slash-free, so
  # `//OUT:build/natives/ccpty.dll` reads as a UNC path, reaches link.exe
  # verbatim, and is IGNORED:
  #   LINK : warning LNK4044: unrecognized option '//OUT:build/natives/ccpty.dll'
  # The DLL then lands in the CWD under the first .obj's name and the export
  # sanity check below fails on a file that was never written. cygpath -w keeps
  # the value all-backslash. Same rule for every //Fo and the aec/lame //OUT
  # below; pinned by native_scripts_test.dart.
  link //nologo //DLL //OUT:"$(cygpath -w build/natives/ccpty.dll)" \
    "$(cygpath -w "$RUNNER_TEMP/ccpty.obj")" kernel32.lib \
    || { echo "ccpty.dll link failed"; exit 1; }

  # Sanity: every symbol pty_ffi_bindings.dart looks up must be exported (a miss
  # is a runtime lookupFunction failure, not a load failure — invisible here).
  PTY_EXPORTS="$(dumpbin //nologo //exports "$(cygpath -w build/natives/ccpty.dll)")" \
    || { echo "dumpbin failed on ccpty.dll"; exit 1; }
  for sym in Dart_InitializeApiDL pty_create pty_write pty_ack_read pty_resize pty_getpid pty_error; do
    grep -qw "$sym" <<<"$PTY_EXPORTS" || { echo "built ccpty.dll is missing the $sym export"; exit 1; }
  done
  log "Built ccpty.dll"
)

# --- tree-sitter runtime ---------------------------------------------------
(
  trap '[ $? -eq 0 ] || echo "ERROR: tree-sitter.dll not built — cc_server REFUSES TO BOOT without it (code graph indexing has no fallback)" >&2' EXIT
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
  # `|| true`: head -1 can SIGPIPE find; the `[ -n "$RT" ]` guard below is the
  # authoritative check and prints the actionable message.
  RT=$(find "$RUNNER_TEMP/ts/build" -name 'tree-sitter.dll' | head -1 || true)
  [ -n "$RT" ] && cp "$RT" build/natives/tree-sitter.dll && log "Built tree-sitter.dll"
)

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
    trap '[ $? -eq 0 ] || echo "ERROR: tree-sitter grammar '"$name"' failed to build — it is a REQUIRED native" >&2' EXIT
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
  )
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
# (the release workflow sets one up, e.g. via ilammy/msvc-dev-cmd).
# BOOT-REQUIRED for the desktop's system-capture meeting recorder: AEC has no
# fallback, so a failure here is fatal.
(
  trap '[ $? -eq 0 ] || echo "ERROR: aec_ffi.dll not built — it is a REQUIRED native (remote-mode meeting recording throws AecUnavailable without it)" >&2' EXIT
  SHIM="$REPO_ROOT/packages/cc_natives/native/aec_ffi.cc"
  command -v meson >/dev/null || { echo "meson not found"; exit 1; }
  command -v ninja >/dev/null || { echo "ninja not found"; exit 1; }
  command -v cl >/dev/null 2>&1 || { echo "cl.exe (MSVC) not on PATH"; exit 1; }
  [ -f "$SHIM" ] || { echo "shim missing: $SHIM"; exit 1; }

  git_clone_pinned https://gitlab.freedesktop.org/pulseaudio/webrtc-audio-processing.git \
    "$WAP_REF" "$RUNNER_TEMP/wap"
  SRC="$RUNNER_TEMP/wap"
  # MSVC accepts the designated initializers WebRTC's agc2 code uses only
  # under /std:c++20 (input_volume_stats_reporter.cc: error C7555); GCC and
  # Clang take them as a C++17 extension, which is why the unix builds never
  # tripped this. The override outranks the project's cpp_std=c++17 default,
  # and the abseil-cpp fallback gets the same std explicitly so the two
  # static archives are not compiled against different standard levels.
  #
  # b_vscrt=mt: meson's release default compiles /MD, but the shim below —
  # like every other Windows native here, see the pty block's CRT note —
  # links the static CRT, and mixing them fails the aec_ffi.dll link with
  #   LNK2038: mismatch detected for 'RuntimeLibrary': value
  #   'MD_DynamicRelease' doesn't match value 'MT_StaticRelease'
  # for every object in the archive. A meson base option, so the abseil
  # subproject inherits it too.
  ( cd "$SRC" && meson setup build --vsenv \
      --buildtype=release --default-library=static \
      -Dcpp_std=c++20 -Dabseil-cpp:cpp_std=c++20 -Db_vscrt=mt \
      --force-fallback-for=abseil-cpp )
  # The example target's link may fail (as on macOS) — every archive we need is
  # built before it, so ignore a non-zero ninja exit.
  ( cd "$SRC" && ninja -C build ) || true

  # meson names static libraries libfoo.a even under MSVC — they are ordinary
  # COFF archives link.exe accepts by path — so waiting for an MSVC-flavoured
  # webrtc-audio-processing-2.lib found nothing after a fully successful
  # 440-target build. Same fixed path as build_aec.sh uses on macOS/Linux.
  MAIN_LIB="$SRC/build/webrtc/modules/audio_processing/libwebrtc-audio-processing-2.a"
  [ -f "$MAIN_LIB" ] || { echo "APM static archive not built: $MAIN_LIB"; exit 1; }
  ABSEIL_INC=$(find "$SRC/subprojects" -maxdepth 1 -type d -name 'abseil-cpp-*' | head -1 || true)
  [ -n "$ABSEIL_INC" ] || { echo "abseil subproject missing"; exit 1; }

  # Compile the shim, then link a DLL: whole-archive the APM lib and the deps,
  # exporting the six C entry points the FFI loader looks up.
  # //MT matches b_vscrt=mt above (cl's default is /MT, but leaving the CRT
  # choice implicit is how the mismatch crept in); //std:c++20 matches the
  # webrtc archives so shim and library agree on the headers' standard level.
  cl //std:c++20 //O2 //MT //DWEBRTC_WIN //DWEBRTC_APM_DEBUG_DUMP=0 \
    //I "$(cygpath -w "$SRC/webrtc")" //I "$(cygpath -w "$ABSEIL_INC")" \
    //c "$(cygpath -w "$SHIM")" //Fo"$(cygpath -w "$RUNNER_TEMP/aec_ffi.obj")"
  OTHER_LIBS=()
  while IFS= read -r l; do
    [ "$l" = "$MAIN_LIB" ] || OTHER_LIBS+=("$(cygpath -w "$l")")
  done < <(find "$SRC/build" -name '*.a')
  # //OUT and //Fo via cygpath -w — see the ccpty link note above.
  # winmm.lib: rtc::SystemTimeNanos calls timeGetTime, which lives in
  # winmm.dll — without it the link dies with LNK2019 __imp_timeGetTime, the
  # single system symbol the whole-archived APM objects reach outside the
  # default lib set.
  link //DLL //OUT:"$(cygpath -w build/natives/aec_ffi.dll)" "$RUNNER_TEMP/aec_ffi.obj" \
    //WHOLEARCHIVE:"$(cygpath -w "$MAIN_LIB")" "${OTHER_LIBS[@]}" winmm.lib \
    //EXPORT:aec_create //EXPORT:aec_destroy //EXPORT:aec_version \
    //EXPORT:aec_process_reverse //EXPORT:aec_process_capture \
    //EXPORT:aec_get_metrics
  [ -f build/natives/aec_ffi.dll ] && log "Built aec_ffi.dll"
)

# --- lame (MP3 encoder) ----------------------------------------------------
# Mirrors scripts/natives/build_lame.sh with the MSVC toolchain: compile the
# extern "C" shim (packages/cc_natives/native/lame_ffi.cc) and link it against a
# STATIC libmp3lame so the DLL is self-contained (Mp3Encoder turns the meeting /
# session PCM16 into MP3). The shim carries no __declspec, so each C entry point
# is exported by passing /EXPORT to link.exe — same trick as aec above.
#
# libmp3lame provenance (LGPL-2.1, LAME 3.100 — MP3's core patents expired in
# 2017, so shipping an encoder is unencumbered): vcpkg's `mp3lame` port, static
# triplet. vcpkg is preinstalled on the GitHub Windows runners
# (VCPKG_INSTALLATION_ROOT). Overrides, both mirroring build_lame.sh's contract:
#   LAME_PREFIX=<dir>   use a prebuilt libmp3lame (<dir>/include/lame/lame.h +
#                       <dir>/lib/*mp3lame*.lib) and skip vcpkg entirely
#   LAME_TRIPLET=<t>    vcpkg triplet (default x64-windows-static)
#
# The static triplet builds against the static CRT, so the shim compiles /MT to
# match — a /MD shim linked against a /MT archive is a CRT-mismatch link error.
# Best-effort, like on macOS/Linux: Mp3Encoder.tryCreate returns null without
# this DLL and callers keep the raw PCM.
(
  trap '[ $? -eq 0 ] || echo "ERROR: lame_ffi.dll not built — cc_server REFUSES TO BOOT without it (soundscape MP3 encoding has no fallback)" >&2' EXIT
  SHIM="$REPO_ROOT/packages/cc_natives/native/lame_ffi.cc"
  LAME_TRIPLET="${LAME_TRIPLET:-x64-windows-static}"
  command -v cl >/dev/null 2>&1 || { echo "cl.exe (MSVC) not on PATH"; exit 1; }
  [ -f "$SHIM" ] || { echo "shim missing: $SHIM"; exit 1; }

  # cygpath -u throughout so a Windows-style override / VCPKG_INSTALLATION_ROOT
  # (C:\vcpkg) becomes a path bash's own `[ -f ]` tests understand.
  PREFIX="${LAME_PREFIX:+$(cygpath -u "$LAME_PREFIX")}"
  if [ -z "$PREFIX" ]; then
    VCPKG_ROOT="$(cygpath -u "${VCPKG_INSTALLATION_ROOT:-C:/vcpkg}")"
    [ -x "$VCPKG_ROOT/vcpkg.exe" ] || { echo "vcpkg not found at $VCPKG_ROOT (set LAME_PREFIX to a prebuilt libmp3lame)"; exit 1; }
    # Run from the vcpkg root so it stays in classic mode (a vcpkg.json in the
    # CWD would flip it to manifest mode and install nowhere we look).
    ( cd "$VCPKG_ROOT" && ./vcpkg.exe install mp3lame --triplet "$LAME_TRIPLET" ) \
      || { echo "vcpkg install mp3lame:$LAME_TRIPLET failed"; exit 1; }
    PREFIX="$VCPKG_ROOT/installed/$LAME_TRIPLET"
  fi
  [ -f "$PREFIX/include/lame/lame.h" ] || { echo "no lame/lame.h under $PREFIX/include"; exit 1; }
  LAME_LIB="$(find "$PREFIX/lib" -maxdepth 1 -name '*mp3lame*.lib' 2>/dev/null | head -1 || true)"
  [ -n "$LAME_LIB" ] || { echo "no static libmp3lame under $PREFIX/lib"; exit 1; }
  # vcpkg's static mp3lame splits the HIP/mpglib decoder into its own
  # libmpghip-static.lib, and libmp3lame-static.lib(mpglib_interface.obj)
  # references its InitMP3/decodeMP3/tabsel_123/… — 6 unresolved externals
  # (LNK2019) without it. The shim only encodes, but the archive member is
  # pulled in regardless. Optional on purpose: a LAME_PREFIX built without
  # the decoder has no such lib and no such references.
  HIP_LIB="$(find "$PREFIX/lib" -maxdepth 1 -name '*mpghip*.lib' 2>/dev/null | head -1 || true)"
  log "Using libmp3lame: $LAME_LIB${HIP_LIB:+ + $HIP_LIB}"

  cl //nologo //std:c++17 //O2 //MT \
    //I "$(cygpath -w "$PREFIX/include")" \
    //c "$(cygpath -w "$SHIM")" \
    //Fo"$(cygpath -w "$RUNNER_TEMP/lame_ffi.obj")" \
    || { echo "shim compile failed"; exit 1; }
  # //OUT via cygpath -w — see the ccpty link note above.
  link //nologo //DLL //OUT:"$(cygpath -w build/natives/lame_ffi.dll)" \
    "$(cygpath -w "$RUNNER_TEMP/lame_ffi.obj")" "$(cygpath -w "$LAME_LIB")" \
    ${HIP_LIB:+"$(cygpath -w "$HIP_LIB")"} \
    //EXPORT:cc_lame_create //EXPORT:cc_lame_encode //EXPORT:cc_lame_flush \
    //EXPORT:cc_lame_destroy //EXPORT:cc_lame_version \
    || { echo "lame_ffi.dll link failed"; exit 1; }

  # Sanity: the five symbols LameFfiBindings.tryLoad looks up must be exported.
  LAME_EXPORTS="$(dumpbin //nologo //exports "$(cygpath -w build/natives/lame_ffi.dll)")" \
    || { echo "dumpbin failed on lame_ffi.dll"; exit 1; }
  for sym in cc_lame_create cc_lame_encode cc_lame_flush cc_lame_destroy cc_lame_version; do
    grep -qw "$sym" <<<"$LAME_EXPORTS" || { echo "built lame_ffi.dll is missing the $sym export"; exit 1; }
  done
  log "Built lame_ffi.dll"
)

# --- tree-sitter .scm queries ----------------------------------------------
# The hand-authored queries travel beside the grammar DLLs — GrammarManager
# resolves a language's query from the same dir as its lib (beside the .exe on
# Windows; see loadQuery). queryIdFor maps tsx → typescript, so only 4 ship.
cp -f "$REPO_ROOT/scripts/natives/queries/"*.scm build/natives/ \
  || { echo "ERROR: failed to stage the .scm queries" >&2; exit 1; }
SCM_COUNT="$(find build/natives -maxdepth 1 -name '*.scm' | wc -l | tr -d ' ' || true)"
[ "$SCM_COUNT" -gt 0 ] || { echo "ERROR: no .scm queries staged into build/natives" >&2; exit 1; }
log "Staged $SCM_COUNT .scm queries"

log "Staged Windows native libraries:"
ls -la build/natives
