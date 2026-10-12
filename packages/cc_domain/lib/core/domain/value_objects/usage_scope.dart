/// How a usage report relates to the counters already accumulated for a run.
///
/// A provider that reports per-request usage and one that reports an absolute
/// whole-process cumulative ledger look identical on the wire unless the scope
/// is carried. Treating the second as additive inflates a resumed CLI run's
/// totals on every turn; treating the first as absolute silently discards every
/// request but the last.
enum UsageScope {
  /// Additive usage for one model request (the default).
  request,

  /// Additive usage for one whole turn/agent invocation.
  turn,

  /// ABSOLUTE cumulative usage for the run so far. A later reading REPLACES the
  /// accumulated totals (last-wins per axis) rather than adding to them — the
  /// Claude CLI `total_cost_usd` / `modelUsage` path.
  runCumulative;

  /// Stable wire/storage spelling.
  String get wire {
    switch (this) {
      case UsageScope.request:
        return 'request';
      case UsageScope.turn:
        return 'turn';
      case UsageScope.runCumulative:
        return 'run_cumulative';
    }
  }

  /// Parses a wire/storage spelling, accepting `runCumulative` too. Unknown
  /// values answer [request] — the historical additive behavior.
  static UsageScope fromWire(String? value) {
    switch (value) {
      case 'turn':
        return UsageScope.turn;
      case 'runCumulative':
      case 'run_cumulative':
        return UsageScope.runCumulative;
      case 'request':
      default:
        return UsageScope.request;
    }
  }
}
