/// A deterministic supervisor over the run's task checklist.
///
/// The failure it exists for: an agent opens a checklist, appends to it and
/// then never transitions anything — it works for a dozen turns while the user
/// stares at a list of `pending` items that says nothing about where the run
/// actually is. The tool's own result can flag *shape* problems (nothing
/// in_progress, several in_progress, items dropped by a short re-send) because
/// it is read on every call — but it is powerless against the case that matters
/// most, an agent that simply stops calling it.
///
/// This closes that gap from the loop side and deliberately does so WITHOUT a
/// model: staleness is a counting problem, so the check is free, instant and
/// cannot hallucinate. It rides the same seam as the doom-loop repetition guard
/// (observe the turn's tool calls, inject one `system` steer, re-arm), rather
/// than spending a second model's tokens on it via the `Advisor` watchdog.
library;

import 'dart:convert';

/// Status values the checklist tool accepts, in its own wire spelling.
const String _pending = 'pending';
const String _inProgress = 'in_progress';

/// Watches a run's checklist writes and produces a steering note when the list
/// has gone stale — the agent has open items but has done real work for several
/// turns without updating them.
///
/// Stateful and single-run: construct one per loop. Pure apart from that state,
/// so the whole policy is unit-testable without a provider.
class ChecklistSupervisor {
  /// Creates a supervisor.
  ///
  /// [staleAfterTurns] is how many tool-bearing turns of other work may pass
  /// with open checklist items before the nudge fires; values below 1 are
  /// treated as 1. [maxNudges] caps how many times a single run is steered, so
  /// an agent that keeps ignoring the note is told a few times and then left
  /// alone — nagging every turn would burn context and train the model to skip
  /// system notes wholesale.
  ChecklistSupervisor({
    this.toolName = 'todo_write',
    int staleAfterTurns = 4,
    this.maxNudges = 2,
  }) : staleAfterTurns = staleAfterTurns < 1 ? 1 : staleAfterTurns;

  /// The checklist-write tool this supervisor watches.
  final String toolName;

  /// Tool-bearing turns of other work tolerated before nudging.
  final int staleAfterTurns;

  /// Maximum nudges emitted over the whole run.
  final int maxNudges;

  /// Tool-bearing turns since the last checklist write.
  int _turnsSinceWrite = 0;

  /// Nudges emitted so far.
  int _nudges = 0;

  /// Whether the current staleness episode has already been nudged. Cleared by
  /// the next write, so a run that goes stale twice is steered twice.
  bool _nudgedThisEpisode = false;

  /// The item the last write left in_progress, if any.
  String? _active;

  /// The first item the last write left pending, if any.
  String? _nextPending;

  /// Whether the last write left anything unfinished. Until the first write
  /// there is no checklist to be stale about, so nothing fires.
  bool _hasOpenWork = false;

  /// Records one tool-bearing turn's [calls] (name → decoded arguments, in the
  /// order the model emitted them) and returns the steering note to inject
  /// before the next turn, or null to stay silent.
  ///
  /// A turn that writes the checklist is always silent: the write's own result
  /// already carries the shape feedback and re-stating it here would double the
  /// nag on the one turn the agent did the right thing.
  String? observeTurn(List<({String name, Map<String, dynamic> args})> calls) {
    final write = _lastChecklistWrite(calls);
    if (write != null) {
      _ingest(write);
      _turnsSinceWrite = 0;
      _nudgedThisEpisode = false;
      return null;
    }

    _turnsSinceWrite++;
    if (!_hasOpenWork ||
        _nudgedThisEpisode ||
        _nudges >= maxNudges ||
        _turnsSinceWrite < staleAfterTurns) {
      return null;
    }
    _nudgedThisEpisode = true;
    _nudges++;
    return _note();
  }

  /// Drops the staleness counter without forgetting the checklist state — for
  /// history rewrites (compaction, rewind), where the turn count no longer
  /// describes how long the agent has been ignoring its list. The list itself is
  /// persisted server-side and survives, so [_hasOpenWork] stays valid.
  void resetCadence() {
    _turnsSinceWrite = 0;
    _nudgedThisEpisode = false;
  }

  /// The most recent checklist write in [calls], or null when the turn had none.
  Map<String, dynamic>? _lastChecklistWrite(
    List<({String name, Map<String, dynamic> args})> calls,
  ) {
    final target = _normalize(toolName);
    for (final call in calls.reversed) {
      if (_normalize(call.name) == target) {
        return call.args;
      }
    }
    return null;
  }

  /// Reads the checklist state out of a write's arguments. Unparseable args
  /// (a malformed call the tool itself will reject) leave the prior state
  /// untouched rather than inventing one.
  void _ingest(Map<String, dynamic> args) {
    final raw = args['todos'];
    if (raw is! List) {
      return;
    }
    String? active;
    String? nextPending;
    var open = false;
    for (final item in raw) {
      if (item is! Map) {
        continue;
      }
      final content = item['content'];
      final status = item['status'];
      if (content is! String || status is! String) {
        continue;
      }
      if (status == _inProgress) {
        open = true;
        active ??= content;
      } else if (status == _pending) {
        open = true;
        nextPending ??= content;
      }
    }
    _active = active;
    _nextPending = nextPending;
    _hasOpenWork = open;
  }

  String _note() {
    final buf = StringBuffer(
      'Your task checklist is out of date: $_turnsSinceWrite turns of work have '
      'gone by without a `$toolName` call. ',
    );
    final active = _active;
    if (active != null) {
      buf.write(
        'It still shows "$active" as in_progress. If that is finished, call '
        '`$toolName` now with it completed; if you have moved on to something '
        'else, mark that instead. ',
      );
    } else {
      final next = _nextPending;
      buf.write(
        next != null
            ? 'Nothing is in_progress and "$next" is still pending. Call '
                  '`$toolName` now to mark what you are actually working on. '
            : 'Call `$toolName` now so it reflects what you are actually '
                  'working on. ',
      );
    }
    buf.write(
      'Remember to pass the FULL list and to keep the status of every item '
      'current as you go — a checklist the user cannot trust is worse than no '
      'checklist.',
    );
    return buf.toString();
  }

  /// Folds a wire tool name to its bare, lowercase form: strips an
  /// `mcp__<server>__` prefix so a bridged tool matches its own name.
  static String _normalize(String raw) {
    final lower = raw.trim().toLowerCase();
    if (!lower.startsWith('mcp__')) {
      return lower;
    }
    final idx = lower.lastIndexOf('__');
    return idx >= 0 ? lower.substring(idx + 2) : lower;
  }
}

/// Decodes a tool call's arguments for [ChecklistSupervisor.observeTurn].
///
/// The loop holds args as a decoded map already; adapters that carry them as a
/// JSON string use this so a malformed payload degrades to an empty map instead
/// of throwing inside the supervisor.
Map<String, dynamic> decodeChecklistArgs(Object? args) {
  if (args is Map<String, dynamic>) {
    return args;
  }
  if (args is Map) {
    return args.cast<String, dynamic>();
  }
  if (args is String && args.trim().isNotEmpty) {
    try {
      final decoded = jsonDecode(args);
      if (decoded is Map) {
        return decoded.cast<String, dynamic>();
      }
    } on FormatException {
      return const {};
    }
  }
  return const {};
}
