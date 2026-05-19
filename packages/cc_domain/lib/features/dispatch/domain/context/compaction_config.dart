/// Tunables for anchored conversation compaction.
///
/// Compaction fires when the live (non-compacted) region of a conversation
/// grows close to the model's context window. The newest turns are kept
/// verbatim; everything older is folded into an anchored summary that carries
/// the prior summary forward (preserve still-true, drop stale, merge new).
class CompactionConfig {
  /// Creates a [CompactionConfig].
  const CompactionConfig({
    this.auto = true,
    this.prune = true,
    this.keepTurns = 3,
    this.keepTokens,
    this.buffer = 8000,
  })  : assert(keepTurns >= 1, 'must keep at least one turn verbatim'),
        assert(buffer >= 0, 'buffer must be non-negative');

  /// Whether compaction triggers automatically on context pressure. When false
  /// only an explicit (manual) compaction request compacts.
  final bool auto;

  /// Whether selective tool-output pruning runs alongside compaction.
  final bool prune;

  /// Number of newest turns (delimited by user messages) kept verbatim.
  final int keepTurns;

  /// Optionally keep the newest turns worth of this many tokens verbatim.
  /// When set, the kept region is the LARGER of [keepTurns] turns and the
  /// turns that fit in [keepTokens] — so a few very large turns are not split.
  final int? keepTokens;

  /// Headroom (tokens) kept free below the context window. Auto-compaction
  /// triggers once `usage + buffer >= contextWindow`.
  final int buffer;

  /// The default configuration.
  static const CompactionConfig defaults = CompactionConfig();

  /// Returns a copy with selected fields overridden.
  CompactionConfig copyWith({
    bool? auto,
    bool? prune,
    int? keepTurns,
    int? keepTokens,
    int? buffer,
  }) =>
      CompactionConfig(
        auto: auto ?? this.auto,
        prune: prune ?? this.prune,
        keepTurns: keepTurns ?? this.keepTurns,
        keepTokens: keepTokens ?? this.keepTokens,
        buffer: buffer ?? this.buffer,
      );
}
