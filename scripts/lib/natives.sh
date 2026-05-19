#!/usr/bin/env bash
#
# Source it; don't execute it:
#   source scripts/lib/natives.sh   # then cc_natives_for <role> <os>
#
# THE required-native matrix. One row per shipped FFI library.
#
# This used to be stated four times for four audiences, in two different shell
# implementations, with four comments asking the reader to "change them
# together": verify_natives.sh's `require` list, cc_server_package.sh's separate
# `require_native` list, the runtime table in
# packages/cc_server_core/lib/src/cc_server_runtime.dart, and
# native_preflight.dart. Now the two shell consumers read this file and
# test/tooling/native_matrix_test.dart asserts the Dart runtime table agrees
# with it, so a drift is a failing test rather than a boot failure on a user's
# machine.
#
# Row format — pipe-delimited, four fields:
#
#   base|roles|platforms|description
#
#   base         the library's base name, WITHOUT the platform prefix (`lib` on
#                macOS/Linux, none on Windows) or extension. Matching is
#                dot-bounded, so `tree-sitter` never matches
#                libtree-sitter-dart.dylib and a versioned soname
#                (libfoo.so.1.2.3) still does.
#   roles        comma-separated: `desktop` (the Flutter app's own native dir),
#                `server` (a cc_server bundle's lib dir — everything the boot
#                preflight probes).
#   platforms    `all`, or `!windows` for the single documented exemption.
#   description  what breaks without it; printed verbatim in failures.
#
# Every native is REQUIRED. There is no degraded mode: a missing library means a
# broken install, so packaging refuses to produce the artifact rather than
# shipping something that dies on first launch.
#
# rift is the one platform exemption: there is no MSVC copy-on-write backend, so
# on Windows plain `git worktree` is the BACKEND rather than a degradation (see
# `RiftRepoIsolationAdapter.missingRiftIsExpected`).

CC_NATIVES=(
  # Client-side: the meeting recorder's echo canceller runs in the Flutter
  # isolate, and the in-app indexer needs the code-graph natives.
  "aec_ffi|desktop|all|meeting echo cancellation"
  "fff_c|desktop,server|all|fuzzy file search"
  "tree-sitter|desktop,server|all|code graph indexing"

  # One row per shipped grammar so a failure names the exact missing library.
  # Keep in step with `kLanguageByExtension`
  # (packages/cc_natives/lib/src/code_index/code_languages.dart) — the indexer
  # throws on a recognised language whose grammar is absent, and
  # native_matrix_test.dart pins the two sets together.
  "tree-sitter-dart|desktop,server|all|dart code graph grammar"
  "tree-sitter-javascript|desktop,server|all|javascript code graph grammar"
  "tree-sitter-typescript|desktop,server|all|typescript code graph grammar"
  "tree-sitter-tsx|desktop,server|all|tsx code graph grammar"
  "tree-sitter-php|desktop,server|all|php code graph grammar"

  # Server-side: probed by the boot preflight, so a miss refuses to start.
  "ccpty|server|all|sandboxed terminals"
  "cc_watcher|server|all|code-graph file watching"
  "lame_ffi|server|all|soundscape MP3 encoding"
  # ONE library for both on-device ML workloads: it statically links
  # sherpa-onnx together with a single ONNX Runtime.
  "cc_inference|server|all|semantic embeddings, meeting transcription, diarization, VAD, dictation"
  "rift_ffi|server|!windows|copy-on-write worktrees"
)

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
