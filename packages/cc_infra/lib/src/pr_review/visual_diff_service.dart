import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:cc_domain/core/domain/ports/git_command_port.dart';
import 'package:cc_domain/features/pr_review/domain/repositories/review_studio_repository.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/visual_diff.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';
import 'package:cc_infra/src/pr_review/image_differ.dart';
import 'package:cc_infra/src/util/cc_paths.dart';
import 'package:path/path.dart' as p;

/// The outcome of a visual-diff run — either the produced snapshots or an
/// HONEST reason it could not run (never a silent pass; PRD 18 §4 / acceptance).
class VisualDiffOutcome {
  /// Creates a [VisualDiffOutcome].
  const VisualDiffOutcome({
    required this.available,
    required this.reason,
    this.snapshots = const [],
  });

  /// Unavailable with [reason].
  factory VisualDiffOutcome.unavailable(String reason) =>
      VisualDiffOutcome(available: false, reason: reason);

  /// Whether the visual axis could run on this host + repo.
  final bool available;

  /// Human-readable reason when [available] is false (e.g. "no Flutter SDK on
  /// host", "no Widgetbook app in repo", "no golden-testable use-cases").
  final String reason;

  /// The produced snapshots (empty when unavailable or when nothing changed).
  final List<VisualDiffSnapshot> snapshots;
}

/// Renders a PR's changed UI components before/after via a headless
/// `flutter test` golden pass and diffs the pixels (PRD 18 §4).
///
/// The pure-Dart server cannot render Flutter widgets in-process, so rendering
/// runs as a supervised child `flutter test` in the PR's base and head
/// worktrees (offscreen — no display needed). This REQUIRES a Flutter SDK on
/// the host: declared as a host capability, degraded gracefully otherwise. The
/// image diff is pure Dart ([ImageDiffer]).
class VisualDiffService {
  /// Creates a [VisualDiffService].
  VisualDiffService({
    required VisualDiffRepository repository,
    required CcPaths paths,
    String? flutterBinary,
    this.testTimeout = const Duration(minutes: 8),
  }) : _repository = repository,
       _paths = paths,
       _flutterBinary = flutterBinary;

  final VisualDiffRepository _repository;
  final CcPaths _paths;
  final String? _flutterBinary;

  /// Timeout for a single `flutter test` golden pass.
  final Duration testTimeout;

  static const _differ = ImageDiffer();

  /// Whether a Flutter SDK is resolvable on this host (cheap precheck — no
  /// worktree needed). When false, the visual axis is honestly unavailable
  /// before any expensive provisioning.
  Future<bool> hostHasFlutter() async => (await _resolveFlutter()) != null;

  /// Detects whether the visual axis can run for [repoPath] on this host.
  /// Returns null when capable, or an honest reason string otherwise.
  Future<String?> unavailableReason(String repoPath) async {
    final flutter = await _resolveFlutter();
    if (flutter == null) {
      return 'no Flutter SDK on host';
    }
    if (!await _hasWidgetbook(repoPath)) {
      return 'no Widgetbook app in repo';
    }
    return null;
  }

  /// Renders + diffs changed components in [repoPath] (a worktree checked out
  /// at [headSha]) by rendering goldens at head, checking out [baseSha] and
  /// rendering again, then restoring head. Returns either the snapshots or an
  /// honest unavailability reason. The worktree is throwaway, so the internal
  /// checkouts are safe.
  Future<VisualDiffOutcome> compute({
    required String workspaceId,
    required String repoId,
    required String prNodeId,
    required String repoPath,
    required GitCommandPort git,
    required String baseSha,
    required String headSha,
  }) async {
    final reason = await unavailableReason(repoPath);
    if (reason != null) {
      return VisualDiffOutcome.unavailable(reason);
    }
    final flutter = (await _resolveFlutter())!;

    // Render goldens offscreen at both SHAs. A harness/subprocess failure
    // degrades to "unavailable", never a crash and never a silent pass.
    Map<String, Uint8List> baseGoldens;
    Map<String, Uint8List> headGoldens;
    try {
      headGoldens = await _renderGoldens(flutter, repoPath);
      await _checkout(git, repoPath, baseSha);
      baseGoldens = await _renderGoldens(flutter, repoPath);
      await _checkout(git, repoPath, headSha);
    } catch (e) {
      CcInfraLog.warning('visual_diff: golden render failed: $e');
      // Best-effort restore to head so the worktree isn't left on base.
      await _checkout(git, repoPath, headSha).catchError((_) {});
      return VisualDiffOutcome.unavailable('golden harness error');
    }

    if (baseGoldens.isEmpty && headGoldens.isEmpty) {
      return VisualDiffOutcome.unavailable('no golden-testable use-cases');
    }

    final componentKeys = {...baseGoldens.keys, ...headGoldens.keys};
    final snapshots = <VisualDiffSnapshot>[];
    for (final key in componentKeys) {
      final base = baseGoldens[key];
      final head = headGoldens[key];
      final snapshot = await _diffComponent(
        workspaceId: workspaceId,
        repoId: repoId,
        prNodeId: prNodeId,
        headSha: headSha,
        componentKey: key,
        baseBytes: base,
        headBytes: head,
      );
      if (snapshot != null) {
        await _repository.upsert(workspaceId, snapshot);
        snapshots.add(snapshot);
      }
    }
    return VisualDiffOutcome(available: true, reason: '', snapshots: snapshots);
  }

  Future<VisualDiffSnapshot?> _diffComponent({
    required String workspaceId,
    required String repoId,
    required String prNodeId,
    required String headSha,
    required String componentKey,
    required Uint8List? baseBytes,
    required Uint8List? headBytes,
  }) async {
    final dir = await _paths.reviewSnapshotDir(prNodeId, componentKey);
    VisualDiffStatus status;
    String? baseRef;
    String? headRef;
    String? diffRef;
    var changedPercent = 0.0;

    if (baseBytes == null && headBytes != null) {
      status = VisualDiffStatus.added;
      headRef = await _write(dir, 'head.png', headBytes);
    } else if (headBytes == null && baseBytes != null) {
      status = VisualDiffStatus.removed;
      baseRef = await _write(dir, 'base.png', baseBytes);
    } else if (baseBytes != null && headBytes != null) {
      final result = _differ.compare(baseBytes, headBytes);
      changedPercent = result.changedPercent;
      baseRef = await _write(dir, 'base.png', baseBytes);
      headRef = await _write(dir, 'head.png', headBytes);
      if (result.identical) {
        status = VisualDiffStatus.unchanged;
      } else {
        status = VisualDiffStatus.changed;
        if (result.overlayPng != null) {
          diffRef = await _write(dir, 'diff.png', result.overlayPng!);
        }
      }
    } else {
      return null;
    }

    return VisualDiffSnapshot(
      id: '$prNodeId:$componentKey',
      workspaceId: workspaceId,
      repoId: repoId,
      prNodeId: prNodeId,
      componentKey: componentKey,
      componentTitle: _humanize(componentKey),
      status: status,
      variants: [
        VisualDiffVariant(
          viewport: 'default',
          brightness: 'light',
          status: status,
          baseImageRef: baseRef,
          headImageRef: headRef,
          diffImageRef: diffRef,
          changedRegionPercent: changedPercent,
        ),
      ],
      headSha: headSha,
    );
  }

  Future<void> _checkout(
    GitCommandPort git,
    String repoPath,
    String ref,
  ) async {
    final result = await git.run([
      'checkout',
      '--force',
      ref,
    ], workdir: repoPath);
    if (!result.isSuccess) {
      throw StateError('git checkout $ref failed: ${result.stderr}');
    }
  }

  /// Runs the repo's golden tests offscreen and collects the produced PNGs,
  /// keyed by their golden path relative to the repo. Uses
  /// `flutter test --update-goldens` so the render is regenerated
  /// deterministically at this SHA (throwaway worktree).
  Future<Map<String, Uint8List>> _renderGoldens(
    String flutter,
    String repoPath,
  ) async {
    final result =
        await Process.run(flutter, [
          'test',
          '--update-goldens',
          '--no-pub',
        ], workingDirectory: repoPath).timeout(
          testTimeout,
          onTimeout: () {
            throw TimeoutException('flutter test golden pass timed out');
          },
        );
    if (result.exitCode != 0 && result.exitCode != 1) {
      // 1 = some tests failed (goldens may still be produced); other codes are
      // harness failures.
      CcInfraLog.warning(
        'visual_diff: flutter test exit ${result.exitCode} in $repoPath',
      );
    }
    return _collectGoldens(repoPath);
  }

  /// Collects `.png` files under any `goldens/` or `golden/` directory in the
  /// repo's `test/` tree, keyed by repo-relative path.
  Future<Map<String, Uint8List>> _collectGoldens(String repoPath) async {
    final out = <String, Uint8List>{};
    final testDir = Directory(p.join(repoPath, 'test'));
    if (!testDir.existsSync()) {
      return out;
    }
    await for (final entity in testDir.list(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.png')) {
        continue;
      }
      final segments = p.split(entity.path);
      if (!segments.contains('goldens') && !segments.contains('golden')) {
        continue;
      }
      final key = p.relative(entity.path, from: repoPath);
      out[key] = await entity.readAsBytes();
    }
    return out;
  }

  Future<String> _write(Directory dir, String name, Uint8List bytes) async {
    final file = File(p.join(dir.path, name));
    await file.writeAsBytes(bytes);
    return file.path;
  }

  Future<bool> _hasWidgetbook(String repoPath) async {
    // Detect a Widgetbook app: a `widgetbook` dependency in any pubspec.
    final root = Directory(repoPath);
    if (!root.existsSync()) {
      return false;
    }
    final rootPubspec = File(p.join(repoPath, 'pubspec.yaml'));
    if (rootPubspec.existsSync() &&
        (await rootPubspec.readAsString()).contains('widgetbook')) {
      return true;
    }
    // Also check one level of sub-packages (monorepo apps/*, packages/*).
    for (final sub in ['apps', 'packages']) {
      final dir = Directory(p.join(repoPath, sub));
      if (!dir.existsSync()) {
        continue;
      }
      for (final child in dir.listSync().whereType<Directory>()) {
        final pubspec = File(p.join(child.path, 'pubspec.yaml'));
        if (pubspec.existsSync() &&
            (await pubspec.readAsString()).contains('widgetbook')) {
          return true;
        }
      }
    }
    return false;
  }

  Future<String?> _resolveFlutter() async {
    if (_flutterBinary != null && File(_flutterBinary).existsSync()) {
      return _flutterBinary;
    }
    // Probe PATH (`flutter`) then a common fvm location. Kept simple: the
    // capability declaration only needs a runnable flutter.
    for (final candidate in ['flutter', 'fvm']) {
      try {
        final which = await Process.run(
          Platform.isWindows ? 'where' : 'which',
          [candidate],
        );
        if (which.exitCode == 0) {
          final path = (which.stdout as String).trim().split('\n').first.trim();
          if (path.isNotEmpty) {
            // `fvm` runs flutter via `fvm flutter`; we return the flutter proxy
            // only when a bare `flutter` is present. `fvm` alone is not enough
            // without the `flutter` subcommand, but bare flutter is preferred.
            if (candidate == 'flutter') {
              return path;
            }
          }
        }
      } catch (_) {
        // Probe failed — try the next candidate.
      }
    }
    return null;
  }

  String _humanize(String key) {
    final base = p.basenameWithoutExtension(key);
    final spaced = base
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .replaceAllMapped(RegExp('([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}')
        .trim();
    if (spaced.isEmpty) {
      return base;
    }
    return spaced[0].toUpperCase() + spaced.substring(1);
  }
}
