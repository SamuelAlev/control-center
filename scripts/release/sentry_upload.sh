#!/usr/bin/env bash
#
# Uploads a build's native debug files and (web) source maps to Sentry through
# the official sentry-cli.
#
# USAGE:
#   scripts/release/sentry_upload.sh --platform macos|linux|windows|web [options]
#
#   --platform P            macos | linux | windows | web (required)
#   --arch A                linux|windows build arch: x64 (default) | arm64
#   --build-dir DIR         build output root (default: build)
#   --web-dir DIR           web build output (default: <build-dir>/web)
#   --build-name V          value passed to `flutter build --build-name`
#   --build-number N        value passed to `flutter build --build-number`
#   --release R             override the derived release (env: SENTRY_RELEASE)
#   --dist D                override the derived dist (env: SENTRY_DIST)
#   --split-debug-info DIR  Dart --split-debug-info output, uploaded as debug files
#   --ignore-web-path GLOB  exclude web files from injection/upload (repeatable)
#   --set-commits           also run `releases set-commits --auto`
#   --ignore-missing-commits  pass --ignore-missing to set-commits
#   --wait                  pass --wait so the server processes before we exit
#   --allow-missing-credentials
#                           warn and skip when SENTRY_AUTH_TOKEN is unset
#
# CREDENTIALS
# SENTRY_AUTH_TOKEN is handed to sentry-cli through the environment only, never
# argv. SENTRY_ORG / SENTRY_PROJECT default to use-ctrl / control-center-app.
# SENTRY_URL is honored by sentry-cli for self-hosted or regional installs.
#
# RELEASE / DIST
# The release string is what the APP reports at runtime — uploading under any
# other name symbolicates nothing. Sentry's Flutter SDK derives it from native
# metadata (LoadReleaseIntegration -> PackageInfo), so this script reads the same
# source instead of the pubspec:
#
#   macos    Contents/Info.plist -> <CFBundleIdentifier>@<ShortVersion>+<Version>
#            (the bundle identifier, not the project name: package_info_plus
#             returns CFBundleIdentifier as packageName on darwin)
#   linux    data/flutter_assets/version.json -> <package_name>@<version>[+<build>]
#   web      build/web/version.json (same shape)
#   windows  the executable's VERSIONINFO: InternalName is compiled from
#            windows/runner/Runner.rc (cross-checked against the pubspec name) and
#            ProductVersion is FLUTTER_VERSION = <build-name>+<build-number>
#
# --release overrides the derivation outright, --dist only the distribution.
# When --build-name/--build-number are given, they are cross-checked against the
# artifact: a mismatch means the symbols would be filed under a release the app
# never reports, so it is a hard error.
#
# WHAT IS UPLOADED
#   debug files  `debug-files upload` over the platform's build roots (the same
#                roots sentry_dart_plugin enumerated), plus --split-debug-info
#                when the build used Dart --split-debug-info. Sources are NOT
#                uploaded (no --include-sources): the plugin config did not
#                enable that, and source bundles are a separate disclosure
#                decision.
#   web maps     only with --platform web: `sourcemaps inject` over each
#                JavaScript file (one invocation listing every file — pointing
#                inject at the directory has corrupted Flutter's source maps),
#                then `sourcemaps upload` with --ext js --ext map and the same
#                --strip-prefix values the plugin computed from the maps.
#                There are no exclusions by default (the plugin config set none).
#
# NOTE ON DART SYMBOLS
# No build here passes --obfuscate or --split-debug-info, and this repository has
# no Android/iOS target, so there is no Dart obfuscation map to upload: the
# plugin's dart-symbol-map path was unreachable for it (it only ran for
# Android/iOS debug files). A future obfuscated build needs
# `sentry-cli dart-symbol-map upload <map> <debug-file>` paired with the debug
# file carrying the same debug id. --split-debug-info DIR is uploaded through
# debug-files, which is what the plugin did with its symbols_folder.
#
# FAILURE SEMANTICS
# Upload failures fail the step. Credential-free builds can explicitly opt out
# with --allow-missing-credentials; they warn without downloading the CLI.

set -euo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"
source "$REPO_ROOT/scripts/lib/common.sh"
load_native_pins

usage() {
  sed -n '/^# USAGE:/,/^# FAILURE SEMANTICS$/p' "${BASH_SOURCE[0]}" \
    | sed -e 's/^# \{0,1\}//' -e '$d'
}

PLATFORM=""
ARCH=""
BUILD_DIR="build"
WEB_DIR=""
BUILD_NAME=""
BUILD_NUMBER=""
RELEASE_OVERRIDE="${SENTRY_RELEASE:-}"
DIST_OVERRIDE="${SENTRY_DIST:-}"
SPLIT_DEBUG_INFO="${SENTRY_SPLIT_DEBUG_INFO_DIR:-}"
SET_COMMITS=0
IGNORE_MISSING=0
WAIT=0
ALLOW_MISSING=0
IGNORE_WEB_PATHS=()

need_value() { # argv...
  [ "$#" -ge 2 ] || die "$1 needs a value (see --help)"
}

while [ $# -gt 0 ]; do
  case "$1" in
    --platform)     need_value "$@"; PLATFORM="$2"; shift 2 ;;
    --arch)         need_value "$@"; ARCH="$2"; shift 2 ;;
    --build-dir)    need_value "$@"; BUILD_DIR="$2"; shift 2 ;;
    --web-dir)      need_value "$@"; WEB_DIR="$2"; shift 2 ;;
    --build-name)   need_value "$@"; BUILD_NAME="$2"; shift 2 ;;
    --build-number) need_value "$@"; BUILD_NUMBER="$2"; shift 2 ;;
    --release)      need_value "$@"; RELEASE_OVERRIDE="$2"; shift 2 ;;
    --dist)         need_value "$@"; DIST_OVERRIDE="$2"; shift 2 ;;
    --split-debug-info) need_value "$@"; SPLIT_DEBUG_INFO="$2"; shift 2 ;;
    --ignore-web-path)  need_value "$@"; IGNORE_WEB_PATHS+=("$2"); shift 2 ;;
    --set-commits)              SET_COMMITS=1; shift ;;
    --ignore-missing-commits)   IGNORE_MISSING=1; shift ;;
    --wait)                     WAIT=1; shift ;;
    --allow-missing-credentials) ALLOW_MISSING=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) die "unknown argument '$1' (see --help)" ;;
  esac
done

case "$PLATFORM" in
  macos|linux|windows|web) ;;
  '') die "--platform is required (macos|linux|windows|web)" ;;
  *)  die "unknown platform '$PLATFORM' (expected macos|linux|windows|web)" ;;
esac

if [ "$PLATFORM" = windows ]; then
  ARCH="$(cc_windows_arch "${ARCH:-x64}")"
else
  case "${ARCH:-x64}" in
    x64|arm64) ARCH="${ARCH:-x64}" ;;
    *) die "unknown architecture '${ARCH}' (expected x64|arm64)" ;;
  esac
fi

# ---------------------------------------------------------------------------
# Credentials
# ---------------------------------------------------------------------------

# Gate BEFORE downloading or reading anything else: a local run without a token
# must not fetch a 28 MB binary, and the skip must be explicit.
if [ -z "${SENTRY_AUTH_TOKEN:-}" ]; then
  if [ "$ALLOW_MISSING" -eq 1 ]; then
    warn "SENTRY_AUTH_TOKEN is not set — skipping the Sentry upload; no debug files or source maps were sent."
    exit 0
  fi
  die "SENTRY_AUTH_TOKEN is not set, so nothing can be uploaded.
  CI: pass the SENTRY_AUTH_TOKEN secret to this step.
  Local: export SENTRY_AUTH_TOKEN, or pass --allow-missing-credentials to skip."
fi

# python3 is used only by the version.json and source-map-prefix paths (linux,
# web). Requiring it lazily matters: a Windows release must not depend on a
# python3 that Git Bash there may not have on PATH.
require_python3() {
  if [ -z "${_CC_PYTHON3_READY:-}" ]; then
    require_cmd python3 "Install python3 (it ships with macOS and every CI runner)."
    _CC_PYTHON3_READY=1
  fi
}

SENTRY_ORG="${SENTRY_ORG:-use-ctrl}"
SENTRY_PROJECT="${SENTRY_PROJECT:-control-center-app}"

# ---------------------------------------------------------------------------
# sentry-cli: the pinned upstream binary
# ---------------------------------------------------------------------------

: "${SENTRY_CLI_VERSION:?SENTRY_CLI_VERSION missing from scripts/lib/native_pins.env}"

cli_os="$PLATFORM"
cli_arch="$ARCH"
if [ "$PLATFORM" = web ]; then
  # The web upload runs on whichever host built the bundle.
  cli_os="$(cc_platform)"
  case "$cli_os" in
    macos) cli_arch=arm64 ;; # Darwin-universal: the asset is the same either way
    linux)
      case "$(uname -m)" in
        x86_64|amd64) cli_arch=x64 ;;
        aarch64|arm64) cli_arch=arm64 ;;
        *) die "unsupported Linux host architecture $(uname -m)" ;;
      esac ;;
    windows) cli_arch=x64 ;;
  esac
fi

case "$cli_os:$cli_arch" in
  macos:*)     cli_target=sentry-cli-Darwin-universal;   cli_sha="$SENTRY_CLI_SHA256_DARWIN_UNIVERSAL" ;;
  linux:x64)   cli_target=sentry-cli-Linux-x86_64;       cli_sha="$SENTRY_CLI_SHA256_LINUX_X86_64" ;;
  linux:arm64) cli_target=sentry-cli-Linux-aarch64;      cli_sha="$SENTRY_CLI_SHA256_LINUX_AARCH64" ;;
  windows:x64) cli_target=sentry-cli-Windows-x86_64.exe; cli_sha="$SENTRY_CLI_SHA256_WINDOWS_X86_64" ;;
  windows:arm64) cli_target=sentry-cli-Windows-aarch64.exe; cli_sha="$SENTRY_CLI_SHA256_WINDOWS_AARCH64" ;;
  *) die "no pinned sentry-cli for $cli_os:$cli_arch" ;;
esac

# SENTRY_CLI is an explicit-binary escape hatch for local bisects and for the
# tests (which must not touch the network). It bypasses the pin, so it says so.
if [ -n "${SENTRY_CLI:-}" ]; then
  [ -x "$SENTRY_CLI" ] || die "SENTRY_CLI=$SENTRY_CLI is not an executable file"
  warn "SENTRY_CLI is set — using $SENTRY_CLI without verifying it against the pin in native_pins.env."
  SENTRY_CLI_BIN="$SENTRY_CLI"
else
  cli_dir="$BUILD_DIR/sentry-cli/$SENTRY_CLI_VERSION"
  SENTRY_CLI_BIN="$cli_dir/$cli_target"
  if [ -f "$SENTRY_CLI_BIN" ]; then
    # A cached copy is re-verified on every run: the version is part of the
    # path, so a mismatch means the bytes changed under us — re-download by
    # deleting the file rather than trusting it.
    sha256_verify "$SENTRY_CLI_BIN" "$cli_sha"
  else
    mkdir -p "$cli_dir"
    # Download to a side path and move it in only after it verifies: an
    # interrupted fetch must not leave a file the next run has to reject.
    fetch_pinned \
      "https://github.com/getsentry/sentry-cli/releases/download/$SENTRY_CLI_VERSION/$cli_target" \
      "$cli_sha" "$SENTRY_CLI_BIN.part"
    mv "$SENTRY_CLI_BIN.part" "$SENTRY_CLI_BIN"
  fi
  if [ "$cli_os" != windows ]; then
    chmod +x "$SENTRY_CLI_BIN"
  fi
  # The binary must be the pinned release, not a same-named impostor: the pin
  # covers bytes, this covers "those bytes are a working CLI of that version".
  cli_version="$("$SENTRY_CLI_BIN" --version)" \
    || die "$SENTRY_CLI_BIN --version failed; the pinned binary is not runnable on this host."
  case "$cli_version" in
    *"$SENTRY_CLI_VERSION"*) ;;
    *) die "$SENTRY_CLI_BIN reports '$cli_version' but native_pins.env pins $SENTRY_CLI_VERSION" ;;
  esac
fi

# ---------------------------------------------------------------------------
# Release / dist
# ---------------------------------------------------------------------------

RELEASE=""
DIST=""

check_build_inputs() { # artifact-version artifact-build
  if [ -n "$BUILD_NAME" ] && [ "$BUILD_NAME" != "$1" ]; then
    die "the artifact reports version '$1' but --build-name is '$BUILD_NAME'.
      Symbols uploaded under a release the app never reports are never used."
  fi
  if [ -n "$BUILD_NUMBER" ] && [ "$BUILD_NUMBER" != "${2:-}" ]; then
    die "the artifact reports build '$2' but --build-number is '$BUILD_NUMBER'.
      Symbols uploaded under a release the app never reports are never used."
  fi
}

# Reads <name>@<version>[+<build>] and the build number out of a Flutter
# version.json, which `flutter build web` and the Linux desktop build write into
# the bundle (flutter_tools: targets/web.dart, targets/linux.dart).
release_from_version_json() { # version.json
  local out
  require_python3
  out="$(python3 - "$1" <<'PYEOF'
import json, sys

with open(sys.argv[1]) as f:
    version = json.load(f)

# package_name is what the SDK reports on linux/web; app_name is the fallback
# when a platform leaves it out (both are the pubspec name for this app).
name = version.get("package_name") or version.get("app_name") or ""
build = version.get("build_number") or ""
build_name = version.get("version") or ""
if not name or not build_name:
    sys.exit(f"{sys.argv[1]} has no package_name/app_name and no version")
print(f"{name}@{build_name}" + (f"+{build}" if build else ""))
print(build)
print(build_name)
PYEOF
)" || die "could not read $1"
  RELEASE="$(printf '%s\n' "$out" | sed -n 1p)"
  DIST="$(printf '%s\n' "$out" | sed -n 2p)"
  check_build_inputs "$(printf '%s\n' "$out" | sed -n 3p)" "$DIST"
}

macos_app_path() {
  local app
  app="$(find "$BUILD_DIR/macos/Build/Products/Release" -maxdepth 1 -name '*.app' \
    -print 2>/dev/null | head -1)" || true
  [ -n "$app" ] || die "no .app found under $BUILD_DIR/macos/Build/Products/Release — build first."
  printf '%s\n' "$app"
}

plist_value() { # plist key
  /usr/libexec/PlistBuddy -c "Print :$2" "$1" 2>/dev/null
}

release_from_macos_app() { # app
  local plist="$1/Contents/Info.plist"
  [ -f "$plist" ] || die "no Info.plist in $1"
  local id version build
  id="$(plist_value "$plist" CFBundleIdentifier)"
  version="$(plist_value "$plist" CFBundleShortVersionString)"
  build="$(plist_value "$plist" CFBundleVersion)"
  [ -n "$id" ] && [ -n "$version" ] && [ -n "$build" ] \
    || die "$plist has no CFBundleIdentifier/CFBundleShortVersionString/CFBundleVersion"
  check_build_inputs "$version" "$build"
  RELEASE="$id@$version+$build"
  DIST="$build"
}

pubspec_name() {
  sed -n 's/^name:[[:space:]]*//p' pubspec.yaml | head -1
}

release_from_windows_exe() {
  # The published exe carries InternalName as a compile-time literal from
  # windows/runner/Runner.rc; package_info_plus reports it as packageName, so a
  # rename in one place and not the other would silently orphan the symbols.
  local internal pubspec
  internal="$(sed -n 's/^[[:space:]]*VALUE "InternalName", "\([^"]*\)".*/\1/p' \
    windows/runner/Runner.rc | head -1)"
  pubspec="$(pubspec_name)"
  [ -n "$internal" ] || die "could not read InternalName from windows/runner/Runner.rc"
  if [ "$internal" != "$pubspec" ]; then
    die "windows/runner/Runner.rc InternalName is '$internal' but pubspec name is '$pubspec'.
      package_info_plus reports InternalName as the release owner, so the two must agree."
  fi

  local version build
  version="${BUILD_NAME:-$(sed -n 's/^version:[[:space:]]*//p' pubspec.yaml | head -1)}"
  build=""
  case "$version" in
    *+*) build="${version#*+}"; version="${version%%+*}" ;;
  esac
  if [ -n "$BUILD_NUMBER" ]; then
    build="$BUILD_NUMBER"
  fi
  RELEASE="$internal@$version"
  if [ -n "$build" ]; then
    RELEASE="$RELEASE+$build"
  fi
  DIST="$build"
}

if [ -n "$RELEASE_OVERRIDE" ]; then
  RELEASE="$RELEASE_OVERRIDE"
  warn "using SENTRY_RELEASE/--release '$RELEASE' instead of deriving it from the build."
else
  case "$PLATFORM" in
    macos)   release_from_macos_app "$(macos_app_path)" ;;
    linux)   release_from_version_json "$BUILD_DIR/linux/$ARCH/release/bundle/data/flutter_assets/version.json" ;;
    web)     release_from_version_json "${WEB_DIR:-$BUILD_DIR/web}/version.json" ;;
    windows) release_from_windows_exe ;;
  esac
fi

if [ -n "$DIST_OVERRIDE" ]; then
  DIST="$DIST_OVERRIDE"
fi

[ -n "$RELEASE" ] || die "could not derive a release name; pass --release"

# ---------------------------------------------------------------------------
# Debug-file roots
# ---------------------------------------------------------------------------

debug_roots=()
case "$PLATFORM" in
  macos)
    root="$BUILD_DIR/macos/Build/Products/Release"
    [ -d "$root" ] || die "no $root — run the macOS release build first."
    debug_roots+=("$root")
    # Plugin frameworks produced outside the app bundle (the plugin enumerated
    # this root too); absent for a plain app build.
    if [ -d "$BUILD_DIR/macos/framework/Release" ]; then
      debug_roots+=("$BUILD_DIR/macos/framework/Release")
    fi ;;
  linux)
    root="$BUILD_DIR/linux/$ARCH/release/bundle"
    [ -d "$root" ] || die "no $root — run the Linux release build first (--arch $ARCH)."
    debug_roots+=("$root") ;;
  windows)
    root="$BUILD_DIR/windows/$ARCH/runner/Release"
    [ -d "$root" ] || die "no $root — run the Windows release build first (--arch $ARCH)."
    debug_roots+=("$root")
    # Flutter's own DLL ships without its PDB in the release dir.
    pdb="windows/flutter/ephemeral/flutter_windows.dll.pdb"
    if [ -f "$pdb" ]; then
      debug_roots+=("$pdb")
    fi ;;
  web) : ;; # source maps only
esac

if [ -n "$SPLIT_DEBUG_INFO" ]; then
  [ -d "$SPLIT_DEBUG_INFO" ] \
    || die "--split-debug-info '$SPLIT_DEBUG_INFO' is not a directory"
  debug_roots+=("$SPLIT_DEBUG_INFO")
fi

# ---------------------------------------------------------------------------
# Run
# ---------------------------------------------------------------------------

org_project=()
if [ -n "$SENTRY_ORG" ]; then org_project+=(--org "$SENTRY_ORG"); fi
if [ -n "$SENTRY_PROJECT" ]; then org_project+=(--project "$SENTRY_PROJECT"); fi
upload_flags=("${org_project[@]+"${org_project[@]}"}")
if [ "$WAIT" -eq 1 ]; then upload_flags+=(--wait); fi

sentry_run() { # argv...  — a failure here is the step's failure
  log "sentry-cli $*"
  "$SENTRY_CLI_BIN" "$@" || die "sentry-cli $* failed — the Sentry upload did not complete."
}

sentry_run_optional() { # argv... — for steps the plugin treated as best-effort
  log "sentry-cli $*"
  "$SENTRY_CLI_BIN" "$@" \
    || warn "sentry-cli $* failed; continuing (this step is not load-bearing)."
}

log "Sentry release $RELEASE${DIST:+ (dist $DIST)} → $SENTRY_ORG/$SENTRY_PROJECT"

# 1. Debug files. First, as the plugin did: DIFs are associated by debug id, not
#    by release, so they need no release to exist yet.
for root in "${debug_roots[@]+"${debug_roots[@]}"}"; do
  sentry_run debug-files upload "${upload_flags[@]+"${upload_flags[@]}"}" "$root"
done

# 2. Release record.
sentry_run_optional releases new "$RELEASE" "${org_project[@]+"${org_project[@]}"}"

if [ "$PLATFORM" = web ]; then
  web_dir="${WEB_DIR:-$BUILD_DIR/web}"
  [ -d "$web_dir" ] || die "no web build at $web_dir"

  # One invocation listing every JavaScript file. Handing `sourcemaps inject` the
  # directory instead has produced corrupt Flutter source maps.
  js_files=()
  while IFS= read -r js; do
    [ -n "$js" ] && js_files+=("$js")
  done < <(find "$web_dir" -type f -name '*.js' | sort)

  if [ "${#js_files[@]}" -eq 0 ]; then
    die "no JavaScript files under $web_dir — nothing to inject debug ids into."
  fi

  map_files=()
  while IFS= read -r map; do
    [ -n "$map" ] && map_files+=("$map")
  done < <(find "$web_dir" -type f -name '*.js.map' | sort)

  # Path prefixes the plugin stripped from source maps: everything before a
  # Flutter SDK source reference, plus each '../'-style relative prefix.
  strip_prefixes=()
  if [ "${#map_files[@]}" -gt 0 ]; then
    require_python3
    prefixes="$(python3 - "${map_files[@]+"${map_files[@]}"}" <<'PYEOF'
import json, re, sys

FLUTTER_FRAGMENT = "/flutter/packages/flutter/lib/src/"
parent_pattern = re.compile(r"^(?:\.\./)+")

flutter_prefixes, parent_prefixes = [], []
for path in sys.argv[1:]:
    try:
        with open(path) as f:
            source_map = json.load(f)
    except Exception:
        continue
    sources = source_map.get("sources")
    if not isinstance(sources, list):
        continue
    for entry in sources:
        if not isinstance(entry, str):
            continue
        index = entry.find(FLUTTER_FRAGMENT)
        if index > 0:
            prefix = entry[:index]
            if prefix not in flutter_prefixes:
                flutter_prefixes.append(prefix)
        match = parent_pattern.match(entry)
        if match:
            prefix = "../" * (len(match.group(0)) // 3)
            if prefix not in parent_prefixes:
                parent_prefixes.append(prefix)

# Most specific first, so three levels are stripped before one level of the
# same prefix matches.
parent_prefixes.sort(key=lambda p: -p.count("../"))
for prefix in flutter_prefixes + parent_prefixes:
    print(prefix)
PYEOF
)" || die "could not derive source-map prefixes from ${web_dir}"
    while IFS= read -r prefix; do
      [ -n "$prefix" ] && strip_prefixes+=("$prefix")
    done <<<"$prefixes"
  fi

  inject_args=(sourcemaps inject "${js_files[@]}")
  for glob in "${IGNORE_WEB_PATHS[@]+"${IGNORE_WEB_PATHS[@]}"}"; do
    inject_args+=(--ignore "$glob")
  done
  inject_args+=("${org_project[@]+"${org_project[@]}"}")
  sentry_run "${inject_args[@]}"

  upload_args=(sourcemaps upload --release "$RELEASE")
  if [ -n "$DIST" ]; then upload_args+=(--dist "$DIST"); fi
  if [ "$WAIT" -eq 1 ]; then upload_args+=(--wait); fi
  upload_args+=("$web_dir" --ext js --ext map)
  for prefix in "${strip_prefixes[@]+"${strip_prefixes[@]}"}"; do
    upload_args+=(--strip-prefix "$prefix")
  done
  for glob in "${IGNORE_WEB_PATHS[@]+"${IGNORE_WEB_PATHS[@]}"}"; do
    upload_args+=(--ignore "$glob")
  done
  upload_args+=("${org_project[@]+"${org_project[@]}"}")
  sentry_run "${upload_args[@]}"
fi

# 3. Optional commit association. Needs an unshallow checkout and the org's
#    repository integration; the plugin's default and non-fatal, opt-in here.
if [ "$SET_COMMITS" -eq 1 ]; then
  commit_args=(releases set-commits "$RELEASE" --auto)
  if [ "$IGNORE_MISSING" -eq 1 ]; then commit_args+=(--ignore-missing); fi
  commit_args+=("${org_project[@]+"${org_project[@]}"}")
  sentry_run_optional "${commit_args[@]}"
fi

# 4. Finalize last, so a release is only ever marked released after its symbols
#    landed.
sentry_run releases finalize "$RELEASE" "${org_project[@]+"${org_project[@]}"}"

log "Sentry upload complete for $RELEASE${DIST:+ (dist $DIST)}."
