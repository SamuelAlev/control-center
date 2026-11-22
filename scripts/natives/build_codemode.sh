#!/usr/bin/env bash
#
# Builds cc_codemode (code mode's locked-down JavaScript runner; REQUIRED).
# First-party cargo workspace. Installs the executable to
# <support_root>/codemode/cc_codemode and, given DEST_DIR, to
# DEST_DIR/codemode/cc_codemode, then proves the lockdown on each installed
# copy with `cc_codemode --self-test`. A failed self-test fails the build.
# Usage: scripts/natives/build_codemode.sh [DEST_DIR]
#
set -euo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$REPO_ROOT/scripts/natives/lib/natives_common.sh"
source "$REPO_ROOT/scripts/lib/codemode.sh"

DEST="${1:-}"
CRATE_DIR="$REPO_ROOT/packages/cc_natives/native/codemode"

case "$(uname -s)" in
  Darwin | Linux) ;;
  *)
    die "build_codemode.sh does not support $(uname -s). Windows natives are built by scripts/release/windows_natives.sh." ;;
esac
native_detect_platform
require_cmd cargo "Install Rust via https://rustup.rs/ and re-run."
[ -f "$CRATE_DIR/Cargo.toml" ] || die "codemode crate not found: $CRATE_DIR"

# NOT the crate-local `target/`: the repo-root build/ dir is gitignored and
# excluded from analysis.
export CARGO_TARGET_DIR="$REPO_ROOT/build/cargo/codemode"
native_cargo_darwin_strip

# Reproducible paths: the executable keeps source paths for panic locations
# and QuickJS-NG's assertions, and without remapping they name the builder's
# home directory (the cargo registry), the checkout and the target directory.
# Each prefix is rewritten for Rust (--remap-path-prefix) and for the C code
# (-ffile-prefix-map); codemode_check_paths below fails the build if one
# survives. Later entries win where prefixes nest (the cargo home inside the
# home directory), for rustc and the C compiler alike. The flags travel as CARGO_ENCODED_RUSTFLAGS (one argument per
# field), so a path with spaces stays one argument; it carries RUSTFLAGS
# along, which cargo would otherwise ignore beside it.
CODEMODE_CARGO_HOME="${CARGO_HOME:-$HOME/.cargo}"
CODEMODE_REMAPS=(
  "$HOME=/build/home"
  "$CODEMODE_CARGO_HOME=/build/cargo"
  "$REPO_ROOT=/build/src"
  "$CARGO_TARGET_DIR=/build/target"
)
CODEMODE_RUSTFLAGS=()
read -r -a CODEMODE_RUSTFLAGS <<<"${RUSTFLAGS:-}"
for remap in "${CODEMODE_REMAPS[@]}"; do
  CODEMODE_RUSTFLAGS+=("--remap-path-prefix=$remap")
done
CARGO_ENCODED_RUSTFLAGS="$(IFS=$'\x1f'; printf '%s' "${CODEMODE_RUSTFLAGS[*]}")"
export CARGO_ENCODED_RUSTFLAGS
unset RUSTFLAGS

# Hardening for QuickJS-NG, the runner's C code: stack protector and
# fortified libc calls everywhere; on Linux also the control-flow flags (CET
# on x86_64, BTI and return-address signing on aarch64), of which only
# return-address signing is in force (see codemode_check_hardening).
# rquickjs-sys compiles it with the cc crate, which reads CFLAGS_<target>;
# the Windows equivalent is in scripts/release/windows_natives.sh. QuickJS's assertions
# stay on (NDEBUG is not defined); PROVENANCE.md says why.
TRIPLE="$(rustc -vV | sed -n 's/^host: //p')"
[ -n "$TRIPLE" ] || die "rustc -vV did not report a host triple"
CODEMODE_CFLAGS="-fstack-protector-strong -U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=2"
case "$TRIPLE" in
  x86_64-unknown-linux-gnu) CODEMODE_CFLAGS+=" -fcf-protection=full" ;;
  aarch64-unknown-linux-gnu) CODEMODE_CFLAGS+=" -mbranch-protection=standard" ;;
  aarch64-apple-darwin) ;;
  *) die "build_codemode.sh has no hardening flags for $TRIPLE" ;;
esac
for remap in "${CODEMODE_REMAPS[@]}"; do
  CODEMODE_CFLAGS+=" -ffile-prefix-map=$remap"
done
export "CFLAGS_${TRIPLE//-/_}=$CODEMODE_CFLAGS"

log "Building cc_codemode (cargo, release) for $NATIVE_OS ($TRIPLE)"
cargo build --release --locked --manifest-path "$CRATE_DIR/Cargo.toml" -p cc_codemode

BUILT="$CARGO_TARGET_DIR/release/cc_codemode"
[ -x "$BUILT" ] || die "cargo build succeeded but $BUILT is missing"

# Proves the flags reached the C objects that were linked. The objects are
# checked: the executable carries no CET or BTI property, because Rust's own
# objects are not marked (stable Rust has no flag for it) and the linker keeps
# the property only when every object has it. So IBT and BTI landing pads in
# QuickJS-NG are inert: no loader enforces them for this executable.
# What is in force: the stack protector and the fortified calls everywhere,
# and on aarch64 Linux return-address signing (PAC), which works per
# function without any property. README.md ("Build hardening") has the
# per-platform account.
codemode_check_hardening() {
  local obj undefined notes
  # Cargo has used both build/rquickjs-sys-<hash>/out and (1.100)
  # build/rquickjs-sys/<hash>/out; the newest object is the one linked.
  obj="$(find "$CARGO_TARGET_DIR/release/build" -path '*/rquickjs-sys*/out/*-quickjs.o' -exec ls -t {} + 2>/dev/null | head -1)"
  [ -n "$obj" ] || die "no compiled quickjs.o under $CARGO_TARGET_DIR/release/build"
  undefined="$(nm -u "$obj")"
  grep -q '__stack_chk_fail' <<<"$undefined" \
    || die "quickjs.o has no stack protector (no __stack_chk_fail reference): $obj"
  case "$TRIPLE" in
    *-linux-gnu)
      # glibc keeps every fortified snprintf as a __snprintf_chk call. On
      # macOS clang folds QuickJS's calls back to the plain ones (their
      # destination sizes are unknown), so there is nothing to see there.
      grep -Eq '__(snprintf|vsnprintf|memcpy|memmove|memset)_chk' <<<"$undefined" \
        || die "quickjs.o has no fortified libc calls: $obj" ;;
  esac
  case "$TRIPLE" in
    x86_64-unknown-linux-gnu)
      notes="$(readelf -n "$obj")"
      grep -q 'x86 feature: IBT, SHSTK' <<<"$notes" \
        || die "quickjs.o is not marked for IBT and SHSTK: $obj" ;;
    aarch64-unknown-linux-gnu)
      notes="$(readelf -n "$obj")"
      grep -q 'AArch64 feature: BTI, PAC' <<<"$notes" \
        || die "quickjs.o is not marked for BTI and PAC: $obj" ;;
  esac
  echo "  - hardening present in $obj"
}
codemode_check_hardening

# Fails when the executable still names a build path: the remapping above
# did not reach some path. The same check (scripts/lib/codemode.sh) runs
# again whenever a runner is staged or packaged; here it also knows the
# target directory and the cargo home this build used.
case "$NATIVE_OS" in
  Darwin) CODEMODE_OS=macos ;;
  *) CODEMODE_OS=linux ;;
esac
cc_codemode_check_paths "$BUILT" "$CODEMODE_OS" "$CARGO_TARGET_DIR" "$CODEMODE_CARGO_HOME"
echo "  - no build paths in $BUILT"

dests=("$(native_support_root)/codemode")
[ -n "$DEST" ] && dests+=("$DEST/codemode")

for d in "${dests[@]}"; do
  mkdir -p "$d"
  cp -f "$BUILT" "$d/cc_codemode"
  chmod +x "$d/cc_codemode"
  native_adhoc_sign "$d/cc_codemode"
  echo "  - $d/cc_codemode"
  # The staging gate: version, self-test with a full lockdown, a release
  # build, no build paths. Its output goes to a pipe, never a file (the
  # lockdown sets a zero file-size limit).
  cc_codemode_verify "$d" "$CODEMODE_OS"
done

log "Done. Installed cc_codemode ($(du -h "$BUILT" | cut -f1)) to ${#dests[@]} location(s)."
