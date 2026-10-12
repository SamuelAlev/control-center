/// What a model call was FOR, so its usage is attributable and its cost is
/// comparable across optimizations.
///
/// Recorded at the provider-call boundary. Without it, work moved off the main
/// thread (into a summarizer, a watchdog advisor, a side request or a
/// subagent) silently stops being counted — and an optimization then looks
/// cheaper purely because it changed who paid.
enum LlmCallPurpose {
  /// The main agent loop's own turn.
  main,

  /// Context compaction / summarization.
  compaction,

  /// Watchdog advisor review.
  advisor,

  /// An auxiliary side request (e.g. an out-of-band question).
  sideRequest,

  /// A subagent spawned by the main run.
  subagent;

  /// Stable wire/storage spelling (`side_request` for [sideRequest]).
  String get wire {
    switch (this) {
      case LlmCallPurpose.main:
        return 'main';
      case LlmCallPurpose.compaction:
        return 'compaction';
      case LlmCallPurpose.advisor:
        return 'advisor';
      case LlmCallPurpose.sideRequest:
        return 'side_request';
      case LlmCallPurpose.subagent:
        return 'subagent';
    }
  }

  /// Parses a wire/storage spelling, accepting both `sideRequest` and
  /// `side_request`. Unknown values answer [main] — the purpose every
  /// pre-attribution record implicitly had.
  static LlmCallPurpose fromWire(String? value) {
    switch (value) {
      case 'compaction':
        return LlmCallPurpose.compaction;
      case 'advisor':
        return LlmCallPurpose.advisor;
      case 'sideRequest':
      case 'side_request':
        return LlmCallPurpose.sideRequest;
      case 'subagent':
        return LlmCallPurpose.subagent;
      case 'main':
      default:
        return LlmCallPurpose.main;
    }
  }
}
