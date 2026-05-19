import 'dart:io';

import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';
import 'package:path/path.dart' as p;

/// Bundles the prebuilt Control Center native libraries into the `cc_server`
/// binary the SAME way `sqlite3`/`sqlite_vector` bundle theirs: each dylib is
/// emitted as a [CodeAsset] with [DynamicLoadingBundled], so `dart build cli`
/// copies it into `bundle/lib/` beside `libsqlite3` — the server is then
/// self-contained and nothing but the on-device MODELS is downloaded at
/// runtime.
///
/// The natives themselves are NOT compiled here (rift/fff are cargo builds,
/// aec is meson+WebRTC, …). They are staged as prebuilt artifacts by
/// `scripts/natives/build_natives.sh`
/// into `<repo>/build/natives/` (override with `CC_NATIVES_PREBUILT_DIR`) and
/// this hook re-emits whatever is staged — mirroring `sqlite_vector`'s
/// prebuilt-re-emit hook rather than `sqlite3`'s compile-from-source hook.
///
/// Missing staging FAILS the build. Every native is required — the produced
/// server would refuse to boot (`cc_server_runtime`'s native preflight throws) —
/// so failing here turns "it built fine but dies on start" into one actionable
/// error naming the script to run.
///
/// Escape hatch for compile-only workflows that never run the binary (a syntax
/// check on a fresh clone): create an empty `.cc_natives_allow_missing` file at
/// the repo root, which downgrades the failure to a warning. Do NOT leave it in
/// place for a packaging run — `scripts/release/verify_natives.sh` would catch
/// the result anyway, but only after a much longer build.
///
/// A FILE, not an environment variable: the hooks runner spawns this hook as its
/// own process and does NOT forward the caller's environment, so
/// `CC_NATIVES_ALLOW_MISSING=1 dart build cli` is silently ignored. Both env
/// names are still read first in case a future SDK does forward them, but the
/// file is what actually works today. (The long-documented
/// `CC_NATIVES_PREBUILT_DIR` override was non-functional for the same reason;
/// `.cc_natives_prebuilt_dir` replaces it.)
void main(List<String> args) async {
  await build(args, (input, output) async {
    if (!input.config.buildCodeAssets) {
      return;
    }

    final repoRoot = _repoRoot(input);
    final stagingDir = _resolveStagingDir(input);
    if (stagingDir == null || !stagingDir.existsSync()) {
      _reportMissing(
        repoRoot,
        'no prebuilt natives staged (${stagingDir?.path ?? '<unresolved>'})',
      );
      return;
    }

    final os = input.config.code.targetOS;
    final extensions = switch (os) {
      OS.macOS => const ['.dylib'],
      OS.windows => const ['.dll'],
      _ => const ['.so'],
    };

    var emitted = 0;
    final entries = stagingDir.listSync().whereType<File>().toList()
      ..sort((a, b) => a.path.compareTo(b.path));
    for (final file in entries) {
      final name = p.basename(file.path);
      // Versioned Linux sonames (libonnxruntime.so.1.22.0) don't end in .so.
      final isLibrary = extensions.any(name.contains);
      if (!isLibrary) {
        continue;
      }
      output.dependencies.add(file.uri);
      final assetFile = await _thinIfFat(input, file);
      output.assets.code.add(
        CodeAsset(
          package: input.packageName,
          // The asset id is never resolved at runtime — the loaders in
          // cc_natives open these by path from `<exeDir>/../lib/` (see
          // `bundledLibraryCandidates`). The id only has to be unique.
          name: 'natives/$name',
          linkMode: DynamicLoadingBundled(),
          file: assetFile.uri,
        ),
      );
      emitted++;
    }

    if (emitted == 0) {
      _reportMissing(
        repoRoot,
        '${stagingDir.path} contains no native libraries',
      );
    } else {
      stdout.writeln(
        'cc_server hook: bundling $emitted native libraries from '
        '${stagingDir.path}',
      );
    }
  });
}

/// Fails the build for a missing/empty staging dir, unless the repo-root
/// `.cc_natives_allow_missing` marker opts into warn-only behaviour.
void _reportMissing(String repoRoot, String what) {
  final remedy =
      'run scripts/natives/build_natives.sh (on Windows '
      'scripts/release/windows_natives.sh) first. Every native is REQUIRED: the '
      'built server refuses to boot without them. To build anyway '
      '(compile-only workflows), create ${p.join(repoRoot, _allowMissingFile)}.';
  if (_allowMissing(repoRoot)) {
    stderr.writeln('cc_server hook: $what — $remedy');
    return;
  }
  throw StateError('cc_server hook: $what — $remedy');
}

/// Repo-root marker that downgrades a missing-natives failure to a warning.
const _allowMissingFile = '.cc_natives_allow_missing';

/// Repo-root file whose contents override the staging directory.
const _prebuiltDirFile = '.cc_natives_prebuilt_dir';

/// Whether the caller opted into building without natives. The env var is read
/// first for forward-compatibility, but the hooks runner does not forward the
/// caller's environment — the FILE is what works today.
bool _allowMissing(String repoRoot) =>
    Platform.environment['CC_NATIVES_ALLOW_MISSING'] == '1' ||
    File(p.join(repoRoot, _allowMissingFile)).existsSync();

/// The repo root: `packageRoot` is `<repo>/apps/cc_server/`, two levels down.
String _repoRoot(BuildInput input) =>
    p.normalize(p.join(input.packageRoot.toFilePath(), '..', '..'));

/// Thins a universal (fat) macOS dylib down to the target architecture,
/// preserving its leaf name (the runtime loaders open by path, so the bundled
/// file name must not change). The prebuilt sherpa-onnx / onnxruntime dylibs
/// ship universal and `dart build cli`'s install-name rewriting rejects
/// multi-architecture Mach-Os. Same trick as `sqlite_vector`'s hook.
Future<File> _thinIfFat(BuildInput input, File file) async {
  if (input.config.code.targetOS != OS.macOS) {
    return file;
  }
  final archs = await Process.run('/usr/bin/lipo', ['-archs', file.path]);
  final archList = (archs.stdout as String).trim().split(RegExp(r'\s+'));
  if (archs.exitCode != 0 || archList.length <= 1) {
    return file;
  }
  final thinArch = switch (input.config.code.targetArchitecture) {
    Architecture.arm64 => 'arm64',
    Architecture.x64 => 'x86_64',
    _ => null,
  };
  if (thinArch == null) {
    return file;
  }
  final outputFile = File.fromUri(
    input.outputDirectory.resolve('thinned/${p.basename(file.path)}'),
  );
  await outputFile.parent.create(recursive: true);
  final result = await Process.run('/usr/bin/lipo', [
    file.path,
    '-thin',
    thinArch,
    '-output',
    outputFile.path,
  ]);
  if (result.exitCode != 0) {
    throw StateError(
      'Failed to thin ${p.basename(file.path)} for $thinArch: '
      '${result.stderr}',
    );
  }
  return outputFile;
}

/// The staging directory holding the prebuilt natives, in order: the
/// `CC_NATIVES_PREBUILT_DIR` env var (forward-compatible only — see
/// [_allowMissing] for why env does not reach a hook), the repo-root
/// `.cc_natives_prebuilt_dir` pointer file, else `<repo>/build/natives` (the
/// default DEST of `scripts/natives/build_natives.sh`).
Directory? _resolveStagingDir(BuildInput input) {
  final env = Platform.environment['CC_NATIVES_PREBUILT_DIR'];
  if (env != null && env.isNotEmpty) {
    return Directory(env);
  }
  final repoRoot = _repoRoot(input);
  final pointer = File(p.join(repoRoot, _prebuiltDirFile));
  if (pointer.existsSync()) {
    final target = pointer.readAsStringSync().trim();
    if (target.isNotEmpty) {
      return Directory(target);
    }
  }
  return Directory(p.join(repoRoot, 'build', 'natives'));
}
