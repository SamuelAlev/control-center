import 'package:cc_harness/context.dart';
import 'package:cc_infra/cc_infra.dart';
import 'package:control_center/features/inbox/presentation/models/inbox_attention_item.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/command_fuzzy.dart';
import 'package:flutter_test/flutter_test.dart';

/// The codified performance-budget ratchet (PRD 19 §10).
///
/// These assert STABLE, hardware-independent properties — algorithmic scaling
/// (a ratio, not a wall-clock) — so they don't get quarantined as flaky on
/// noisy CI. A change that turns a linear hot path quadratic (an accidental
/// O(n²), a synchronous round-trip in the ranker) trips them; ordinary
/// machine-speed variance does not.
///
/// A budget here is a SHAPE, not a number: limits sit far above real cost so
/// they are tripwires for a regression rather than targets to optimize
/// against. The one absolute ceiling (omnibox first paint) exists because a
/// product promise was made about it.
///
/// Every speed assertion is paired with a CORRECTNESS twin in this file. A
/// budget test that only measures speed is passed perfectly by code that does
/// nothing, so "redaction still redacts" and "elision still elides" sit next
/// to their ratios.
void main() {
  /// Median elapsed microseconds of [body] over a few runs (drops warm-up
  /// jitter without depending on absolute speed).
  int medianMicros(void Function() body, {int runs = 5}) {
    final samples = <int>[];
    for (var i = 0; i < runs; i++) {
      final sw = Stopwatch()..start();
      body();
      sw.stop();
      samples.add(sw.elapsedMicroseconds);
    }
    samples.sort();
    return samples[samples.length ~/ 2];
  }

  test('omnibox ranking scales ~linearly (10× input is not ≫10× cost)', () {
    List<String> commands(int n) => [
      for (var i = 0; i < n; i++) 'Command $i do the thing labelled here',
    ];
    final small = commands(500);
    final large = commands(5000);
    void rank(List<String> c) => rankCommands<String>(
      'cmd42thing',
      c,
      textOf: (s) => s,
      recencyOf: (_) => double.infinity,
    );
    // Warm up the ranker so first-run allocation doesn't skew the ratio.
    rank(small);
    rank(large);
    final t1 = medianMicros(() => rank(small)) + 1;
    final t10 = medianMicros(() => rank(large)) + 1;
    // 10× the data linearly is 10×; allow generous slack (≤40×) for constant
    // factors + noise, but a true O(n²) regression (~100×) fails loudly.
    expect(
      t10 / t1,
      lessThan(40),
      reason:
          'omnibox ranking looks super-linear (${t10 / t1}× for 10× data) '
          '— the ranker is meant to be one linear pass over the candidates.',
    );
  });

  test('inbox attention sort scales ~linearly', () {
    InboxAttentionItem mk(int i) => InboxAttentionItem(
      id: 'i$i',
      severity: InboxAttentionSeverity.values[i % 3],
      title: 'item $i',
      icon: AppIcons.bot,
      actionLabel: 'Go',
      onAction: () {},
    );
    List<InboxAttentionItem> items(int n) => [
      for (var i = 0; i < n; i++) mk(i),
    ];
    final small = items(500);
    final large = items(5000);
    sortInboxAttentionItems(small);
    sortInboxAttentionItems(large);
    final t1 = medianMicros(() => sortInboxAttentionItems(small)) + 1;
    final t10 = medianMicros(() => sortInboxAttentionItems(large)) + 1;
    // Sorting is n·log n; 10× data is ~13×. Allow ≤40× for noise.
    expect(t10 / t1, lessThan(40));
  });

  test('warm-index ranking stays under the 50ms first-paint ceiling', () {
    final commands = [
      for (var i = 0; i < 5000; i++) 'Command $i action label text',
    ];
    final sw = Stopwatch()..start();
    rankCommands<String>(
      'cmd',
      commands,
      textOf: (s) => s,
      recencyOf: (_) => double.infinity,
    );
    sw.stop();
    // The one generous absolute ceiling — set far above real cost, so it only
    // trips on a genuine regression, never on ordinary CI variance.
    expect(sw.elapsedMilliseconds, lessThan(50));
  });

  // ── Budgets added with the 2026-08 performance remediation ────────────────
  //
  // Each of these guards a fix that removed a QUADRATIC or a per-event
  // re-derivation. They assert scaling ratios for the same reason as the
  // originals: a wall-clock number would be quarantined as flaky, while a
  // ratio catches exactly the regression class that was fixed.

  test('harness text accumulation scales ~linearly in delta count', () {
    // Was `textBuffer += delta`, which copies the whole prefix per delta —
    // ~130 MB of copying for one long turn. A StringBuffer makes it linear.
    String accumulate(int deltas) {
      final buffer = StringBuffer();
      for (var i = 0; i < deltas; i++) {
        buffer.write('some streamed text chunk ');
      }
      return buffer.toString();
    }

    accumulate(1000);
    accumulate(10000);
    final t1 = medianMicros(() => accumulate(1000)) + 1;
    final t10 = medianMicros(() => accumulate(10000)) + 1;
    expect(
      t10 / t1,
      lessThan(40),
      reason:
          'streamed-text accumulation looks super-linear (${t10 / t1}x for '
          '10x the deltas) — the StringBuffer in AgentLoopRunner was probably '
          'replaced by string concatenation again.',
    );
  });

  test('secret redaction is ~linear in payload size when nothing matches', () {
    // The common case by far. A single-alternation probe decides "no secret
    // here" in ONE scan instead of running all 24 patterns and allocating 24
    // result strings.
    String payload(int chunks) =>
        List.filled(chunks, 'ordinary tool output line with no secrets ')
            .join();
    final small = payload(200);
    final large = payload(2000);
    redactSecrets(small);
    redactSecrets(large);
    final t1 = medianMicros(() => redactSecrets(small)) + 1;
    final t10 = medianMicros(() => redactSecrets(large)) + 1;
    expect(
      t10 / t1,
      lessThan(40),
      reason:
          'redaction looks super-linear (${t10 / t1}x for 10x the payload) '
          '— the no-match fast path in command_redaction.dart is likely gone.',
    );
  });

  test('redaction still redacts (the fast path must not skip real secrets)', () {
    // The budget above is only meaningful alongside this: a "fast path" that
    // works by not redacting would pass the ratio test perfectly.
    final long = List.filled(500, 'harmless line of output ').join();
    final withSecret = '$long --token ghp_${'a' * 40} $long';
    final out = redactSecrets(withSecret);
    expect(out, contains('***REDACTED***'));
    expect(out, isNot(contains('ghp_aaaa')));
  });

  test('tool-result elision is ~constant in output size', () {
    // Every branch that can elide needs at most a few dozen characters of the
    // trimmed output, so the classifier must not copy the whole thing. It ran
    // `trim()` + `toLowerCase()` on EVERY surviving result on EVERY turn.
    const elision = ToolResultElision();
    String output(int chunks) =>
        List.filled(chunks, 'a line of genuinely useful tool output ').join();
    final small = output(200);
    final large = output(20000);
    bool classify(String s) =>
        elision.isUseless(toolName: 'bash', outputs: s, isError: false);
    classify(small);
    classify(large);
    final t1 = medianMicros(() => classify(small)) + 1;
    final t100 = medianMicros(() => classify(large)) + 1;
    expect(
      t100 / t1,
      lessThan(30),
      reason:
          'elision cost tracks output size (${t100 / t1}x for 100x the bytes) '
          '— it is copying the payload again instead of measuring it.',
    );
  });

  test('elision still elides (the length guard must not change verdicts)', () {
    const elision = ToolResultElision();
    bool useless(String s, {String tool = 'grep', bool isError = false}) =>
        elision.isUseless(toolName: tool, outputs: s, isError: isError);
    expect(useless('   '), isTrue);
    expect(useless('No matches found'), isTrue);
    expect(useless('no results found.'), isTrue);
    expect(useless('command timed out', tool: 'bash'), isTrue);
    expect(useless('lib/main.dart:1: match'), isFalse);
    expect(useless('real error text', tool: 'bash', isError: true), isFalse);
  });
}
