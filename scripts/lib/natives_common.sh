#!/usr/bin/env bash
#
# Shared helpers for the native-FFI build scripts:
#   scripts/build_rift.sh         librift_ffi   (CoW worktree engine)
#   scripts/build_fff.sh          libfff_c      (fast file finder)
#   scripts/build_tree_sitter.sh  libtree-sitter + grammars (code indexer)
#
# Source it; don't execute it:
#   REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
#   source "$REPO_ROOT/scripts/lib/natives_common.sh"
#
# It standardises the things those scripts each used to do slightly differently:
# a greppable `==>` progress line, a shallow clone of a pinned commit, resolving
# the install dir next to control_center.db (robust against bundle-id drift),
# and ad-hoc codesigning a dylib on macOS for the local Hardened Runtime.
#
# Defining functions only — no side effects at source time. Callers run
# native_detect_platform before native_support_root / the $NATIVE_* globals.

# Progress / diagnostics. `log` mirrors build_natives.sh's `==>` prefix.
log()  { printf '==> %s\n' "$*"; }
warn() { printf '!! %s\n' "$*" >&2; }
die()  { printf 'Error: %s\n' "$*" >&2; exit 1; }

# Abort early with an install hint when a required tool is missing.
require_cmd() { # cmd hint
  command -v "$1" >/dev/null 2>&1 || die "$1 not found. $2"
}

# Shallow-clone a single pinned commit (GitHub allows fetch-by-SHA); falls back
# to a full fetch + checkout if the server rejects a shallow SHA fetch.
git_clone_pinned() { # repo ref dest
  git init -q "$3"
  git -C "$3" remote add origin "$1"
  if git -C "$3" fetch -q --depth 1 origin "$2" 2>/dev/null; then
    git -C "$3" -c advice.detachedHead=false checkout -q FETCH_HEAD
  else
    git -C "$3" fetch -q origin
    git -C "$3" -c advice.detachedHead=false checkout -q "$2"
  fi
}

# Sets the platform globals consumed by the build scripts:
#   NATIVE_OS      Darwin|Linux            (raw `uname -s`)
#   NATIVE_EXT     dylib|so                (shared-library extension, no dot)
#   NATIVE_SONAME  -install_name|-soname   (linker flag for an embedded soname)
# and the internals used by native_support_root. Aborts on Windows — the
# Windows release builds natives via scripts/release/windows_natives.sh instead.
native_detect_platform() {
  NATIVE_OS="$(uname -s)"
  case "$NATIVE_OS" in
    Darwin)
      NATIVE_EXT="dylib"; NATIVE_SONAME="-install_name"
      _support_base="$HOME/Library/Application Support"
      # Must match PRODUCT_BUNDLE_IDENTIFIER in macos/Runner/Configs/AppInfo.xcconfig.
      _support_fallback="$_support_base/com.alev.control-center" ;;
    Linux)
      NATIVE_EXT="so"; NATIVE_SONAME="-soname"
      _support_base="${XDG_DATA_HOME:-$HOME/.local/share}"
      _support_fallback="$_support_base/control_center" ;;
    *)
      die "unsupported platform: $NATIVE_OS (build natives manually on Windows; see scripts/release/windows_natives.sh)" ;;
  esac
}

# Echoes the Control Center app-support root — the directory holding
# control_center.db (with grammars/ beside it). Auto-detects the real directory
# so it survives bundle-id differences across builds, and falls back to the
# canonical bundle-id path when no DB exists yet. Needs native_detect_platform.
native_support_root() {
  local db
  db="$(find "$_support_base" -maxdepth 3 -name control_center.db 2>/dev/null | head -1)"
  if [ -n "$db" ]; then
    dirname "$db"
  else
    printf '%s\n' "$_support_fallback"
  fi
}

# Ad-hoc codesigns a freshly-installed dylib so it loads under the local
# Hardened Runtime. No-op off macOS. A release re-signs with the app's identity
# when embedding into Runner.app/Contents/Frameworks/ (see macos_package.sh).
native_adhoc_sign() { # path
  [ "$NATIVE_OS" = "Darwin" ] || return 0
  codesign -s - -f "$1" >/dev/null 2>&1 || true
}
