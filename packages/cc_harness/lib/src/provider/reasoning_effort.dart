/// A unified reasoning-effort knob that trades latency for quality uniformly
/// across providers.
///
/// Each model declares
/// which efforts it accepts via its `ThinkingConfig`; a single selector here is
/// remapped per-model to the right upstream wire value (or even a different
/// model id, via `effortRouting`).
///
/// Ordering (least → most intensive) is meaningful: [index] is used to pick a
/// model's nearest supported effort when the requested one is unavailable.
enum ReasoningEffort {
  /// No / negligible reasoning. Fastest, cheapest.
  minimal,

  /// Light reasoning.
  low,

  /// Balanced reasoning (a common default).
  medium,

  /// Heavy reasoning.
  high,

  /// Maximum reasoning. Slowest, most expensive.
  xhigh;

  /// Parses an effort from its wire id, tolerant of a few aliases. Returns
  /// null when the value is unrecognized.
  static ReasoningEffort? fromId(String? raw) {
    switch (raw?.trim().toLowerCase()) {
      case 'minimal':
      case 'none':
      case 'off':
        return ReasoningEffort.minimal;
      case 'low':
        return ReasoningEffort.low;
      case 'medium':
      case 'mid':
        return ReasoningEffort.medium;
      case 'high':
        return ReasoningEffort.high;
      case 'xhigh':
      case 'max':
      case 'extra-high':
        return ReasoningEffort.xhigh;
      default:
        return null;
    }
  }

  /// The canonical wire id (e.g. `'xhigh'`).
  String get id => name;

  /// Sentence-case display label (e.g. `'Extra high'`).
  String get label => switch (this) {
    ReasoningEffort.minimal => 'Minimal',
    ReasoningEffort.low => 'Low',
    ReasoningEffort.medium => 'Medium',
    ReasoningEffort.high => 'High',
    ReasoningEffort.xhigh => 'Extra high',
  };
}
