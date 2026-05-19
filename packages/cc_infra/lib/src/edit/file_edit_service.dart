/// Applies hashline [Patch]es to real files on disk.
///
/// [FileEditService] is the filesystem-facing adapter for the pure-Dart
/// hashline subsystem (`package:cc_domain/.../edit/`). The hashline [Patcher]
/// never touches the filesystem; this service supplies the `readLive` callback
/// (via `dart:io`), implements a [SnapshotStore] over an in-memory cache so
/// drifted files can recover through a three-way merge, and commits the whole
/// patch atomically — every section is written only when all sections prepare
/// successfully, otherwise nothing is written.
library;

import 'dart:io';

import 'package:cc_domain/features/dispatch/domain/edit/hashline.dart';
import 'package:path/path.dart' as p;

/// Per-file detail of a successfully applied section.
class FileEditChange {
  /// Creates a [FileEditChange].
  const FileEditChange({
    required this.path,
    required this.firstChangedLine,
    required this.warnings,
  });

  /// The file path that was written.
  final String path;

  /// The first 1-indexed line that differs from the pre-edit content, or null
  /// when the apply was a no-op.
  final int? firstChangedLine;

  /// Warnings collected during apply / recovery (e.g. a three-way-merge
  /// recovery notice). Empty when the edit landed verbatim.
  final List<String> warnings;
}

/// Per-file detail of a section that could not be applied.
class FileEditFailure {
  /// Creates a [FileEditFailure].
  const FileEditFailure({
    required this.path,
    required this.expectedHash,
    required this.actualHash,
    required this.hashRecognized,
    required this.message,
  });

  /// The file path the failed section targeted.
  final String path;

  /// The 4-hex hash the section was anchored to.
  final String expectedHash;

  /// The 4-hex hash the live file actually has.
  final String actualHash;

  /// True when [expectedHash] resolved to a cached snapshot (the file drifted
  /// since the read), false when no snapshot was ever recorded for it (likely
  /// a fabricated or stale-session tag).
  final bool hashRecognized;

  /// The human-readable rejection message from the hashline core.
  final String message;
}

/// The outcome of [FileEditService.apply].
///
/// On success [changes] lists every file written and [failures] is empty. On
/// failure NOTHING was written: [failures] lists the sections that could not be
/// prepared and [heldBack] lists the sections that prepared cleanly but were
/// held back by the atomic all-or-nothing commit.
class FileEditResult {
  /// Creates a successful [FileEditResult]. [failures] and [heldBack] are empty.
  const FileEditResult.success({required this.changes})
    : applied = true,
      failures = const [],
      heldBack = const [];

  /// Creates a failed [FileEditResult]. [changes] is empty (nothing written).
  const FileEditResult.failure({
    required this.failures,
    required this.heldBack,
  }) : applied = false,
       changes = const [];

  /// Whether the whole patch applied and every file was written.
  final bool applied;

  /// Per-file changes that were written (empty on failure).
  final List<FileEditChange> changes;

  /// Per-file failures (empty on success).
  final List<FileEditFailure> failures;

  /// Paths that prepared successfully but were held back because the patch as a
  /// whole failed (atomic commit). Empty on success.
  final List<String> heldBack;

  /// A clear, agent-readable summary of the outcome.
  String get summary {
    if (applied) {
      if (changes.isEmpty) {
        return 'No files changed.';
      }
      final parts = changes.map((c) {
        final where = c.firstChangedLine == null
            ? 'no line change'
            : 'first change at line ${c.firstChangedLine}';
        final warn = c.warnings.isEmpty
            ? ''
            : ' (${c.warnings.join('; ')})';
        return '${c.path}: $where$warn';
      });
      return 'Applied ${changes.length} file(s): ${parts.join(', ')}.';
    }
    final buffer = StringBuffer()
      ..write('Patch rejected — no files were written. ');
    buffer.write('${failures.length} section(s) failed:');
    for (final f in failures) {
      buffer.write('\n  - ${f.message}');
    }
    if (heldBack.isNotEmpty) {
      buffer.write(
        '\n${heldBack.length} section(s) would have applied but were held '
        'back for atomicity: ${heldBack.join(', ')}.',
      );
    }
    return buffer.toString();
  }
}

/// Applies hashline patches to files on disk with snapshot-backed recovery.
///
/// One instance should live for the duration of a worktree edit session: its
/// in-memory snapshot cache is the recovery basis. Every live read and every
/// successful write seeds the cache, so a follow-up edit anchored to a version
/// this session has seen can recover through a three-way merge even after the
/// file drifts on disk.
class FileEditService implements SnapshotStore {
  /// Creates a [FileEditService] with an optional [blockResolver] for resolving
  /// block-anchored edits to concrete spans.
  FileEditService({BlockResolver? blockResolver})
    : _blockResolver = blockResolver;

  final BlockResolver? _blockResolver;

  /// Normalized path → {content hash → normalized content}. The recovery
  /// basis: a section anchored to any hash this session has seen for the path
  /// can three-way-merge against the live file even after external drift.
  ///
  /// Keyed by hash (not just "latest content") so a live read of a drifted
  /// version does not evict an earlier version the section may still be
  /// anchored to.
  final Map<String, Map<String, String>> _snapshotCache = {};

  /// Caches [content] for [path] keyed by its content hash.
  void _cache(String path, String content) {
    final normalized = normalizeContent(content);
    (_snapshotCache[p.normalize(path)] ??= {})[computeContentHash(normalized)] =
        normalized;
  }

  /// Records [content] for [path] as a known version, enabling recovery against
  /// it on a later edit even before this session has read the file itself.
  ///
  /// [content] is normalized before storage so it hashes identically to a live
  /// read.
  void recordSnapshot(String path, String content) => _cache(path, content);

  /// The 4-hex content hash of [content], for callers building a [Section]'s
  /// `fileHash`.
  String computeHashFor(String content) => computeContentHash(content);

  @override
  String? textForHash(String path, String fourHexHash) =>
      _snapshotCache[p.normalize(path)]?[fourHexHash];

  /// Reads, validates, and applies [patch] against the real filesystem.
  ///
  /// Reads each section's live content (a missing file is treated as empty),
  /// seeds the snapshot cache with it, then runs the hashline [Patcher]. When
  /// every section prepares successfully the new content is written to each
  /// file (creating parent directories as needed) and the cache is updated;
  /// otherwise NOTHING is written and the failures are returned.
  Future<FileEditResult> apply(Patch patch) async {
    Future<String?> readLive(String path) async {
      final file = File(path);
      if (!file.existsSync()) {
        return null;
      }
      final normalized = normalizeContent(await file.readAsString());
      // Seed the cache so subsequent edits this session can recover.
      _cache(path, normalized);
      return normalized;
    }

    final patcher = Patcher(blockResolver: _blockResolver, snapshots: this);
    final result = await patcher.apply(patch, readLive: readLive);

    if (!result.allApplied) {
      final failures = <FileEditFailure>[];
      final heldBack = <String>[];
      for (final section in result.sections) {
        if (section.isApplied) {
          heldBack.add(section.path);
          continue;
        }
        final error = section.error!;
        failures.add(
          FileEditFailure(
            path: error.path,
            expectedHash: error.expectedFileHash,
            actualHash: error.actualFileHash,
            hashRecognized: error.hashRecognized,
            message: error.message,
          ),
        );
      }
      return FileEditResult.failure(failures: failures, heldBack: heldBack);
    }

    // All sections prepared — commit atomically.
    final changes = <FileEditChange>[];
    for (final section in result.sections) {
      final newContent = section.newContent!;
      final file = File(section.path);
      await file.parent.create(recursive: true);
      await file.writeAsString(newContent);
      _cache(section.path, newContent);
      changes.add(
        FileEditChange(
          path: section.path,
          firstChangedLine: section.firstChangedLine,
          warnings: section.warnings,
        ),
      );
    }
    return FileEditResult.success(changes: changes);
  }
}
