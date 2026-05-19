#!/usr/bin/env bash
#
# Shared helpers for the native-FFI build scripts:
#   scripts/natives/build_rift.sh         librift_ffi   (CoW worktree engine)
#   scripts/natives/build_fff.sh          libfff_c      (fast file finder)
#   scripts/natives/build_tree_sitter.sh  libtree-sitter + grammars (code indexer)
#
# Source it; don't execute it:
#   REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
#   source "$REPO_ROOT/scripts/natives/lib/natives_common.sh"
#
# SOURCING THIS ASSERTS A MACOS-OR-LINUX HOST. That is the boundary between this
# file and scripts/lib/common.sh, which it pulls in: native_detect_platform dies
# on Windows, because the Windows natives are built by a different toolchain
# entirely (scripts/release/windows_natives.sh, MSVC). Anything that must also
# run under Git Bash belongs in common.sh, not here.
#
# It standardises the things the build scripts each used to do slightly
# differently: a shallow clone of a pinned commit, resolving the install dir
# next to control_center.db (robust against bundle-id drift), and ad-hoc
# codesigning a dylib on macOS for the local Hardened Runtime.
#
# Defining functions only — no side effects at source time. Callers run
# native_detect_platform before native_support_root / the $NATIVE_* globals.

# log / warn / die / require_cmd / sha256_* / assert_exports / … all live in the
# host-agnostic library. Sourced here so every build script gets them from one
# place; `die` grows a ::error:: annotation under GitHub Actions for free.
# shellcheck source=../../lib/common.sh
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../../lib" && pwd)/common.sh"

# Shallow-clone a single pinned commit (GitHub allows fetch-by-SHA); falls back
# to a full fetch + checkout if the server rejects a shallow SHA fetch. Both
# fetches are retried with a pause between rounds: the pinned sources span
# hosts, and gitlab.freedesktop.org (webrtc-audio-processing) in particular
# answers a fraction of clones with
#   remote: GitLab is not responding
#   fatal: … The requested URL returned error: 502
# which used to abort a 20-minute release run on the spot. Three rounds ride
# out a transient 502; a real outage still dies loudly, and a bad pin still
# fails at the checkout, not after the retry budget.
git_clone_pinned() { # repo ref dest
  git init -q "$3"
  git -C "$3" remote add origin "$1" 2>/dev/null \
    || git -C "$3" remote set-url origin "$1"
  local attempt
  for attempt in 1 2 3; do
    if git -C "$3" fetch -q --depth 1 origin "$2" 2>/dev/null; then
      git -C "$3" -c advice.detachedHead=false checkout -q FETCH_HEAD
      return 0
    fi
    if git -C "$3" fetch -q origin; then
      git -C "$3" -c advice.detachedHead=false checkout -q "$2"
      return 0
    fi
    if [ "$attempt" -lt 3 ]; then
      log "fetch of $1 failed (attempt $attempt/3), retrying in $((attempt * 20))s"
      sleep $((attempt * 20))
    fi
  done
  die "could not fetch $1 @ $2 after 3 attempts"
}

# Sets the platform globals consumed by the build scripts:
#   NATIVE_OS      Darwin|Linux            (raw `uname -s`)
#   NATIVE_EXT     dylib|so                (shared-library extension, no dot)
#   NATIVE_SONAME  the COMPLETE linker flag prefix for an embedded soname,
#                  ready to be concatenated with the library file name:
#                  `-Wl,-install_name,` on macOS, `-Wl,-soname,` on Linux.
#                  Both are ONE token routed through the compiler driver. The
#                  bare `-install_name <name>` two-token form clang accepts has
#                  no gcc equivalent — `cc ... -soname libfoo.so` fails with
#                  `unrecognized command-line option '-soname'`, which is how it
#                  broke every Linux native build.
# and the internals used by native_support_root. Aborts on Windows — the
# Windows release builds natives via scripts/release/windows_natives.sh instead.
native_detect_platform() {
  NATIVE_OS="$(uname -s)"
  case "$NATIVE_OS" in
    Darwin)
      NATIVE_EXT="dylib"; NATIVE_SONAME="-Wl,-install_name,"
      _support_base="$HOME/Library/Application Support"
      # Must match PRODUCT_BUNDLE_IDENTIFIER in macos/Runner/Configs/AppInfo.xcconfig.
      _support_fallback="$_support_base/com.alev.control-center" ;;
    Linux)
      NATIVE_EXT="so"; NATIVE_SONAME="-Wl,-soname,"
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
  local dbs count
  dbs="$(find "$_support_base" -maxdepth 3 -name control_center.db 2>/dev/null || true)"
  count="$(printf '%s' "$dbs" | grep -c . || true)"
  case "${count:-0}" in
    0) printf '%s\n' "$_support_fallback" ;;
    1) dirname "$dbs" ;;
    # Several app-support dirs (a dev bundle id beside the release one) used to
    # be resolved with `| head -1`, so which install got the freshly built dylib
    # depended on directory order. Refuse instead of guessing: silently
    # refreshing the wrong install is indistinguishable from the build not
    # working.
    *) die "found $count control_center.db files under $_support_base:
$(printf '%s' "$dbs" | sed 's/^/  /')
Pass an explicit DEST_DIR, or remove the stale app-support directory." ;;
  esac
}

# Ad-hoc codesigns a freshly-installed dylib so it loads under the local
# Hardened Runtime. No-op off macOS. A release re-signs with the app's identity
# when embedding into Runner.app/Contents/Frameworks/ (see macos_package.sh).
native_adhoc_sign() { # path
  [ "$NATIVE_OS" = "Darwin" ] || return 0
  codesign -s - -f "$1" >/dev/null 2>&1 || true
}
