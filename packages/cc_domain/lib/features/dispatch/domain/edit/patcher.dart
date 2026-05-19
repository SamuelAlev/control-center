/// The patch orchestrator.
///
/// [Patcher] validates and applies a [Patch] entirely in memory, never touching
/// the filesystem itself. The caller supplies live file content via a
/// `readLive` callback (the real file IO lives in the infrastructure layer) and
/// decides whether to persist based on the preflight result.
///
/// The contract is an **atomic multi-section preflight**: every section is read,
/// hash-validated, block-resolved, and applied in memory before anything is
/// reported as ready to write. A per-section hash mismatch (when recovery
/// fails) is surfaced as a [MismatchError] result entry, not thrown, so the
/// caller can inspect the whole batch and only commit when [PatcherApplyResult.allApplied]
/// is true. The only thrown errors are programmer errors (duplicate paths).
library;

import 'package:cc_domain/features/dispatch/domain/edit/apply_edits.dart';
import 'package:cc_domain/features/dispatch/domain/edit/block_resolver.dart';
import 'package:cc_domain/features/dispatch/domain/edit/content_hash.dart';
import 'package:cc_domain/features/dispatch/domain/edit/edit.dart';
import 'package:cc_domain/features/dispatch/domain/edit/recovery.dart';

/// A cache of full-file versions keyed by content hash, used for recovery.
///
/// When a section's hash does not match the live file, the patcher asks the
/// store for the cached version whose content hashes to that 4-hex tag. The
/// returned text is the snapshot recovery replays the edit against. Pure seam:
/// the implementation (LRU, persistent, …) lives outside this package.
abstract class SnapshotStore {
  /// The cached full text for [path] whose content hashes to [fourHexHash], or
  /// null when no such version is retained.
  String? textForHash(String path, String fourHexHash);
}

/// The outcome of preparing one [Section].
///
/// Exactly one of [error] / "applied" state is meaningful: when [error] is
/// non-null the section failed hash validation and could not be recovered; when
/// it is null the section was applied in memory and [newContent] holds the
/// result.
class PreparedSection {
  /// Creates a successfully-prepared section.
  const PreparedSection.applied({
    required this.path,
    required this.liveContent,
    required this.newContent,
    required this.fileHash,
    required this.isNoop,
    this.firstChangedLine,
    this.warnings = const [],
  }) : error = null;

  /// Creates a failed section carrying its [MismatchError].
  const PreparedSection.failed({
    required this.path,
    required this.liveContent,
    required MismatchError this.error,
  }) : newContent = null,
       fileHash = null,
       isNoop = false,
       firstChangedLine = null,
       warnings = const [];

  /// The section's target path.
  final String path;

  /// The live, normalized content read for [path].
  final String liveContent;

  /// The post-edit content, or null when the section failed validation.
  final String? newContent;

  /// The 4-hex content hash of [newContent], or null when the section failed.
  final String? fileHash;

  /// Whether the apply produced no change (`newContent == liveContent`).
  final bool isNoop;

  /// First 1-indexed changed line in [newContent], or null for a noop/failure.
  final int? firstChangedLine;

  /// Warnings collected during apply / recovery.
  final List<String> warnings;

  /// The mismatch error when the section failed validation, else null.
  final MismatchError? error;

  /// Whether this section was prepared successfully (no [error]).
  bool get isApplied => error == null;
}

/// The result of [Patcher.apply]: one [PreparedSection] per input section.
class PatcherApplyResult {
  /// Creates a [PatcherApplyResult].
  const PatcherApplyResult({required this.sections});

  /// Per-section results, in the original patch order.
  final List<PreparedSection> sections;

  /// Whether every section was applied successfully and the whole patch is
  /// safe to write to disk.
  bool get allApplied => sections.every((s) => s.isApplied);
}

/// Raised (as a *result entry*, never thrown) when a section's hash does not
/// match the live file and recovery is unavailable or failed.
///
/// Carries the expected and actual hashes plus [hashRecognized] — whether the
/// expected hash resolved to a cached snapshot (the file drifted) or was never
/// recorded (likely fabricated or from a prior session) — so the caller can
/// render an actionable rejection.
class MismatchError {
  /// Creates a [MismatchError].
  const MismatchError({
    required this.path,
    required this.expectedFileHash,
    required this.actualFileHash,
    required this.hashRecognized,
  });

  /// The section's target path.
  final String path;

  /// The 4-hex hash the section was anchored to.
  final String expectedFileHash;

  /// The 4-hex hash the live file actually has.
  final String actualFileHash;

  /// True when [expectedFileHash] resolved to a cached snapshot (the file
  /// drifted since), false when no snapshot was ever recorded for it.
  final bool hashRecognized;

  /// A human-readable rejection message.
  String get message {
    if (!hashRecognized) {
      return 'Edit rejected for $path: hash #$expectedFileHash is not from '
          'this session. The current file hashes to #$actualFileHash. '
          'Re-read the file to copy a current tag.';
    }
    return 'Edit rejected for $path: file changed between read and edit. '
        'Section is bound to #$expectedFileHash, but the current file hashes '
        'to #$actualFileHash. Re-read the file to refresh the tag.';
  }

  @override
  String toString() => 'MismatchError($message)';
}

/// Thrown only for programmer errors in a patch (e.g. duplicate paths).
class PatchStructureException implements Exception {
  /// Creates a [PatchStructureException].
  const PatchStructureException(this.message);

  /// Description of the structural problem.
  final String message;

  @override
  String toString() => 'PatchStructureException: $message';
}

/// Orchestrates validating and applying a [Patch] in memory.
///
/// Stateless across calls aside from the injected [blockResolver] and
/// [snapshots]; reuse one instance. The filesystem is entirely external — the
/// caller passes a `readLive` callback and writes nothing until
/// [PatcherApplyResult.allApplied] is true.
class Patcher {
  /// Creates a [Patcher].
  const Patcher({this.blockResolver, this.snapshots});

  /// Resolves block-anchored edits to concrete spans. Optional: a replace/delete
  /// [BlockEdit] with no resolver yields a failed section (via
  /// [BlockResolutionException] surfaced as a mismatch on the missing snapshot
  /// path); an insert-after block lowers to a plain insert with a warning.
  final BlockResolver? blockResolver;

  /// Recovery snapshot store. Optional: without it, a hash mismatch is always a
  /// hard [MismatchError] (no recovery is attempted).
  final SnapshotStore? snapshots;

  /// Prepare and apply every section of [patch] in memory.
  ///
  /// Phase 1 prepares all sections: reads live content via [readLive],
  /// validates the section hash (recovering against [snapshots] on mismatch),
  /// and applies the edits. Phase 2 collects the prepared results. Per-section
  /// failures are returned as [PreparedSection]s carrying a [MismatchError] —
  /// nothing is thrown for them. Duplicate canonical paths in one patch are a
  /// programmer error and throw [PatchStructureException].
  Future<PatcherApplyResult> apply(
    Patch patch, {
    required Future<String?> Function(String path) readLive,
  }) async {
    _assertUniquePaths(patch.sections);

    final prepared = <PreparedSection>[];
    for (final section in patch.sections) {
      prepared.add(await _prepare(section, readLive));
    }
    return PatcherApplyResult(sections: prepared);
  }

  void _assertUniquePaths(List<Section> sections) {
    final seen = <String>{};
    for (final section in sections) {
      if (!seen.add(section.path)) {
        throw PatchStructureException(
          'Multiple sections target the same path (${section.path}). Merge '
          'their edits under one section before applying.',
        );
      }
    }
  }

  Future<PreparedSection> _prepare(
    Section section,
    Future<String?> Function(String path) readLive,
  ) async {
    final raw = await readLive(section.path);
    final live = normalizeContent(raw ?? '');
    final liveHash = computeContentHash(live);

    // Lower convenience ReplaceEdits, then resolve any block edits. Block
    // anchors are expressed against the version the tag names: resolve against
    // live content when it still matches the tag, otherwise against the cached
    // snapshot so the resulting ranges flow through recovery.
    final lowered = lowerReplaceEdits(section.edits);

    if (liveHash == section.fileHash) {
      return _applyResolved(
        section: section,
        baseForBlocks: live,
        live: live,
        edits: lowered,
      );
    }

    // Hash mismatch: try recovery against the cached snapshot.
    final snapshot = snapshots?.textForHash(section.path, section.fileHash);
    final hashRecognized = snapshot != null;
    if (snapshot != null) {
      // Resolve blocks against the snapshot so spans match the tagged content.
      final ResolveBlockResult resolvedForRecovery;
      try {
        resolvedForRecovery = resolveBlockEdits(
          lowered,
          snapshot,
          section.path,
          blockResolver,
        );
      } on BlockResolutionException {
        return PreparedSection.failed(
          path: section.path,
          liveContent: live,
          error: MismatchError(
            path: section.path,
            expectedFileHash: section.fileHash,
            actualFileHash: liveHash,
            hashRecognized: hashRecognized,
          ),
        );
      }
      final recovered = tryRecover(
        previousText: snapshot,
        currentText: live,
        edits: resolvedForRecovery.edits,
        anchorLines: section.collectAnchorLines(),
      );
      if (recovered != null) {
        final newContent = recovered.text;
        return PreparedSection.applied(
          path: section.path,
          liveContent: live,
          newContent: newContent,
          fileHash: computeContentHash(newContent),
          isNoop: newContent == live,
          firstChangedLine: _firstChangedLine(live, newContent),
          warnings: [...resolvedForRecovery.warnings, ...recovered.warnings],
        );
      }
    }

    return PreparedSection.failed(
      path: section.path,
      liveContent: live,
      error: MismatchError(
        path: section.path,
        expectedFileHash: section.fileHash,
        actualFileHash: liveHash,
        hashRecognized: hashRecognized,
      ),
    );
  }

  PreparedSection _applyResolved({
    required Section section,
    required String baseForBlocks,
    required String live,
    required List<Edit> edits,
  }) {
    final ResolveBlockResult resolved;
    try {
      resolved = resolveBlockEdits(
        edits,
        baseForBlocks,
        section.path,
        blockResolver,
      );
    } on BlockResolutionException {
      // A replace/delete block with no safe lowering: reject this section. The
      // live content is the version the tag names, so report a mismatch with
      // the live hash on both sides (the failure is resolution, not drift).
      final liveHash = computeContentHash(live);
      return PreparedSection.failed(
        path: section.path,
        liveContent: live,
        error: MismatchError(
          path: section.path,
          expectedFileHash: section.fileHash,
          actualFileHash: liveHash,
          hashRecognized: true,
        ),
      );
    }

    final result = applyEdits(live, resolved.edits);
    final newContent = result.text;
    return PreparedSection.applied(
      path: section.path,
      liveContent: live,
      newContent: newContent,
      fileHash: computeContentHash(newContent),
      isNoop: newContent == live,
      firstChangedLine: result.firstChangedLine,
      warnings: [...resolved.warnings, ...result.warnings],
    );
  }

  int? _firstChangedLine(String a, String b) {
    if (a == b) {
      return null;
    }
    final aLines = a.split('\n');
    final bLines = b.split('\n');
    final max = aLines.length > bLines.length ? aLines.length : bLines.length;
    for (var i = 0; i < max; i++) {
      final aLine = i < aLines.length ? aLines[i] : null;
      final bLine = i < bLines.length ? bLines[i] : null;
      if (aLine != bLine) {
        return i + 1;
      }
    }
    return null;
  }
}
