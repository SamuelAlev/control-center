#!/usr/bin/env bash
#
# Builds the tree-sitter runtime (libtree-sitter) and the per-language grammar
# libs the code indexer uses, then installs them where GrammarManager resolves
# them: the grammars/ dir beside control_center.db (see GrammarManager.resolve
# — that dir is searched first).
#
# REQUIRED, runtime AND every grammar: cc_server's boot preflight resolves each
# one by name and refuses to start on a miss and the indexer throws rather than
# skipping a language — the extension->language registry (code_languages.dart)
# and the grammar set built here are the SAME list, so an unresolvable language
# is always a broken install, never finite coverage. A release bundles the libs
# (macOS Contents/Frameworks/, Linux bundle/lib/, Windows beside the .exe) — see
# scripts/release/*. The Windows runtime DLL needs cmake for symbol export; this
# script targets macOS/Linux (see scripts/release/windows_natives.sh).
#
# The grammar lib filename + entrypoint must match the indexer's languageId
# (lib/core/infrastructure/code_index/code_languages.dart):
#   libtree-sitter-<languageId>.<ext>  exports  tree_sitter_<languageId>
# (the packages/cc_natives path is code_index/code_languages.dart)
#
# Source/refs (override the matching *_REF env to iterate or bump; pins live in
# scripts/lib/native_pins.env): TREE_SITTER_REF and TS_<LANG>_REF.
#
# Requirements: git, a C compiler (cc/clang/gcc); a C++ compiler (c++) only when
# a grammar ships a C++ scanner (scanner.cc).
#
# Usage:
#   scripts/natives/build_tree_sitter.sh [DEST_DIR]   # DEST defaults to <app-support>/grammars
set -euo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$REPO_ROOT/scripts/natives/lib/natives_common.sh"

# Pinned commits for reproducible builds (override via the matching *_REF env).
# Pins (runtime + every grammar) come from scripts/lib/native_pins.env,
# where Renovate keeps the runtime and grammars in ABI lockstep. An env
# override still wins, for one-off bisects.
load_native_pins

native_detect_platform
CC="${CC:-cc}"
require_cmd "$CC" "Install Xcode Command Line Tools (macOS) or build-essential/clang (Linux) and re-run."

# Explicit DEST installs flat (CI stages into build/natives for the bundle);
# otherwise install into the grammars/ dir beside control_center.db, where
# GrammarManager looks.
if [ -n "${1:-}" ]; then
  DEST="$1"
else
  DEST="$(native_support_root)/grammars"
fi
log "Installing grammars into: $DEST"
mkdir -p "$DEST"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

log "Building libtree-sitter ($NATIVE_EXT)"
git_clone_pinned "$TREE_SITTER_REPO" "$TREE_SITTER_REF" "$WORK/tree-sitter"
"$CC" -O2 -fPIC -shared \
  -I "$WORK/tree-sitter/lib/include" \
  -I "$WORK/tree-sitter/lib/src" \
  "$WORK/tree-sitter/lib/src/lib.c" \
  "${NATIVE_SONAME}libtree-sitter.$NATIVE_EXT" \
  -o "$DEST/libtree-sitter.$NATIVE_EXT"
native_adhoc_sign "$DEST/libtree-sitter.$NATIVE_EXT"

# build_grammar <languageId> <repo-url> <ref> <src-subdir>
build_grammar() {
  local name="$1" repo="$2" ref="$3" subdir="$4"
  local dir="$WORK/g-$name"
  log "Building tree-sitter-$name ($NATIVE_EXT)"
  [ -d "$dir" ] || git_clone_pinned "$repo" "$ref" "$dir"
  local src="$dir/$subdir"
  if [ ! -f "$src/parser.c" ]; then
    warn "parser.c not at $src — skipping $name (grammar layout changed?)"
    return 0
  fi
  local compiler="$CC"
  local srcs="$src/parser.c"
  [ -f "$src/scanner.c" ] && srcs="$srcs $src/scanner.c"
  if [ -f "$src/scanner.cc" ]; then
    srcs="$srcs $src/scanner.cc"
    compiler="${CXX:-c++}"
  fi
  # shellcheck disable=SC2086
  "$compiler" -O2 -fPIC -shared -I "$src" $srcs \
    "${NATIVE_SONAME}libtree-sitter-$name.$NATIVE_EXT" \
    -o "$DEST/libtree-sitter-$name.$NATIVE_EXT"
  native_adhoc_sign "$DEST/libtree-sitter-$name.$NATIVE_EXT"
}

build_grammar dart       https://github.com/UserNobody14/tree-sitter-dart.git           "$TS_DART_REF"       src
build_grammar javascript https://github.com/tree-sitter/tree-sitter-javascript.git      "$TS_JAVASCRIPT_REF" src
build_grammar typescript https://github.com/tree-sitter/tree-sitter-typescript.git      "$TS_TYPESCRIPT_REF" typescript/src
build_grammar tsx        https://github.com/tree-sitter/tree-sitter-typescript.git      "$TS_TYPESCRIPT_REF" tsx/src
build_grammar php        https://github.com/tree-sitter/tree-sitter-php.git              "$TS_PHP_REF"        php/src
build_grammar python     https://github.com/tree-sitter/tree-sitter-python.git          "$TS_PYTHON_REF"     src
build_grammar rust       https://github.com/tree-sitter/tree-sitter-rust.git            "$TS_RUST_REF"       src
build_grammar zig        https://github.com/tree-sitter-grammars/tree-sitter-zig.git    "$TS_ZIG_REF"        src
build_grammar c          https://github.com/tree-sitter/tree-sitter-c.git               "$TS_C_REF"          src
build_grammar cpp        https://github.com/tree-sitter/tree-sitter-cpp.git             "$TS_CPP_REF"        src
build_grammar go         https://github.com/tree-sitter/tree-sitter-go.git              "$TS_GO_REF"         src
build_grammar java       https://github.com/tree-sitter/tree-sitter-java.git            "$TS_JAVA_REF"       src
build_grammar ruby       https://github.com/tree-sitter/tree-sitter-ruby.git            "$TS_RUBY_REF"       src
build_grammar c_sharp    https://github.com/tree-sitter/tree-sitter-c-sharp.git         "$TS_C_SHARP_REF"    src
# Swift's release tags omit parser.c; pin the matching *-with-generated-files
# tag (see renovate extractVersionTemplate). Ada has no version tags — master.
build_grammar swift      https://github.com/alex-pinkus/tree-sitter-swift.git           "$TS_SWIFT_REF"      src
build_grammar kotlin     https://github.com/tree-sitter-grammars/tree-sitter-kotlin.git "$TS_KOTLIN_REF"     src
build_grammar r          https://github.com/r-lib/tree-sitter-r.git                     "$TS_R_REF"          src
build_grammar asm        https://github.com/RubixDev/tree-sitter-asm.git                 "$TS_ASM_REF"        src
build_grammar matlab     https://github.com/acristoffers/tree-sitter-matlab.git         "$TS_MATLAB_REF"    src
build_grammar ada        https://github.com/briot/tree-sitter-ada.git                   "$TS_ADA_REF"        src

# Stage the hand-authored `.scm` queries beside the grammar libs. GrammarManager
# resolves a language's query from the same dirs as its lib (see loadQuery), so
# the queries travel with the natives in dev and in release bundles. queryIdFor
# maps tsx → typescript, so those two share one query file.
log "Staging .scm queries into: $DEST"
cp -f "$REPO_ROOT/scripts/natives/queries/"*.scm "$DEST/"

log "Done. Installed:"
ls -la "$DEST"/libtree-sitter*."$NATIVE_EXT" "$DEST"/*.scm
echo "Restart Control Center and re-index a repo to populate the code graph."
