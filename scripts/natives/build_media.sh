#!/usr/bin/env bash
# Stage checksum-pinned FFmpeg/FFprobe and PDFium; compile our PDF and SVG helpers.
# Usage: bash scripts/natives/build_media.sh [DEST_DIR] [x64|arm64 (Windows)]
set -euo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$REPO_ROOT/scripts/lib/common.sh"
load_native_pins
case "${FFMPEG_MEDIA_MAC_BUILD:?}" in
  *"_${FFMPEG_MEDIA_VERSION:?}") ;;
  *) die "macOS FFmpeg release does not match FFMPEG_MEDIA_VERSION" ;;
esac
case "${FFMPEG_MEDIA_BTBN_BUILD:?}" in
  "n${FFMPEG_MEDIA_VERSION}-"*) ;;
  *) die "BtbN FFmpeg build does not match FFMPEG_MEDIA_VERSION" ;;
esac

OS="$(cc_platform)"
DEST="${1:-$REPO_ROOT/build/natives}"
mkdir -p "$DEST"
DEST="$(cd "$DEST" && pwd)/media"
mkdir -p "$DEST"
WORK="${RUNNER_TEMP:-$REPO_ROOT/build}/cc-media"
mkdir -p "$WORK"

case "$OS" in
  macos)
    [ "$(uname -m)" = arm64 ] || die "media binaries require native macOS arm64"
    export MACOSX_DEPLOYMENT_TARGET=13.0
    PLATFORM=mac-arm64
    PDF_LIB=libpdfium.dylib
    SUFFIX= ;;
  linux)
    [ "$(uname -m)" = x86_64 ] || die "media binaries require native Linux x64"
    PLATFORM=linux-x64
    PDF_LIB=libpdfium.so
    SUFFIX= ;;
  windows)
    ARCH="$(cc_windows_arch "${2:-${VSCMD_ARG_TGT_ARCH:-x64}}")"
    [ "${VSCMD_ARG_TGT_ARCH:-}" = "$ARCH" ] || die "MSVC target must be $ARCH (run vcvarsall for $ARCH)"
    PLATFORM=win-$ARCH
    PDF_LIB=pdfium.dll
    SUFFIX=.exe
    # RUNNER_TEMP is a drive path (D:\a\_temp). Git Bash's GNU tar reads the
    # "D:" of `tar xf D:\...` as a remote host ("Cannot connect to D: resolve
    # failed"), so every archive path below must be a POSIX /d/... path.
    WORK="$(cygpath -u "$WORK")"
    mkdir -p "$WORK" ;;
esac

# Re-verify cached archives on EVERY invocation. A stale/unverified cache must
# never be accepted just because it has the expected filename.
fetch_media() { # url digest archive
  local url="$1" digest="$2" archive="$3"
  if [ -f "$archive" ] && [ "$(sha256_of "$archive")" = "$digest" ]; then
    log "Using verified $(basename "$archive")"
  else
    fetch_pinned "$url" "$digest" "$archive"
  fi
  sha256_verify "$archive" "$digest"
}

FF_SOURCE_ARCHIVE="$WORK/ffmpeg-source-${FFMPEG_MEDIA_VERSION:?}.tar.xz"
fetch_media "https://ffmpeg.org/releases/ffmpeg-${FFMPEG_MEDIA_VERSION}.tar.xz" \
  "${FFMPEG_MEDIA_SOURCE_SHA256:?}" "$FF_SOURCE_ARCHIVE"
FF_BUILD= FF_SHA=
case "$PLATFORM" in
  mac-arm64)
    FF_BASE="https://ffmpeg.martin-riedl.de/download/macos/arm64/${FFMPEG_MEDIA_MAC_BUILD:?}"
    FF_ARCHIVE="$WORK/ffmpeg-mac-${FFMPEG_MEDIA_MAC_BUILD}.zip"
    PROBE_ARCHIVE="$WORK/ffprobe-mac-${FFMPEG_MEDIA_MAC_BUILD}.zip"
    fetch_media "$FF_BASE/ffmpeg.zip" "${FFMPEG_MEDIA_SHA256_MAC_FFMPEG:?}" "$FF_ARCHIVE"
    fetch_media "$FF_BASE/ffprobe.zip" "${FFMPEG_MEDIA_SHA256_MAC_FFPROBE:?}" "$PROBE_ARCHIVE" ;;
  *)
    case "$PLATFORM" in
      linux-x64) FF_TARGET=linux64; FF_SHA="${FFMPEG_MEDIA_SHA256_LINUX_X64:?}"; FF_EXT=tar.xz ;;
      win-x64) FF_TARGET=win64; FF_SHA="${FFMPEG_MEDIA_SHA256_WIN_X64:?}"; FF_EXT=zip ;;
      win-arm64) FF_TARGET=winarm64; FF_SHA="${FFMPEG_MEDIA_SHA256_WIN_ARM64:?}"; FF_EXT=zip ;;
    esac
    FF_BUILD="ffmpeg-${FFMPEG_MEDIA_BTBN_BUILD:?}-$FF_TARGET-gpl-9.0"
    FF_BASE="https://github.com/BtbN/FFmpeg-Builds/releases/download/${FFMPEG_MEDIA_BTBN_RELEASE:?}"
    FF_ARCHIVE="$WORK/$FF_BUILD.$FF_EXT"
    fetch_media "$FF_BASE/$FF_BUILD.$FF_EXT" "$FF_SHA" "$FF_ARCHIVE" ;;
esac
PDF_ARCHIVE="$WORK/pdfium-${PDFIUM_MEDIA_VERSION:?}-$PLATFORM.tgz"
case "$PLATFORM" in
  mac-arm64) PDF_SHA="${PDFIUM_MEDIA_SHA256_MAC_ARM64:?}" ;;
  linux-x64) PDF_SHA="${PDFIUM_MEDIA_SHA256_LINUX_X64:?}" ;;
  win-x64) PDF_SHA="${PDFIUM_MEDIA_SHA256_WIN_X64:?}" ;;
  win-arm64) PDF_SHA="${PDFIUM_MEDIA_SHA256_WIN_ARM64:?}" ;;
esac
fetch_media "https://github.com/bblanchon/pdfium-binaries/releases/download/chromium/${PDFIUM_MEDIA_VERSION}/pdfium-$PLATFORM.tgz" \
  "$PDF_SHA" "$PDF_ARCHIVE"

# Extract the verified archives into fresh, disposable directories. Only the
# publisher's actual binaries are staged; no local FFmpeg/zlib build is allowed.
FF_SOURCE="$WORK/ffmpeg-${FFMPEG_MEDIA_VERSION}"
FF_EXTRACT="$WORK/ffmpeg-prebuilt-$PLATFORM"
PDF_SOURCE="$WORK/pdfium-$PLATFORM"
rm -rf "$FF_SOURCE" "$FF_EXTRACT" "$PDF_SOURCE"
mkdir -p "$FF_EXTRACT" "$PDF_SOURCE"
tar xJf "$FF_SOURCE_ARCHIVE" -C "$WORK" \
  "ffmpeg-${FFMPEG_MEDIA_VERSION}/LICENSE.md" \
  "ffmpeg-${FFMPEG_MEDIA_VERSION}/COPYING.GPLv3" \
  "ffmpeg-${FFMPEG_MEDIA_VERSION}/COPYING.LGPLv2.1" \
  "ffmpeg-${FFMPEG_MEDIA_VERSION}/COPYING.LGPLv3"
tar xzf "$PDF_ARCHIVE" -C "$PDF_SOURCE"
if [ "$OS" = macos ]; then
  unzip -oq "$FF_ARCHIVE" -d "$FF_EXTRACT"
  unzip -oq "$PROBE_ARCHIVE" -d "$FF_EXTRACT"
else
  case "$OS" in
    windows) unzip -oq "$FF_ARCHIVE" -d "$FF_EXTRACT" ;;
    linux) tar xJf "$FF_ARCHIVE" -C "$FF_EXTRACT" ;;
  esac
  [ -s "$FF_EXTRACT/$FF_BUILD/LICENSE.txt" ] || die "BtbN GPLv3 notice missing"
fi
[ -s "$FF_SOURCE/LICENSE.md" ] && [ -s "$FF_SOURCE/COPYING.GPLv3" ] \
  || die "FFmpeg source notices missing"
[ -f "$FF_EXTRACT/${FF_BUILD:+$FF_BUILD/bin/}ffmpeg$SUFFIX" ] \
  || die "prebuilt FFmpeg archive layout changed"
[ -f "$FF_EXTRACT/${FF_BUILD:+$FF_BUILD/bin/}ffprobe$SUFFIX" ] \
  || die "prebuilt FFprobe archive layout changed"
[ -f "$PDF_SOURCE/include/fpdfview.h" ] || die "PDFium headers missing"
case "$OS" in
  windows) [ -f "$PDF_SOURCE/bin/$PDF_LIB" ] && [ -f "$PDF_SOURCE/lib/pdfium.dll.lib" ] || die "PDFium Windows DLL/import library missing" ;;
  *) [ -f "$PDF_SOURCE/lib/$PDF_LIB" ] || die "PDFium shared library missing" ;;
esac
[ -f "$PDF_SOURCE/LICENSE" ] || die "PDFium license missing"
# The releases ship FFmpeg's dependency libraries statically inside ffmpeg and
# ffprobe; PDFium's sole shared library stays next to our locally built helper.
for tool in ffmpeg ffprobe; do
  cp -f "$FF_EXTRACT/${FF_BUILD:+$FF_BUILD/bin/}$tool$SUFFIX" "$DEST/$tool$SUFFIX"
  chmod +x "$DEST/$tool$SUFFIX"
done
# zlib is statically linked by each publisher, not a separately staged DLL.
# Match the actual zlib version string embedded in the checksum-pinned binary;
# the BtbN build uses a downstream 1.3.2.1-motley revision.
if [ "$OS" = macos ]; then
  Z_BUNDLED_VERSION="$ZLIB_MEDIA_VERSION"
else
  Z_BUNDLED_VERSION="$ZLIB_MEDIA_BTBN_VERSION"
fi
LC_ALL=C grep -aFq "$Z_BUNDLED_VERSION" "$DEST/ffmpeg$SUFFIX" \
  || die "prebuilt FFmpeg does not contain expected bundled zlib $Z_BUNDLED_VERSION"

case "$OS" in
  windows)
    cp -f "$PDF_SOURCE/bin/$PDF_LIB" "$DEST/$PDF_LIB"
    # cl and link must be the target's MSVC tools, never Git Bash's link.exe.
    require_cmd cl "Set up the $ARCH MSVC developer environment."
    require_cmd link "Set up the $ARCH MSVC developer environment."
    [ "$(dirname "$(command -v cl)")" = "$(dirname "$(command -v link)")" ] \
      || die "link.exe is not the MSVC linker (Git Bash may shadow it)"
    SRC="$(cygpath -w "$REPO_ROOT/packages/cc_natives/native/media/cc_pdf_render.cc")"
    OUT="$(cygpath -w "$DEST/cc_pdf_render.exe")"
    INC="$(cygpath -w "$PDF_SOURCE/include")"
    IMPORT="$(cygpath -w "$PDF_SOURCE/lib/pdfium.dll.lib")"
    OBJ="$(cygpath -w "$WORK/cc_pdf_render-$ARCH.obj")"
    cl //nologo //O2 //MT //EHsc //std:c++17 //I"$INC" "$SRC" \
      //Fo"$OBJ" //Fe"$OUT" //link "$IMPORT"
    for exe in ffmpeg.exe ffprobe.exe cc_pdf_render.exe pdfium.dll; do
      [ "$(pe_machine "$DEST/$exe")" = "$ARCH" ] || die "$exe is not a $ARCH PE image"
    done ;;
  macos)
    cp -f "$PDF_SOURCE/lib/$PDF_LIB" "$DEST/$PDF_LIB"
    install_name_tool -id @rpath/libpdfium.dylib "$DEST/$PDF_LIB"
    clang++ -O2 -std=c++17 -mmacosx-version-min=13.0 -I"$PDF_SOURCE/include" \
      "$REPO_ROOT/packages/cc_natives/native/media/cc_pdf_render.cc" \
      -L"$DEST" -lpdfium '-Wl,-rpath,@executable_path' -o "$DEST/cc_pdf_render"
    for exe in ffmpeg ffprobe cc_pdf_render libpdfium.dylib; do
      codesign --force --sign - "$DEST/$exe" >/dev/null
    done ;;
  linux)
    cp -f "$PDF_SOURCE/lib/$PDF_LIB" "$DEST/$PDF_LIB"
    c++ -O2 -std=c++17 -I"$PDF_SOURCE/include" \
      "$REPO_ROOT/packages/cc_natives/native/media/cc_pdf_render.cc" \
      -L"$DEST" -lpdfium '-Wl,-rpath,$ORIGIN' -o "$DEST/cc_pdf_render" ;;
esac

# All four target architectures build the same first-party wrapper against
# exactly the resvg/usvg versions and transitive checksums in Cargo.lock.
require_cmd cargo "Install Rust via https://rustup.rs/ and re-run."
SVG_CRATE="$REPO_ROOT/packages/cc_natives/native/media/svg"
export CARGO_TARGET_DIR="$REPO_ROOT/build/cargo/svg"
if [ "$OS" = windows ]; then
  export RUSTFLAGS="${RUSTFLAGS:-} -Ctarget-feature=+crt-static"
fi
cargo build --release --locked --manifest-path "$SVG_CRATE/Cargo.toml"
[ -s "$CARGO_TARGET_DIR/release/cc_svg_render$SUFFIX" ] || die "SVG helper missing after cargo build"
cp -f "$CARGO_TARGET_DIR/release/cc_svg_render$SUFFIX" "$DEST/cc_svg_render$SUFFIX"
chmod +x "$DEST/cc_svg_render$SUFFIX"
mkdir -p "$DEST/fonts"
cp -f "$REPO_ROOT/packages/cc_ui/fonts/Manrope-Variable.ttf" "$DEST/fonts/"
cp -f "$REPO_ROOT/packages/cc_ui/fonts/FiraCode-VF.ttf" "$DEST/fonts/"
cp -f "$REPO_ROOT/third_party/licenses/manrope-font-LICENSE.txt" "$DEST/fonts/"
cp -f "$REPO_ROOT/third_party/licenses/firacode-font-LICENSE.txt" "$DEST/fonts/"

# Fetch every locked target dependency (including architecture-specific crates)
# before copying its checksum-verified Cargo source notices into the bundle.
cargo fetch --locked --manifest-path "$SVG_CRATE/Cargo.toml"
rm -rf "$DEST/svg-licenses"
mkdir -p "$DEST/svg-licenses"
svg_notice_package() { # name version source
  local name="$1" version="$2" source="$3" source_dir= candidate found=0
  local cargo_home="${CARGO_HOME:-$HOME/.cargo}"
  # GitHub's Windows images export CARGO_HOME as C:\Users\...\.cargo; glob
  # through the POSIX form so backslashes never reach the pattern.
  [ "$OS" = windows ] && cargo_home="$(cygpath -u "$cargo_home")"
  [ "$source" = "registry+https://github.com/rust-lang/crates.io-index" ] \
    || die "unrecognized SVG dependency source for $name $version: $source"
  for candidate in "$cargo_home"/registry/src/*/"$name-$version"; do
    [ -s "$candidate/Cargo.toml" ] && { source_dir="$candidate"; break; }
  done
  [ -n "$source_dir" ] || die "Cargo source missing for $name $version"
  mkdir -p "$DEST/svg-licenses/$name-$version"
  cp -f "$source_dir/Cargo.toml" "$DEST/svg-licenses/$name-$version/Cargo.toml"
  for candidate in "$source_dir"/LICENSE* "$source_dir"/LICENCE* \
    "$source_dir"/COPYING* "$source_dir"/NOTICE* "$source_dir"/COPYRIGHT*; do
    [ -s "$candidate" ] || continue
    cp -f "$candidate" "$DEST/svg-licenses/$name-$version/${candidate##*/}"
    found=1
  done
  [ "$found" = 1 ] || die "dependency $name $version has no distributable license notice"
}
svg_name= svg_version= svg_source= svg_count=0
while IFS= read -r line; do
  case "$line" in
    '[[package]]')
      if [ -n "$svg_source" ]; then
        svg_notice_package "$svg_name" "$svg_version" "$svg_source"
        svg_count=$((svg_count + 1))
      fi
      svg_name= svg_version= svg_source= ;;
    'name = "'*) svg_name="${line#*\"}"; svg_name="${svg_name%%\"*}" ;;
    'version = "'*) svg_version="${line#*\"}"; svg_version="${svg_version%%\"*}" ;;
    'source = "'*) svg_source="${line#*\"}"; svg_source="${svg_source%%\"*}" ;;
  esac
done < "$SVG_CRATE/Cargo.lock"
if [ -n "$svg_source" ]; then
  svg_notice_package "$svg_name" "$svg_version" "$svg_source"
  svg_count=$((svg_count + 1))
fi
[ "$svg_count" -gt 1 ] || die "SVG Cargo.lock has no dependency notices"
cp -f "$DEST/svg-licenses/resvg-0.48.1/LICENSE-MIT" "$DEST/resvg-LICENSE-MIT.txt"
cp -f "$DEST/svg-licenses/resvg-0.48.1/LICENSE-APACHE" "$DEST/resvg-LICENSE-APACHE.txt"
cp -f "$SVG_CRATE/Cargo.lock" "$DEST/resvg-Cargo.lock"
{
  printf 'cc_svg_render: application-owned wrapper, source packages/cc_natives/native/media/svg/src/main.rs\n'
  printf 'resvg/usvg 0.48.1: https://github.com/linebender/resvg/tree/v0.48.1\n'
  printf 'Exact Rust dependency versions and registry checksums: resvg-Cargo.lock (packages/cc_natives/native/media/svg/Cargo.lock)\n'
  printf 'Dual license: Apache-2.0 OR MIT; upstream texts resvg-LICENSE-APACHE.txt and resvg-LICENSE-MIT.txt.\n'
  printf 'All %s locked registry crates have Cargo.toml metadata and actual upstream LICENSE/COPYING/NOTICE/COPYRIGHT files in svg-licenses/<crate-version>/.\n' "$svg_count"
} > "$DEST/resvg-SOURCE.txt"
if [ "$OS" = windows ]; then
  [ "$(pe_machine "$DEST/cc_svg_render.exe")" = "$ARCH" ] || die "cc_svg_render.exe is not a $ARCH PE image"
elif [ "$OS" = macos ]; then
  codesign --force --sign - "$DEST/cc_svg_render" >/dev/null
fi

# Keep the publisher's GPLv3 text (BtbN) and upstream FFmpeg/PDFium
# notices next to the executables in dev and release distributions.
cp -f "$PDF_SOURCE/LICENSE" "$DEST/pdfium-LICENSE.txt"
rm -rf "$DEST/pdfium-licenses"
cp -R "$PDF_SOURCE/licenses" "$DEST/pdfium-licenses"
cp -f "$FF_SOURCE/COPYING.GPLv3" "$DEST/ffmpeg-GPL-3.0.txt"
cp -f "$FF_SOURCE/COPYING.LGPLv2.1" "$DEST/ffmpeg-LGPL-2.1.txt"
cp -f "$FF_SOURCE/COPYING.LGPLv3" "$DEST/ffmpeg-LGPL-3.0.txt"
cp -f "$FF_SOURCE/LICENSE.md" "$DEST/ffmpeg-LICENSE.txt"
rm -f "$DEST/zlib-LICENSE.txt" "$DEST/ffmpeg-publisher-LICENSE.txt"
if [ "$OS" != macos ]; then
  cp -f "$FF_EXTRACT/$FF_BUILD/LICENSE.txt" "$DEST/ffmpeg-publisher-LICENSE.txt"
fi
{
  printf 'FFmpeg %s (separate GPLv3 command-line programs)\n' "$FFMPEG_MEDIA_VERSION"
  printf 'Publisher archive: %s/%s (SHA-256 %s)\n' "$FF_BASE" "$(basename "$FF_ARCHIVE")" \
    "${FF_SHA:-$FFMPEG_MEDIA_SHA256_MAC_FFMPEG}"
  if [ "$OS" = macos ]; then
    printf 'Publisher ffprobe archive: %s/%s (SHA-256 %s)\n' "$FF_BASE" "$(basename "$PROBE_ARCHIVE")" \
      "$FFMPEG_MEDIA_SHA256_MAC_FFPROBE"
    printf 'Publisher historical build recipe (version-matched, not attested by ZIP): https://git.martin-riedl.de/ffmpeg/build-script/src/commit/%s\n' \
      "$FFMPEG_MEDIA_MAC_RECIPE_COMMIT"
    printf 'Publisher component versions: %s/versions.txt\n' "$FF_BASE"
    printf 'Publisher-reported zlib: %s\n' "$ZLIB_MEDIA_VERSION"
    printf 'Bundled zlib version upstream source: https://github.com/madler/zlib/tree/v%s\n' \
      "$ZLIB_MEDIA_VERSION"
    printf 'The publisher ZIPs contain executables only; GPLv3 and FFmpeg notices here come from the checksum-pinned upstream source archive.\n'
  else
    printf 'Publisher release: https://github.com/BtbN/FFmpeg-Builds/releases/tag/%s\n' \
      "$FFMPEG_MEDIA_BTBN_RELEASE"
    printf 'Publisher build recipe: https://github.com/BtbN/FFmpeg-Builds/tree/%s\n' \
      "$FFMPEG_MEDIA_BTBN_RECIPE_COMMIT"
    printf 'Publisher FFmpeg checkout: %s (9.0 release branch)\n' "$FFMPEG_MEDIA_BTBN_BUILD"
    printf 'Publisher FFmpeg source checkout: https://github.com/FFmpeg/FFmpeg/tree/%s\n' \
      "$FFMPEG_MEDIA_BTBN_SOURCE_COMMIT"
    printf 'Publisher zlib recipe: https://github.com/BtbN/FFmpeg-Builds/blob/%s/scripts.d/20-zlib.sh\n' \
      "$FFMPEG_MEDIA_BTBN_RECIPE_COMMIT"
    printf 'Publisher zlib checkout: https://github.com/madler/zlib/tree/767c4c947852e143f582c85f14cf573411df1b35 (zlib.h: %s)\n' \
      "$ZLIB_MEDIA_BTBN_VERSION"
  fi
  printf 'Upstream FFmpeg %s LICENSE/COPYING notices: https://ffmpeg.org/releases/ffmpeg-%s.tar.xz (SHA-256 %s)\n' \
    "$FFMPEG_MEDIA_VERSION" "$FFMPEG_MEDIA_VERSION" "$FFMPEG_MEDIA_SOURCE_SHA256"
  printf 'PDFium: https://github.com/bblanchon/pdfium-binaries/releases/tag/chromium%%2F%s (SHA-256 %s)\n' \
    "$PDFIUM_MEDIA_VERSION" "$PDF_SHA"
  printf 'Builds link additional third-party libraries; publisher recipes and version metadata identify sources. The publisher archives do not include complete dependency source and license sets.\n'
} > "$DEST/ffmpeg-SOURCE.txt"

if [ "$OS" = windows ]; then
  # Standalone server's default in CcServerConfig._defaultDataDir. Desktop
  # launchers with a different app-support root can pass CC_SERVER_DATA_DIR.
  DATA_ROOT="${CC_SERVER_DATA_DIR:-}"
  if [ -z "$DATA_ROOT" ]; then
    DATA_BASE="${APPDATA:-${LOCALAPPDATA:-}}"
    [ -n "$DATA_BASE" ] || die "set CC_SERVER_DATA_DIR or APPDATA for the dev media install"
    DATA_ROOT="$DATA_BASE/control-center"
  fi
  SUPPORT="$(cygpath -u "$DATA_ROOT")/media"
else
  source "$REPO_ROOT/scripts/natives/lib/natives_common.sh"
  native_detect_platform
  SUPPORT="$(native_support_root)/media"
fi
if [ "$SUPPORT" != "$DEST" ]; then
  mkdir -p "$SUPPORT"
  rm -f "$SUPPORT/zlib-LICENSE.txt"
  cp -f "$DEST/ffmpeg$SUFFIX" "$DEST/ffprobe$SUFFIX" \
    "$DEST/cc_pdf_render$SUFFIX" "$DEST/cc_svg_render$SUFFIX" "$DEST/$PDF_LIB" \
    "$DEST/"*-LICENSE.txt "$DEST/"*-LGPL-*.txt "$DEST/ffmpeg-GPL-3.0.txt" \
    "$DEST/ffmpeg-SOURCE.txt" "$DEST/resvg-SOURCE.txt" "$DEST/resvg-Cargo.lock" "$SUPPORT/"
  rm -rf "$SUPPORT/pdfium-licenses"
  cp -R "$DEST/pdfium-licenses" "$SUPPORT/"
  rm -rf "$SUPPORT/svg-licenses"
  cp -R "$DEST/svg-licenses" "$SUPPORT/"
  if [ "$OS" = macos ]; then
    for tool in ffmpeg ffprobe cc_pdf_render cc_svg_render libpdfium.dylib; do
      codesign --force --sign - "$SUPPORT/$tool" >/dev/null
    done
  fi
fi
log "Managed media tools staged in $DEST (dev install: $SUPPORT)"
