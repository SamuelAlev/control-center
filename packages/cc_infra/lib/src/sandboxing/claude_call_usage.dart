/// The size of ONE model call as it streams: a main-thread call from its
/// `message_start` / `message_delta` stream events, a subagent call from its
/// `assistant` lines.
///
/// Unlike `ClaudeUsage` (the invocation's summed spend), this is occupancy:
/// [promptTokens] is everything the model read on that call (uncached input
/// plus cache read plus cache write) and [outputTokens] what it has written
/// back so far, which the next call carries forward. The prompt's parts are
/// kept apart so the call can be priced while it streams, and [messageId]
/// ties every report of one call together, so the spend the turn's `result`
/// has not reported yet can be counted once (`ClaudeUnreportedUsage`).
class ClaudeCallUsage {
  /// Creates a [ClaudeCallUsage].
  const ClaudeCallUsage({
    required this.messageId,
    required this.inputTokens,
    required this.cacheReadTokens,
    required this.cacheWriteTokens,
    required this.callStarted,
    this.outputTokens = 0,
    this.model,
    this.subagent = false,
  });

  /// The API message id, shared by every report of the same call.
  final String messageId;

  /// The model that served the call, when the stream names it.
  final String? model;

  /// Whether a subagent made the call. Its reports are partial: only its
  /// `assistant` lines that hold a tool call are streamed (its final answer
  /// never is), each with the output count at that block.
  final bool subagent;

  /// Uncached input tokens the call read.
  final int inputTokens;

  /// Input tokens the call read from the prompt cache.
  final int cacheReadTokens;

  /// Input tokens the call wrote to the prompt cache.
  final int cacheWriteTokens;

  /// Whether this is the call's first report (its `message_start`): a new
  /// call began. Later reports of the same call only grow [outputTokens].
  final bool callStarted;

  /// Output tokens produced by the call so far.
  final int outputTokens;

  /// Input tokens the call read, cached or not.
  int get promptTokens => inputTokens + cacheReadTokens + cacheWriteTokens;

  /// Tokens in the window once this call's output joins the context.
  int get contextTokens => promptTokens + outputTokens;

  /// The same call, reported again with [outputTokens] written so far.
  ClaudeCallUsage withOutput(int outputTokens) => ClaudeCallUsage(
    messageId: messageId,
    inputTokens: inputTokens,
    cacheReadTokens: cacheReadTokens,
    cacheWriteTokens: cacheWriteTokens,
    callStarted: false,
    outputTokens: outputTokens,
    model: model,
    subagent: subagent,
  );
}

/// The model calls a `claude` process streamed that no `result` has reported
/// yet, one entry per call, merged across its repeated reports.
///
/// Claude Code totals a turn only in its `result`. A process that dies first
/// (a stop, the silence watchdog, a crash, a server shutdown) takes that
/// report with it, and the run recorded nothing for the turn. This keeps
/// what the stream showed of each call meanwhile, so the run's usage can
/// include it until a `result` reports it ([settle]), or count it for good
/// when none will (the caller folds the totals in, then calls [settle]).
///
/// Each call is priced alone, as it is recorded: a context-price tier is
/// decided by one request's prompt, not by a sum of them.
class ClaudeUnreportedUsage {
  final Map<String, _UnreportedCall> _calls = {};
  final Set<String> _settled = {};
  final Set<String> _costReported = {};
  var _input = 0;
  var _output = 0;
  var _cacheRead = 0;
  var _cacheWrite = 0;
  var _pricedMicros = 0;
  var _unpriced = 0;

  /// Folds one report of a call in, priced by [priceMicros] (null when the
  /// model has no known price). Each counter keeps its largest report: a
  /// main-thread call's `assistant` lines can carry a smaller output count
  /// than its `message_delta`. Returns whether the call's usage grew. A call
  /// a `result` already reported is ignored.
  bool record(
    ClaudeCallUsage call,
    int? Function(ClaudeCallUsage call) priceMicros,
  ) {
    if (_settled.contains(call.messageId)) {
      return false;
    }
    final before = _calls[call.messageId];
    final merged = before == null
        ? call
        : ClaudeCallUsage(
            messageId: call.messageId,
            inputTokens: _max(before.usage.inputTokens, call.inputTokens),
            cacheReadTokens: _max(
              before.usage.cacheReadTokens,
              call.cacheReadTokens,
            ),
            cacheWriteTokens: _max(
              before.usage.cacheWriteTokens,
              call.cacheWriteTokens,
            ),
            outputTokens: _max(before.usage.outputTokens, call.outputTokens),
            callStarted: false,
            model: call.model ?? before.usage.model,
            subagent: before.usage.subagent || call.subagent,
          );
    if (before != null &&
        merged.inputTokens == before.usage.inputTokens &&
        merged.cacheReadTokens == before.usage.cacheReadTokens &&
        merged.cacheWriteTokens == before.usage.cacheWriteTokens &&
        merged.outputTokens == before.usage.outputTokens) {
      return false;
    }
    if (before != null) {
      _count(before, -1);
    }
    final entry = _UnreportedCall(
      merged,
      _costReported.contains(call.messageId) ? 0 : priceMicros(merged),
    );
    _calls[call.messageId] = entry;
    _count(entry, 1);
    return true;
  }

  /// Whether no call is waiting on a `result`.
  bool get isEmpty => _calls.isEmpty;

  /// How many calls are waiting on a `result`.
  int get calls => _calls.length;

  /// Uncached input tokens across the waiting calls.
  int get inputTokens => _input;

  /// Output tokens across the waiting calls.
  int get outputTokens => _output;

  /// Cache-read tokens across the waiting calls.
  int get cacheReadTokens => _cacheRead;

  /// Cache-write tokens across the waiting calls.
  int get cacheWriteTokens => _cacheWrite;

  /// The waiting calls' estimated cost, in micro-dollars, over the calls
  /// whose model has a known price.
  int get pricedMicros => _pricedMicros;

  /// Whether some waiting call could not be priced.
  bool get hasUnpriced => _unpriced > 0;

  /// Every call recorded so far is accounted for — by a `result`, or by the
  /// caller having folded [inputTokens] &co into the run. A later report of
  /// one of them is ignored.
  void settle() {
    _settled.addAll(_calls.keys);
    _calls.clear();
    _costReported.clear();
    _input = 0;
    _output = 0;
    _cacheRead = 0;
    _cacheWrite = 0;
    _pricedMicros = 0;
    _unpriced = 0;
  }

  /// A `result` reported what the waiting calls cost but not their tokens (a
  /// partial result: `total_cost_usd` with no `usage` or `modelUsage`). They
  /// keep their tokens, for a later result's whole-tree counters to settle or
  /// a fold to count, but no longer their estimated cost, which would count
  /// that spend twice.
  void dropEstimates() {
    for (final MapEntry(:key, :value) in _calls.entries.toList()) {
      _count(value, -1);
      final entry = _UnreportedCall(value.usage, 0);
      _calls[key] = entry;
      _count(entry, 1);
      _costReported.add(key);
    }
  }

  void _count(_UnreportedCall entry, int sign) {
    final u = entry.usage;
    _input += sign * u.inputTokens;
    _output += sign * u.outputTokens;
    _cacheRead += sign * u.cacheReadTokens;
    _cacheWrite += sign * u.cacheWriteTokens;
    final micros = entry.micros;
    if (micros == null) {
      _unpriced += sign;
    } else {
      _pricedMicros += sign * micros;
    }
  }

  static int _max(int a, int b) => a > b ? a : b;
}

/// One waiting call: its merged usage and its price, when known.
class _UnreportedCall {
  const _UnreportedCall(this.usage, this.micros);

  final ClaudeCallUsage usage;
  final int? micros;
}
