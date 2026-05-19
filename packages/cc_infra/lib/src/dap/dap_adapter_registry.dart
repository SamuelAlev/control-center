import 'dart:io';

import 'package:path/path.dart' as p;

/// How to launch one debug adapter, and when it applies.
class DapAdapterSpec {
  /// Creates a [DapAdapterSpec].
  const DapAdapterSpec({
    required this.id,
    required this.command,
    required this.args,
    required this.rootMarkers,
    required this.extensions,
    this.localBinDirs = const [],
    this.launchDefaults = const {},
  });

  /// Stable id, reported to the model.
  final String id;

  /// Executable to spawn.
  final String command;

  /// Arguments that make it speak DAP on stdio.
  final List<String> args;

  /// Files whose presence means this project uses this adapter.
  final List<String> rootMarkers;

  /// Source extensions it can set breakpoints in.
  final List<String> extensions;

  /// Project-local directories searched before `$PATH`.
  final List<String> localBinDirs;

  /// Defaults folded into every `launch` request.
  final Map<String, dynamic> launchDefaults;
}

/// The adapters we know how to launch.
///
/// **Dart is first because this repo is Dart.** `dart debug_adapter` ships with
/// the SDK — no install step, no version drift against the analyzer already
/// running — and it composes with `flutter test --start-paused`, which is the
/// one place a stack frame answers a question a print statement cannot.
const List<DapAdapterSpec> kDapAdapters = [
  DapAdapterSpec(
    id: 'dart',
    command: 'dart',
    args: ['debug_adapter'],
    rootMarkers: ['pubspec.yaml'],
    extensions: ['dart'],
    launchDefaults: {'type': 'dart'},
  ),
  DapAdapterSpec(
    id: 'debugpy',
    command: 'python3',
    args: ['-m', 'debugpy.adapter'],
    rootMarkers: ['pyproject.toml', 'setup.py', 'requirements.txt'],
    extensions: ['py'],
    localBinDirs: ['.venv/bin', 'venv/bin'],
    launchDefaults: {'type': 'python'},
  ),
  DapAdapterSpec(
    id: 'lldb',
    command: 'lldb-dap',
    args: [],
    rootMarkers: ['Cargo.toml', 'CMakeLists.txt'],
    extensions: ['rs', 'c', 'cc', 'cpp', 'h', 'hpp'],
    launchDefaults: {'type': 'lldb'},
  ),
  DapAdapterSpec(
    id: 'delve',
    command: 'dlv',
    args: ['dap'],
    rootMarkers: ['go.mod'],
    extensions: ['go'],
    launchDefaults: {'type': 'go'},
  ),
];

/// A spec that resolved to an executable on this host.
class ResolvedDapAdapter {
  /// Creates a [ResolvedDapAdapter].
  const ResolvedDapAdapter({required this.spec, required this.executable});

  /// The spec it came from.
  final DapAdapterSpec spec;

  /// Absolute path (or bare name, when it resolved on `$PATH`).
  final String executable;
}

/// Picks the adapters usable in [root].
///
/// **Intersection, not union** — the same rule the language-server registry
/// uses. A root marker alone means "this project is Python" and says nothing
/// about whether `debugpy` is installed; a resolvable binary alone means the
/// host has a Go toolchain and says nothing about this checkout. Only both
/// together mean a debug session can actually start, and offering a `debug`
/// tool that always fails is worse than not offering it.
List<ResolvedDapAdapter> detectDapAdapters(
  String root, {
  List<DapAdapterSpec> specs = kDapAdapters,
  String? Function(String command, List<String> localBinDirs, String root)?
  resolveBinary,
}) {
  final resolve = resolveBinary ?? resolveAdapterBinary;
  final found = <ResolvedDapAdapter>[];
  for (final spec in specs) {
    if (!spec.rootMarkers.any(
      (marker) => File(p.join(root, marker)).existsSync(),
    )) {
      continue;
    }
    final executable = resolve(spec.command, spec.localBinDirs, root);
    if (executable == null) {
      continue;
    }
    found.add(ResolvedDapAdapter(spec: spec, executable: executable));
  }
  return found;
}

/// Resolves [command], preferring a project-local install.
///
/// A checkout's own `.venv` is the interpreter its dependencies are installed
/// against; a `$PATH` python is a different environment, and attaching a
/// debugger from the wrong one fails in a way that reads as "your code is
/// broken".
String? resolveAdapterBinary(
  String command,
  List<String> localBinDirs,
  String root,
) {
  for (final dir in localBinDirs) {
    final candidate = File(p.join(root, dir, command));
    if (candidate.existsSync()) {
      return candidate.path;
    }
  }
  final which = Platform.isWindows ? 'where' : 'which';
  try {
    final result = Process.runSync(which, [command]);
    if (result.exitCode == 0) {
      final first = '${result.stdout}'.split('\n').first.trim();
      if (first.isNotEmpty) {
        return first;
      }
    }
  } on Object {
    // No `which`/`where` on this host: treat as unresolvable rather than
    // assuming the bare name will work, since a failed spawn surfaces much
    // later and much less clearly.
  }
  return null;
}

/// The adapter that claims [path], among [adapters].
ResolvedDapAdapter? adapterForPath(
  String path,
  List<ResolvedDapAdapter> adapters,
) {
  final dot = path.lastIndexOf('.');
  if (dot < 0 || dot == path.length - 1) {
    return null;
  }
  final ext = path.substring(dot + 1).toLowerCase();
  for (final adapter in adapters) {
    if (adapter.spec.extensions.contains(ext)) {
      return adapter;
    }
  }
  return null;
}
