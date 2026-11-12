/// A person holding mutating control of a space's worktree (take-over).
///
/// While it stands, no agent run is dispatched into the space and the runs
/// that were active are held: [pausedRunIds] resume when it is handed back,
/// [stoppedRunIds] (runs with no safe turn boundary) stay stopped.
final class SpaceTakeover {
  /// Creates a take-over of [spaceId] by [userId]. Throws [ArgumentError] on
  /// an empty space or user id.
  SpaceTakeover({
    required this.spaceId,
    required this.userId,
    required this.displayName,
    required this.since,
    List<String> pausedRunIds = const [],
    List<String> stoppedRunIds = const [],
  }) : pausedRunIds = List.unmodifiable(pausedRunIds),
       stoppedRunIds = List.unmodifiable(stoppedRunIds) {
    if (spaceId.isEmpty) {
      throw ArgumentError.value(spaceId, 'spaceId', 'must not be empty');
    }
    if (userId.isEmpty) {
      throw ArgumentError.value(userId, 'userId', 'must not be empty');
    }
  }

  /// The space taken over.
  final String spaceId;

  /// Who holds it.
  final String userId;

  /// The holder's name as shown when it started.
  final String displayName;

  /// When it started.
  final DateTime since;

  /// Runs paused at a turn boundary; resumed on hand-back.
  final List<String> pausedRunIds;

  /// Runs stopped because they had no safe turn boundary.
  final List<String> stoppedRunIds;

  /// The wire form `takeover.status` / `takeover.watch` answer with.
  Map<String, dynamic> toWire() => {
    'user_id': userId,
    'display_name': displayName,
    'since': since.toIso8601String(),
    'paused_run_ids': pausedRunIds,
    'stopped_run_ids': stoppedRunIds,
  };

  @override
  bool operator ==(Object other) =>
      other is SpaceTakeover &&
      other.spaceId == spaceId &&
      other.userId == userId &&
      other.displayName == displayName &&
      other.since == since &&
      _sameList(other.pausedRunIds, pausedRunIds) &&
      _sameList(other.stoppedRunIds, stoppedRunIds);

  @override
  int get hashCode => Object.hash(
    spaceId,
    userId,
    displayName,
    since,
    Object.hashAll(pausedRunIds),
    Object.hashAll(stoppedRunIds),
  );

  static bool _sameList(List<String> a, List<String> b) {
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
}
