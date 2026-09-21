#!/usr/bin/env bash
#
# Source it: `source scripts/lib/natives.sh` then `cc_natives_for <role> <os>`.
# Required-native matrix (pinned to runtime by test). Row: base|roles|platforms|description
# (base without lib/ext; roles desktop|server; platforms all|!windows). rift is the
# Windows exemption (git worktree backend). Missing native ⇒ refuse to ship/boot.
#

CC_NATIVES=(
  # Client-side: the meeting recorder's echo canceller runs in the Flutter
  # isolate and the in-app indexer needs the code-graph natives.
  "aec_ffi|desktop|all|meeting echo cancellation"
  "fff_c|desktop,server|all|fuzzy file search"
  "tree-sitter|desktop,server|all|code graph indexing"

  # One row per shipped grammar so a failure names the exact missing library.
  # Keep in step with `kLanguageByExtension`
  # (packages/cc_natives/lib/src/code_index/code_languages.dart) — the indexer
  # throws on a recognised language whose grammar is absent and
  # native_matrix_test.dart pins the two sets together.
  "tree-sitter-dart|desktop,server|all|dart code graph grammar"
  "tree-sitter-javascript|desktop,server|all|javascript code graph grammar"
  "tree-sitter-typescript|desktop,server|all|typescript code graph grammar"
  "tree-sitter-tsx|desktop,server|all|tsx code graph grammar"
  "tree-sitter-php|desktop,server|all|php code graph grammar"
  "tree-sitter-python|desktop,server|all|python code graph grammar"
  "tree-sitter-rust|desktop,server|all|rust code graph grammar"
  "tree-sitter-zig|desktop,server|all|zig code graph grammar"
  "tree-sitter-c|desktop,server|all|c code graph grammar"
  "tree-sitter-cpp|desktop,server|all|c++ code graph grammar"
  "tree-sitter-go|desktop,server|all|go code graph grammar"
  "tree-sitter-java|desktop,server|all|java code graph grammar"
  "tree-sitter-ruby|desktop,server|all|ruby code graph grammar"
  "tree-sitter-c_sharp|desktop,server|all|c# code graph grammar"
  "tree-sitter-swift|desktop,server|all|swift code graph grammar"
  "tree-sitter-kotlin|desktop,server|all|kotlin code graph grammar"
  "tree-sitter-r|desktop,server|all|r code graph grammar"
  "tree-sitter-asm|desktop,server|all|assembly code graph grammar"
  "tree-sitter-matlab|desktop,server|all|matlab code graph grammar"
  "tree-sitter-ada|desktop,server|all|ada code graph grammar"

  # Server-side: probed by the boot preflight, so a miss refuses to start.
  "ccpty|server|all|sandboxed terminals"
  "cc_watcher|server|all|code-graph file watching"
  "lame_ffi|server|all|soundscape MP3 encoding"
  # ONE library for both on-device ML workloads: it statically links
  # sherpa-onnx together with a single ONNX Runtime.
  "cc_inference|server|all|semantic embeddings, meeting transcription, diarization, VAD, dictation"
  "cc_saml|server|all|SAML SSO response verification"
  "rift_ffi|server|!windows|copy-on-write worktrees"
)

# Linux RUNTIME ABI floor: preflight dlopens, so a newer glibc/libstdc++ symbol
# than the base image reports as "missing". verify_natives.sh fails bundles that
# need anything newer. Raise the base image before raising these maxima.
CC_NATIVES_BASE_IMAGE="debian:trixie-slim" # docker/cc_server/Dockerfile
CC_NATIVES_GLIBC_MAX="2.41"                # Debian 13 glibc
CC_NATIVES_GLIBCXX_MAX="3.4.33"            # Debian 13 libstdc++ (GCC 14)

# Echoes the `base|description` of every native required for a role on an OS.
cc_natives_for() { # role os
  local role="$1" os="$2" row base roles platforms desc
  for row in "${CC_NATIVES[@]}"; do
    IFS='|' read -r base roles platforms desc <<< "$row"
    case ",$roles," in *",$role,"*) ;; *) continue ;; esac
    if [ "$platforms" = "!$os" ]; then
      continue
    fi
    printf '%s|%s\n' "$base" "$desc"
  done
}
