#!/usr/bin/env bash
#
# Packages the STANDALONE, self-hostable cc_server — the pure-Dart backend the
# web/phone thin clients dial — into a downloadable archive for one OS:
#
#   1. ensures the `dart build cli` bundle exists (builds it if absent). When
#      build/natives is staged BEFORE the build, apps/cc_server/hook/build.dart
#      bundles every runtime native into `<bundle>/lib/` as DynamicLoadingBundled
#      code assets — the same way libsqlite3 travels,
#   2. copies it to a friendly-named dist dir and (as an ordering safety net for
#      a bundle built before the natives were staged) stages EVERY runtime native
#      (rift / fff / tree-sitter / pty / aec + sherpa-onnx + onnxruntime) into the
#      directory the resolver looks in for THIS OS, then VERIFIES the natives the
#      server's boot preflight requires are present (the server refuses to boot
#      without them — never ship an archive that cannot start),
#   3. macOS only: Developer-ID signs every Mach-O inside-out + notarizes the zip
#      (stapling a loose CLI isn't supported, so first run uses online Gatekeeper),
#   4. archives (tar.gz on macOS/Linux, zip on Windows) + writes a SHA-256.
#
# This is the server counterpart to macos_package.sh / linux_package.sh, which
# EMBED a copy of cc_server inside the desktop app. Those leave the original
# `dart build cli` bundle untouched (they stage natives into their own copy), so
# this script copies the clean bundle and stages into the copy too.
#
# Built-in app credentials (Google Calendar's device-code client, the Klipy GIF
# key, the GitHub device-flow client id) are NOT handled here. They are baked
# into the server's source constants by `builtin_credentials.sh inject` — one
# release-job step ahead of every build, so that this script and the desktop
# packagers cannot disagree about them. Run it yourself before a local release
# build, or this archive ships without them.
#
# Where natives must land (matches packages/cc_natives/.../native_library.dart's
# `bundledLibraryCandidates`, relative to the cc_server binary at
# `<bundle>/bin/cc_server`):
#   * macOS   — `<bundle>/Frameworks/`     (`@executable_path/../Frameworks`)
#   * Linux   — `<bundle>/bin/lib/`        (`<exeDir>/lib`)
#   * Windows — `<bundle>/bin/`            (beside the .exe)
# sherpa-onnx-c-api finds its onnxruntime sibling via its own @loader_path/rpath,
# so both MUST share that one directory.
#
# Environment (macOS signing/notarization — all optional; absent ⇒ unsigned):
#   MACOS_CERTIFICATE / MACOS_CERTIFICATE_PWD   base64 Developer ID .p12 (CI)
#   NOTARY_PROFILE                              stored notarytool profile (local)
#   APPLE_ID / APPLE_TEAM_ID / APPLE_APP_PASSWORD   notarytool credentials (CI)
#   NATIVES                                     staged-natives dir (default build/natives)
#
# Usage:
#   scripts/release/cc_server_package.sh <version> [macos|linux|windows]
#   (OS defaults to the host's `uname`.)
set -euo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"
source "$REPO_ROOT/scripts/lib/common.sh"

VERSION="${1:?usage: cc_server_package.sh <version> [os]}"

# Resolve the target OS (arg 2, else the host).
OS="${2:-}"
if [ -z "$OS" ]; then
  case "$(uname -s)" in
    Darwin) OS=macos ;;
    Linux)  OS=linux ;;
    *)      OS=windows ;;
  esac
fi

# Per-OS layout: the `dart build cli` arch dir, the native file extension, the
# resolver-relative dir natives are staged into and the archive format.
case "$OS" in
  macos)   ARCH=arm64; CLI_DIR=macos_arm64;   LIBEXT=dylib; STAGE_REL=Frameworks; FMT=tar ;;
  linux)   ARCH=x64;   CLI_DIR=linux_x64;     LIBEXT=so;    STAGE_REL=bin/lib;    FMT=tar ;;
  windows) ARCH=x64;   CLI_DIR=windows_x64;   LIBEXT=dll;   STAGE_REL=bin;        FMT=zip ;;
  *) echo "ERROR: unknown OS '$OS' (expected macos|linux|windows)"; exit 2 ;;
esac

NATIVES="${NATIVES:-build/natives}"
BUNDLE="apps/cc_server/build/cli/$CLI_DIR/bundle"
NAME="cc_server-${VERSION}-${OS}-${ARCH}"
DIST="dist/$NAME"

echo "==> Packaging standalone cc_server: $NAME"

# 1. Ensure the `dart build cli` bundle exists. macos_package.sh / linux_package.sh
# / the Windows job already built it; this guard covers a standalone run.
if [ ! -e "$BUNDLE/bin/cc_server" ] && [ ! -e "$BUNDLE/bin/cc_server.exe" ]; then
  echo "==> Building cc_server cli bundle"
  # Prefer the repo's fvm SDK (local), fall back to PATH `dart` (CI's flutter-action SDK).
  DART_BIN="$REPO_ROOT/.fvm/flutter_sdk/bin/dart"
  [ -x "$DART_BIN" ] || DART_BIN="$(command -v dart)"
  ( cd apps/cc_server && "$DART_BIN" build cli )
fi
test -d "$BUNDLE" || { echo "ERROR: cc_server bundle not found at $BUNDLE"; exit 1; }

# 2. Copy the clean bundle to the dist dir, then stage natives into the resolver
# dir so the original `dart build cli` output stays pristine for any later reuse.
rm -rf "$DIST"
mkdir -p "$DIST"
cp -R "$BUNDLE/." "$DIST/"

STAGE="$DIST/$STAGE_REL"
mkdir -p "$STAGE"
echo "==> Staging natives into $STAGE_REL/"
shopt -s nullglob
copied=0
for f in "$NATIVES"/*."$LIBEXT"; do
  echo "  + $(basename "$f")"
  cp -f "$f" "$STAGE/"
  copied=$((copied + 1))
done
[ "$copied" -gt 0 ] || { echo "ERROR: no *.$LIBEXT natives in $NATIVES — run scripts/natives/build_natives.sh first (every native is boot-required)" >&2; exit 1; }
# Tree-sitter `.scm` queries: ship the CANONICAL files (scripts/natives/queries/)
# as real files beside the grammar libs — GrammarManager prefers the on-disk copy,
# so prod runs the same artifacts a dev tree does. The generated constants in
# embedded_queries.dart (tool/gen_embedded_queries.dart) remain the compiled-in
# fallback should these files go missing.
scm_copied=0
for q in "$REPO_ROOT"/scripts/natives/queries/*.scm; do
  echo "  + $(basename "$q")"
  cp -f "$q" "$STAGE/"
  scm_copied=$((scm_copied + 1))
done
[ "$scm_copied" -gt 0 ] || { echo "ERROR: no .scm queries in $REPO_ROOT/scripts/natives/queries" >&2; exit 1; }
# Verify the natives the server's boot preflight REQUIRES.
#
# This used to be a SECOND, independently-written copy of the required-native
# matrix (a glob list, next to verify_natives.sh's stricter prefix+extension
# matcher), with a comment asking the reader to keep it in step with the Dart
# runtime table. Now there is one matrix (scripts/lib/natives.sh) and one
# matcher: the libraries may live in lib/ (bundled by the build hook) or in the
# staged dir, so both are searched and missing from both means this archive
# cannot boot.
bash scripts/release/verify_natives.sh --dir "$DIST/lib" --dir "$STAGE" "$OS" server

# Drop the second copy of every native (Linux). The bundle carries each one
# TWICE: the build hook emits them as DynamicLoadingBundled code assets into
# `<bundle>/lib/`, and the staging above copies them into `bin/lib/`. Both are
# searched (`bundledLibraryCandidates` tries `<exeDir>/../lib` then
# `<exeDir>/lib`), so the second copy is pure weight — 49 MB, measured on the
# container built from this archive.
#
# The STAGED copy is the one kept: it is the directory `CC_NATIVE_LIB_DIR`
# names, the one the `.scm` queries sit beside, and the fallback every
# env-var-driven resolver (inference, pty, watcher, saml) lands on anyway.
# Byte-identical is the condition, so the staging's original purpose survives:
# it is a safety net for a bundle built BEFORE the natives were staged, and in
# that case `lib/` holds nothing to match and nothing is removed. Nothing
# resolves these by ASSET ID (no `@Native` in cc_natives does), which is what
# makes `lib/` the removable copy rather than the load-bearing one — unlike
# libsqlite3, which is bundled the same way but IS resolved by id, and stays.
#
# macOS and Windows keep both copies: there the staged dir is `Frameworks/` and
# `bin/` respectively, and macOS additionally signs every Mach-O in place below,
# so the two copies are not interchangeable the way they are here.
if [ "$OS" = linux ]; then
  freed=0
  for f in "$STAGE"/*."$LIBEXT"; do
    dup="$DIST/lib/$(basename "$f")"
    if [ -f "$dup" ] && cmp -s "$f" "$dup"; then
      freed=$((freed + $(wc -c < "$dup")))
      rm -f "$dup"
    fi
  done
  echo "==> Removed duplicate natives from lib/ ($((freed / 1048576)) MiB)"
fi

# Vendored code-server (VS Code in the browser) — the CI fetch step extracted
# the pinned standalone archive into build/code-server/<platform>/. Stage it
# BESIDE the cc_server binary at <bundle>/bin/code-server/<platform>/ so
# CodeServerService resolves it bundle-relative (offline-first: no on-demand
# download needed on a bundled server). Best-effort — a missing fetch degrades
# to on-demand managed download at runtime.
case "$OS" in
  macos)   CS_PLATFORM="darwin-arm64" ;;
  linux)   CS_PLATFORM="linux-x64" ;;
  windows) CS_PLATFORM="windows-x64" ;;
esac
CS_SRC="build/code-server/$CS_PLATFORM"
if [ -d "$CS_SRC" ]; then
  echo "==> Staging vendored code-server ($CS_PLATFORM) beside the binary"
  mkdir -p "$DIST/bin/code-server"
  cp -R "$CS_SRC" "$DIST/bin/code-server/$CS_PLATFORM"
else
  echo "::warning::no vendored code-server at $CS_SRC — server falls back to on-demand managed download"
fi

# 2b. Legal notices at the archive root. The server role's set is the larger of
# the two: it is the one that vendors code-server (a whole Node runtime).
install -m644 LICENSE "$DIST/LICENSE"
bash scripts/release/gen_third_party_licenses.sh server \
  "$DIST/THIRD-PARTY-LICENSES.txt"

# 3. macOS: Developer-ID sign every Mach-O inside-out, then notarize the zip.
# Best-effort: with no identity (a fork / dry-run without secrets) ship unsigned —
# matches the Windows installer's conditional signing.
if [ "$OS" = macos ]; then
  RUNNER_TEMP="${RUNNER_TEMP:-$(mktemp -d)}"
# Decoded signing material lives in scratch, which is always removed on exit.
scratch_dir
SECRETS_DIR="$SCRATCH_DIR"
  # Resolve a Developer ID Application identity. In the release job macos_package.sh
  # already imported the cert into a keychain on the search list, so find-identity
  # sees it; otherwise (standalone, with MACOS_CERTIFICATE) import it ourselves.
  IDENTITY="$(security find-identity -v -p codesigning 2>/dev/null | grep "Developer ID Application" | head -1 | awk '{print $2}' || true)"
  if [ -z "$IDENTITY" ] && [ -n "${MACOS_CERTIFICATE:-}" ]; then
    KEYCHAIN="$SECRETS_DIR/cc_server.keychain"
    echo "$MACOS_CERTIFICATE" | base64 --decode > "$SECRETS_DIR/cc_server_cert.p12"
    security create-keychain -p actions "$KEYCHAIN" 2>/dev/null || true
    security set-keychain-settings -lut 21600 "$KEYCHAIN"
    security unlock-keychain -p actions "$KEYCHAIN"
    security import "$SECRETS_DIR/cc_server_cert.p12" -k "$KEYCHAIN" -P "${MACOS_CERTIFICATE_PWD:-}" -T /usr/bin/codesign
    # Intentional word-splitting: prepend our keychain to the existing search
    # list, each path a separate arg (mirrors macos_package.sh).
    # shellcheck disable=SC2046
    security list-keychains -d user -s "$KEYCHAIN" $(security list-keychains -d user | sed s/\"//g)
    security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k actions "$KEYCHAIN" >/dev/null 2>&1 || true
    IDENTITY="$(security find-identity -v -p codesigning "$KEYCHAIN" | grep "Developer ID Application" | head -1 | awk '{print $2}' || true)"
  fi

  # dry_run.sh --skip-sign exports this. It was ignored here, so the flag that
  # says "don't" still produced a signing + notarization round trip for anyone
  # with a Developer ID in their keychain. As in macos_package.sh, it makes the
  # signing calls no-ops rather than skipping the block — the enumeration below
  # is the part worth exercising in a dry run and it needs no certificate.
  if [ "${ALLOW_UNSIGNED:-0}" = "1" ]; then
    warn "ALLOW_UNSIGNED=1 — packaging cc_server without Developer ID or notarization. Local verification only, not distributable."
    SKIP_SIGNING=1
  fi

  if [ -n "$IDENTITY" ] || [ "${SKIP_SIGNING:-0}" = "1" ]; then
    echo "==> Signing cc_server with ${IDENTITY:-<none>} (hardened runtime, inside-out)"
    sign() {
      [ "${SKIP_SIGNING:-0}" = "1" ] && return 0
      codesign --force --options runtime --timestamp -s "$IDENTITY" "$@"
    }
    sign_entitled() { # entitlements file...
      [ "${SKIP_SIGNING:-0}" = "1" ] && return 0
      local ent="$1"; shift
      codesign --force --options runtime --timestamp --entitlements "$ent" -s "$IDENTITY" "$@"
    }

    # The archive carries THREE kinds of Mach-O and the notary service inspects
    # every one of them:
    #   * cc_server's natives (Frameworks/*.dylib) + the bundled libsqlite3 and
    #     sqlite_vector (lib/*.dylib),
    #   * the cc_server executable itself,
    #   * and everything inside the vendored code-server staged above — a whole
    #     Node runtime (bin/code-server/<platform>/lib/node), its compiled
    #     addons (*.node) and its helper binaries (ripgrep, …).
    #
    # That third group is why v0.0.1 came back `status: Invalid`: this loop was
    # a *.dylib glob, code-server is staged BEFORE it runs and several dozen
    # unsigned Mach-Os went into the zip. So enumerate what is actually there
    # rather than the two directories we happen to remember — a glob silently
    # stops covering the archive the moment anything new is staged into it.
    #
    # Payloads (dylibs, addons) first, the cc_server binary last.
    CS_ENTITLEMENTS="$REPO_ROOT/scripts/release/entitlements/code_server.entitlements"
    test -f "$CS_ENTITLEMENTS" || die "missing $CS_ENTITLEMENTS — the vendored node cannot be signed without its hardened-runtime exceptions"

    # Every Mach-O in the archive, one per line.
    machos() { find "$DIST" -type f \( -perm -u+x -o -name '*.dylib' -o -name '*.node' \); }

    while IFS= read -r f; do
      [ "$f" = "$DIST/bin/cc_server" ] && continue
      file -b "$f" | grep -q 'Mach-O' || continue
      rel="${f#"$DIST"/}"
      echo "  sign $rel"
      # code-server's executables are Node. Under the hardened runtime V8 cannot
      # allocate executable memory without an explicit exception, so a node
      # signed bare here would notarize and then refuse to start — see the
      # entitlements file. Its dylibs/addons take none: entitlements are read
      # from a process's main executable.
      case "$rel" in
        bin/code-server/*)
          if file -b "$f" | grep -q 'Mach-O.*executable'; then
            sign_entitled "$CS_ENTITLEMENTS" "$f"
            continue
          fi
          ;;
      esac
      sign "$f"
    done < <(machos)
    # Dart AOT maps its embedded snapshot as executable memory — signed bare
    # under the hardened runtime it notarizes and is then SIGKILLed on launch
    # (CODESIGNING: Invalid Page). See entitlements/cc_server.entitlements.
    CC_ENTITLEMENTS="$REPO_ROOT/scripts/release/entitlements/cc_server.entitlements"
    test -f "$CC_ENTITLEMENTS" || die "missing $CC_ENTITLEMENTS — cc_server cannot be signed without its dart-aot hardened-runtime exception"
    echo "  sign bin/cc_server (dart-aot entitlements)"
    sign_entitled "$CC_ENTITLEMENTS" "$DIST/bin/cc_server"

    if [ "${SKIP_SIGNING:-0}" = "1" ]; then
      warn "ALLOW_UNSIGNED — skipping signature verification and notarization; this archive is not distributable."
    else
      # What the loop above can still miss. `codesign --verify` accepts an ad-hoc
      # signature and says nothing about the hardened runtime and the notary
      # service reports a bare `status: Invalid` naming no file — 15 minutes
      # later. Hold every Mach-O to the rule the notary actually applies, here,
      # where the failure names the offending path.
      echo "==> Verifying every Mach-O in the archive is Developer-ID signed + hardened"
      BAD_CODE=""
      while IFS= read -r macho; do
        file -b "$macho" | grep -q 'Mach-O' || continue
        # `|| true`: an UNSIGNED binary — the loudest thing this check exists to
        # find — makes `codesign -d` exit 1, which under pipefail would abort the
        # script here instead of reaching the report below.
        FLAGS="$(codesign -d --verbose=2 "$macho" 2>&1 |
          sed -n 's/^CodeDirectory .*flags=[^(]*(\([^)]*\)).*/\1/p' | head -1 || true)"
        case ",$FLAGS," in
          *,adhoc,*) BAD_CODE="$BAD_CODE
  ad-hoc signed:        ${macho#"$DIST"/}" ;;
          *runtime*) ;;
          *) BAD_CODE="$BAD_CODE
  no hardened runtime:  ${macho#"$DIST"/} (flags: ${FLAGS:-unsigned})" ;;
        esac
      done < <(machos)
      [ -z "$BAD_CODE" ] || die "the notary service will reject this archive:$BAD_CODE

Every Mach-O in the archive must be signed with the Developer ID identity under
the hardened runtime. Something is staging code the signing pass above does not
reach — extend it rather than relaxing this check."
      log "All Mach-Os in the archive are Developer-ID signed + hardened"

      # Notarize the zipped bundle. Prefer a stored notarytool keychain profile,
      # else Apple-ID credentials. Skip (with a warning) when neither is present.
      ZIP="$RUNNER_TEMP/$NAME.zip"
      ( cd "$DIST" && zip -qry "$ZIP" . )
      NOTARIZE=1
      if [ -n "${NOTARY_PROFILE:-}" ]; then
        echo "==> Notarizing (keychain profile)"
        NOTARY_AUTH=(--keychain-profile "$NOTARY_PROFILE")
      elif [ -n "${APPLE_ID:-}" ]; then
        echo "==> Notarizing (apple-id)"
        NOTARY_AUTH=(--apple-id "$APPLE_ID" --team-id "${APPLE_TEAM_ID:?}" --password "${APPLE_APP_PASSWORD:?}")
      else
        NOTARIZE=0
        echo "::warning::no NOTARY_PROFILE/APPLE_ID — cc_server signed but NOT notarized (first run needs a Gatekeeper override)"
      fi
      if [ "$NOTARIZE" = 1 ]; then
        # `notarytool submit --wait` EXITS 0 on `status: Invalid` — it reports
        # that the submission completed, not that it passed. Unchecked (as it was
        # for v0.0.1) the script printed
        #   Current status: Invalid.............Processing complete
        # and then walked on to archive, checksum and "==> Done", so a REJECTED
        # build shipped as a release asset and CI stayed green. Read the status,
        # and on anything but Accepted print the notary log — the only place that
        # names the offending binary and the reason.
        NOTARY_OUT="$SCRATCH_DIR/notarytool.txt"
        NOTARY_OK=1
        xcrun notarytool submit "$ZIP" "${NOTARY_AUTH[@]}" --wait 2>&1 | tee "$NOTARY_OUT" || NOTARY_OK=0
        grep -q 'status: Accepted' "$NOTARY_OUT" || NOTARY_OK=0
        if [ "$NOTARY_OK" != 1 ]; then
          SUBMISSION_ID="$(sed -n 's/^ *id: *\([0-9a-fA-F-]\{36\}\) *$/\1/p' "$NOTARY_OUT" | head -1)"
          if [ -n "$SUBMISSION_ID" ]; then
            echo "==> Notary log for $SUBMISSION_ID"
            xcrun notarytool log "$SUBMISSION_ID" "${NOTARY_AUTH[@]}" || true
          fi
          die "notarization failed — see the notary log above (this archive is NOT distributable)"
        fi
      fi
    fi
    # A loose CLI / its zip cannot be stapled (stapler only handles .app/.dmg/.pkg),
    # so notarization is verified online at first launch — documented in release notes.
  else
    echo "::warning::no Developer ID identity (and no MACOS_CERTIFICATE) — shipping cc_server UNSIGNED"
  fi
fi

# 4. Archive + checksum.
mkdir -p dist
if [ "$FMT" = tar ]; then
  ARCHIVE="$NAME.tar.gz"
  tar czf "$ARCHIVE" -C dist "$NAME"
else
  ARCHIVE="$NAME.zip"
  make_zip "dist/$NAME" "$PWD/$ARCHIVE"
fi

sha256_sidecar "$ARCHIVE"
echo "==> Done: $ARCHIVE"
