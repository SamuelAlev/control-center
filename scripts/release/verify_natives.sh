#!/usr/bin/env bash
#
# Verifies that a packaged directory carries every native library the artifact
# REQUIRES and fails the build when one is missing.
#
# The matrix itself lives in scripts/lib/natives.sh — one row per library, read
# by this script and by cc_server_package.sh and pinned against the Dart
# runtime table by test/tooling/native_matrix_test.dart. This script owns the
# MATCHING rules (platform prefix/extension, dot-bounded base names); it does
# not own the list.
#
# Every native is required. There is no degraded mode: a bundle missing one
# either crashes the desktop's meeting recorder or refuses to boot its server,
# so catching it here beats shipping an artifact that dies on first launch.
#
# Roles:
#   desktop  the Flutter app's own native dir. Needs aec (the meeting recorder's
#            echo canceller runs CLIENT-side, in the Flutter isolate) plus the
#            code-graph natives the in-app indexer uses. Does NOT need the
#            server-only set — the desktop spawns cc_server, whose libs are
#            verified under the `server` role.
#   server   a cc_server bundle's library dir: everything the boot preflight
#            probes. A miss here means the binary refuses to start.
#
# Usage:
#   scripts/release/verify_natives.sh <dir> <macos|linux|windows> <desktop|server>
#   scripts/release/verify_natives.sh --dir A --dir B <os> <role>
#
# Repeatable --dir exists because a cc_server bundle splits its libraries across
# two directories depending on platform layout; a native satisfies the check
# when it is present in ANY of them.
set -euo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$REPO_ROOT/scripts/lib/common.sh"
source "$REPO_ROOT/scripts/lib/natives.sh"

DIRS=()
while [ "${1:-}" = "--dir" ]; do
  shift
  DIRS+=("${1:?--dir needs a path}")
  shift
done

if [ "${#DIRS[@]}" -eq 0 ]; then
  DIRS+=("${1:?usage: verify_natives.sh [--dir D]... <dir> <macos|linux|windows> <desktop|server>}")
  shift
fi
OS="${1:?missing os (macos|linux|windows)}"
ROLE="${2:?missing role (desktop|server)}"

case "$OS" in
  macos)   PREFIX=lib; EXT=dylib ;;
  linux)   PREFIX=lib; EXT=so ;;
  windows) PREFIX='';  EXT=dll ;;
  *) die "verify_natives.sh: unknown os '$OS'" ;;
esac
case "$ROLE" in
  desktop|server) ;;
  *) die "verify_natives.sh: unknown role '$ROLE'" ;;
esac

for d in "${DIRS[@]}"; do
  [ -d "$d" ] || die "verify_natives.sh: not a directory: $d"
done

log "Verifying $ROLE natives ($OS) in ${DIRS[*]}"
shopt -s nullglob
missing=0

# Returns 0 when a base name is present in any search dir.
#
# The base name must be followed by a DOT, so versioned sonames still match
# (libonnxruntime.1.21.0.dylib, libonnxruntime.so.1.22.0) while a longer sibling
# does not: base `tree-sitter` must not be satisfied by
# libtree-sitter-dart.dylib, or a bundle carrying only grammars would pass here
# and then boot-fail.
found_native() { # base
  local base="$1" dir f
  for dir in "${DIRS[@]}"; do
    for f in "$dir/$PREFIX$base".*; do
      case "${f##*/}" in
        "$PREFIX$base".*."$EXT"|"$PREFIX$base"."$EXT"|"$PREFIX$base"."$EXT".*)
          [ -e "$f" ] && { printf '%s\n' "$(basename "$f")"; return 0; } ;;
      esac
    done
  done
  return 1
}

while IFS='|' read -r base desc; do
  if hit="$(found_native "$base")"; then
    printf '  ok %s (%s)\n' "$desc" "$hit"
  else
    printf 'ERROR: required native missing: %s (%s%s.%s)\n' "$desc" "$PREFIX" "$base" "$EXT" >&2
    missing=1
  fi
done < <(cc_natives_for "$ROLE" "$OS")

# The runtime ABI floor (Linux). Presence is not loadability: a library built
# against a newer glibc/libstdc++ than the runtime provides fails `dlopen`, and
# the boot preflight — which probes BY LOADING — then reports it missing with
# the file sitting right there in the bundle. That shipped: natives compiled on
# the ubuntu-24.04 runner needed GLIBC_2.38/2.39 and the container ran Debian
# 12's 2.36, so the demo server refused to boot and its error blamed staging.
#
# Checked here because this is the last place the answer is one line of
# Dockerfile rather than a container that will not start. The floor and the
# base image that sets it live in scripts/lib/natives.sh, beside the matrix.
#
# Non-Linux hosts skip it: the ELF artifacts are always packaged on Linux, and
# `readelf` is not a thing a mac has. On Linux the tool is REQUIRED — silently
# not checking is how the mismatch shipped in the first place.
ver_gt() { # a b -> 0 when a > b
  [ "$1" != "$2" ] && [ "$(printf '%s\n%s\n' "$1" "$2" | sort -V | tail -1)" = "$1" ]
}

check_abi_floor() {
  local tool="" candidate dir f reqs req kind version floor offenders failed

  if [ "$(uname -s)" != Linux ]; then
    echo "  -- ABI floor not checked (needs readelf on a Linux host; CI packages Linux artifacts on Linux)"
    return 0
  fi
  for candidate in readelf objdump; do
    if command -v "$candidate" >/dev/null 2>&1; then tool="$candidate"; break; fi
  done
  [ -n "$tool" ] || die "verify_natives.sh: need readelf or objdump to check the ABI floor (apt-get install binutils)"

  echo "Verifying ABI floor: glibc <= $CC_NATIVES_GLIBC_MAX, libstdc++ <= GLIBCXX_$CC_NATIVES_GLIBCXX_MAX (${CC_NATIVES_BASE_IMAGE})"
  failed=0
  for dir in "${DIRS[@]}"; do
    for f in "$dir"/*.so "$dir"/*.so.*; do
      [ -e "$f" ] || continue
      case "$tool" in
        readelf)  reqs="$(readelf -V -W "$f" 2>/dev/null)" ;;
        objdump)  reqs="$(objdump -p "$f" 2>/dev/null)" ;;
      esac
      # `|| true`: a library with no versioned glibc reference at all (the AOT
      # snapshot, a grammar) makes grep exit 1, and under `pipefail` that would
      # end the script mid-sweep — silently passing every file after it.
      reqs="$(printf '%s' "$reqs" | grep -oE 'GLIBC(XX)?_[0-9]+(\.[0-9]+)*' | sort -u || true)"
      for req in $reqs; do
        case "$req" in
          GLIBCXX_*) kind=libstdc++; version="${req#GLIBCXX_}"; floor="$CC_NATIVES_GLIBCXX_MAX" ;;
          GLIBC_*)   kind=glibc;     version="${req#GLIBC_}";   floor="$CC_NATIVES_GLIBC_MAX" ;;
          *) continue ;;
        esac
        if ver_gt "$version" "$floor"; then
          # Name the symbols, not just the version: "needs GLIBC_2.39" sends the
          # reader to the base image, `pidfd_spawnp` sends them to what pulled
          # it in — which is the half that decides whether the fix is the
          # image, a build flag or a dependency.
          offenders="$(
            case "$tool" in
              readelf) readelf --dyn-syms -W "$f" 2>/dev/null | grep -F "@$req" | awk '{print $8}' ;;
              objdump) objdump -T "$f" 2>/dev/null | grep -F "$req" | awk '{print $NF}' ;;
            esac | sed 's/@.*//' | sort -u | tr '\n' ' ' || true
          )"
          printf 'ERROR: %s requires %s (%s floor is %s) — symbols: %s\n' \
            "$(basename "$f")" "$req" "$kind" "$floor" "${offenders:-unknown}" >&2
          failed=1
        fi
      done
    done
  done
  if [ "$failed" -ne 0 ]; then
    die "bundle needs a newer runtime ABI than ${CC_NATIVES_BASE_IMAGE} provides — these libraries would fail dlopen and the boot preflight would report them MISSING. Either raise the base image in docker/cc_server/Dockerfile (and CC_NATIVES_* in scripts/lib/natives.sh with it) or build the natives on an older toolchain."
  fi
  echo "  ok every library loads within the ${CC_NATIVES_BASE_IMAGE} ABI"
}


if [ "$OS" = windows ] && [ "$ROLE" = server ]; then
  echo "  -- rift skipped (Windows has no MSVC CoW backend; git worktree is the backend)"
fi

# The tree-sitter `.scm` queries. Deliberately NOT fatal here, unlike in the
# staging scripts that must produce them: `embeddedTreeSitterQueries` is
# compiled into every host and pinned by test/tooling/embedded_queries_test.dart,
# so extraction still works without them. The on-disk copies exist so prod runs
# the same artifacts a dev tree does. Two different questions, two answers —
# staging asserts it produced them, verification tolerates their absence.
scm=0
for d in "${DIRS[@]}"; do
  for f in "$d"/*.scm; do [ -e "$f" ] && scm=$((scm + 1)); done
done
if [ "$scm" -gt 0 ]; then
  echo "  ok tree-sitter .scm queries ($scm files)"
else
  echo "  -- no .scm queries on disk (falling back to the compiled-in copies)"
fi

[ "$missing" -eq 0 ] || die "$ROLE bundle is missing required natives — run scripts/natives/build_natives.sh (on Windows scripts/release/windows_natives.sh) and re-package"

# Presence, then loadability. Both must hold, and only the first one has ever
# been obvious from a directory listing.
if [ "$OS" = linux ]; then
  check_abi_floor
fi

log "All required $ROLE natives present"
