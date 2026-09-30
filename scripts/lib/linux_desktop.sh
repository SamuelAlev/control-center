#!/usr/bin/env bash
#
# Source it. What the Linux desktop build (the AppImage and the linux-x64
# tarball it is cut from) may assume of the machine it runs on, shared by
# bundle_linux_deps.sh (which makes the bundle meet it) and lint_appdir.sh
# (which fails an AppDir that does not). Linux-only: the helpers call readelf,
# ldd and ldconfig from the build host.
#

# The ABI floor. The desktop runs on the HOST's glibc and libstdc++ (both are on
# appimage_excludelist), and AppImageHub requires an AppImage to start on the
# oldest still-supported Ubuntu LTS without extra packages. Ubuntu 22.04 is that
# release until its standard support ends in April 2027: glibc 2.35, libstdc++
# from GCC 12. release.yml and natives.yml build Linux on the matching runner,
# so these are the versions that build links against; raise all four together.
# test/tooling/linux_desktop_test.dart pins the runner to this line.
CC_DESKTOP_LINUX_BASE="ubuntu-22.04"
CC_DESKTOP_GLIBC_MAX="2.35"
CC_DESKTOP_GLIBCXX_MAX="3.4.30"
CC_DESKTOP_CXXABI_MAX="1.3.13"

# Libraries the host provides, with everything they link. Nothing in their
# closure is bundled, even when a bundled ELF links it directly.
#   GTK 3: Flutter's embedder IS a GTK application, so a host without GTK cannot
#     run the app at all, and a private GTK/GLib would drag in themes, pixbuf
#     loaders, input methods and GIO modules that must match the host's.
#   libcurl: every desktop has it (dnf, pacman and zypper link it; Ubuntu ships
#     libcurl4). A bundled copy keeps Debian's compiled-in CA path,
#     /etc/ssl/certs/ca-certificates.crt, which Fedora and openSUSE do not have,
#     so sentry's native crash uploads would fail TLS there.
#   libpulse: the client of the host's sound server (PulseAudio or PipeWire's
#     pulse shim); the host's ALSA plugins link it too, and two copies in one
#     process would collide on the soname.
CC_DESKTOP_HOST_ROOTS=(
  libgtk-3.so.0
  libcurl.so.4
  libpulse.so.0
  libpulse-simple.so.0
)

# Libraries the build host copies into the bundle. Each one is here because a
# plugin links it, the stock ubuntu-22.04 runner (AppImageHub's test machine)
# lacks it or may, and it is safe to carry privately. bundle_linux_deps.sh
# refuses to copy anything else: a new plugin dependency is a decision (bundle
# it, or add it to the host roots above), not something to discover in a
# release. The license of each ships in THIRD-PARTY-LICENSES.txt, read from the
# build host's Debian copyright file.
#   libnotify.so.4    local_notifier (desktop notifications)
#   libsecret-1.so.0  flutter_secure_storage (the Secret Service keyring)
CC_DESKTOP_BUNDLED_LIBS=(
  libnotify.so.4
  libsecret-1.so.0
)

# Linked but never loaded, so neither bundled nor required of the host.
#   libjvm.so: libdartjni.so (package:jni) is only opened by Dart FFI when a JVM
#     is in use, which the Linux desktop never does.
CC_DESKTOP_UNLOADED_LIBS=(
  libjvm.so
)

# Prints every regular ELF file under a directory, NUL-separated.
desktop_elf_files() { # dir
  local f
  while IFS= read -r -d '' f; do
    [ "$(od -An -tx1 -N4 "$f" 2>/dev/null)" = " 7f 45 4c 46" ] && printf '%s\0' "$f"
  done < <(find "$1" -type f -print0)
  return 0
}

# Prints an ELF's DT_NEEDED sonames, one per line.
desktop_elf_needed() { # elf
  readelf -dW "$1" 2>/dev/null | sed -nE 's/.*\(NEEDED\).*\[(.*)\]$/\1/p'
}

# Prints an ELF's RUNPATH (or legacy RPATH) entries with $ORIGIN expanded, one
# per line.
desktop_elf_search_dirs() { # elf
  local origin entry
  origin="$(cd "$(dirname "$1")" && pwd)"
  readelf -dW "$1" 2>/dev/null |
    sed -nE 's/.*\((RUNPATH|RPATH)\).*\[(.*)\]$/\2/p' |
    tr ':' '\n' |
    while IFS= read -r entry; do
      [ -n "$entry" ] || continue
      entry="${entry//\$\{ORIGIN\}/$origin}"
      printf '%s\n' "${entry//\$ORIGIN/$origin}"
    done
}

# Prints the host path of a soname for the build host's architecture. awk reads
# to the end rather than `exit`ing at the match: ldconfig would die of SIGPIPE,
# and callers run under pipefail.
desktop_host_lib_path() { # soname
  local abi
  case "$(uname -m)" in
    x86_64) abi="x86-64" ;;
    aarch64) abi="AArch64" ;;
    *) abi="$(uname -m)" ;;
  esac
  ldconfig -p | awk -v n="$1" -v a="$abi" '$1 == n && index($0, a) && !p { p = $NF } END { if (p) print p }'
}

# Prints the sonames the host is assumed to provide: appimage_excludelist plus
# each host root and its closure on the build host. Fails when the build host
# lacks a root, since the closure cannot then be known.
desktop_host_sonames() {
  local root path
  grep -vE '^[[:space:]]*(#|$)' "$REPO_ROOT/scripts/release/appimage_excludelist"
  for root in "${CC_DESKTOP_HOST_ROOTS[@]}"; do
    path="$(desktop_host_lib_path "$root")"
    [ -n "$path" ] || die "the build host has no $root; install its -dev package (release.yml lists them)"
    printf '%s\n' "$root"
    ldd "$path" | awk '$2 == "=>" { print $1 } $1 ~ /^\// { n = split($1, p, "/"); print p[n] }'
  done
}
