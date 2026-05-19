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
# packages/cc_server_core/lib/src/cc_server_runtime.dart and
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

# THE RUNTIME ABI FLOOR (Linux).
#
# "Present" and "loadable" are different claims, and shipping the first while
# asserting the second is how a release boots into `required native libraries
# are missing` with every file sitting right there on disk. The preflight probes
# by `dlopen`, so a library whose symbol versions the runtime's glibc/libstdc++
# do not provide is reported MISSING — sending whoever reads that message to
# look at staging, which was never wrong.
#
# Measured, on the demo container: natives compiled on the ubuntu-24.04 runner
# (glibc 2.39, libstdc++ 14) needed `__isoc23_strtol` (GLIBC_2.38 — glibc ≥2.38
# headers redirect `strtol` whenever `_GNU_SOURCE` is defined, which every C
# dependency here does), `pidfd_spawnp`/`pidfd_getpid` (GLIBC_2.39, from Rust
# std's spawn path) and GLIBCXX_3.4.32. The image ran debian:bookworm-slim,
# which ships glibc 2.36 and libstdc++ 12 — so rift, fff and lame could not
# load and the server refused to boot.
#
# These two values are what the RUNTIME BASE IMAGE below provides.
# verify_natives.sh fails a Linux bundle whose libraries need anything newer, so
# a builder/runtime mismatch is a red packaging step instead of an operator's
# boot. To raise them, raise the base image first — never the other way round.
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
