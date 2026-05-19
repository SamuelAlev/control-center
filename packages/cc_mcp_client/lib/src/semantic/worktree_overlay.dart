import 'package:path/path.dart' as p;

/// A single vector-search hit, transport-agnostic.
class SemanticHit {
  /// Creates a [SemanticHit].
  const SemanticHit({
    required this.filePath,
    required this.startLine,
    required this.endLine,
    required this.score,
    required this.content,
    this.fileHash,
  });

  /// Repo-relative file path.
  final String filePath;

  /// 1-based first line.
  final int startLine;

  /// 1-based last line.
  final int endLine;

  /// Similarity score.
  final double score;

  /// The chunk text.
  final String content;

  /// The file hash the chunk was indexed at (for baseline validation).
  final String? fileHash;

  /// Stable identity for de-dup across the baseline + delta result sets.
  String get dedupeKey => '$filePath:$startLine:$endLine';
}

/// Resolves the current on-disk hash of a file (repo-relative path). Returns
/// null when the file is gone. Injected so the overlay is testable off-disk.
typedef FileHasher = Future<String?> Function(String relativePath);

/// Reuses a shared, committed-baseline code index across many worktrees instead
/// of re-embedding the whole repo per worktree (PRD 01 phase 1.6).
///
/// A worktree only diverges from the shared baseline in a handful of files. The
/// overlay tracks:
/// * **baseline** — `relpath → fileHash` of the shared committed index.
/// * **shadows** — files whose working-tree hash differs from the baseline;
///   their baseline chunks are stale and must be re-embedded into the worktree-
///   local delta index.
/// * **blocked** — files currently being re-embedded (in flight); their hits
///   are suppressed until settled to avoid serving half-indexed state.
///
/// At search time, a baseline hit is accepted only if the file is neither
/// shadowed nor blocked AND its current hash still matches the baseline (a
/// last-line defence against a missed shadow). A delta (worktree-local) hit is
/// accepted unless the file is blocked.
class WorktreeOverlay {
  /// Creates a [WorktreeOverlay].
  WorktreeOverlay({
    required this.workspacePath,
    required Map<String, String> baseline,
    required FileHasher fileHasher,
  }) : _baseline = Map.unmodifiable(baseline),
       _fileHasher = fileHasher;

  /// Absolute path of the current worktree root.
  final String workspacePath;

  final Map<String, String> _baseline;
  final FileHasher _fileHasher;

  final Set<String> _shadows = {};
  final Set<String> _blocked = {};
  bool _ready = false;

  /// Files diverged from the baseline.
  Set<String> get shadows => Set.unmodifiable(_shadows);

  /// Files currently being (re-)indexed.
  Set<String> get blocked => Set.unmodifiable(_blocked);

  /// Whether [reconcile] has run for the current batch.
  bool get ready => _ready;

  /// The baseline `relpath → hash` map.
  Map<String, String> get baseline => _baseline;

  /// Converts an absolute path to a normalised repo-relative one, or null when
  /// it escapes the worktree.
  String? relative(String absolutePath) {
    final rel = p.relative(absolutePath, from: workspacePath);
    if (rel.startsWith('..') || p.isAbsolute(rel)) {
      return null;
    }
    return p.normalize(rel).replaceAll(r'\', '/');
  }

  /// The baseline hash for a repo-relative [relativePath], if indexed.
  String? baselineHash(String relativePath) => _baseline[relativePath];

  /// Resets per-batch state before a fresh reconcile.
  void prepare() {
    _shadows.clear();
    _blocked.clear();
    _ready = false;
  }

  /// Marks [relativePath] as in-flight (being re-embedded).
  void block(String relativePath) => _blocked.add(relativePath);

  /// Records the outcome of (re-)hashing [relativePath]: a hash differing from
  /// the baseline marks it shadowed; a matching hash clears the shadow. When
  /// not [pending], the file is removed from the blocked set.
  void settle(String relativePath, String hash, {bool pending = false}) {
    final base = _baseline[relativePath];
    if (base != hash) {
      _shadows.add(relativePath);
    } else {
      _shadows.remove(relativePath);
    }
    if (!pending) {
      _blocked.remove(relativePath);
    }
  }

  /// Rebuilds the shadow set from the current working-tree hashes
  /// (`relpath → hash`) and marks the overlay [ready]. A file present in the
  /// baseline but absent from [current] (deleted) is shadowed.
  void reconcile(Map<String, String> current) {
    _shadows.clear();
    for (final entry in _baseline.entries) {
      final now = current[entry.key];
      if (now != entry.value) {
        _shadows.add(entry.key);
      }
    }
    // Files new in the worktree (not in baseline) are delta-only; nothing to
    // shadow for them.
    _ready = true;
  }

  /// Whether a *baseline* search [hit] is still valid for this worktree.
  ///
  /// Re-hashes the file (caching the result in [checks] across the search's
  /// retries) and rejects the hit if the file is shadowed, blocked, deleted, or
  /// its hash no longer matches the baseline.
  Future<bool> acceptsBaselineHit(
    SemanticHit hit, {
    Map<String, String?>? checks,
  }) async {
    final path = hit.filePath;
    if (_shadows.contains(path) || _blocked.contains(path)) {
      return false;
    }
    final base = _baseline[path];
    if (base == null) {
      return false;
    }
    final cache = checks;
    String? currentHash;
    if (cache != null && cache.containsKey(path)) {
      currentHash = cache[path];
    } else {
      currentHash = await _fileHasher(path);
      cache?[path] = currentHash;
    }
    return currentHash != null && currentHash == base;
  }

  /// Whether a *delta* (worktree-local) search [hit] is valid — accepted unless
  /// the file is mid-flight.
  bool acceptsDeltaHit(SemanticHit hit) => !_blocked.contains(hit.filePath);

  /// Merges baseline + delta hits, de-duping by `file:start:end` (keeping the
  /// higher score) and returning the top [limit] by score.
  static List<SemanticHit> mergeRanked(
    Iterable<SemanticHit> baselineHits,
    Iterable<SemanticHit> deltaHits, {
    required int limit,
  }) {
    final byKey = <String, SemanticHit>{};
    for (final hit in [...deltaHits, ...baselineHits]) {
      final existing = byKey[hit.dedupeKey];
      if (existing == null || hit.score > existing.score) {
        byKey[hit.dedupeKey] = hit;
      }
    }
    final merged = byKey.values.toList()
      ..sort((a, b) => b.score.compareTo(a.score));
    return merged.length > limit ? merged.sublist(0, limit) : merged;
  }
}
