import 'package:cc_harness/context.dart';
import 'package:cc_harness/loop.dart';
import 'package:cc_harness/messages.dart';
import 'package:cc_harness/provider.dart';

/// A watchdog [Advisor] backed by an [LlmProviderPort]: a cheap second model
/// silently watches the driving agent work and flags real problems.
///
/// Unlike a stateless one-shot reviewer, it keeps its **own append-only
/// context** and feeds the model only the primary transcript appended since its
/// last review (a "Session update" delta), so the reviewer accumulates
/// continuity across turns without re-sending the whole history each time.
/// Its output runs through an
/// [AdvisorEmissionGuard] that drops content-free noise, exact repeats and
/// de-escalations before a note ever reaches the primary.
///
/// Contract with the reviewer model (enforced in [_parse] + the guard, not just
/// prose): reply `OK` for nothing to flag (the common case) or a single
/// `<severity>: <sentence>` line where severity is `nit`, `concern`, or
/// `blocker`.
///
/// The call is cache-free and never throws — a provider failure returns null
/// and, after a few in a row, the advisor goes quiet for the rest of the run
/// (re-armed by `reset`).
class WatchdogAdvisor implements Advisor {
  /// Creates a [WatchdogAdvisor] over `provider`.
  ///
  /// [model] optionally overrides the reviewer model (a bare id the run's
  /// provider serves — typically a cheaper/faster sibling). [attention] is
  /// `WATCHDOG.md` content the reviewer should weigh especially; [projectContext]
  /// is the project's standing instructions (AGENTS.md / CLAUDE.md) so it holds
  /// the agent to conventions instead of advising against them; [extraInstructions]
  /// is any `advisor.instructions` from `.agents/harness.json`.
  WatchdogAdvisor(
    this._provider, {
    String? model,
    String? attention,
    String? projectContext,
    String? extraInstructions,
    int maxConvoMessages = 24,
    int maxConsecutiveFailures = 3,
    AdvisorEmissionGuard? guard,
  }) : _model = model,
       _maxConvoMessages = maxConvoMessages,
       _maxConsecutiveFailures = maxConsecutiveFailures,
       _guard = guard ?? AdvisorEmissionGuard(),
       _system = _buildSystem(
         attention: attention,
         projectContext: projectContext,
         extraInstructions: extraInstructions,
       );

  final LlmProviderPort _provider;
  final String? _model;
  final String _system;
  final int _maxConvoMessages;
  final int _maxConsecutiveFailures;
  final AdvisorEmissionGuard _guard;

  /// The reviewer's own append-only conversation (delta user turns + its own
  /// replies). Never the primary transcript — deltas are digested first.
  final List<HarnessMessage> _convo = [];

  /// How far into the primary history has already been delivered to the
  /// reviewer. Advanced only after a successful review so a failed one re-renders.
  int _cursor = 0;

  /// Consecutive provider failures; at [_maxConsecutiveFailures] the advisor
  /// stops reviewing until [reset].
  int _failures = 0;

  static final _severityPattern = RegExp(
    r'^\s*(nit|concern|blocker)\s*[:\-–—]\s*(.+)$',
    caseSensitive: false,
    dotAll: true,
  );

  static const String _baseline =
      'You are a terse senior reviewer silently watching another agent ("the '
      'agent") work through a coding task. You receive the conversation as '
      'incremental "Session update" deltas — the agent\'s latest turns, its '
      'tool actions and results.\n\n'
      'Judge ONLY whether the agent\'s most recent work has a real problem: a '
      'bug, a wrong assumption, a missed requirement, an unsafe or destructive '
      'action, or a repeated approach that plainly is not working. You are '
      'advice, not orders — the agent weighs your note.\n\n'
      'Respond with EXACTLY ONE of:\n'
      '- `OK` — nothing worth flagging (the common case; prefer silence).\n'
      '- `<severity>: <one concrete, actionable sentence>` — where <severity> '
      'is `nit`, `concern`, or `blocker`.\n\n'
      'Rules: at most one note per update; be specific and terse; NEVER repeat '
      'advice you already gave; do not praise, summarize, or narrate. When '
      'unsure, reply `OK`.';

  @override
  Future<AdvisorNote?> review(List<HarnessMessage> history) async {
    if (_failures >= _maxConsecutiveFailures) {
      return null; // gone quiet for this run until reset()
    }
    // The primary history shrank (compaction rewrote it without an explicit
    // reset) — re-prime rather than slice past the end.
    if (history.length < _cursor) {
      _resetContext();
    }

    final delta = serializeHarnessHistory(
      history.sublist(_cursor),
      selfAgentName: 'agent',
    ).trim();
    final newCursor = history.length;
    if (delta.isEmpty) {
      _cursor = newCursor; // nothing reviewable in the delta; skip past it
      return null;
    }

    final deltaMsg = HarnessMessage.user('### Session update\n\n$delta');
    _convo.add(deltaMsg);
    _trimConvo();

    final String reply;
    try {
      reply = await _complete();
    } on Object {
      // Roll the delta back out and leave the cursor put so the next review
      // re-renders it; a run of failures trips the quiet fuse above.
      _convo.remove(deltaMsg);
      _failures++;
      return null;
    }
    _failures = 0;
    _cursor = newCursor;
    // Record the reviewer's own reply so it remembers what it already said and
    // does not re-raise it next delta.
    _convo.add(HarnessMessage.assistant(reply.isEmpty ? 'OK' : reply));
    _trimConvo();

    final parsed = _parse(reply);
    if (parsed == null) {
      return null;
    }
    if (!_guard.accept(parsed.note, parsed.severity)) {
      return null;
    }
    return parsed;
  }

  @override
  void reset() {
    _resetContext();
    _guard.reset();
    _failures = 0;
  }

  void _resetContext() {
    _cursor = 0;
    _convo.clear();
  }

  Future<String> _complete() async {
    final buf = StringBuffer();
    await for (final event in _provider.complete(
      messages: List.of(_convo),
      config: LlmCompleteConfig(
        model: _model,
        systemPrompt: _system,
        maxTokens: 256,
        cacheEnabled: false,
      ),
    )) {
      switch (event) {
        case LlmTextDelta(:final text):
          buf.write(text);
        case LlmError():
          throw StateError('advisor provider error');
        default:
          break;
      }
    }
    return buf.toString().trim();
  }

  /// Parses the reviewer's reply into a note, or null when it is `OK`/empty.
  AdvisorNote? _parse(String reply) {
    final text = reply.trim();
    if (text.isEmpty) {
      return null;
    }
    final match = _severityPattern.firstMatch(text);
    final AdvisorSeverity severity;
    final String raw;
    if (match != null) {
      severity = _severityFromWord(match.group(1)!);
      raw = match.group(2)!;
    } else {
      // No explicit severity marker — take the whole reply as a plain nit; the
      // guard drops it if it is "OK"/noise.
      severity = AdvisorSeverity.nit;
      raw = text;
    }
    final note = raw.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (note.isEmpty) {
      return null;
    }
    // Keep it to one terse note — cap defensively.
    final capped = note.length > 400 ? '${note.substring(0, 397)}...' : note;
    return AdvisorNote(capped, severity: severity);
  }

  AdvisorSeverity _severityFromWord(String word) {
    switch (word.toLowerCase()) {
      case 'blocker':
        return AdvisorSeverity.blocker;
      case 'concern':
        return AdvisorSeverity.concern;
      default:
        return AdvisorSeverity.nit;
    }
  }

  void _trimConvo() {
    // Evict the oldest [user-delta, assistant-reply] PAIR at a time so the
    // conversation still starts with a user turn. Dropping only the leading
    // user would strand its assistant reply at index 0 and the Anthropic
    // Messages API rejects a leading assistant message — every later request
    // would 400 and, after a few, silently fuse the advisor for the rest of a
    // long run (exactly the /goal, /loop runs it exists to guard).
    while (_convo.length > _maxConvoMessages) {
      _convo.removeAt(0); // oldest user delta
      if (_convo.isNotEmpty && _convo.first.role == HarnessRole.assistant) {
        _convo.removeAt(0); // its paired assistant reply
      }
    }
  }

  static String _buildSystem({
    String? attention,
    String? projectContext,
    String? extraInstructions,
  }) {
    final buf = StringBuffer(_baseline);
    final ctx = projectContext?.trim();
    if (ctx != null && ctx.isNotEmpty) {
      buf
        ..writeln()
        ..writeln()
        ..writeln(
          'The agent works under these standing project conventions — '
          'hold it to them and do not advise against them:',
        )
        ..writeln('<project-conventions>')
        ..writeln(ctx)
        ..writeln('</project-conventions>');
    }
    final att = attention?.trim();
    if (att != null && att.isNotEmpty) {
      buf
        ..writeln()
        ..writeln()
        ..writeln('Especially pay attention to:')
        ..writeln('<attention>')
        ..writeln(att)
        ..writeln('</attention>');
    }
    final extra = extraInstructions?.trim();
    if (extra != null && extra.isNotEmpty) {
      buf
        ..writeln()
        ..writeln()
        ..writeln(extra);
    }
    return buf.toString().trim();
  }
}

/// Case-insensitive, punctuation-folded normalization of an advisor note.
/// Collapses every run of non-letter / non-digit characters into a single
/// space and trims, so `"Stop."`, `"*Stop*"` and `"  stop  "` all key to
/// `stop`, while `"No issue; continue."` keys to `no issue continue`.
String normalizeAdvisorNote(String note) => note
    .toLowerCase()
    .replaceAll(RegExp(r'[^\p{L}\p{N}]+', unicode: true), ' ')
    .trim();

/// Normalized phrases the reviewer occasionally emits that carry no concrete
/// actionable content. Silence is the correct expression of "no concerns", so
/// these are dropped at the emission boundary even if the model ignores the
/// "prefer silence" instruction. Each entry must be the output of
/// [normalizeAdvisorNote].
const Set<String> _suppressedNormalizedPhrases = {
  // Self-stop noise — telling the agent to "stop" without a reason is useless.
  'stop', 'stop here', 'stop now', 'halt', 'abort',
  // Completion self-talk — the agent already finished the task.
  'done', 'task done', 'task complete', 'complete', 'finished',
  'ok', 'okay', 'ok done',
  // "Nothing to flag" — silence says this better.
  'no issue', 'no issues', 'no issue continue', 'no concerns', 'no concern',
  'nothing to add', 'nothing to flag', 'nothing to report', 'no notes',
  'no further input', 'no further input needed', 'no further input required',
  'no further advice', 'no further advice needed',
  'no further watcher input', 'no further watcher input needed',
  // Endorsements — equivalent to silence.
  'lgtm', 'looks good', 'all good', 'agent is on track', 'agent on track',
  'on track', 'continue', 'carry on',
};

/// Bounds the dedupe history so a very long run cannot grow it without bound.
const int _defaultGuardCapacity = 4096;

/// Decides whether an advisor note should reach the primary agent.
///
/// Drops, in order: content-free noise ([_suppressedNormalizedPhrases]) and
/// repeats at the same-or-lower severity (a run-scoped, FIFO-evicted dedupe
/// keyed by normalized text, holding the highest delivered severity per note so
/// a real escalation — nit → concern → blocker — still passes while a verbatim
/// re-tag at equal/lower severity is suppressed). Reset on advisor re-prime.
class AdvisorEmissionGuard {
  /// Creates a guard with an optional dedupe [capacity].
  AdvisorEmissionGuard({int capacity = _defaultGuardCapacity})
    : _capacity = capacity;

  final int _capacity;

  /// Normalized note → highest delivered severity rank.
  final Map<String, int> _deliveredRank = {};

  /// Insertion order, for FIFO eviction at [_capacity].
  final List<String> _order = [];

  /// Drops all dedupe state (called on advisor re-prime so a re-primed reviewer
  /// can re-raise issues folded away by compaction).
  void reset() {
    _deliveredRank.clear();
    _order.clear();
  }

  /// Whether the note should be delivered. On true the guard has recorded it.
  bool accept(String note, AdvisorSeverity severity) {
    final key = normalizeAdvisorNote(note);
    if (key.isEmpty) {
      return false;
    }
    if (_suppressedNormalizedPhrases.contains(key)) {
      return false;
    }
    final rank = severity.rank;
    final previous = _deliveredRank[key];
    if (previous != null && rank <= previous) {
      return false; // verbatim repeat or de-escalation
    }
    _deliveredRank[key] = rank;
    if (previous == null) {
      _order.add(key);
      if (_order.length > _capacity) {
        final stale = _order.removeAt(0);
        _deliveredRank.remove(stale);
      }
    }
    return true;
  }
}
