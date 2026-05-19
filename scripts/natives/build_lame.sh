#!/usr/bin/env bash
#
# Builds liblame_ffi — a thin C ABI (packages/cc_natives/native/lame_ffi.cc) over
# libmp3lame (LAME) — and installs it where LameFfiBindings looks for it (the
# app-support root next to control_center.db, plus an optional explicit DEST for
# CI staging / bundle embedding). Mirrors scripts/natives/build_aec.sh.
#
# Mp3Encoder wraps this to turn interleaved PCM16 into a frame-aligned MP3 byte
# stream (encode chunk -> append bytes -> flush at end).
#
# REQUIRED on every platform: cc_server's boot preflight refuses to start without
# liblame_ffi, and Mp3Encoder.create THROWS LameUnavailable rather than letting
# the soundscape routes quietly 404 a feature the host is supposed to have.
#
# libmp3lame source: LAME 3.100 (the last upstream release), LGPL-2.1. It is NOT
# vendored. Two ways to obtain it, tried in order:
#   (a) a system libmp3lame (Homebrew `lame`, apt `libmp3lame-dev`) — its static
#       archive is preferred so liblame_ffi stays self-contained; if only a
#       shared lib is present we link that and warn it is not self-contained;
#   (b) otherwise download the LAME 3.100 tarball and
#       `./configure --disable-shared --enable-static --with-pic --disable-frontend && make
#       && make install` into a temp prefix, then statically link libmp3lame.a.
# Override detection with LAME_PREFIX=<dir> (its <dir>/include/lame/lame.h and
# <dir>/lib/libmp3lame.{a,dylib,so} are used) or force source build with
# LAME_FORCE_SOURCE=1. The core MP3 patents expired in 2017, so distributing an
# MP3 encoder is unencumbered.
#
# Cross-platform: builds on macOS (arm64/x86_64) and Linux (x86_64/arm64) here.
# Windows is NOT handled in this script — mirroring build_aec.sh, it defers the
# Windows build to scripts/release/windows_natives.sh, whose lame branch compiles
# this same shim with cl.exe against a STATIC libmp3lame (vcpkg's `mp3lame` port,
# or LAME_PREFIX) and /EXPORTs the five cc_lame_* symbols into lame_ffi.dll. Any
# non-Darwin/Linux OS here is a hard error — every native is required, so there
# is nothing for build_natives.sh to be best-effort about.
#
# Source/ref (override to iterate or bump):
#   LAME_VERSION default 3.100
#   LAME_URL     default the SourceForge 3.100 tarball
#   LAME_SHA256  default the published 3.100 checksum (override if it drifts)
#
# Requirements: a C++ compiler (c++). Source build additionally needs curl, tar
# and make.
#
# Usage:
#   scripts/natives/build_lame.sh [DEST_DIR]
#   LAME_FORCE_SOURCE=1 scripts/natives/build_lame.sh ./build/natives
set -euo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$REPO_ROOT/scripts/natives/lib/natives_common.sh"

# LAME_VERSION + LAME_SHA256 come from scripts/lib/native_pins.env.
load_native_pins
LAME_URL="${LAME_URL:-https://downloads.sourceforge.net/project/lame/lame/${LAME_VERSION}/lame-${LAME_VERSION}.tar.gz}"
DEST="${1:-}"
SHIM="$REPO_ROOT/packages/cc_natives/native/lame_ffi.cc"

# native_detect_platform aborts on anything but Darwin/Linux; on Windows the
# release pipeline builds natives via scripts/release/windows_natives.sh instead.
case "$(uname -s)" in
  Darwin | Linux) ;;
  *)
    die "build_lame.sh does not support $(uname -s). Windows natives are built by scripts/release/windows_natives.sh (MSVC + vcpkg mp3lame)." ;;
esac
native_detect_platform
CXX="${CXX:-c++}"
require_cmd "$CXX" "Install a C++ toolchain (Xcode CLT on macOS, build-essential on Linux) and re-run."
[ -f "$SHIM" ] || die "shim source not found: $SHIM"

LIB="liblame_ffi.$NATIVE_EXT"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# Resolves libmp3lame: sets LAME_INC (dir containing lame/lame.h), and exactly
# one of LAME_STATIC (path to libmp3lame.a, preferred — self-contained) or
# LAME_SHARED_DIR (dir holding libmp3lame.{dylib,so}, linked with -lmp3lame).
LAME_INC=""
LAME_STATIC=""
LAME_SHARED_DIR=""

probe_prefix() { # dir  -> 0 and sets LAME_* when it holds lame headers + a lib
  local prefix="$1"
  [ -n "$prefix" ] && [ -f "$prefix/include/lame/lame.h" ] || return 1
  LAME_INC="$prefix/include"
  if [ -f "$prefix/lib/libmp3lame.a" ]; then
    LAME_STATIC="$prefix/lib/libmp3lame.a"
    return 0
  fi
  local shared="lib/libmp3lame.$NATIVE_EXT"
  if [ -f "$prefix/$shared" ] || ls "$prefix"/lib/libmp3lame.* >/dev/null 2>&1; then
    LAME_SHARED_DIR="$prefix/lib"
    return 0
  fi
  return 1
}

find_system_lame() {
  local candidates=()
  [ -n "${LAME_PREFIX:-}" ] && candidates+=("$LAME_PREFIX")
  if command -v brew >/dev/null 2>&1; then
    local bp
    bp="$(brew --prefix lame 2>/dev/null || true)"
    [ -n "$bp" ] && candidates+=("$bp")
  fi
  candidates+=(/opt/homebrew/opt/lame /usr/local/opt/lame /opt/homebrew /usr/local /usr)
  local c
  for c in "${candidates[@]}"; do
    probe_prefix "$c" && return 0
  done
  return 1
}

build_lame_from_source() {
  require_cmd curl "Install curl (or set LAME_PREFIX to a prebuilt libmp3lame)."
  require_cmd tar "Install tar."
  require_cmd make "Install make (build-essential / Xcode CLT)."
  local tarball="$WORK/lame.tar.gz"
  log "Downloading LAME $LAME_VERSION ($LAME_URL)"
  curl -fSL "$LAME_URL" -o "$tarball"
  # sha256_of, not a hand-rolled `shasum … | awk`: the shared helper covers both
  # coreutils and macOS AND avoids GNU's filename escaping, which silently
  # prefixed the digest with `\` for any path containing a backslash (see
  # scripts/lib/common.sh). A checksum is also fail-closed here — the previous
  # "no shasum, skip the check" branch turned a supply-chain guard off on
  # exactly the machines least likely to be trusted.
  local got
  got="$(sha256_of "$tarball")"
  [ "$got" = "$LAME_SHA256" ] || die "LAME tarball sha256 mismatch: got $got, expected $LAME_SHA256 (set LAME_SHA256 to override if you bumped LAME_VERSION)."
  tar -xzf "$tarball" -C "$WORK"
  local src="$WORK/lame-$LAME_VERSION"
  [ -d "$src" ] || die "unexpected tarball layout: $src not found"
  local inst="$WORK/lame-install"
  log "Configuring + building LAME (static, no frontend) into $inst"
  # --with-pic / -fPIC is REQUIRED, not hygiene: this static archive is linked
  # into the SHARED liblame_ffi.so, and on x86-64 ld refuses non-PIC objects in
  # a shared object —
  #   relocation R_X86_64_PC32 against symbol `sfBandIndex' can not be used
  #   when making a shared object; recompile with -fPIC
  #   final link failed: bad value
  # macOS never sees it because PIC is the default there, which is why this only
  # broke the Linux build.
  ( cd "$src" && CFLAGS="${CFLAGS:-} -fPIC" ./configure \
      --prefix="$inst" \
      --disable-shared --enable-static --with-pic \
      --disable-frontend --disable-decoder \
      >/dev/null )
  ( cd "$src" && make -j"$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 2)" >/dev/null && make install >/dev/null )
  probe_prefix "$inst" || die "LAME source build produced no usable libmp3lame under $inst"
  [ -n "$LAME_STATIC" ] || die "LAME source build produced no static libmp3lame.a under $inst"
}

if [ "${LAME_FORCE_SOURCE:-0}" = "1" ]; then
  log "LAME_FORCE_SOURCE=1 — building libmp3lame from source"
  build_lame_from_source
elif find_system_lame; then
  if [ -n "$LAME_STATIC" ]; then
    log "Using system libmp3lame (static): $LAME_STATIC (headers: $LAME_INC)"
  else
    log "Using system libmp3lame (shared): $LAME_SHARED_DIR (headers: $LAME_INC)"
  fi
else
  log "No system libmp3lame found — building from source"
  build_lame_from_source
fi

log "Compiling shim ($SHIM) for $NATIVE_OS"
"$CXX" -std=c++17 -O2 -fPIC \
  -I "$LAME_INC" \
  -c "$SHIM" -o "$WORK/lame_ffi.o"

# Link the shim into a self-contained dylib: prefer the static archive; fall
# back to the system shared libmp3lame (then the dylib is NOT self-contained,
# warned below). -lm supplies libmp3lame's math deps on Linux.
LINK_LIBS=()
if [ -n "$LAME_STATIC" ]; then
  LINK_LIBS+=("$LAME_STATIC")
else
  LINK_LIBS+=(-L"$LAME_SHARED_DIR" -lmp3lame)
fi

if [ "$NATIVE_OS" = "Darwin" ]; then
  log "Linking $LIB"
  "$CXX" -dynamiclib -o "$WORK/$LIB" "$WORK/lame_ffi.o" \
    "${LINK_LIBS[@]}" \
    -install_name "@rpath/$LIB"
else
  log "Linking $LIB"
  "$CXX" -shared -o "$WORK/$LIB" "$WORK/lame_ffi.o" \
    "${LINK_LIBS[@]}" \
    -Wl,-soname,"$LIB" \
    -lm
fi

# Sanity: confirm our C symbol is exported and (when we linked statically) that
# there is no runtime dependency on a system libmp3lame — it must be self-contained.
if [ "$NATIVE_OS" = "Darwin" ]; then
  if ! nm -gU "$WORK/$LIB" | grep -q "_cc_lame_create"; then
    die "built $LIB is missing the cc_lame_create symbol"
  fi
  if [ -n "$LAME_STATIC" ] && otool -L "$WORK/$LIB" | grep -qi "libmp3lame"; then
    warn "WARNING: $LIB links a non-bundled libmp3lame despite static build — not self-contained:"
    otool -L "$WORK/$LIB" | grep -i mp3lame >&2 || true
  fi
else
  if ! nm -D "$WORK/$LIB" | grep -q " cc_lame_create"; then
    die "built $LIB is missing the cc_lame_create symbol"
  fi
  if [ -n "$LAME_STATIC" ] && ldd "$WORK/$LIB" 2>/dev/null | grep -qi "libmp3lame"; then
    warn "WARNING: $LIB links a system libmp3lame despite static build — not self-contained:"
    ldd "$WORK/$LIB" | grep -i mp3lame >&2 || true
  fi
fi

# Install to: the app-support root (the single dev / runtime location) and the
# optional explicit DEST (CI staging — release packaging copies it into the
# bundle). Mirrors build_aec.sh.
dests=("$(native_support_root)")
[ -n "$DEST" ] && dests+=("$DEST")

for d in "${dests[@]}"; do
  mkdir -p "$d"
  cp -f "$WORK/$LIB" "$d/$LIB"
  native_adhoc_sign "$d/$LIB"
  echo "  - $d/$LIB"
done

log "Done. Installed $LIB ($(du -h "$WORK/$LIB" | cut -f1)) to ${#dests[@]} location(s)."
