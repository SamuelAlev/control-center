#!/usr/bin/env bash
# Source with scripts/lib/common.sh. Managed media is required for server roles.
# shellcheck source=natives.sh
source "$(dirname "${BASH_SOURCE[0]}")/natives.sh"

cc_svg_verify_notice_package() { # media-dir name version
  local source="$1/svg-licenses/$2-$3" f found=0
  [ -s "$source/Cargo.toml" ] || die "SVG crate metadata missing: $source/Cargo.toml"
  for f in "$source"/LICENSE* "$source"/LICENCE* "$source"/COPYING* \
    "$source"/NOTICE* "$source"/COPYRIGHT*; do
    [ -s "$f" ] && found=1
  done
  [ "$found" = 1 ] || die "SVG crate license notice missing: $source"
}

cc_media_verify() { # media-dir os [architecture]
  local dir="$1" os="$2" arch="${3:-}" suffix= lib= f got deps version req floor encoders decoders filters demuxers prefix identity
  local line crate_name= crate_version= crate_source= notice_count=0
  case "$os" in
    macos) lib=libpdfium.dylib ;;
    linux) lib=libpdfium.so ;;
    windows) lib=pdfium.dll; suffix=.exe; arch="$(cc_windows_arch "${arch:-x64}")" ;;
    *) die "unsupported media platform: $os" ;;
  esac
  # Release packaging and the native cache gate both use this verifier; neither
  # may silently accept yesterday's binaries after a version pin changes.
  load_native_pins
  if [ "$os" = macos ]; then
    case "$FFMPEG_MEDIA_MAC_BUILD" in
      *"_${FFMPEG_MEDIA_VERSION}") ;;
      *) die "macOS FFmpeg release does not match FFMPEG_MEDIA_VERSION" ;;
    esac
    prefix="$FFMPEG_MEDIA_VERSION-"
  else
    case "$FFMPEG_MEDIA_BTBN_BUILD" in
      "n${FFMPEG_MEDIA_VERSION}-"*) ;;
      *) die "BtbN FFmpeg build does not match FFMPEG_MEDIA_VERSION" ;;
    esac
    prefix="$FFMPEG_MEDIA_BTBN_BUILD-"
  fi
  [ -d "$dir" ] || die "required media directory missing: $dir"
  for f in "ffmpeg$suffix" "ffprobe$suffix" "cc_pdf_render$suffix" \
    "cc_svg_render$suffix" "$lib" resvg-LICENSE-MIT.txt \
    resvg-LICENSE-APACHE.txt resvg-SOURCE.txt resvg-Cargo.lock \
    fonts/Manrope-Variable.ttf fonts/FiraCode-VF.ttf \
    fonts/manrope-font-LICENSE.txt fonts/firacode-font-LICENSE.txt \
    pdfium-LICENSE.txt ffmpeg-LICENSE.txt ffmpeg-GPL-3.0.txt \
    ffmpeg-LGPL-2.1.txt ffmpeg-LGPL-3.0.txt ffmpeg-SOURCE.txt \
    pdfium-licenses/pdfium.txt pdfium-licenses/icu.txt \
    pdfium-licenses/llvm-libc.txt pdfium-licenses/fast_float.txt \
    pdfium-licenses/libjpeg_turbo.md pdfium-licenses/freetype.txt \
    pdfium-licenses/libjpeg_turbo.ijg pdfium-licenses/harfbuzz.txt \
    pdfium-licenses/dragonbox-Apache2-LLVM.txt pdfium-licenses/dragonbox-Boost.txt \
    pdfium-licenses/abseil.txt pdfium-licenses/lcms.txt \
    pdfium-licenses/simdutf.txt pdfium-licenses/agg23.txt \
    pdfium-licenses/libopenjpeg.txt pdfium-licenses/zlib.txt \
    pdfium-licenses/libpng.txt; do
    [ -s "$dir/$f" ] || die "required media artifact missing/empty: $dir/$f"
  done
  # Cargo.lock is copied verbatim into media/. Every locked registry dependency,
  # not just resvg itself, must carry its own upstream license and manifest.
  while IFS= read -r line; do
    case "$line" in
      '[[package]]')
        if [ -n "$crate_source" ]; then
          [ "$crate_source" = "registry+https://github.com/rust-lang/crates.io-index" ] \
            || die "unrecognized SVG dependency source: $crate_source"
          cc_svg_verify_notice_package "$dir" "$crate_name" "$crate_version"
          notice_count=$((notice_count + 1))
        fi
        crate_name= crate_version= crate_source= ;;
      'name = "'*) crate_name="${line#*\"}"; crate_name="${crate_name%%\"*}" ;;
      'version = "'*) crate_version="${line#*\"}"; crate_version="${crate_version%%\"*}" ;;
      'source = "'*) crate_source="${line#*\"}"; crate_source="${crate_source%%\"*}" ;;
    esac
  done < "$dir/resvg-Cargo.lock"
  if [ -n "$crate_source" ]; then
    [ "$crate_source" = "registry+https://github.com/rust-lang/crates.io-index" ] \
      || die "unrecognized SVG dependency source: $crate_source"
    cc_svg_verify_notice_package "$dir" "$crate_name" "$crate_version"
    notice_count=$((notice_count + 1))
  fi
  [ "$notice_count" -gt 1 ] || die "SVG crate license set is empty"
  if [ "$os" != macos ]; then
    [ -s "$dir/ffmpeg-publisher-LICENSE.txt" ] \
      || die "BtbN publisher GPLv3 notice missing: $dir/ffmpeg-publisher-LICENSE.txt"
  fi
  for f in "ffmpeg$suffix" "ffprobe$suffix" "cc_pdf_render$suffix" "cc_svg_render$suffix"; do
    [ -x "$dir/$f" ] || die "required media tool not executable: $dir/$f"
  done
  [ "$("$dir/cc_svg_render$suffix" --version)" = "cc_svg_render 0.1.0 (resvg 0.48.1)" ] \
    || die "cc_svg_render is missing or does not match the pinned resvg 0.48.1 wrapper"
  for f in ffmpeg ffprobe; do
    identity="$("$dir/$f$suffix" -version)" \
      || die "managed $f cannot start: $dir/$f$suffix"
    got="${identity%%$'\n'*}"
    case "$got" in
      "$f version $prefix"*) ;;
      *) die "managed $f reports '$got', expected $prefix" ;;
    esac
    case "$identity" in
      *--enable-gpl*) ;;
      *) die "managed $f lacks the GPL codec build" ;;
    esac
    case "$identity" in
      *--enable-nonfree*) die "managed $f is a nonredistributable nonfree build" ;;
    esac
  done
  encoders="$("$dir/ffmpeg$suffix" -hide_banner -encoders)" \
    || die "managed ffmpeg cannot list encoders"
  decoders="$("$dir/ffmpeg$suffix" -hide_banner -decoders)" \
    || die "managed ffmpeg cannot list decoders"
  filters="$("$dir/ffmpeg$suffix" -hide_banner -filters)" \
    || die "managed ffmpeg cannot list filters"
  demuxers="$("$dir/ffmpeg$suffix" -hide_banner -demuxers)" \
    || die "managed ffmpeg cannot list demuxers"
  for f in png mjpeg; do
    grep -Eq "(^|[[:space:]])$f[[:space:]]" <<<"$encoders" \
      || die "managed ffmpeg lacks the $f encoder"
  done
  for f in png mjpeg ppm hevc webp gif apng; do
    grep -Eq "(^|[[:space:]])$f[[:space:]]" <<<"$decoders" \
      || die "managed ffmpeg lacks the $f decoder"
  done
  for f in scale showinfo fps trim; do
    grep -Eq "(^|[[:space:]])$f[[:space:]]" <<<"$filters" \
      || die "managed ffmpeg lacks the $f filter"
  done
  for f in image2 webp_pipe gif apng; do
    grep -Eq "(^|[[:space:]])$f[[:space:]]" <<<"$demuxers" \
      || die "managed ffmpeg lacks the $f demuxer"
  done
  grep -Eq '(^|[[:space:]])mov,mp4,' <<<"$demuxers" \
    || die "managed ffmpeg lacks the HEIF/MOV demuxer"
  if [ "$os" = windows ]; then
    for f in ffmpeg.exe ffprobe.exe cc_pdf_render.exe cc_svg_render.exe pdfium.dll; do
      got="$(pe_machine "$dir/$f")"
      [ "$got" = "$arch" ] || die "media/$f is $got, expected Windows $arch"
    done
  elif [ "$os" = macos ]; then
    for f in ffmpeg ffprobe cc_pdf_render cc_svg_render libpdfium.dylib; do
      lipo -archs "$dir/$f" | grep -qw arm64 || die "media/$f is not macOS arm64"
      deps="$(otool -L "$dir/$f")"
      while IFS= read -r req; do
        case "$req" in
          /usr/lib/*|/System/Library/*) ;;
          @rpath/libpdfium.dylib)
            case "$f" in cc_pdf_render|libpdfium.dylib) ;; *) die "media/$f unexpectedly loads PDFium" ;; esac ;;
          *) die "media/$f requires unbundled $req" ;;
        esac
      done < <(printf '%s\n' "$deps" | sed -n '2,$s/^[[:space:]]*\([^[:space:]]*\).*/\1/p')
      if [ "$f" = ffmpeg ] || [ "$f" = ffprobe ]; then
        case "$deps" in
          *'/usr/lib/libz.'*) die "media/$f dynamically loads system zlib instead of pinned static zlib" ;;
        esac
      fi
    done
    otool -L "$dir/cc_pdf_render" | grep -Fq '@rpath/libpdfium.dylib' \
      || die "cc_pdf_render does not load its adjacent PDFium"
  else
    require_cmd readelf "Install binutils for the media ABI/package gate."
    for f in ffmpeg ffprobe cc_pdf_render cc_svg_render libpdfium.so; do
      readelf -h "$dir/$f" | grep -q 'Machine:.*Advanced Micro Devices X86-64' \
        || die "media/$f is not Linux x64"
      deps="$(readelf -d "$dir/$f")"
      # Only the supported OS C/C++ runtime may be external to media/.
      # libmvec.so.1 is glibc's x86-64 vector math library, shipped in libc6
      # itself (glibc >= 2.22) and on the AppImage excludelist; BtbN's
      # FFmpeg links it.
      while IFS= read -r req; do
        case "$req" in
          libc.so.6|libm.so.6|libmvec.so.1|libpthread.so.0|libdl.so.2|librt.so.1|libstdc++.so.6|libgcc_s.so.1|ld-linux-x86-64.so.2) ;;
          libpdfium.so) [ "$f" = cc_pdf_render ] || die "media/$f unexpectedly loads PDFium" ;;
          *) die "media/$f requires unbundled $req" ;;
        esac
      done < <(printf '%s\n' "$deps" | grep 'NEEDED' | sed -n 's/.*\[\(.*\)\].*/\1/p')
      for req in $(readelf -V -W "$dir/$f" | grep -oE 'GLIBC(X{2})?_[0-9]+(\.[0-9]+)*' | sort -u || true); do
        case "$req" in
          GLIBCXX_*) version="${req#GLIBCXX_}"; floor="$CC_NATIVES_GLIBCXX_MAX" ;;
          GLIBC_*) version="${req#GLIBC_}"; floor="$CC_NATIVES_GLIBC_MAX" ;;
        esac
        [ "$version" = "$floor" ] || [ "$(printf '%s\n%s\n' "$version" "$floor" | sort -V | tail -1)" = "$floor" ] \
          || die "media/$f needs $req beyond supported $CC_NATIVES_BASE_IMAGE ABI $floor"
      done
    done
    readelf -d "$dir/cc_pdf_render" | grep -Fq '$ORIGIN' \
      || die "cc_pdf_render cannot load adjacent PDFium (no \$ORIGIN RUNPATH)"
  fi
  log "Verified managed media tools ($os${arch:+ $arch}): $dir"
}

cc_media_stage() { # build/natives destination os [architecture]
  local source="$1/media" destination="$2" os="$3" arch="${4:-}"
  cc_media_verify "$source" "$os" "$arch"
  rm -rf "$destination"
  mkdir -p "$destination"
  cp -R "$source/." "$destination/"
  cc_media_verify "$destination" "$os" "$arch"
}
