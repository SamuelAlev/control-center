import 'dart:io';

import 'package:cc_harness/loop.dart';
import 'package:cc_harness/messages.dart';
import 'package:cc_harness/provider.dart';
import 'package:cc_harness_runtime/src/advisor/watchdog_advisor.dart';
import 'package:cc_harness_runtime/src/advisor/watchdog_discovery.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// A provider that returns scripted replies and records every request it saw.
class _RecordingProvider implements LlmProviderPort {
  _RecordingProvider(this.replies);

  /// One entry per `complete` call; each is either a reply string (emitted as a
  /// text delta + done) or null to emit an [LlmError].
  final List<String?> replies;

  final List<List<HarnessMessage>> requests = [];
  final List<String?> models = [];
  int calls = 0;

  @override
  String get displayName => 'Recording';
  @override
  String get defaultModel => 'mock';
  @override
  Future<List<ProviderModel>> listModels() async => const [];

  @override
  Stream<LlmEvent> complete({
    required List<HarnessMessage> messages,
    List<LlmToolSchema> tools = const [],
    LlmCompleteConfig config = const LlmCompleteConfig(),
  }) async* {
    requests.add(List.of(messages));
    models.add(config.model);
    final i = calls < replies.length ? calls : replies.length - 1;
    calls++;
    final reply = replies[i];
    if (reply == null) {
      yield const LlmError('boom');
      return;
    }
    yield LlmTextDelta(reply);
    yield const LlmDone();
  }
}

/// Builds a primary history of [n] trivial assistant turns.
List<HarnessMessage> _history(int n) => [
  HarnessMessage.user('do the task'),
  for (var i = 0; i < n; i++) HarnessMessage.assistant('turn $i'),
];

void main() {
  group('normalizeAdvisorNote', () {
    test('folds casing and punctuation', () {
      expect(normalizeAdvisorNote('Stop.'), 'stop');
      expect(normalizeAdvisorNote('*Stop*'), 'stop');
      expect(normalizeAdvisorNote('  STOP!  '), 'stop');
      expect(normalizeAdvisorNote('No issue; continue.'), 'no issue continue');
    });
  });

  group('AdvisorEmissionGuard', () {
    test('suppresses content-free noise', () {
      final guard = AdvisorEmissionGuard();
      for (final noise in ['OK', 'stop', 'LGTM', 'looks good', 'no issues']) {
        expect(
          guard.accept(noise, AdvisorSeverity.nit),
          isFalse,
          reason: noise,
        );
      }
    });

    test('dedupes an identical note at the same severity', () {
      final guard = AdvisorEmissionGuard();
      expect(
        guard.accept('missing await on end()', AdvisorSeverity.concern),
        isTrue,
      );
      expect(
        guard.accept('missing await on end()', AdvisorSeverity.concern),
        isFalse,
      );
      // Punctuation/casing variant is the same normalized key.
      expect(
        guard.accept('Missing await on end().', AdvisorSeverity.concern),
        isFalse,
      );
    });

    test('allows a real escalation but not a de-escalation', () {
      final guard = AdvisorEmissionGuard();
      expect(guard.accept('race in cache', AdvisorSeverity.nit), isTrue);
      // Same note, higher severity — a genuine escalation, delivered.
      expect(guard.accept('race in cache', AdvisorSeverity.blocker), isTrue);
      // Back down — suppressed.
      expect(guard.accept('race in cache', AdvisorSeverity.concern), isFalse);
      expect(guard.accept('race in cache', AdvisorSeverity.blocker), isFalse);
    });

    test('reset re-arms the dedupe memory', () {
      final guard = AdvisorEmissionGuard();
      expect(guard.accept('a real note', AdvisorSeverity.concern), isTrue);
      expect(guard.accept('a real note', AdvisorSeverity.concern), isFalse);
      guard.reset();
      expect(guard.accept('a real note', AdvisorSeverity.concern), isTrue);
    });
  });

  group('WatchdogAdvisor.review', () {
    test('parses a severity-tagged note', () async {
      final provider = _RecordingProvider(['BLOCKER: you dropped the error']);
      final advisor = WatchdogAdvisor(provider);
      final note = await advisor.review(_history(1));
      expect(note, isNotNull);
      expect(note!.severity, AdvisorSeverity.blocker);
      expect(note.note, 'you dropped the error');
    });

    test('a reply with no severity marker is a plain nit', () async {
      final provider = _RecordingProvider(['consider the empty-list case']);
      final advisor = WatchdogAdvisor(provider);
      final note = await advisor.review(_history(1));
      expect(note!.severity, AdvisorSeverity.nit);
      expect(note.note, 'consider the empty-list case');
    });

    test('OK means silence', () async {
      final provider = _RecordingProvider(['OK']);
      final advisor = WatchdogAdvisor(provider);
      expect(await advisor.review(_history(1)), isNull);
    });

    test('passes a model override through to the provider', () async {
      final provider = _RecordingProvider(['nit: tidy this up']);
      final advisor = WatchdogAdvisor(provider, model: 'claude-haiku-4-5');
      await advisor.review(_history(1));
      expect(provider.models.single, 'claude-haiku-4-5');
    });

    test(
      'feeds only the delta on the second review (append-only context)',
      () async {
        final provider = _RecordingProvider(['OK', 'OK']);
        final advisor = WatchdogAdvisor(provider);

        await advisor.review(_history(1)); // turn 0
        final firstReq = provider.requests[0];
        // First review: one user "Session update" carrying turn 0.
        expect(firstReq, hasLength(1));
        expect(firstReq.single.textContent, contains('turn 0'));

        await advisor.review(_history(2)); // turns 0 + 1, but only 1 is new
        final secondReq = provider.requests[1];
        // Context accumulated (prior delta + prior reply + new delta),
        // and the NEW delta must carry only the new turn, not the old one.
        expect(secondReq.length, greaterThan(1));
        final newestDelta = secondReq.last.textContent;
        expect(newestDelta, contains('turn 1'));
        expect(newestDelta, isNot(contains('turn 0')));
      },
    );

    test('does not re-emit the same note twice across reviews', () async {
      final provider = _RecordingProvider([
        'concern: handle the null path',
        'concern: handle the null path',
      ]);
      final advisor = WatchdogAdvisor(provider);
      final first = await advisor.review(_history(1));
      final second = await advisor.review(_history(2));
      expect(first, isNotNull);
      expect(second, isNull); // deduped by the emission guard
    });

    test('goes quiet after consecutive failures, re-armed by reset', () async {
      final provider = _RecordingProvider([null, null]); // always errors
      final advisor = WatchdogAdvisor(provider, maxConsecutiveFailures: 2);
      expect(await advisor.review(_history(1)), isNull); // failure 1
      expect(await advisor.review(_history(2)), isNull); // failure 2 → fused
      final callsAtFuse = provider.calls;
      // Now quiet: further reviews do not even hit the provider.
      expect(await advisor.review(_history(3)), isNull);
      expect(provider.calls, callsAtFuse);
      // reset re-arms it.
      advisor.reset();
      // Give it a working reply this time (script clamps to last entry = null,
      // so this still errors, but it must at least call the provider again).
      await advisor.review(_history(4));
      expect(provider.calls, greaterThan(callsAtFuse));
    });

    test(
      'a failed review does not advance the cursor (delta re-renders)',
      () async {
        // First call errors, second succeeds. The delta rendered on the retry
        // must still contain the turn from the failed attempt.
        final provider = _RecordingProvider([null, 'concern: fix it']);
        final advisor = WatchdogAdvisor(provider);
        expect(await advisor.review(_history(1)), isNull); // errored
        final note = await advisor.review(_history(1)); // same history, retried
        expect(note, isNotNull);
        // The successful call's delta still carried turn 0.
        expect(provider.requests.last.last.textContent, contains('turn 0'));
      },
    );

    test(
      'a long run keeps the advisor conversation user-led (no fuse)',
      () async {
        // Regression: front-trimming a single message once _convo exceeds the
        // cap would strand a leading assistant reply, which Anthropic rejects,
        // fusing the advisor mid-run. Drive well past the default cap (24 → trims
        // on the 13th review) and assert every request still starts with a user
        // turn and the provider is called every time (never fused).
        final provider = _RecordingProvider(['OK']);
        final advisor = WatchdogAdvisor(provider);
        const reviews = 20;
        for (var i = 1; i <= reviews; i++) {
          await advisor.review(_history(i));
        }
        expect(provider.calls, reviews, reason: 'advisor must not fuse');
        for (final req in provider.requests) {
          expect(req.first.role, HarnessRole.user);
        }
      },
    );

    test('reset re-primes so the next review replays from the top', () async {
      final provider = _RecordingProvider(['OK', 'OK']);
      final advisor = WatchdogAdvisor(provider);
      await advisor.review(_history(3)); // consumes turns 0..2
      advisor.reset();
      await advisor.review(_history(3)); // re-primed: replays 0..2 again
      final afterReset = provider.requests.last;
      // Single fresh delta again (context cleared), carrying all turns.
      expect(afterReset, hasLength(1));
      expect(afterReset.single.textContent, contains('turn 2'));
    });
  });

  group('loadWatchdogContext', () {
    test('reads WATCHDOG.md and project conventions from the tree', () async {
      final dir = await Directory.systemTemp.createTemp('watchdog_ctx_test_');
      addTearDown(() => dir.delete(recursive: true));
      await File(
        p.join(dir.path, 'WATCHDOG.md'),
      ).writeAsString('Watch for unbounded loops.');
      await File(
        p.join(dir.path, 'AGENTS.md'),
      ).writeAsString('Always use fvm.');

      final ctx = await loadWatchdogContext(dir.path);
      expect(ctx.attention, contains('unbounded loops'));
      expect(ctx.projectContext, contains('fvm'));
    });

    test('returns none when nothing is on disk', () async {
      final dir = await Directory.systemTemp.createTemp('watchdog_empty_');
      addTearDown(() => dir.delete(recursive: true));
      final ctx = await loadWatchdogContext(dir.path);
      expect(ctx.attention, isNull);
      expect(ctx.projectContext, isNull);
    });
  });
}
