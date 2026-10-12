/// The observable stages of one agent run.
///
/// The old single "TTFT" number was measured from run start to the first
/// `TextEvent` — time to first *visible text*, not transport TTFB and not
/// provider TTFT. A thinking-first or tool-first run does useful work while
/// that metric stays unset, and the number it eventually reports includes all
/// of the context loading and process startup that happened before the request
/// was even sent.
///
/// Each boundary is therefore recorded separately. A stage that is not
/// directly observable is simply absent from its [RunLatencyProfile] (null) —
/// never zero-filled, which would drag a percentile toward zero and read as
/// "instant".
enum RunStage {
  /// The user's request was accepted (run start).
  submitted,

  /// Prompt/context assembly finished (memory, conversation, prompt build).
  contextReady,

  /// The runtime, sandbox and MCP servers were ready to serve.
  runtimeReady,

  /// The model request left the client.
  requestSent,

  /// The first non-empty response-body byte arrived (TTFB), not HTTP headers.
  /// Only a transport that observes the body stream reports this.
  firstResponseByte,

  /// The first model delta (text or thinking) arrived.
  firstModelDelta,

  /// The first USEFUL work landed: assistant text, or a tool call that advances
  /// the task. This is the number an efficiency claim should move.
  firstUsefulText,

  /// The task's independent verification began.
  verificationStart,

  /// The task was verified complete — distinct from the run merely ending.
  verifiedCompletion;

  /// Stable wire/storage spelling.
  String get wire {
    switch (this) {
      case RunStage.submitted:
        return 'submitted';
      case RunStage.contextReady:
        return 'context_ready';
      case RunStage.runtimeReady:
        return 'runtime_ready';
      case RunStage.requestSent:
        return 'request_sent';
      case RunStage.firstResponseByte:
        return 'first_response_byte';
      case RunStage.firstModelDelta:
        return 'first_model_delta';
      case RunStage.firstUsefulText:
        return 'first_useful_text';
      case RunStage.verificationStart:
        return 'verification_start';
      case RunStage.verifiedCompletion:
        return 'verified_completion';
    }
  }

  /// Parses a wire/storage spelling, or null when unrecognized (an unknown
  /// stage is dropped rather than mapped onto a different boundary).
  static RunStage? tryFromWire(String? value) {
    switch (value) {
      case 'submitted':
        return RunStage.submitted;
      case 'context_ready':
        return RunStage.contextReady;
      case 'runtime_ready':
        return RunStage.runtimeReady;
      case 'request_sent':
        return RunStage.requestSent;
      case 'first_response_byte':
        return RunStage.firstResponseByte;
      case 'first_model_delta':
        return RunStage.firstModelDelta;
      case 'first_useful_text':
        return RunStage.firstUsefulText;
      case 'verification_start':
        return RunStage.verificationStart;
      case 'verified_completion':
        return RunStage.verifiedCompletion;
      default:
        return null;
    }
  }
}

/// Who observed a `StageTimingEvent`.
///
/// Carried so a reader can tell a measured provider boundary from a harness
/// bookkeeping marker. CLI process output is not provider TTFB.
enum RunTimingSource {
  /// Reported by the model provider itself.
  provider,

  /// Observed at the HTTP body-stream boundary.
  transport,

  /// Observed by a CLI/adapter process wrapper.
  adapter,

  /// Harness bookkeeping (context assembly, sandbox readiness).
  harness;

  /// Stable wire/storage spelling.
  String get wire {
    switch (this) {
      case RunTimingSource.provider:
        return 'provider';
      case RunTimingSource.transport:
        return 'transport';
      case RunTimingSource.adapter:
        return 'adapter';
      case RunTimingSource.harness:
        return 'harness';
    }
  }

  /// Parses a wire/storage spelling, or null when unrecognized.
  static RunTimingSource? tryFromWire(String? value) {
    switch (value) {
      case 'provider':
        return RunTimingSource.provider;
      case 'transport':
        return RunTimingSource.transport;
      case 'adapter':
        return RunTimingSource.adapter;
      case 'harness':
        return RunTimingSource.harness;
      default:
        return null;
    }
  }
}

/// One observed stage boundary of a run: its offset from run start, who saw it,
/// and (for a span rather than an instant) how long the stage itself took.
class RunStageTiming {
  /// Creates a stage timing.
  const RunStageTiming({
    required this.stage,
    required this.offsetMs,
    required this.source,
    this.durationMs,
    this.provider,
    this.modelId,
    this.requestId,
  });

  /// The stage this timing marks.
  final RunStage stage;

  /// Milliseconds from run start to this boundary.
  final int offsetMs;

  /// Who observed the boundary.
  final RunTimingSource source;

  /// Milliseconds this stage itself took, when the boundary closes a span.
  final int? durationMs;

  /// Provider id, when the timing is provider/transport specific.
  final String? provider;

  /// Model id, when known.
  final String? modelId;

  /// Physical request identity; prevents pairing boundaries across retries.
  final String? requestId;

  /// JSON-safe map for the run log's latency column.
  Map<String, dynamic> toJson() => {
    'stage': stage.wire,
    'offsetMs': offsetMs,
    'source': source.wire,
    if (durationMs != null) 'durationMs': durationMs,
    if (provider != null) 'provider': provider,
    if (modelId != null) 'modelId': modelId,
    if (requestId != null) 'requestId': requestId,
  };

  /// Rebuilds a timing from [toJson] output; null when the payload is not a
  /// recognizable timing (an unknown stage is dropped, not guessed).
  static RunStageTiming? fromJson(Object? raw) {
    if (raw is! Map) {
      return null;
    }
    final stage = RunStage.tryFromWire(raw['stage'] as String?);
    final source = RunTimingSource.tryFromWire(raw['source'] as String?);
    final offset = raw['offsetMs'];
    if (stage == null || offset is! num) {
      return null;
    }
    final duration = raw['durationMs'];
    return RunStageTiming(
      stage: stage,
      offsetMs: offset.toInt(),
      // An unrecognized source is harness bookkeeping: claiming `provider` for
      // a boundary whose observer is unknown would fabricate a measurement.
      source: source ?? RunTimingSource.harness,
      durationMs: duration is num ? duration.toInt() : null,
      provider: raw['provider'] as String?,
      modelId: raw['modelId'] as String?,
      requestId: raw['requestId'] as String?,
    );
  }

  /// The first-recorded timing wins for a stage: the loop may observe the same
  /// boundary repeatedly (one first delta per attempt), and "time to first"
  /// means the earliest.
  static RunStageTiming earlier(RunStageTiming a, RunStageTiming b) {
    if (a.offsetMs == b.offsetMs &&
        !_providerBoundary(a.source) &&
        _providerBoundary(b.source)) {
      return b;
    }
    return a.offsetMs <= b.offsetMs ? a : b;
  }

  static bool _providerBoundary(RunTimingSource source) =>
      source == RunTimingSource.provider || source == RunTimingSource.transport;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RunStageTiming &&
          stage == other.stage &&
          offsetMs == other.offsetMs &&
          source == other.source &&
          durationMs == other.durationMs &&
          provider == other.provider &&
          modelId == other.modelId &&
          requestId == other.requestId;

  @override
  int get hashCode => Object.hash(
    stage,
    offsetMs,
    source,
    durationMs,
    provider,
    modelId,
    requestId,
  );
}

/// A run's observed stage offsets, keyed by [RunStage].
///
/// Immutable and JSON-round-trippable. An absent stage means UNKNOWN — the
/// reader must not treat it as zero.
class RunLatencyProfile {
  /// Creates a profile from explicit stage timings.
  const RunLatencyProfile(this.timings);

  /// An empty profile: every stage unknown.
  static const empty = RunLatencyProfile(<RunStage, RunStageTiming>{});

  /// Observed timings by stage.
  final Map<RunStage, RunStageTiming> timings;

  /// True when nothing was observed.
  bool get isEmpty => timings.isEmpty;

  /// Offset in ms for [stage], or null when unobserved.
  int? offsetMs(RunStage stage) => timings[stage]?.offsetMs;

  /// Duration in ms of [stage]'s span, or null when unobserved/unspanned.
  int? durationMs(RunStage stage) => timings[stage]?.durationMs;

  /// Time from [RunStage.submitted] to [RunStage.firstUsefulText], or null
  /// unless BOTH were observed.
  int? get timeToFirstUsefulWorkMs {
    final start = offsetMs(RunStage.submitted);
    final useful = offsetMs(RunStage.firstUsefulText);
    if (start == null || useful == null) {
      return null;
    }
    return useful - start;
  }

  /// Request commitment to the first response-body byte, when both boundaries
  /// were observed for the same physical request.
  int? get transportTtfbMs => _providerInterval(RunStage.firstResponseByte);

  /// Request commitment to the first model-authored event, excluding buffered
  /// CLI output and harness-derived text timestamps.
  int? get providerTtftMs => _providerInterval(RunStage.firstModelDelta);

  int? _providerInterval(RunStage end) {
    final sent = timings[RunStage.requestSent];
    final received = timings[end];
    if (sent == null ||
        received == null ||
        !RunStageTiming._providerBoundary(sent.source) ||
        !RunStageTiming._providerBoundary(received.source) ||
        sent.requestId != received.requestId ||
        (sent.provider != null &&
            received.provider != null &&
            sent.provider != received.provider)) {
      return null;
    }
    final elapsed = received.offsetMs - sent.offsetMs;
    return elapsed < 0 ? null : elapsed;
  }

  /// Returns a copy with [timing] folded in, keeping the EARLIEST observation
  /// per stage.
  RunLatencyProfile merge(RunStageTiming timing) {
    final existing = timings[timing.stage];
    return RunLatencyProfile({
      ...timings,
      timing.stage: existing == null
          ? timing
          : RunStageTiming.earlier(existing, timing),
    });
  }

  /// Folds a whole list of timings.
  RunLatencyProfile mergeAll(Iterable<RunStageTiming> incoming) =>
      incoming.fold(this, (acc, t) => acc.merge(t));

  /// JSON-safe list, ordered by stage for a stable diff/replay.
  List<Map<String, dynamic>> toJson() {
    final sorted = timings.values.toList()
      ..sort((a, b) => a.stage.index.compareTo(b.stage.index));
    return [for (final t in sorted) t.toJson()];
  }

  /// Rebuilds a profile from [toJson] output; unrecognized entries are dropped.
  static RunLatencyProfile fromJson(Object? raw) {
    if (raw is! List) {
      return empty;
    }
    var profile = empty;
    for (final entry in raw) {
      final timing = RunStageTiming.fromJson(entry);
      if (timing != null) {
        profile = profile.merge(timing);
      }
    }
    return profile;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RunLatencyProfile &&
          timings.length == other.timings.length &&
          timings.entries.every((e) => other.timings[e.key] == e.value);

  @override
  int get hashCode =>
      Object.hashAll([for (final stage in RunStage.values) timings[stage]]);
}
