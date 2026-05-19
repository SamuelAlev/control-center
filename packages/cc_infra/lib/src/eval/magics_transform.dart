/// Rewrites the IPython magics people reflexively type into plain Python.
///
/// **Why bother instead of just documenting "no magics".** These are muscle
/// memory. A model that has read a million notebooks types `%pip install pandas`
/// and `!ls` without thinking, and a vanilla interpreter answers with a
/// `SyntaxError` that says nothing about what to do instead. The failure is
/// cheap to prevent and expensive to debug: the model usually retries the same
/// line with different quoting.
///
/// **`%pip` evicts `sys.modules` afterwards.** Installing a package into a
/// live interpreter does nothing for a module that was already imported — the
/// old one stays bound, `import pandas` succeeds, and the version the user just
/// installed is not the one running. Clearing the cached entry is what makes
/// "install then import" behave the way everyone expects.
String transformPythonMagics(String source) {
  final out = <String>[];
  final lines = source.split('\n');

  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    final trimmed = line.trimLeft();
    final indent = line.substring(0, line.length - trimmed.length);

    // Cell magics own the whole rest of the cell, so they are handled first
    // and consume everything below them.
    if (trimmed.startsWith('%%bash') || trimmed.startsWith('%%sh')) {
      final body = lines.sublist(i + 1).join('\n');
      out
        ..add('import subprocess as _cc_subprocess')
        ..add(
          'print(_cc_subprocess.run(${_pyString(body)}, shell=True, '
          'capture_output=True, text=True).stdout, end="")',
        );
      return out.join('\n');
    }
    if (trimmed.startsWith('%%timeit')) {
      final body = lines.sublist(i + 1).join('\n');
      out
        ..add('import timeit as _cc_timeit')
        ..add(
          'print(_cc_timeit.timeit(${_pyString(body)}, globals=globals(), '
          'number=1000), "seconds for 1000 runs")',
        );
      return out.join('\n');
    }
    if (trimmed.startsWith('%%')) {
      // An unknown cell magic: leave the cell alone rather than mangling it.
      // A SyntaxError naming the magic is more honest than a silent rewrite
      // into something that runs and means something else.
      return source;
    }

    if (trimmed.startsWith('%pip ') || trimmed.startsWith('!pip ')) {
      final rest = trimmed.substring(5).trim();
      out
        ..add('${indent}import subprocess as _cc_subprocess, sys as _cc_sys')
        ..add(
          '${indent}print(_cc_subprocess.run([_cc_sys.executable, "-m", '
          '"pip", ${_pyArgs(rest)}], capture_output=True, text=True).stdout, '
          'end="")',
        )
        // Without this the freshly installed version is invisible to an
        // already-imported module for the rest of the kernel's life.
        ..add(
          '${indent}for _cc_m in [m for m in list(_cc_sys.modules) '
          'if not m.startswith("_")]:\n'
          '$indent    _cc_sys.modules.pop(_cc_m, None)',
        );
      continue;
    }
    if (trimmed.startsWith('%cd ')) {
      final target = trimmed.substring(4).trim();
      out
        ..add('${indent}import os as _cc_os')
        ..add('${indent}_cc_os.chdir(${_pyString(_unquote(target))})');
      continue;
    }
    if (trimmed.startsWith('!')) {
      out
        ..add('${indent}import subprocess as _cc_subprocess')
        ..add(
          '${indent}print(_cc_subprocess.run(${_pyString(trimmed.substring(1))}, '
          'shell=True, capture_output=True, text=True).stdout, end="")',
        );
      continue;
    }
    if (trimmed.startsWith('%time ')) {
      out
        ..add('${indent}import time as _cc_time')
        ..add('${indent}_cc_t0 = _cc_time.perf_counter()')
        ..add(indent + trimmed.substring(6))
        ..add(
          '${indent}print("took", _cc_time.perf_counter() - _cc_t0, "s")',
        );
      continue;
    }
    if (trimmed.startsWith('%matplotlib')) {
      // The backend is already forced to Agg by the runner; the line is a
      // no-op rather than an error.
      continue;
    }

    out.add(line);
  }
  return out.join('\n');
}

/// Rewrites the shell escapes people type into JavaScript cells.
String transformJsMagics(String source) {
  final out = <String>[];
  for (final line in source.split('\n')) {
    final trimmed = line.trimLeft();
    final indent = line.substring(0, line.length - trimmed.length);
    if (trimmed.startsWith('!')) {
      out.add(
        '${indent}console.log(require("child_process")'
        '.execSync(${_jsString(trimmed.substring(1))}).toString());',
      );
      continue;
    }
    out.add(line);
  }
  return out.join('\n');
}

/// A Python string literal for [value], safe for any content.
String _pyString(String value) {
  final escaped = value
      .replaceAll(r'\', r'\\')
      .replaceAll('"', r'\"')
      .replaceAll('\n', r'\n')
      .replaceAll('\r', r'\r');
  return '"$escaped"';
}

/// A JavaScript string literal for [value].
String _jsString(String value) {
  final escaped = value
      .replaceAll(r'\', r'\\')
      .replaceAll('"', r'\"')
      .replaceAll('\n', r'\n')
      .replaceAll('\r', r'\r');
  return '"$escaped"';
}

/// Splits a shell-ish argument string into Python string literals.
String _pyArgs(String rest) {
  final args = rest.split(RegExp(r'\s+')).where((a) => a.isNotEmpty);
  return args.map((a) => _pyString(_unquote(a))).join(', ');
}

String _unquote(String value) {
  if (value.length >= 2 &&
      ((value.startsWith('"') && value.endsWith('"')) ||
          (value.startsWith("'") && value.endsWith("'")))) {
    return value.substring(1, value.length - 1);
  }
  return value;
}
