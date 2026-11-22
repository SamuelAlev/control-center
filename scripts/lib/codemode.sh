#!/usr/bin/env bash
# Source with scripts/lib/common.sh. Code mode's runner, cc_codemode, is
# required for server roles: the server refuses to boot without it. It is an
# executable, not an FFI library, so it travels like the media helpers: built
# into <natives>/codemode/ and staged as bin/codemode/ beside the server
# executable. There is no fallback and no switch that makes it optional.
# shellcheck source=natives.sh
source "$(dirname "${BASH_SOURCE[0]}")/natives.sh"

CC_CODEMODE_REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"

# Fails when the runner names a build machine's paths. The release builds
# remap every source path to /build/… (C:\build\… on Windows); this check
# holds every staged or packaged runner to that, whatever built or cached it.
# It looks for:
#   * the prefixes this machine can name: $HOME, the checkout, $CARGO_HOME,
#     and any given as arguments (a build passes its target directory);
#   * generic markers, which catch a runner built on another machine:
#     /Users/ and /home/ (except the remapped /build/home/), C:\Users\ for
#     Windows, and a cargo registry path (registry/src/) anywhere but under
#     the remapped /build/cargo/. Cargo names workspace sources by relative
#     path, so an unremapped build's absolute paths are its dependencies'
#     sources in the cargo home (and QuickJS-NG's in the target directory);
#     every runner has registry paths, in its panic locations. Measured:
#     the remapped release builds (macOS arm64, Linux arm64 and x86_64)
#     contain none of the markers; an unremapped release build has 14
#     registry paths outside /build/cargo/, a macOS debug build /Users/ 389
#     times.
# On Windows the image is searched as bytes and as UTF-16 (MSVC's assert
# stores __FILE__ as a wide string), and in both path styles.
cc_codemode_check_paths() { # exe os [extra-prefix...]
  local exe="$1" os="$2" prefix view hits wide=""
  shift 2
  local prefixes=("$@" "$CC_CODEMODE_REPO_ROOT")
  [ -n "${HOME:-}" ] && prefixes+=("$HOME")
  [ -n "${CARGO_HOME:-}" ] && prefixes+=("$CARGO_HOME")
  local views=("$exe")
  if [ "$os" = windows ]; then
    if command -v cygpath >/dev/null 2>&1; then
      for prefix in "$CC_CODEMODE_REPO_ROOT" "${HOME:-}" "${CARGO_HOME:-}"; do
        [ -n "$prefix" ] && prefixes+=("$(cygpath -w "$prefix")")
      done
    fi
    wide="$(mktemp)"
    # Both byte offsets, so a wide string is found whatever its alignment.
    { iconv -c -f UTF-16LE -t UTF-8 "$exe"
      tail -c +2 "$exe" | iconv -c -f UTF-16LE -t UTF-8
    } >"$wide" 2>/dev/null || true
    views+=("$wide")
  fi
  for view in "${views[@]}"; do
    for prefix in "${prefixes[@]}"; do
      [ "${#prefix}" -gt 3 ] || continue
      if LC_ALL=C grep -a -i -q -F -- "$prefix" "$view"; then
        [ -z "$wide" ] || rm -f "$wide"
        die "code mode runner contains the build path $prefix: $exe (built without the path remapping of scripts/natives/build_codemode.sh or scripts/release/windows_natives.sh?)"
      fi
    done
    hits="$(LC_ALL=C grep -a -o -E '.{0,6}/(Users|home)/' "$view" | grep -v -E '/build/home/$' | head -3 || true)"
    if [ -z "$hits" ] && [ "$os" = windows ]; then
      hits="$(LC_ALL=C grep -a -o -i -F 'C:\Users\' "$view" | head -3 || true)"
    fi
    if [ -z "$hits" ]; then
      # Up to 13 characters before, exactly the length of /build/cargo/.
      hits="$(LC_ALL=C grep -a -o -E '.{0,13}registry[/\\]src[/\\]' "$view" \
        | grep -v -E 'build[/\\]cargo[/\\]registry[/\\]src[/\\]$' | head -3 || true)"
    fi
    if [ -n "$hits" ]; then
      [ -z "$wide" ] || rm -f "$wide"
      die "code mode runner contains a build machine's path ($(printf '%s' "$hits" | tr '\n' ' ' | tr -c '[:print:]' '?')): $exe (built without path remapping?)"
    fi
  done
  [ -z "$wide" ] || rm -f "$wide"
}

# Fails unless dir holds a runnable cc_codemode for the release architecture
# that confines itself on this host. It accepts the architectures the release
# scripts package: macOS arm64, Linux x64 or arm64, Windows x64 or arm64.
# Without an architecture, Linux means this host's and Windows means x64; the
# release passes it (cc_server_package.sh). Every invocation of the runner
# goes through a command substitution: the lockdown sets a zero file-size
# limit, so a runner whose stdout or stderr is a regular file is killed by
# SIGXFSZ.
cc_codemode_verify() { # codemode-dir os [architecture]
  local dir="$1" os="$2" arch="${3:-}" exe out got deps req version floor
  case "$os" in
    macos) exe="$dir/cc_codemode" ;;
    linux)
      exe="$dir/cc_codemode"
      if [ -z "$arch" ]; then
        case "$(uname -m)" in
          x86_64) arch=x64 ;;
          aarch64 | arm64) arch=arm64 ;;
          *) die "unsupported Linux code mode host: $(uname -m)" ;;
        esac
      fi
      case "$arch" in
        x64 | arm64) ;;
        *) die "unsupported Linux code mode architecture: $arch (expected x64 or arm64)" ;;
      esac ;;
    windows)
      exe="$dir/cc_codemode.exe"
      arch="$(cc_windows_arch "${arch:-x64}")" ;;
    *) die "unsupported code mode platform: $os" ;;
  esac
  # The engine version comes from the same pin file the licence notices and
  # native_pins_test.dart read, so yesterday's runner cannot pass after a bump.
  load_native_pins
  : "${CODEMODE_QUICKJS_NG_VERSION:?CODEMODE_QUICKJS_NG_VERSION is not pinned in scripts/lib/native_pins.env}"
  [ -d "$dir" ] \
    || die "required code mode runner directory missing: $dir (run scripts/natives/build_natives.sh; Windows: scripts/release/windows_natives.sh)"
  [ -s "$exe" ] || die "required code mode runner missing/empty: $exe"
  [ -x "$exe" ] || die "code mode runner not executable: $exe"
  case "$os" in
    windows)
      got="$(pe_machine "$exe")"
      [ "$got" = "$arch" ] || die "codemode/cc_codemode.exe is $got, expected Windows $arch" ;;
    macos)
      lipo -archs "$exe" | grep -qw arm64 || die "codemode/cc_codemode is not macOS arm64"
      deps="$(otool -L "$exe")"
      while IFS= read -r req; do
        case "$req" in
          /usr/lib/* | /System/Library/*) ;;
          *) die "codemode/cc_codemode requires unbundled $req" ;;
        esac
      done < <(printf '%s\n' "$deps" | sed -n '2,$s/^[[:space:]]*\([^[:space:]]*\).*/\1/p') ;;
    linux)
      require_cmd readelf "Install binutils for the code mode runner gate."
      local machine loader
      case "$arch" in
        x64) machine='Advanced Micro Devices X86-64' loader=ld-linux-x86-64.so.2 ;;
        arm64) machine='AArch64' loader=ld-linux-aarch64.so.1 ;;
      esac
      readelf -h "$exe" | grep -q "Machine:.*$machine" \
        || die "codemode/cc_codemode is not Linux $arch"
      deps="$(readelf -d "$exe")"
      # Only the C runtime may be external: the runner links QuickJS-NG and
      # every Rust dependency statically.
      while IFS= read -r req; do
        case "$req" in
          libc.so.6 | libm.so.6 | libpthread.so.0 | libdl.so.2 | librt.so.1 | libgcc_s.so.1 | "$loader") ;;
          *) die "codemode/cc_codemode requires unbundled $req" ;;
        esac
      done < <(printf '%s\n' "$deps" | grep 'NEEDED' | sed -n 's/.*\[\(.*\)\].*/\1/p')
      for req in $(readelf -V -W "$exe" | grep -oE 'GLIBC_[0-9]+(\.[0-9]+)*' | sort -u || true); do
        version="${req#GLIBC_}"
        floor="$CC_NATIVES_GLIBC_MAX"
        [ "$version" = "$floor" ] || [ "$(printf '%s\n%s\n' "$version" "$floor" | sort -V | tail -1)" = "$floor" ] \
          || die "codemode/cc_codemode needs $req beyond supported $CC_NATIVES_BASE_IMAGE ABI $floor"
      done ;;
  esac
  out="$("$exe" --version 2>&1)" || die "code mode runner cannot start: $exe
$out"
  case "$out" in
    "cc_codemode "*" quickjs-ng $CODEMODE_QUICKJS_NG_VERSION protocol "*) ;;
    *) die "code mode runner reports '$out', expected QuickJS-NG $CODEMODE_QUICKJS_NG_VERSION" ;;
  esac
  # The self-test applies the lockdown and attempts what it must deny; it exits
  # 0 only when the level is full and every attempt was refused.
  if ! out="$("$exe" --self-test 2>&1)"; then
    die "code mode runner lockdown self-test failed on this host: $exe
$out"
  fi
  case "$out" in
    *'"ok":true'*'"level":"full"'* | *'"level":"full"'*'"ok":true'*) ;;
    *) die "code mode runner self-test did not report a full lockdown: $exe
$out" ;;
  esac
  # A debug build passes the self-test too, but its CPU use against the
  # budget is unoptimised and its overflow checks end scripts with exit 4.
  case "$out" in
    *'"build":"release"'*) ;;
    *) die "code mode runner is not a release build (self-test build field): $exe" ;;
  esac
  cc_codemode_check_paths "$exe" "$os"
  log "Verified code mode runner ($os${arch:+ $arch}): $exe"
}

# Copies <natives>/codemode/cc_codemode[.exe] to destination, verifying the
# source before the copy and the relocated copy after it.
cc_codemode_stage() { # build/natives destination os [architecture]
  local source="$1/codemode" destination="$2" os="$3" arch="${4:-}" name=cc_codemode
  [ "$os" = windows ] && name=cc_codemode.exe
  cc_codemode_verify "$source" "$os" "$arch"
  rm -rf "$destination"
  mkdir -p "$destination"
  cp -f "$source/$name" "$destination/$name"
  chmod +x "$destination/$name"
  cc_codemode_verify "$destination" "$os" "$arch"
}
