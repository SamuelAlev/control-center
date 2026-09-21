#!/usr/bin/env bash
#
# Source it. Third-party redistributed components + licenses for
# gen_third_party_licenses.sh; pinned against natives.sh by test. Compiled-in/
# bundled only (not Dart pub packages). LAME is LGPL via source availability.
#

CC_THIRD_PARTY=(
  "rift|@RIFT_REF|MIT|https://github.com/anomalyco/rift|rift-MIT.txt|static|desktop,server"
  "fff|@FFF_REF|MIT|https://github.com/dmtrKovalenko/fff|fff-MIT.txt|static|desktop,server"
  "tree-sitter|@TREE_SITTER_REF|MIT|https://github.com/tree-sitter/tree-sitter|tree-sitter-MIT.txt|static|desktop,server"
  "tree-sitter-dart|@TS_DART_REF|MIT|https://github.com/UserNobody14/tree-sitter-dart|tree-sitter-dart-MIT.txt|static|desktop,server"
  "tree-sitter-javascript|@TS_JAVASCRIPT_REF|MIT|https://github.com/tree-sitter/tree-sitter-javascript|tree-sitter-javascript-MIT.txt|static|desktop,server"
  "tree-sitter-typescript|@TS_TYPESCRIPT_REF|MIT|https://github.com/tree-sitter/tree-sitter-typescript|tree-sitter-typescript-MIT.txt|static|desktop,server"
  "tree-sitter-php|@TS_PHP_REF|MIT|https://github.com/tree-sitter/tree-sitter-php|tree-sitter-php-MIT.txt|static|desktop,server"
  "tree-sitter-python|@TS_PYTHON_REF|MIT|https://github.com/tree-sitter/tree-sitter-python|tree-sitter-python-MIT.txt|static|desktop,server"
  "tree-sitter-rust|@TS_RUST_REF|MIT|https://github.com/tree-sitter/tree-sitter-rust|tree-sitter-rust-MIT.txt|static|desktop,server"
  "tree-sitter-zig|@TS_ZIG_REF|MIT|https://github.com/tree-sitter-grammars/tree-sitter-zig|tree-sitter-zig-MIT.txt|static|desktop,server"
  "tree-sitter-c|@TS_C_REF|MIT|https://github.com/tree-sitter/tree-sitter-c|tree-sitter-c-MIT.txt|static|desktop,server"
  "tree-sitter-cpp|@TS_CPP_REF|MIT|https://github.com/tree-sitter/tree-sitter-cpp|tree-sitter-cpp-MIT.txt|static|desktop,server"
  "tree-sitter-go|@TS_GO_REF|MIT|https://github.com/tree-sitter/tree-sitter-go|tree-sitter-go-MIT.txt|static|desktop,server"
  "tree-sitter-java|@TS_JAVA_REF|MIT|https://github.com/tree-sitter/tree-sitter-java|tree-sitter-java-MIT.txt|static|desktop,server"
  "tree-sitter-ruby|@TS_RUBY_REF|MIT|https://github.com/tree-sitter/tree-sitter-ruby|tree-sitter-ruby-MIT.txt|static|desktop,server"
  "tree-sitter-c-sharp|@TS_C_SHARP_REF|MIT|https://github.com/tree-sitter/tree-sitter-c-sharp|tree-sitter-c-sharp-MIT.txt|static|desktop,server"
  "tree-sitter-swift|@TS_SWIFT_REF|MIT|https://github.com/alex-pinkus/tree-sitter-swift|tree-sitter-swift-MIT.txt|static|desktop,server"
  "tree-sitter-kotlin|@TS_KOTLIN_REF|MIT|https://github.com/tree-sitter-grammars/tree-sitter-kotlin|tree-sitter-kotlin-MIT.txt|static|desktop,server"
  "tree-sitter-r|@TS_R_REF|MIT|https://github.com/r-lib/tree-sitter-r|tree-sitter-r-MIT.txt|static|desktop,server"
  "tree-sitter-asm|@TS_ASM_REF|MIT|https://github.com/RubixDev/tree-sitter-asm|tree-sitter-asm-MIT.txt|static|desktop,server"
  "tree-sitter-matlab|@TS_MATLAB_REF|MIT|https://github.com/acristoffers/tree-sitter-matlab|tree-sitter-matlab-MIT.txt|static|desktop,server"
  "tree-sitter-ada|@TS_ADA_REF|MIT|https://github.com/briot/tree-sitter-ada|tree-sitter-ada-MIT.txt|static|desktop,server"
  "webrtc-audio-processing|@WAP_REF|BSD-3-Clause|https://gitlab.freedesktop.org/pulseaudio/webrtc-audio-processing|webrtc-audio-processing-BSD-3-Clause.txt|static|desktop"
  "LAME (libmp3lame)|@LAME_VERSION|LGPL-2.1-or-later|https://lame.sourceforge.io/|lame-LGPL-2.1.txt|static|desktop,server"
  "sherpa-onnx|@SHERPA_ONNX_VERSION|Apache-2.0|https://github.com/k2-fsa/sherpa-onnx|sherpa-onnx-Apache-2.0.txt|static|desktop,server"
  "ONNX Runtime|1.28.2|MIT|https://github.com/microsoft/onnxruntime|onnxruntime-MIT.txt|static|desktop,server"
  "flutter_pty (vendored C)|0.4.2|MIT|https://github.com/xtyxtyx/flutter_pty|flutter-pty-MIT.txt|static|desktop,server"
  "code-server|@codeServerVersion|MIT|https://github.com/coder/code-server|code-server-MIT.txt|bundled|server"
  "AppImage runtime|1.9.1|MIT|https://github.com/AppImage/type2-runtime|appimage-runtime-MIT.txt|bundled|desktop"
  # Fonts. Vendored into packages/cc_ui/fonts/ and compiled into the Flutter
  # asset bundle, so they ship in the app and never in the server archive. The
  # texts here are copies of the ones beside the .ttf files, which is where a
  # font swap updates them first. Manrope is an explicit freeze: the GitHub
  # repo is gone and upstream no longer tags releases.
  "Manrope (font)|4.505|OFL-1.1|https://github.com/sharanda/manrope|manrope-font-LICENSE.txt|bundled|desktop"
  "Fira Code (font)|6.2|OFL-1.1|https://github.com/tonsky/FiraCode|firacode-font-LICENSE.txt|bundled|desktop"
  "Phosphor Icons (font)|2.0.8|MIT|https://github.com/phosphor-icons/core|phosphor-font-LICENSE.txt|bundled|desktop"
  "WebDriverAgent|v16.12.10|BSD-3-Clause|https://github.com/appium/WebDriverAgent|webdriveragent-BSD-3-Clause.txt|bundled|desktop"
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
