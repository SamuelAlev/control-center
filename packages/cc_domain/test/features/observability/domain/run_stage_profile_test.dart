import 'package:cc_domain/features/observability/domain/run_stage.dart';
import 'package:test/test.dart';

/// Builds a stage timing with a default harness source.
RunStageTiming _timing(
  RunStage stage,
  int offsetMs, {
  RunTimingSource source = RunTimingSource.harness,
  int? durationMs,
  String? provider,
  String? modelId,
}) => RunStageTiming(
  stage: stage,
  offsetMs: offsetMs,
  source: source,
  durationMs: durationMs,
  provider: provider,
  modelId: modelId,
);

/// Covers [RunStageTiming] / [RunLatencyProfile]: JSON round-tripping with
/// unknown entries dropped, unrecognized sources degrading to harness, the
/// earliest-observation merge rule, and the derived metrics that must read
/// null (never zero) when a boundary was never observed.
void main() {
  test('provider latency never combines boundaries from different retries', () {
    final profile = RunLatencyProfile.empty.mergeAll([
      const RunStageTiming(
        stage: RunStage.requestSent,
        offsetMs: 100,
        source: RunTimingSource.transport,
        requestId: 'first:1',
      ),
      const RunStageTiming(
        stage: RunStage.firstResponseByte,
        offsetMs: 450,
        source: RunTimingSource.transport,
        requestId: 'retry:2',
      ),
      const RunStageTiming(
        stage: RunStage.firstModelDelta,
        offsetMs: 460,
        source: RunTimingSource.provider,
        requestId: 'retry:2',
      ),
    ]);
    expect(profile.transportTtfbMs, isNull);
    expect(profile.providerTtftMs, isNull);
    final restored = RunLatencyProfile.fromJson(profile.toJson());
    expect(restored.transportTtfbMs, isNull);
    expect(restored.providerTtftMs, isNull);
  });

  test(
    'buffered CLI text is not provider TTFT, even after a request marker',
    () {
      final profile = RunLatencyProfile.empty.mergeAll([
        _timing(RunStage.requestSent, 100, source: RunTimingSource.transport),
        _timing(RunStage.firstModelDelta, 150, source: RunTimingSource.adapter),
      ]);
      expect(profile.providerTtftMs, isNull);
      // Millisecond rounding can tie the later-reported transport observation
      // with the coarse adapter event; retain the stronger provenance.
      final observed = profile.merge(
        _timing(
          RunStage.firstModelDelta,
          150,
          source: RunTimingSource.provider,
        ),
      );
      expect(observed.providerTtftMs, 50);
    },
  );

  // ---------------------------------------------------------------------------
  // RunStageTiming JSON
  // ---------------------------------------------------------------------------
  group('RunStageTiming JSON', () {
    // Protects: a known stage, its observer, offset and span survive storage.
    test('round-trips a fully-populated timing', () {
      const timing = RunStageTiming(
        stage: RunStage.firstModelDelta,
        offsetMs: 120,
        source: RunTimingSource.transport,
        durationMs: 30,
        provider: 'anthropic',
        modelId: 'claude-sonnet',
      );
      expect(RunStageTiming.fromJson(timing.toJson()), timing);
    });

    // Protects: an unknown stage is dropped rather than mapped onto a
    // different boundary (a wrong boundary is worse than an absent one).
    test('drops an unknown stage', () {
      expect(
        RunStageTiming.fromJson(<String, dynamic>{
          'stage': 'nonsense',
          'offsetMs': 5,
          'source': 'transport',
        }),
        isNull,
      );
    });

    // Protects: a payload without a numeric offset is not a timing.
    test('drops a payload without a numeric offset', () {
      expect(
        RunStageTiming.fromJson(<String, dynamic>{
          'stage': 'submitted',
          'source': 'harness',
        }),
        isNull,
      );
      expect(
        RunStageTiming.fromJson(<String, dynamic>{
          'stage': 'submitted',
          'offsetMs': 'soon',
          'source': 'harness',
        }),
        isNull,
      );
      expect(RunStageTiming.fromJson('nope'), isNull);
    });

    // Protects: an unknown observer must not fabricate a measurement —
    // everything unrecognized is harness bookkeeping.
    test('an unknown or missing source becomes harness', () {
      final unknown = RunStageTiming.fromJson(<String, dynamic>{
        'stage': 'submitted',
        'offsetMs': 0,
        'source': 'nonsense',
      });
      expect(unknown, isNotNull);
      expect(unknown!.source, RunTimingSource.harness);

      final missing = RunStageTiming.fromJson(<String, dynamic>{
        'stage': 'submitted',
        'offsetMs': 0,
      });
      expect(missing, isNotNull);
      expect(missing!.source, RunTimingSource.harness);
    });

    // Protects: a recognized stage and observer are preserved exactly.
    test('keeps a known stage and its observed source', () {
      final known = RunStageTiming.fromJson(<String, dynamic>{
        'stage': 'request_sent',
        'offsetMs': 12,
        'source': 'transport',
      });
      expect(known, isNotNull);
      expect(known!.stage, RunStage.requestSent);
      expect(known.source, RunTimingSource.transport);
      expect(known.offsetMs, 12);
    });
  });

  // ---------------------------------------------------------------------------
  // merge
  // ---------------------------------------------------------------------------
  group('RunLatencyProfile.merge', () {
    // Protects: "time to first" means the EARLIEST observation, and the result
    // must not depend on the order reports arrived in.
    test('keeps the earliest offset for a repeated stage', () {
      final forward = RunLatencyProfile.empty
          .merge(_timing(RunStage.firstModelDelta, 200))
          .merge(_timing(RunStage.firstModelDelta, 120));
      expect(forward.offsetMs(RunStage.firstModelDelta), 120);

      final reversed = RunLatencyProfile.empty
          .merge(_timing(RunStage.firstModelDelta, 120))
          .merge(_timing(RunStage.firstModelDelta, 200));
      expect(reversed.offsetMs(RunStage.firstModelDelta), 120);
    });

    // Protects: folding a whole batch keeps one entry per stage and the
    // earliest offset within it.
    test('mergeAll folds every timing and keeps distinct stages', () {
      final profile = RunLatencyProfile.empty.mergeAll([
        _timing(RunStage.firstModelDelta, 300),
        _timing(RunStage.submitted, 0),
        _timing(RunStage.firstModelDelta, 150),
      ]);

      expect(profile.offsetMs(RunStage.firstModelDelta), 150);
      expect(profile.offsetMs(RunStage.submitted), 0);
      expect(profile.timings.length, 2);
    });

    // Protects: an absent stage means UNKNOWN — the reader must never see it
    // coerced to zero.
    test('an unobserved stage reads null, not zero', () {
      expect(RunLatencyProfile.empty.offsetMs(RunStage.submitted), isNull);
      expect(RunLatencyProfile.empty.durationMs(RunStage.submitted), isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // timeToFirstUsefulWorkMs
  // ---------------------------------------------------------------------------
  group('RunLatencyProfile.timeToFirstUsefulWorkMs', () {
    // Protects: with no run-start boundary the elapsed time is UNKNOWN — a
    // firstUsefulText alone must never read as an elapsed zero.
    test('is null when submitted was never observed', () {
      final profile = RunLatencyProfile.empty
          .merge(_timing(RunStage.requestSent, 100))
          .merge(_timing(RunStage.firstUsefulText, 500));

      expect(profile.offsetMs(RunStage.firstUsefulText), 500);
      expect(profile.timeToFirstUsefulWorkMs, isNull);
    });

    // Protects: the usable number is measured from run start to the first
    // useful work, not to the first byte.
    test('measures submitted to firstUsefulText when both exist', () {
      final profile = RunLatencyProfile.empty
          .merge(_timing(RunStage.submitted, 100))
          .merge(_timing(RunStage.firstUsefulText, 500));

      expect(profile.timeToFirstUsefulWorkMs, 400);
    });

    // Protects: zero is reported only when the two boundaries genuinely
    // coincide, distinguishing it from an unknown.
    test('is zero only when both boundaries coincide', () {
      final profile = RunLatencyProfile.empty
          .merge(_timing(RunStage.submitted, 100))
          .merge(_timing(RunStage.firstUsefulText, 100));

      expect(profile.timeToFirstUsefulWorkMs, 0);
    });

    // Protects: an empty profile reports nothing rather than a zero.
    test('an empty profile reports null', () {
      expect(RunLatencyProfile.empty.timeToFirstUsefulWorkMs, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // transportTtfbMs
  // ---------------------------------------------------------------------------
  group('RunLatencyProfile.transportTtfbMs', () {
    // Protects: a harness bookkeeping marker cannot claim a transport TTFB —
    // the metric is withheld rather than fabricated.
    test('is null when the byte was observed by harness', () {
      final profile = RunLatencyProfile.empty
          .merge(
            _timing(RunStage.requestSent, 100, source: RunTimingSource.adapter),
          )
          .merge(_timing(RunStage.firstResponseByte, 150));

      expect(profile.offsetMs(RunStage.firstResponseByte), 150);
      expect(profile.transportTtfbMs, isNull);
    });

    // Protects: an adapter that hides its socket cannot claim the wire either.
    test('is null when the byte was observed by adapter', () {
      final profile = RunLatencyProfile.empty
          .merge(_timing(RunStage.requestSent, 100))
          .merge(
            _timing(
              RunStage.firstResponseByte,
              150,
              source: RunTimingSource.adapter,
            ),
          );

      expect(profile.transportTtfbMs, isNull);
    });

    // Protects: a genuinely observed transport byte yields the real TTFB.
    test('is measured when the byte was observed on the transport', () {
      final profile = RunLatencyProfile.empty
          .merge(
            _timing(
              RunStage.requestSent,
              100,
              source: RunTimingSource.transport,
            ),
          )
          .merge(
            _timing(
              RunStage.firstResponseByte,
              150,
              source: RunTimingSource.transport,
            ),
          );

      expect(profile.transportTtfbMs, 50);
    });

    // Protects: a provider-reported byte is also a legitimate TTFB source.
    test('accepts a provider-reported byte', () {
      final profile = RunLatencyProfile.empty
          .merge(
            _timing(
              RunStage.requestSent,
              100,
              source: RunTimingSource.transport,
            ),
          )
          .merge(
            _timing(
              RunStage.firstResponseByte,
              150,
              source: RunTimingSource.provider,
            ),
          );

      expect(profile.transportTtfbMs, 50);
    });

    // Protects: without the request-sent boundary the interval is unknown.
    test('is null when requestSent is missing', () {
      final profile = RunLatencyProfile.empty.merge(
        _timing(
          RunStage.firstResponseByte,
          150,
          source: RunTimingSource.transport,
        ),
      );

      expect(profile.transportTtfbMs, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // profile JSON
  // ---------------------------------------------------------------------------
  group('RunLatencyProfile JSON', () {
    // Protects: a multi-stage profile survives storage and replay intact.
    test('round-trips a multi-stage profile', () {
      final profile = RunLatencyProfile.empty.mergeAll([
        _timing(RunStage.submitted, 0),
        _timing(RunStage.requestSent, 50, source: RunTimingSource.adapter),
        _timing(
          RunStage.firstResponseByte,
          80,
          source: RunTimingSource.transport,
        ),
        _timing(
          RunStage.firstModelDelta,
          200,
          source: RunTimingSource.provider,
          durationMs: 30,
        ),
        _timing(RunStage.firstUsefulText, 400),
      ]);

      expect(RunLatencyProfile.fromJson(profile.toJson()), profile);
    });

    // Protects: one unrecognized entry is dropped without losing the rest of
    // the profile.
    test('drops unrecognized entries and keeps valid ones', () {
      final profile = RunLatencyProfile.fromJson([
        _timing(RunStage.submitted, 0).toJson(),
        <String, dynamic>{'stage': 'nonsense', 'offsetMs': 9},
      ]);

      expect(profile.offsetMs(RunStage.submitted), 0);
      expect(profile.offsetMs(RunStage.firstModelDelta), isNull);
      expect(profile.timings.length, 1);
    });

    // Protects: a non-list payload degrades to the empty profile, never a
    // crash or a partially-trusted parse.
    test('a non-list payload is the empty profile', () {
      expect(RunLatencyProfile.fromJson(null), RunLatencyProfile.empty);
      expect(RunLatencyProfile.fromJson('nope'), RunLatencyProfile.empty);
    });

    // Protects: the serialized order is by stage, so a diff/replay is stable.
    test('toJson orders timings by stage', () {
      final profile = RunLatencyProfile.empty.mergeAll([
        _timing(RunStage.firstUsefulText, 400),
        _timing(RunStage.submitted, 0),
        _timing(RunStage.requestSent, 50),
      ]);

      final stages = profile
          .toJson()
          .map((m) => RunStage.tryFromWire(m['stage'] as String))
          .toList();
      expect(stages, [
        RunStage.submitted,
        RunStage.requestSent,
        RunStage.firstUsefulText,
      ]);
    });

    // Protects: replaying a profile with a repeated stage still honors the
    // earliest observation.
    test('fromJson keeps the earliest of two entries for a stage', () {
      final profile = RunLatencyProfile.fromJson([
        _timing(RunStage.firstModelDelta, 300).toJson(),
        _timing(RunStage.firstModelDelta, 150).toJson(),
      ]);

      expect(profile.offsetMs(RunStage.firstModelDelta), 150);
    });
  });
}
