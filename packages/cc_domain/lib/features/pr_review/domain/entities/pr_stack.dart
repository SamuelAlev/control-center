/// State of a pull request inside a stack, as reported by the GitHub stacks
/// API (`open` / `closed`; a merged PR reports `closed` plus a `mergedAt`).
enum PrStackEntryState {
  /// Open.
  open,

  /// Closed (merged or not — check [PrStackEntry.mergedAt]).
  closed;

  /// Parses the API `state` string; unknown values degrade to [closed] so a
  /// new GitHub value never crashes the parser.
  static PrStackEntryState fromString(String? value) =>
      value == 'open' ? PrStackEntryState.open : PrStackEntryState.closed;
}

/// One pull request's membership in a [PrStack], in bottom-to-top order.
///
/// The GitHub stacks API returns a minimal shape (no title/author/diff stats);
/// surfaces that need those enrich the entry by matching [number] against the
/// open-PR list snapshot.
class PrStackEntry {
  /// Creates a [PrStackEntry].
  PrStackEntry({
    required this.number,
    required this.state,
    required this.isDraft,
    required this.headRef,
    required this.headSha,
    this.mergedAt,
  }) {
    if (number <= 0) {
      throw ArgumentError('PR number must be positive');
    }
  }

  /// PR number within the repository.
  final int number;

  /// Whether the PR is open.
  final PrStackEntryState state;

  /// Whether the PR is a draft.
  final bool isDraft;

  /// Head branch ref name.
  final String headRef;

  /// SHA of the head commit.
  final String headSha;

  /// Merge timestamp; non-null marks the entry as merged.
  final DateTime? mergedAt;

  /// Whether this entry merged (vs. merely closed).
  bool get isMerged => mergedAt != null;

  @override
  bool operator ==(Object other) =>
      other is PrStackEntry &&
      other.number == number &&
      other.state == state &&
      other.isDraft == isDraft &&
      other.headRef == headRef &&
      other.headSha == headSha &&
      other.mergedAt == mergedAt;

  @override
  int get hashCode =>
      Object.hash(number, state, isDraft, headRef, headSha, mergedAt);
}

/// A GitHub pull request stack: an ordered chain of PRs where each PR's base
/// ref is the previous PR's head ref. [pullRequests] runs bottom to top — the
/// first entry merges into the stack's [baseRef], the last is the tip.
class PrStack {
  /// Creates a [PrStack].
  PrStack({
    required this.id,
    required this.number,
    required this.externalId,
    required this.url,
    required this.baseRef,
    required this.open,
    required this.pullRequests,
    this.createdAt,
  }) {
    if (number <= 0) {
      throw ArgumentError('Stack number must be positive');
    }
  }

  /// GitHub's stack identifier.
  final int id;

  /// Stack number within the repository (used by the stacks endpoints).
  final int number;

  /// Global node ID.
  final String externalId;

  /// API URL of the stack.
  final String url;

  /// The ref the bottom PR of the stack targets.
  final String baseRef;

  /// Whether the stack is open.
  final bool open;

  /// Creation timestamp.
  final DateTime? createdAt;

  /// The stacked pull requests, bottom to top.
  final List<PrStackEntry> pullRequests;

  /// The entry for PR [prNumber], or null when it isn't in this stack.
  PrStackEntry? entryFor(int prNumber) {
    for (final entry in pullRequests) {
      if (entry.number == prNumber) {
        return entry;
      }
    }
    return null;
  }

  /// Whether PR [prNumber] belongs to this stack.
  bool contains(int prNumber) => entryFor(prNumber) != null;

  @override
  bool operator ==(Object other) =>
      other is PrStack &&
      other.id == id &&
      other.number == number &&
      other.externalId == externalId &&
      other.url == url &&
      other.baseRef == baseRef &&
      other.open == open &&
      other.createdAt == createdAt &&
      _listEquals(other.pullRequests, pullRequests);

  @override
  int get hashCode => Object.hash(
    id,
    number,
    externalId,
    url,
    baseRef,
    open,
    createdAt,
    Object.hashAll(pullRequests),
  );

  static bool _listEquals(List<PrStackEntry> a, List<PrStackEntry> b) {
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
