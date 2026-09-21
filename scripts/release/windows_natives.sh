#!/usr/bin/env bash
#
# Builds Windows native FFI libs into build/natives/ (fff, cc_watcher, ccpty,
# tree-sitter + grammars, aec, lame, cc_inference, cc_saml). rift is the sole
# intentional gap (git worktree backend). All listed libs are REQUIRED — first
# failure aborts. Pins from scripts/lib/native_pins.env (env overrides). Needs
# cargo, cmake, clang, MSVC, and vcpkg/LAME_PREFIX for LAME.
# Usage: scripts/release/windows_natives.sh
#
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

# MSVC's link.exe must win over Git's coreutils `link.exe` (Git Bash puts
# /usr/bin first). Prepend the real MSVC linker dir to PATH or rustc/link fail.
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

# Each native block is a plain subshell with errexit (not `(…) || echo`) — bash
# ignores set -e on the left of `||`, so failures reported the LAST error. EXIT
# trap adds the "required" line; parent set -e still aborts.

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

# --- cc_saml (first-party, in-repo source; boot-REQUIRED) --------------------
# The SAML 2.0 service-provider crypto seam. Mirrors scripts/natives/build_saml.sh,
# which aborts off macOS/Linux — this is the Windows half of the same build, and
# it is the plainest one in this file: the crate is a C-ABI seam over the pinned
# pure-Rust `saml` crate (quick-xml + RustCrypto), so there is no libxml2 /
# xmlsec1 / openssl toolchain, no bindgen and nothing MSVC-specific to arrange.
#
# No degraded path exists on purpose — hand-rolling XML-DSig canonicalization is
# where SAML signature-wrapping vulnerabilities live — so the boot preflight
# refuses to start without this library.
(
  trap '[ $? -eq 0 ] || echo "ERROR: cc_saml.dll not built — cc_server REFUSES TO BOOT without it (SAML SSO has no pure-Dart fallback)" >&2' EXIT
  CARGO_TARGET_DIR="$RUNNER_TEMP/cc_saml_target" \
    cargo build --release --locked \
    --manifest-path packages/cc_natives/native/saml/Cargo.toml
  cp "$RUNNER_TEMP/cc_saml_target/release/cc_saml.dll" build/natives/

  # Sanity: a cdylib whose #[no_mangle] entry points stopped being exported
  # still links and still loads — the failure is a lookupFunction miss at
  # runtime, invisible here. Same seven symbols build_saml.sh checks with nm.
  SAML_EXPORTS="$(dumpbin //nologo //exports "$(cygpath -w build/natives/cc_saml.dll)")" \
    || { echo "dumpbin failed on cc_saml.dll"; exit 1; }
  for sym in cc_saml_abi_version cc_saml_last_error cc_saml_free_string \
    cc_saml_parse_idp_metadata cc_saml_build_authn_request \
    cc_saml_verify_response cc_saml_sp_metadata; do
    grep -qw "$sym" <<<"$SAML_EXPORTS" || { echo "built cc_saml.dll is missing the $sym export"; exit 1; }
  done
  log "Built cc_saml.dll"
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
# tree-sitter grammars: each parser.c carries _WIN32 dllexport; build with clang.
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

# pty (vendored flutter_pty; BOOT-REQUIRED): same umbrella .c as build_pty.sh.
# Require /DDART_SHARED_LIB (Dart_InitializeApiDL export), /MT (no VC++ runtime
# in the zip), /FIstdlib.h /FIstring.h + /we4013 (implicit malloc truncates on
# x64). Do NOT define _WIN32_WINNT alone — lowers NTDDI and hides ConPTY.
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
  # verbatim and is IGNORED:
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

build_grammar dart       https://github.com/UserNobody14/tree-sitter-dart.git           "${TS_DART_REF:?}"       src
build_grammar javascript https://github.com/tree-sitter/tree-sitter-javascript.git      "${TS_JAVASCRIPT_REF:?}" src
build_grammar typescript https://github.com/tree-sitter/tree-sitter-typescript.git      "${TS_TYPESCRIPT_REF:?}" typescript/src
build_grammar tsx        https://github.com/tree-sitter/tree-sitter-typescript.git      "${TS_TYPESCRIPT_REF:?}" tsx/src
build_grammar php        https://github.com/tree-sitter/tree-sitter-php.git              "${TS_PHP_REF:?}"        php/src
build_grammar python     https://github.com/tree-sitter/tree-sitter-python.git          "${TS_PYTHON_REF:?}"     src
build_grammar rust       https://github.com/tree-sitter/tree-sitter-rust.git            "${TS_RUST_REF:?}"       src
build_grammar zig        https://github.com/tree-sitter-grammars/tree-sitter-zig.git    "${TS_ZIG_REF:?}"        src
build_grammar c          https://github.com/tree-sitter/tree-sitter-c.git               "${TS_C_REF:?}"          src
build_grammar cpp        https://github.com/tree-sitter/tree-sitter-cpp.git             "${TS_CPP_REF:?}"        src
build_grammar go         https://github.com/tree-sitter/tree-sitter-go.git              "${TS_GO_REF:?}"         src
build_grammar java       https://github.com/tree-sitter/tree-sitter-java.git            "${TS_JAVA_REF:?}"       src
build_grammar ruby       https://github.com/tree-sitter/tree-sitter-ruby.git            "${TS_RUBY_REF:?}"       src
build_grammar c_sharp    https://github.com/tree-sitter/tree-sitter-c-sharp.git         "${TS_C_SHARP_REF:?}"    src
build_grammar swift      https://github.com/alex-pinkus/tree-sitter-swift.git           "${TS_SWIFT_REF:?}"      src
build_grammar kotlin     https://github.com/tree-sitter-grammars/tree-sitter-kotlin.git "${TS_KOTLIN_REF:?}"     src
build_grammar r          https://github.com/r-lib/tree-sitter-r.git                     "${TS_R_REF:?}"          src
build_grammar asm        https://github.com/RubixDev/tree-sitter-asm.git                 "${TS_ASM_REF:?}"        src
build_grammar matlab     https://github.com/acristoffers/tree-sitter-matlab.git         "${TS_MATLAB_REF:?}"    src
build_grammar ada        https://github.com/briot/tree-sitter-ada.git                   "${TS_ADA_REF:?}"        src

# --- aec (WebRTC AEC3) -----------------------------------------------------
# Mirrors scripts/natives/build_aec.sh but with the MSVC toolchain. WebRTC's
# AEC3 builds on Windows via the same meson webrtc-audio-processing wrap; the
# shim (extern "C", no __declspec) is exported by passing /EXPORT for each C
# symbol to link.exe. Requires meson, ninja and an MSVC dev environment on PATH
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
  # links the static CRT and mixing them fails the aec_ffi.dll link with
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

# lame (REQUIRED): MSVC shim over static libmp3lame (vcpkg / LAME_PREFIX);
# /EXPORT each C symbol; /MT to match the static CRT triplet.
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
  # libmpghip-static.lib and libmp3lame-static.lib(mpglib_interface.obj)
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
