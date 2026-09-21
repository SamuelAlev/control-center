# Sourced from bash steps that spawn Flutter/Dart on Windows.
#
# GitHub windows-latest puts Git usr\bin (GNU tar) ahead of System32
# (bsdtar). Flutter unpacks cache zips with `tar -xf C:\path\file.zip`
# (flutter_tools os.dart _unpackWithTar); GNU tar treats "C:" as a
# remote host:
#   /usr/bin/tar: Cannot connect to C: resolve failed
#
# GITHUB_PATH cannot fix a bash step: Git Bash prepends /usr/bin on
# startup, putting GNU tar back in front. Exporting
# PATH="$RUNNER_TEMP/win-tar:$PATH" also fails — RUNNER_TEMP is
# D:\a\_temp and the colon splits the POSIX PATH. Convert with
# cygpath so Dart's Windows lookup sees tar.exe first.
#
# `[ -x tar.exe ]` is false on NTFS (no Unix execute bit) — test -f.
if [ "${RUNNER_OS:-}" != "Windows" ]; then
  return 0 2>/dev/null || true
fi

if ! command -v cygpath >/dev/null 2>&1; then
  echo "prefer_windows_tar: cygpath not found (need Git Bash)" >&2
  return 1 2>/dev/null || exit 1
fi

_cc_win_tar_dir="$(cygpath -u "${RUNNER_TEMP}")/win-tar"
mkdir -p "${_cc_win_tar_dir}"

_cc_win_tar_src="$(cygpath -u "${SYSTEMROOT:-C:\\Windows}")/System32/tar.exe"
if [ ! -f "${_cc_win_tar_src}" ]; then
  _cc_win_tar_src="/c/Windows/System32/tar.exe"
fi
if [ ! -f "${_cc_win_tar_src}" ]; then
  echo "prefer_windows_tar: Windows tar.exe not found" >&2
  unset _cc_win_tar_dir _cc_win_tar_src
  return 1 2>/dev/null || exit 1
fi

cp -f "${_cc_win_tar_src}" "${_cc_win_tar_dir}/tar.exe"
export PATH="${_cc_win_tar_dir}:${PATH}"
unset _cc_win_tar_dir _cc_win_tar_src
