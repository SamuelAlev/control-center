#!/usr/bin/env bash
#
# Host-agnostic helpers shared by everything under scripts/ — the native build
# scripts, the release packagers, and the local dev/dry-run entry points.
#
# Source it; don't execute it:
#   REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
#   source "$REPO_ROOT/scripts/lib/common.sh"
#
# SAFE TO SOURCE ON ANY HOST, including Git Bash on Windows. That is the whole
# reason this is a separate file from scripts/natives/lib/natives_common.sh:
# that one's native_detect_platform *dies* on Windows, so a script that only
# wants `log`/`die`/`sha256_of` must not be forced to pull it in. Anything added
# here that cannot run under Git Bash belongs in natives_common.sh instead.
#
# Defining functions only — no side effects at source time.

# ---------------------------------------------------------------------------
# Diagnostics
# ---------------------------------------------------------------------------

# `log` mirrors build_natives.sh's greppable `==>` prefix.
log()  { printf '==> %s\n' "$*"; }

# Warnings and errors carry a GitHub Actions annotation when running in CI and
# stay plain locally. Every script used to pick one or the other by hand, so
# half of them emitted `::error::` noise into a developer's terminal and the
# other half produced un-annotated CI failures.
warn() {
  if [ -n "${GITHUB_ACTIONS:-}" ]; then printf '::warning::%s\n' "$*" >&2
  else printf '!! %s\n' "$*" >&2; fi
}
die() {
  if [ -n "${GITHUB_ACTIONS:-}" ]; then printf '::error::%s\n' "$*" >&2
  else printf 'Error: %s\n' "$*" >&2; fi
  exit 1
}

# Abort early with an install hint when a required tool is missing.
require_cmd() { # cmd hint
  command -v "$1" >/dev/null 2>&1 || die "$1 not found. $2"
}

# ---------------------------------------------------------------------------
# Temp directories
# ---------------------------------------------------------------------------

# Sets $SCRATCH_DIR to a fresh directory that is ALWAYS removed on exit.
#
# CALL IT, DO NOT CAPTURE IT:
#     scratch_dir; secrets="$SCRATCH_DIR"     # correct
#     secrets="$(scratch_dir)"                # BROKEN — see below
#
# The capturing form is what shipped, and it self-destructs: command
# substitution runs in a SUBSHELL, so the `trap … EXIT` registered inside it
# fires the moment that subshell exits — deleting the directory before the
# caller ever writes to it. The failure surfaced one line later as
#   macos_package.sh: line 98: /var/folders/…/tmp.XXXX/cert.p12: No such file
# Returning through a global keeps the mktemp, the bookkeeping and the trap in
# the caller's own shell, where they survive.
#
# Use this for anything sensitive — decoded .p12 certificates, provisioning
# profiles, private keys. The packagers used to mint these under
# `RUNNER_TEMP="${RUNNER_TEMP:-$(mktemp -d)}"` with no trap, which is fine on a
# throwaway CI runner and leaks Developer ID material into /tmp on a developer's
# machine. Bulk staging (AppDirs, notarization zips) can still use RUNNER_TEMP;
# secrets go here.
_CC_SCRATCH_DIRS=()
_cc_scratch_cleanup() {
  local d
  for d in "${_CC_SCRATCH_DIRS[@]:-}"; do
    [ -n "$d" ] && rm -rf "$d"
  done
}
scratch_dir() {
  if [ "${#_CC_SCRATCH_DIRS[@]}" -eq 0 ]; then
    trap _cc_scratch_cleanup EXIT
  fi
  SCRATCH_DIR="$(mktemp -d)"
  _CC_SCRATCH_DIRS+=("$SCRATCH_DIR")
}

# ---------------------------------------------------------------------------
# Checksums + pinned downloads
# ---------------------------------------------------------------------------

# Echoes the lowercase hex SHA-256 of a file. GNU coreutils ships `sha256sum`,
# macOS ships `shasum`; scripts used to pick one, the other, or hand-roll the
# both-branches form.
#
# The file is fed on STDIN rather than named as an argument, and that is not a
# style choice. GNU coreutils ESCAPES a filename containing a backslash or a
# newline: it prefixes the whole output line with `\` and doubles the
# backslashes. Every path Git Bash gets on the Windows runner comes from
# `RUNNER_TEMP=D:\a\_temp`, so `sha256sum "$1" | awk '{print $1}'` returned
# `\<digest>` there and the release died on its own pin:
#   ERROR: sherpa-onnx archive sha256 mismatch: got \b7080b6f470bac96…
# — the correct digest, wearing an escape marker. On stdin the filename never
# reaches the output (`<digest>  -`), on both implementations.
sha256_of() { # file
  if command -v sha256sum >/dev/null 2>&1; then sha256sum <"$1" | awk '{print $1}'
  else shasum -a 256 <"$1" | awk '{print $1}'; fi
}

# Writes `<file>.sha256` in the standard two-column `sha256sum -c` format, and
# echoes the line. A local convenience only — the shipped, authoritative list is
# SHA256SUMS.txt from make_release.sh; these sidecars are not release assets.
sha256_sidecar() { # file
  local line
  line="$(sha256_of "$1")  $(basename "$1")"
  printf '%s\n' "$line" | tee "$1.sha256"
}

sha256_verify() { # file expected-sha256
  local actual
  actual="$(sha256_of "$1")"
  [ "$actual" = "$2" ] || die "checksum mismatch for $1
  expected $2
  actual   $actual"
}

# Downloads a URL and verifies it against a pinned SHA-256 before returning.
# Every third-party source in this pipeline is pinned; this is the one helper
# that makes an unpinned download the awkward path rather than the easy one.
fetch_pinned() { # url sha256 dest
  require_cmd curl "Install curl."
  log "fetching $(basename "$3")"
  curl -fsSL "$1" -o "$3"
  sha256_verify "$3" "$2"
}

# ---------------------------------------------------------------------------
# Pinned sources
# ---------------------------------------------------------------------------

# Loads scripts/lib/native_pins.env, WITHOUT clobbering anything already set in
# the environment.
#
# That ordering is the point: the file supplies the defaults (so no build script
# carries its own copy of a SHA, and Renovate has exactly one regex target),
# while `FFF_REF=<other> bash build_fff.sh` still works for a one-off test.
load_native_pins() {
  local pins="${REPO_ROOT:-.}/scripts/lib/native_pins.env" key value
  [ -f "$pins" ] || die "native pin file not found at $pins"
  while IFS='=' read -r key value; do
    # Trim the key before anything looks at it. On the Windows release runner
    # the checkout is CRLF, and Git Bash only ignores the trailing CR when it
    # PARSES a script — `read` hands it straight through as data. That made
    # `key` the single character CR on every blank line here, and `${!key}`
    # below aborted the whole Windows build with a bare
    # ": invalid variable name". .gitattributes now pins this file to LF as
    # well; this stays because the file is data read by bash, so it must not
    # depend on how the tree was checked out.
    key="${key#"${key%%[![:space:]]*}"}"
    key="${key%"${key##*[![:space:]]}"}"
    case "$key" in
      ''|\#*) continue ;;
      # Never feed anything else to the indirect expansion: bash's own message
      # names neither the file nor the line that produced it.
      *[!A-Za-z0-9_]*|[0-9]*)
        die "native_pins.env: '$key' is not a valid variable name" ;;
    esac
    # Strip the trailing ` # vX.Y.Z`. It lives on the assignment line because
    # Renovate matches the digest and the version on ONE line — see the format
    # note in native_pins.env.
    value="${value%%#*}"
    # Trim surrounding whitespace without spawning anything.
    value="${value#"${value%%[![:space:]]*}"}"
    value="${value%"${value##*[![:space:]]}"}"
    # Only set it when the caller has not.
    if [ -z "${!key:-}" ]; then
      export "$key=$value"
    fi
  done < "$pins"
}

# ---------------------------------------------------------------------------
# Toolchain resolution
# ---------------------------------------------------------------------------

# Echoes the dart/flutter binary this repo pins with fvm, falling back to PATH.
# Four scripts each carried their own copy of this ladder and one of them
# aborted with no message at all when neither existed.
_cc_resolve_sdk_bin() { # dart|flutter
  local pinned="${REPO_ROOT:-.}/.fvm/flutter_sdk/bin/$1"
  if [ -x "$pinned" ]; then printf '%s\n' "$pinned"; return 0; fi
  if command -v "fvm" >/dev/null 2>&1; then printf 'fvm %s\n' "$1"; return 0; fi
  command -v "$1" >/dev/null 2>&1 \
    || die "no $1 found: neither $pinned, nor fvm, nor $1 on PATH. Install fvm (https://fvm.app) and run 'fvm install'."
  command -v "$1"
}
resolve_dart()    { _cc_resolve_sdk_bin dart; }
resolve_flutter() { _cc_resolve_sdk_bin flutter; }

# Echoes macos|linux|windows for the host.
#
# Deliberately never dies — that is exactly what separates it from
# native_detect_platform, which asserts a buildable-natives host. Packaging and
# staging code runs on all three.
cc_platform() {
  case "$(uname -s)" in
    Darwin) printf 'macos\n' ;;
    Linux)  printf 'linux\n' ;;
    MINGW*|MSYS*|CYGWIN*|Windows_NT) printf 'windows\n' ;;
    *) die "unsupported platform: $(uname -s)" ;;
  esac
}

# Echoes the `dart build cli` output-directory tag for an OS.
cc_cli_dir() { # macos|linux|windows
  case "$1" in
    macos)   printf 'macos_arm64\n' ;;
    linux)   printf 'linux_x64\n' ;;
    windows) printf 'windows_x64\n' ;;
    *) die "cc_cli_dir: unknown OS '$1' (expected macos|linux|windows)" ;;
  esac
}

# Echoes the shared-library extension for an OS.
cc_lib_ext() { # macos|linux|windows
  case "$1" in
    macos)   printf 'dylib\n' ;;
    linux)   printf 'so\n' ;;
    windows) printf 'dll\n' ;;
    *) die "cc_lib_ext: unknown OS '$1' (expected macos|linux|windows)" ;;
  esac
}

# ---------------------------------------------------------------------------
# cc_server bundle + native staging
# ---------------------------------------------------------------------------

# Echoes the path to the `dart build cli` bundle for an OS, building it first
# when it is absent.
#
# Whatever `builtin_credentials.sh inject` wrote is compiled into that bundle,
# so injection must precede the first call — an existing bundle is reused as-is.
ensure_cc_server_bundle() { # macos|linux|windows
  local bundle exe dart
  bundle="apps/cc_server/build/cli/$(cc_cli_dir "$1")/bundle"
  exe="$bundle/bin/cc_server"
  [ "$1" = "windows" ] && exe="$bundle/bin/cc_server.exe"
  if [ ! -x "$exe" ] && [ ! -f "$exe" ]; then
    # >&2 — this function RETURNS the bundle path on stdout, so anything else
    # written there is captured by the caller's `$(...)` and prepended to the
    # path. It shipped exactly that way: `cp: ==> building cc_server cli bundle
    # (macos) .../bundle/.: No such file or directory`. Every incidental line in
    # here goes to stderr for the same reason.
    log "building cc_server cli bundle ($1)" >&2
    dart="$(resolve_dart)"
    # shellcheck disable=SC2086  # `fvm dart` must word-split into two argv entries.
    ( cd apps/cc_server && $dart build cli ) >&2
  fi
  printf '%s\n' "$bundle"
}

# Copies the staged native libraries + the tree-sitter `.scm` queries from a
# staging dir into a destination, and asserts something actually landed.
#
# This was six near-identical loops across the three packagers and two inline
# workflow steps; the `.scm` half was silently missing from run_desktop.sh.
# GrammarManager resolves a language's query from the same directory as its
# library, so the two always travel together.
#
# Pass `no-queries` as the 4th argument for a destination that must hold code
# and nothing else — the ONE such destination is a macOS .app's
# Contents/Frameworks/, which codesign's default rules treat as a nested-code
# location: any non-Mach-O file there fails the bundle signature with
# "code object is not signed at all ... In subcomponent: .../dart.scm".
# GrammarManager falls back to `embeddedTreeSitterQueries` (generated from these
# same files and pinned to them by test/tooling/embedded_queries_test.dart), so
# the queries are compiled in rather than lost.
stage_natives() { # src dest ext [no-queries]
  local src="$1" dest="$2" ext="$3" queries="${4:-queries}" f copied=0
  case "$queries" in
    queries|no-queries) ;;
    *) die "stage_natives: 4th argument must be 'queries' or 'no-queries', got '$queries'" ;;
  esac
  [ -d "$src" ] || die "stage_natives: native staging dir '$src' does not exist. Run scripts/natives/build_natives.sh first."
  mkdir -p "$dest"
  local had_nullglob=1
  shopt -q nullglob || had_nullglob=0
  shopt -s nullglob
  for f in "$src"/*."$ext"; do
    printf '  staging %s\n' "$(basename "$f")"
    cp -f "$f" "$dest/"
    copied=$((copied + 1))
  done
  if [ "$queries" = queries ]; then
    for f in "$src"/*.scm; do
      printf '  staging %s\n' "$(basename "$f")"
      cp -f "$f" "$dest/"
    done
  fi
  [ "$had_nullglob" -eq 1 ] || shopt -u nullglob
  [ "$copied" -gt 0 ] \
    || die "stage_natives: no *.$ext found in '$src'. Every native is required (there is no degraded mode) — run scripts/natives/build_natives.sh."
}

# Asserts a shared library exports every named symbol.
#
# The tool and its flags differ per platform (`nm -gU` on macOS lists only
# *defined external* symbols, `nm -D` reads the dynamic table on ELF, and
# Windows needs dumpbin), which five build scripts each rediscovered by hand.
assert_exports() { # lib sym...
  local lib="$1"; shift
  local sym table
  case "$(uname -s)" in
    Darwin) table="$(nm -gU "$lib" 2>/dev/null || true)" ;;
    Linux)  table="$(nm -D --defined-only "$lib" 2>/dev/null || true)" ;;
    *)      table="$(dumpbin //exports "$lib" 2>/dev/null || true)" ;;
  esac
  [ -n "$table" ] || die "assert_exports: could not read the symbol table of $lib"
  for sym in "$@"; do
    printf '%s\n' "$table" | grep -q "$sym" \
      || die "$(basename "$lib") does not export '$sym' — the build produced a library the loader cannot use."
  done
}

# ---------------------------------------------------------------------------
# pub resolution
# ---------------------------------------------------------------------------

# Echoes the resolved on-disk root of a pub package.
#
# Reads .dart_tool/package_config.json, which is authoritative for the current
# resolution. There is deliberately NO pub-cache fallback: the previous copies
# of this helper ended in `|| true` and then guessed with
# `find ... | sort -V | tail -1`, which silently staged an arbitrary version of
# sherpa/onnxruntime when the real resolution was unreadable.
pub_package_dir() { # package-name
  require_cmd python3 "Install python3 (it ships with macOS and every CI runner)."
  local dir
  dir="$(python3 - "$1" <<'PYEOF'
import json, os, sys, urllib.parse

pkg = sys.argv[1]
with open(".dart_tool/package_config.json") as f:
    cfg = json.load(f)
for entry in cfg["packages"]:
    if entry["name"] == pkg:
        root = entry["rootUri"]
        if root.startswith("file://"):
            root = urllib.parse.unquote(urllib.parse.urlparse(root).path)
        else:
            root = os.path.join(".dart_tool", root)
        print(os.path.normpath(os.path.abspath(root)))
        break
else:
    sys.exit(f"package '{pkg}' is not in .dart_tool/package_config.json")
PYEOF
  )" || die "could not resolve package '$1'. Run 'flutter pub get' first."
  [ -d "$dir" ] || die "resolved '$1' to '$dir', which does not exist."
  printf '%s\n' "$dir"
}

# ---------------------------------------------------------------------------
# Packaging
# ---------------------------------------------------------------------------

# Zips a directory's CONTENTS (not the directory itself) into an archive,
# using whichever of 7z / PowerShell / zip the host provides.
make_zip() { # srcdir out
  local src="$1" out="$2"
  rm -f "$out"
  if command -v 7z >/dev/null 2>&1; then
    ( cd "$src" && 7z a -tzip -bso0 -bsp0 "$out" ./* ) || die "7z failed to create $out"
  elif command -v powershell >/dev/null 2>&1; then
    powershell -NoProfile -Command \
      "Compress-Archive -Path '$src/*' -DestinationPath '$out' -Force" \
      || die "Compress-Archive failed to create $out"
  elif command -v zip >/dev/null 2>&1; then
    ( cd "$src" && zip -qr "$out" . ) || die "zip failed to create $out"
  else
    die "no zip tool found (tried 7z, powershell, zip)."
  fi
  [ -f "$out" ] || die "make_zip produced no archive at $out"
}

# Fails when any SINGLE asset exceeds the per-file deployment budget.
#
# Cloudflare rejects the whole deploy if any one asset is over 25 MiB, so the
# budget is per file, not per bundle. Failing here names the offending file
# while the bundle is still inspectable (`flutter build web --release --wasm
# --dump-info`) instead of at upload time, minutes in, with an opaque error.
#
# The three deploy workflows each carried a verbatim copy of this, two of them
# with a comment pointing at the third.
assert_asset_budget() { # dir mib
  local dir="$1" limit="$2" oversized
  [ -d "$dir" ] || die "assert_asset_budget: '$dir' does not exist"
  oversized="$(find "$dir" -type f -size +"${limit}"M)"
  if [ -n "$oversized" ]; then
    printf '%s\n' "$oversized" | xargs -I {} du -h {} >&2
    die "assets exceed the ${limit} MiB budget (Cloudflare's hard limit is 25 MiB)"
  fi
  log "asset budget ok (no file over ${limit} MiB in $dir)"
}
