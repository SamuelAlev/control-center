import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/features/evals/domain/evaluation/evaluation_task.dart';
import 'package:cc_harness/cancellation.dart';
import 'package:cc_infra/src/evaluation/controlled_evaluation_process.dart';
import 'package:cc_infra/src/evaluation/evaluation_artifact_reader.dart';
import 'package:path/path.dart' as p;

/// A real, isolated, disposable workspace for one evaluation attempt.
///
/// Isolation is the point: a run may only ever write here, and the workspace is
/// a *copy* of the pinned fixture (never the operator's checkout — the repo's
/// own git-safety rule forbids running git against the source tree). It is
/// either a `git clone` of a fixture repository at a pinned commit or, for a
/// purely inline task, a fresh repository seeded from [EvaluationTask.inlineFiles]
/// so that change detection and `git apply --check` are still real.
class IsolatedTaskWorkspace {
  IsolatedTaskWorkspace._(
    this.root,
    this._baselineRef,
    this._isGitRepo,
    this.keep, [
    this._controlled = false,
    this._baselineFiles = const {},
  ]);

  /// Creates and prepares a workspace for [task] under [parentDir].
  ///
  /// [fixtureRepoPath] is a *copy* of the fixture repository (a path the
  /// operator supplies; the runner never clones the repository under test into
  /// itself). [keep] leaves the directory behind for inspection.
  static Future<IsolatedTaskWorkspace> create({
    required EvaluationTask task,
    required Directory parentDir,
    String? fixtureRepoPath,
    bool keep = false,
    bool controlled = false,
    CancellationToken? cancellation,
  }) async {
    final slug = task.id.replaceAll(RegExp(r'[^A-Za-z0-9_.-]'), '_');
    final root = Directory(
      p.join(
        parentDir.path,
        'cc-eval-$slug-${DateTime.now().microsecondsSinceEpoch}',
      ),
    );
    if (!root.existsSync()) {
      root.createSync(recursive: true);
    }

    if (controlled && fixtureRepoPath != null) {
      throw UnsupportedError(
        'controlled campaigns require inline fixture bytes',
      );
    }
    var isGitRepo = false;
    if (fixtureRepoPath != null && fixtureRepoPath.isNotEmpty) {
      final source = Directory(fixtureRepoPath);
      if (!source.existsSync()) {
        throw StateError(
          'fixture repository "$fixtureRepoPath" does not exist',
        );
      }
      final clone = await Process.run('git', [
        'clone',
        '--quiet',
        '--no-hardlinks',
        source.absolute.path,
        root.path,
      ]);
      if (clone.exitCode != 0) {
        throw StateError(
          'git clone of fixture failed (${clone.exitCode}): '
          '${clone.stderr}',
        );
      }
      isGitRepo = true;
      if (task.baseCommit != null && task.baseCommit!.isNotEmpty) {
        final checkout = await Process.run('git', [
          '-C',
          root.path,
          'checkout',
          '--quiet',
          task.baseCommit!,
        ]);
        if (checkout.exitCode != 0) {
          throw StateError(
            'git checkout ${task.baseCommit} failed '
            '(${checkout.exitCode}): ${checkout.stderr}',
          );
        }
      }
    }

    final workspace = IsolatedTaskWorkspace._(root.path, null, isGitRepo, keep);
    if (controlled) {
      await workspace._seedInlineFiles(task.inlineFiles);
      final setup = task.setupCommand;
      if (setup != null && setup.trim().isNotEmpty) {
        final runner = ControlledEvaluationProcess(
          root: root.path,
          home: '${root.path}-setup-home',
          cancellation: cancellation,
        );
        final outcome = await runner.run(
          setup,
          timeoutSeconds: 120,
          cancel: cancellation,
        );
        if (!outcome.ok) {
          throw StateError('contained task setup failed: ${outcome.stderr}');
        }
      }
      return IsolatedTaskWorkspace._(
        root.path,
        null,
        false,
        keep,
        true,
        await workspace._files(),
      );
    }
    await workspace._seedInlineFiles(task.inlineFiles);

    if (!isGitRepo) {
      // An inline-only task still gets a real repository so that "did this run
      // change anything" and "does this patch apply" are answered by git
      // rather than by a heuristic.
      await workspace._git(['init', '--quiet']);
    }
    await workspace._commitBaseline('baseline');
    isGitRepo = true;

    final setup = task.setupCommand;
    if (setup != null && setup.trim().isNotEmpty) {
      // Trusted fixture generation: it runs BEFORE the agent and its result
      // becomes part of the immutable baseline, so the candidate is measured
      // against the prepared state rather than the raw seeds.
      final prepared = await Process.run(
        'bash',
        ['-lc', setup],
        workingDirectory: root.path,
        environment: Platform.environment,
      );
      if (prepared.exitCode != 0) {
        throw StateError(
          'task "${task.id}" setup command failed (${prepared.exitCode}): '
          '${prepared.stderr}',
        );
      }
      await workspace._commitBaseline('cc-eval fixture setup');
    }

    final head = await workspace._git(['rev-parse', 'HEAD']);
    return IsolatedTaskWorkspace._(
      root.path,
      (head.stdout as String).trim(),
      isGitRepo,
      keep,
    );
  }

  /// Absolute path of the workspace root (the agent's working directory).
  final String root;

  /// Whether the operator asked to keep the workspace after the attempt.
  final bool keep;

  /// The repository revision the run started from (clean tree).
  final String? _baselineRef;

  /// Whether the workspace is a git repository.
  final bool _isGitRepo;
  final bool _controlled;
  final Map<String, List<int>> _baselineFiles;

  /// The revision the run started from, when the workspace is a repository.
  String? get baselineRef => _baselineRef;

  /// Whether change detection is backed by git.
  bool get isGitRepo => _isGitRepo;

  /// The working directory inside the workspace the task targets.
  String subdirectory(String subpath) =>
      subpath == '.' ? root : p.join(root, subpath);

  /// Files (workspace-relative, sorted) that differ from the baseline.
  Future<List<String>> changedFiles() async {
    if (_controlled) {
      final files = await _files();
      return <String>{...files.keys, ..._baselineFiles.keys}
          .where((name) => !_bytesEqual(files[name], _baselineFiles[name]))
          .toList()
        ..sort();
    }
    if (!_isGitRepo) {
      return const [];
    }
    final result = await _git(['status', '--porcelain=v1', '-uall']);
    final paths = <String>[];
    for (final line in result.stdout.toString().split('\n')) {
      if (line.trim().isEmpty) {
        continue;
      }
      // porcelain v1: "XY path" (path may contain spaces; never quotes here
      // because core.quotePath is irrelevant for the ASCII fixture paths the
      // evaluator uses).
      final path = line.length > 3 ? line.substring(3).trim() : '';
      if (path.isEmpty) {
        continue;
      }
      final renamed = path.contains(' -> ')
          ? path.split(' -> ').last.trim()
          : path;
      paths.add(renamed);
    }
    paths.sort();
    return paths;
  }

  /// The unified, binary-safe diff of EVERY change against the baseline:
  /// additions (including untracked files), deletions and mode changes.
  ///
  /// This is the replay recording, so it must capture deliverables the agent
  /// only created (a fresh `answer.txt`, `review.md`, `plan.json`, …) — a
  /// tracked-files-only `git diff HEAD` would record nothing for them, and the
  /// workspace is deleted afterwards.
  Future<String> diff() async {
    if (_controlled) {
      final files = await _files();
      final changes = <String, Object?>{};
      for (final name in <String>{...files.keys, ..._baselineFiles.keys}) {
        if (_bytesEqual(files[name], _baselineFiles[name])) {
          continue;
        }
        changes[name] = files[name] == null ? null : base64Encode(files[name]!);
      }
      return jsonEncode(changes);
    }
    if (!_isGitRepo) {
      return '';
    }
    final baseline = _baselineRef;
    if (baseline == null || baseline.isEmpty) {
      return '';
    }
    await _git(['add', '-A']);
    final result = await Process.run('git', [
      '-C',
      root,
      'diff',
      '--cached',
      '--binary',
      '--no-color',
      baseline,
    ]);
    return result.stdout.toString();
  }

  Future<void> _commitBaseline(String message) async {
    await _git(['add', '-A']);
    await _git([
      '-c',
      'user.email=cc-eval@localhost',
      '-c',
      'user.name=cc-eval',
      'commit',
      '--quiet',
      '--allow-empty',
      '-m',
      message,
    ]);
  }

  /// Removes the workspace from disk (no-op when the operator asked to keep
  /// it, so a failing attempt can be inspected).
  void dispose() {
    if (keep) {
      return;
    }
    try {
      if (Directory(root).existsSync()) {
        Directory(root).deleteSync(recursive: true);
      }
      if (_controlled) {
        for (final name in ['$root-home', '$root-setup-home']) {
          final dir = Directory(name);
          if (dir.existsSync()) {
            dir.deleteSync(recursive: true);
          }
        }
      }
    } on FileSystemException {
      // A workspace the OS still holds open (Windows) costs a temporary
      // directory, never the evaluation: the next run creates its own.
    }
  }

  Future<Map<String, List<int>>> _files() async {
    final out = <String, List<int>>{};
    var total = 0;
    await for (final entity in Directory(
      root,
    ).list(recursive: true, followLinks: false)) {
      if (entity is Link) {
        throw StateError('symlink is not an evaluation artifact');
      }
      if (entity is! File) {
        continue;
      }
      final relative = p.relative(entity.path, from: root);
      if (p.split(relative).contains('.agents')) {
        continue;
      }
      if (p.split(relative).contains('.git')) {
        throw StateError('git metadata is not an evaluation artifact');
      }
      if (out.length >= 1000) {
        throw StateError('attempt artifact count limit exceeded');
      }
      final bytes = await readEvaluationArtifact(
        entity,
        8 * 1024 * 1024 - total,
      );
      total += bytes.length;
      out[relative] = bytes;
    }
    return out;
  }

  static bool _bytesEqual(List<int>? a, List<int>? b) {
    if (a == null || b == null) {
      return a == null && b == null;
    }
    if (a.length != b.length) {
      return false;
    }
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }

  Future<void> _seedInlineFiles(Map<String, dynamic> files) async {
    for (final entry in files.entries) {
      final normalized = p.normalize(entry.key);
      if (p.isAbsolute(normalized) ||
          normalized == '..' ||
          normalized.startsWith('..${p.separator}') ||
          p.split(normalized).contains('.git') ||
          p.split(normalized).contains('.agents')) {
        throw StateError('unsafe fixture path');
      }
      final target = p.join(root, entry.key);
      final file = File(target);
      file.parent.createSync(recursive: true);
      final value = entry.value;
      if (value is String) {
        await file.writeAsString(value);
      } else if (value is Map && value['base64'] is String) {
        await file.writeAsBytes(base64Decode(value['base64'] as String));
      } else {
        await file.writeAsString(jsonEncode(value));
      }
      // Shell fixtures must be runnable as `./script.sh` the way a real
      // repository's scripts are: a task whose check is unrunnable for an
      // unrelated reason measures nothing.
      if (target.endsWith('.sh')) {
        try {
          await Process.run('chmod', ['+x', target]);
        } on ProcessException {
          // chmod is unavailable on some hosts; the corpus can then only use
          // `bash script.sh`, which every check here does anyway.
        }
      }
    }
  }

  Future<ProcessResult> _git(List<String> args) async {
    final result = await Process.run('git', ['-C', root, ...args]);
    if (result.exitCode != 0) {
      throw StateError(
        'git ${args.join(' ')} failed (${result.exitCode}): ${result.stderr}',
      );
    }
    return result;
  }
}
