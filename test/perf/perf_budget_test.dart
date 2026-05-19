import 'package:control_center/features/inbox/domain/inbox_attention_item.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/command_fuzzy.dart';
import 'package:flutter_test/flutter_test.dart';

/// The codified performance-budget ratchet (PRD 19 §10). See `PERF_BUDGET.md`.
///
/// These assert STABLE, hardware-independent properties — algorithmic scaling
/// (a ratio, not a wall-clock) — so they don't get quarantined as flaky on
/// noisy CI. A change that turns a linear hot path quadratic (an accidental
/// O(n²), a synchronous round-trip in the ranker) trips them; ordinary
/// machine-speed variance does not.
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
          '— a regression from the linear budget in PERF_BUDGET.md.',
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
}
