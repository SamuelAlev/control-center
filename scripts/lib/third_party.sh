#!/usr/bin/env bash
#
# THE third-party component table — everything redistributed inside a shipped
# artifact, and the license each one travels under.
#
# Source it; never execute it. Read by scripts/release/gen_third_party_licenses.sh, which
# turns it into the THIRD-PARTY-LICENSES.txt every package carries, and pinned
# against scripts/lib/natives.sh by test/tooling/third_party_licenses_test.dart
# so a native cannot be added to the build without an attribution entry.
#
# This covers COMPILED-IN and BUNDLED components only. Dart/Flutter package
# dependencies of the desktop app are covered by the engine-generated `NOTICES`
# file Flutter already places in the app bundle; `cc_server`'s pub dependencies
# are permissive-only and listed in its own pubspec.
#
# FORMAT — `name|version|spdx|homepage|license_file|linkage|roles`
#   version      a literal, or `@VAR` resolved from scripts/lib/native_pins.env,
#                or `@codeServerVersion` read from the Dart pin.
#   license_file relative to third_party/licenses/
#   linkage      static | dynamic | bundled  (what the artifact actually ships)
#   roles        comma-separated: desktop, server — which ARTIFACT carries it.
#                `desktop` is the app bundle (DMG / AppImage / installer) and
#                `server` is the standalone cc_server archive. They are not the
#                same split as scripts/lib/natives.sh's build roles: every
#                desktop package EMBEDS a cc_server and stages the server
#                natives inside it (see the two verify_natives.sh calls in each
#                packager), so a server-role native such as lame_ffi or
#                cc_inference ships in BOTH artifacts. code-server is the one
#                component vendored only into the standalone archive.
#
# LGPL NOTE: libmp3lame is the one copyleft component. It is linked STATICALLY
# into liblame_ffi, so LGPL-2.1 section 6 applies: the distribution has to let a
# recipient relink the work against a modified libmp3lame. That is satisfied
# here by source availability rather than by shipping object files — the shim
# source, the exact upstream version and its checksum, and the build script are
# all public in this repository. gen_third_party_licenses.sh states this in the
# generated file; if that ever stops being true, link libmp3lame dynamically
# instead, which discharges section 6 on its own.

CC_THIRD_PARTY=(
  "rift|@RIFT_REF|MIT|https://github.com/anomalyco/rift|rift-MIT.txt|static|desktop,server"
  "fff|@FFF_REF|MIT|https://github.com/dmtrKovalenko/fff|fff-MIT.txt|static|desktop,server"
  "tree-sitter|@TREE_SITTER_REF|MIT|https://github.com/tree-sitter/tree-sitter|tree-sitter-MIT.txt|static|desktop,server"
  "tree-sitter-dart|@TS_DART_REF|MIT|https://github.com/UserNobody14/tree-sitter-dart|tree-sitter-dart-MIT.txt|static|desktop,server"
  "tree-sitter-javascript|@TS_JAVASCRIPT_REF|MIT|https://github.com/tree-sitter/tree-sitter-javascript|tree-sitter-javascript-MIT.txt|static|desktop,server"
  "tree-sitter-typescript|@TS_TYPESCRIPT_REF|MIT|https://github.com/tree-sitter/tree-sitter-typescript|tree-sitter-typescript-MIT.txt|static|desktop,server"
  "tree-sitter-php|@TS_PHP_REF|MIT|https://github.com/tree-sitter/tree-sitter-php|tree-sitter-php-MIT.txt|static|desktop,server"
  "webrtc-audio-processing|@WAP_REF|BSD-3-Clause|https://gitlab.freedesktop.org/pulseaudio/webrtc-audio-processing|webrtc-audio-processing-BSD-3-Clause.txt|static|desktop"
  "LAME (libmp3lame)|@LAME_VERSION|LGPL-2.1-or-later|https://lame.sourceforge.io/|lame-LGPL-2.1.txt|static|desktop,server"
  "sherpa-onnx|@SHERPA_ONNX_VERSION|Apache-2.0|https://github.com/k2-fsa/sherpa-onnx|sherpa-onnx-Apache-2.0.txt|static|desktop,server"
  "ONNX Runtime|1.27.1|MIT|https://github.com/microsoft/onnxruntime|onnxruntime-MIT.txt|static|desktop,server"
  "flutter_pty (vendored C)|2.0.0|MIT|https://github.com/xtyxtyx/flutter_pty|flutter-pty-MIT.txt|static|desktop,server"
  "code-server|@codeServerVersion|MIT|https://github.com/coder/code-server|code-server-MIT.txt|bundled|server"
  "AppImage runtime|1.9.1|MIT|https://github.com/AppImage/type2-runtime|appimage-runtime-MIT.txt|bundled|desktop"
  # Fonts. Vendored into packages/cc_ui/fonts/ and compiled into the Flutter
  # asset bundle, so they ship in the app and never in the server archive. The
  # texts here are copies of the ones beside the .ttf files, which is where a
  # font swap updates them first.
  "Manrope (font)|variable|OFL-1.1|https://github.com/sharanda/manrope|manrope-font-LICENSE.txt|bundled|desktop"
  "Fira Code (font)|variable|OFL-1.1|https://github.com/tonsky/FiraCode|firacode-font-LICENSE.txt|bundled|desktop"
  "Phosphor Icons (font)|2.0.8|MIT|https://github.com/phosphor-icons/core|phosphor-font-LICENSE.txt|bundled|desktop"
)

# Prints `name|version|spdx|homepage|license_file|linkage` for one role
# (desktop|server), versions already resolved.
cc_third_party_for() { # role
  local role="$1" row name version spdx home file linkage roles
  for row in "${CC_THIRD_PARTY[@]}"; do
    IFS='|' read -r name version spdx home file linkage roles <<<"$row"
    case ",$roles," in *",$role,"*) ;; *) continue ;; esac
    printf '%s|%s|%s|%s|%s|%s\n' \
      "$name" "$(cc_third_party_version "$version")" "$spdx" "$home" "$file" "$linkage"
  done
}

# Resolves an `@VAR` version reference against the pins; echoes a literal as-is.
cc_third_party_version() { # version
  local v="$1"
  case "$v" in
    @codeServerVersion)
      grep -m1 'const String codeServerVersion' \
        "${REPO_ROOT:-.}/packages/cc_infra/lib/src/ide/code_server_service.dart" 2>/dev/null |
        sed -E "s/.*'([^']+)'.*/\1/" || echo unknown
      ;;
    @*)
      local name="${v#@}" resolved
      resolved="${!name:-}"
      [ -n "$resolved" ] || {
        printf 'unknown'
        return
      }
      # A 40-hex git pin is shortened for the table; a plain version prints
      # whole. Still unambiguous, and the full pin is in native_pins.env.
      case "$resolved" in
        [0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f]*)
          if [ "${#resolved}" -eq 40 ]; then
            printf '%s' "${resolved:0:12}"
          else
            printf '%s' "$resolved"
          fi
          ;;
        *) printf '%s' "$resolved" ;;
      esac
      ;;
    *) printf '%s' "$v" ;;
  esac
}
