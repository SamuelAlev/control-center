import 'package:cc_domain/cc_domain.dart';
import 'package:test/test.dart';

/// PRD 19 §9 + "bulk actions key per item": each item runs under its own
/// derived key, failures are isolated, and a retry re-runs only the failures.
void main() {
  test('derives a stable per-item key as bulkKey/itemId', () async {
    final seen = <String, String>{};
    await runBulkAction<String>(
      bulkKey: 'bulk-1',
      items: ['a', 'b'],
      itemId: (s) => s,
      action: (item, key) async => seen[item] = key,
    );
    expect(seen['a'], 'bulk-1/a');
    expect(seen['b'], 'bulk-1/b');
  });

  test('isolates a per-item failure — others still run', () async {
    final ran = <String>[];
    final outcome = await runBulkAction<String>(
      bulkKey: 'k',
      items: ['ok1', 'boom', 'ok2'],
      itemId: (s) => s,
      action: (item, key) async {
        if (item == 'boom') {
          throw StateError('nope');
        }
        ran.add(item);
      },
    );
    expect(ran, ['ok1', 'ok2']);
    expect(outcome.successCount, 2);
    expect(outcome.allSucceeded, isFalse);
    expect(outcome.failed, ['boom']);
    final boom = outcome.results.firstWhere((r) => r.item == 'boom');
    expect(boom.error, isA<StateError>());
  });

  test('a retry with the same bulkKey reuses the failed items keys', () async {
    // First pass: 'b' fails.
    final first = await runBulkAction<String>(
      bulkKey: 'bulk-x',
      items: ['a', 'b'],
      itemId: (s) => s,
      action: (item, key) async {
        if (item == 'b') {
          throw StateError('flaky');
        }
      },
    );
    // Retry only the failed items with the SAME bulkKey → identical keys,
    // so a server-side ledger dedupes any that actually applied.
    final keys = <String>[];
    await runBulkAction<String>(
      bulkKey: 'bulk-x',
      items: first.failed,
      itemId: (s) => s,
      action: (item, key) async => keys.add(key),
    );
    expect(keys, ['bulk-x/b']);
  });

  test('bulkItemIdempotencyKey composes bulkKey and itemId', () {
    expect(bulkItemIdempotencyKey('K', 'owner/repo#5'), 'K/owner/repo#5');
  });
}
