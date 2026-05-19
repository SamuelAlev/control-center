/// Git working-tree refs captured around an assistant turn, so a revert can
/// restore the filesystem to the state before/after that turn ran. Persisted
/// under an agent-turn message's `metadata['snapshot']`.
class TurnSnapshot {
  /// Creates a [TurnSnapshot].
  const TurnSnapshot({this.start, this.end});

  /// Opaque git ref for the working tree BEFORE the turn ran.
  final String? start;

  /// Opaque git ref for the working tree AFTER the turn ran.
  final String? end;

  /// Whether neither boundary was captured.
  bool get isEmpty => start == null && end == null;

  /// Serializes to the `metadata['snapshot']` shape.
  Map<String, dynamic> toJson() => {
        if (start != null) 'start': start,
        if (end != null) 'end': end,
      };

  /// Reads a [TurnSnapshot] from a message's metadata, or null when absent.
  static TurnSnapshot? fromMetadata(Map<String, dynamic>? metadata) {
    final raw = metadata?['snapshot'];
    if (raw is! Map) {
      return null;
    }
    final start = raw['start'] as String?;
    final end = raw['end'] as String?;
    if (start == null && end == null) {
      return null;
    }
    return TurnSnapshot(start: start, end: end);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TurnSnapshot && start == other.start && end == other.end;

  @override
  int get hashCode => Object.hash(start, end);
}

/// Builds the synthetic `<system-reminder>` injected into a forked session so
/// the agent understands that prior context was retained intentionally and,
/// when forking into a fresh worktree, which directory now supersedes the old
/// one. Ported from kilocode's fork handoff.
String buildForkHandoffReminder({String? directory}) {
  const forkedFrom =
      'This session was forked from an existing session in the current '
      'repository or worktree.';
  const supersedes =
      'For this fork, this location supersedes any earlier repository or '
      'worktree location retained in the copied context.';
  const retained = 'The prior conversation context was retained intentionally.';
  const mayContinue =
      'The user may continue the same task, explore an alternative approach, or '
      'provide new instructions.';
  const followNext =
      "Follow the user's next instruction as the direction for this fork, "
      'using retained context when relevant.';
  return [
    '<system-reminder>',
    forkedFrom,
    if (directory != null) ...[
      'Use this as the current working directory: $directory',
      supersedes,
    ],
    retained,
    mayContinue,
    followNext,
    '</system-reminder>',
  ].join('\n');
}
