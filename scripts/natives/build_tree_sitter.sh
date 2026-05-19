#!/usr/bin/env bash
#
# Builds the tree-sitter runtime (libtree-sitter) and the per-language grammar
# libs the code indexer uses (Dart, JavaScript, TypeScript, TSX, PHP), then
# installs them where GrammarManager resolves them: the grammars/ dir beside
# control_center.db (see GrammarManager.resolve — that dir is searched first).
#
# Dev/dogfood tooling: the app degrades gracefully when these natives are absent
# (see TreeSitterLoader / GrammarManager); a language whose lib is missing is
# simply skipped. A release bundles the libs (macOS Contents/Frameworks/, Linux
# bundle/lib/, Windows beside the .exe) — see scripts/release/*. The Windows
# runtime DLL needs cmake for symbol export; this script targets macOS/Linux
# (see scripts/release/windows_natives.sh).
#
# The grammar lib filename + entrypoint must match the indexer's languageId
# (lib/core/infrastructure/code_index/code_languages.dart):
#   libtree-sitter-<languageId>.<ext>  exports  tree_sitter_<languageId>
#
# Source/refs (override the matching *_REF env to iterate or bump; keep in sync
# with .github/workflows/release.yml):
#   TREE_SITTER_REF TS_DART_REF TS_JAVASCRIPT_REF TS_TYPESCRIPT_REF TS_PHP_REF
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
TREE_SITTER_REPO="${TREE_SITTER_REPO:-https://github.com/tree-sitter/tree-sitter.git}"
TREE_SITTER_REF="${TREE_SITTER_REF:-7f534862c3ec939c3a6ee147f7600ef5c1bf900f}"     # tree-sitter v0.26.9
TS_DART_REF="${TS_DART_REF:-a9bdfa3db2fbc9b9f12c93450d04a671f33a5102}"             # tree-sitter-dart (master)
TS_JAVASCRIPT_REF="${TS_JAVASCRIPT_REF:-44c892e0be055ac465d5eeddae6d3e194424e7de}" # tree-sitter-javascript v0.25.0
TS_TYPESCRIPT_REF="${TS_TYPESCRIPT_REF:-f975a621f4e7f532fe322e13c4f79495e0a7b2e7}" # tree-sitter-typescript v0.23.2 (typescript + tsx)
TS_PHP_REF="${TS_PHP_REF:-5b5627faaa290d89eb3d01b9bf47c3bb9e797dea}"               # tree-sitter-php v0.24.2

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
  "$NATIVE_SONAME" "libtree-sitter.$NATIVE_EXT" \
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
    "$NATIVE_SONAME" "libtree-sitter-$name.$NATIVE_EXT" \
    -o "$DEST/libtree-sitter-$name.$NATIVE_EXT"
  native_adhoc_sign "$DEST/libtree-sitter-$name.$NATIVE_EXT"
}

build_grammar dart       https://github.com/UserNobody14/tree-sitter-dart.git      "$TS_DART_REF"       src
build_grammar javascript https://github.com/tree-sitter/tree-sitter-javascript.git "$TS_JAVASCRIPT_REF" src
build_grammar typescript https://github.com/tree-sitter/tree-sitter-typescript.git "$TS_TYPESCRIPT_REF" typescript/src
build_grammar tsx        https://github.com/tree-sitter/tree-sitter-typescript.git "$TS_TYPESCRIPT_REF" tsx/src
build_grammar php        https://github.com/tree-sitter/tree-sitter-php.git         "$TS_PHP_REF"        php/src

# Stage the hand-authored `.scm` queries beside the grammar libs. GrammarManager
# resolves a language's query from the same dirs as its lib (see loadQuery), so
# the queries travel with the natives in dev and in release bundles. queryIdFor
# maps tsx → typescript, so only 4 query ids ship (dart/javascript/typescript/php).
log "Staging .scm queries into: $DEST"
cp -f "$REPO_ROOT/scripts/natives/queries/"*.scm "$DEST/"

log "Done. Installed:"
ls -la "$DEST"/libtree-sitter*."$NATIVE_EXT" "$DEST"/*.scm
echo "Restart Control Center and re-index a repo to populate the code graph."
