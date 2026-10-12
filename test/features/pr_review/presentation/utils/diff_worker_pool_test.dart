@Timeout(Duration(seconds: 60))
library;

import 'package:control_center/features/pr_review/presentation/utils/diff_isolate_worker.dart';
import 'package:flutter_test/flutter_test.dart';

/// End-to-end test of the real `isolate_manager` native worker path: a job goes
/// through `DiffWorkerPool.enqueue` → a spawned isolate running `diffWorker` →
/// the primitive wire protocol → back into decoded `DiffEvent`s. Guards the
/// regression where syntax colours were lost across the worker boundary.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('enqueue streams coloured tokens through the isolate worker', () async {
    const patch = '''
@@ -1,2 +1,2 @@
-final int x = 1;
+final int x = 2;
 print(x);
''';
    final events = <DiffEvent>[];
    await DiffWorkerPool.instance
        .enqueue(
          fileId: 'test:0',
          patch: patch,
          language: 'dart',
          isDark: true,
          generation: 1,
        )
        .forEach(events.add);

    expect(events.whereType<DiffDone>(), isNotEmpty, reason: 'terminal done');

    final colours = <int>{};
    for (final chunk in events.whereType<DiffTokensChunk>()) {
      for (final line in chunk.tokens) {
        for (final t in line) {
          if (t.colorValue != null) {
            colours.add(t.colorValue!);
          }
        }
      }
    }
    expect(
      colours,
      isNotEmpty,
      reason:
          'syntax highlighting must survive the worker round-trip (non-null colours)',
    );

    await DiffWorkerPool.instance.shutdown();
  });

  test(
    'token cache never serves one patch\'s text for another (same file)',
    () async {
      // Inline mode: no isolates, deterministic completion in the test binding.
      DiffWorkerPool.debugForceInline = true;
      addTearDown(() async {
        DiffWorkerPool.debugForceInline = false;
        await DiffWorkerPool.instance.shutdown();
      });

      // The same filename is routinely tokenized from DIFFERENT diffs: the PR
      // "Files changed" diff (vs the base branch) and the Source control tab's
      // worktree diff. Tokens carry the text the painter draws, so a
      // filename-keyed cache hit paints the other diff's content under this
      // diff's line numbers.
      const prPatch =
          '@@ -21,2 +21,2 @@\n-basebranch old\n+basebranch new\n x\n';
      const worktreePatch =
          '@@ -11,2 +11,2 @@\n-worktree old\n+worktree new\n x\n';

      Future<String> tokenText(String fileId, String patch) async {
        final events = <DiffEvent>[];
        await DiffWorkerPool.instance
            .enqueue(
              fileId: fileId,
              patch: patch,
              language: 'dart',
              isDark: true,
              generation: 1,
              cacheKey: 'lib/same_file.dart',
            )
            .forEach(events.add);
        final buf = StringBuffer();
        for (final chunk in events.whereType<DiffTokensChunk>()) {
          for (final line in chunk.tokens) {
            for (final t in line) {
              buf.write(t.text);
            }
          }
        }
        return buf.toString();
      }

      final prText = await tokenText('pr:0', prPatch);
      expect(prText, contains('basebranch'));

      final worktreeText = await tokenText('scm:0', worktreePatch);
      expect(worktreeText, contains('worktree'));
      expect(
        worktreeText,
        isNot(contains('basebranch')),
        reason:
            'a filename-keyed cache hit must not leak the PR diff\'s text '
            'into the worktree diff',
      );

      // Identical patch + key → the cache DOES serve it (that reuse is the
      // point of the cache).
      final cachedText = await tokenText('scm:1', worktreePatch);
      expect(cachedText, contains('worktree'));
    },
  );

  test('cache separates light and dark theme identities', () async {
    DiffWorkerPool.debugForceInline = true;
    addTearDown(() async {
      DiffWorkerPool.debugForceInline = false;
      await DiffWorkerPool.instance.shutdown();
    });
    const patch = '@@ -1,1 +1,1 @@\n-final a = 1;\n+final b = 2;\n';

    Future<Set<int>> colorsFor({required bool isDark}) async {
      final events = <DiffEvent>[];
      await DiffWorkerPool.instance
          .enqueue(
            fileId: isDark ? 'theme:d' : 'theme:l',
            patch: patch,
            language: 'dart',
            isDark: isDark,
            generation: 1,
            cacheKey: 'lib/theme_file.dart',
          )
          .forEach(events.add);
      return {
        for (final chunk in events.whereType<DiffTokensChunk>())
          for (final line in chunk.tokens)
            for (final t in line)
              if (t.colorValue != null) t.colorValue!,
      };
    }

    final darkColors = await colorsFor(isDark: true);
    final lightColors = await colorsFor(isDark: false);
    expect(darkColors, isNotEmpty);
    expect(lightColors, isNotEmpty);
    expect(
      darkColors.intersection(lightColors),
      isEmpty,
      reason:
          'a dark-keyed cache entry must never serve the light theme '
          '(the key embeds the CC theme identity + revision)',
    );
  });

  // The result cache used to be bounded only by entry count, so 128 large
  // files could retain tens of megabytes. These pin the size budget: skip a
  // result over either budget, evict by estimated retained bytes, and keep the
  // LRU (not FIFO) ordering.
  group('result-cache byte budget', () {
    setUp(() {
      DiffWorkerPool.debugForceInline = true;
    });
    tearDown(() async {
      DiffWorkerPool.debugForceInline = false;
      DiffWorkerPool.debugMaxCacheBytes = null;
      DiffWorkerPool.debugMaxCachedResultBytes = null;
      await DiffWorkerPool.instance.shutdown();
    });

    // `language: null` tokenizes each line as a single plain token, so the
    // retained-bytes estimate is the patch's content plus fixed per-line,
    // per-slot and per-token overhead — deterministic and measurable.
    Future<List<DiffEvent>> tokenize(
      String fileId,
      String cacheKey,
      String patch,
    ) async {
      final events = <DiffEvent>[];
      await DiffWorkerPool.instance
          .enqueue(
            fileId: fileId,
            patch: patch,
            language: null,
            isDark: true,
            generation: 1,
            cacheKey: cacheKey,
          )
          .forEach(events.add);
      return events;
    }

    String patchWithLines(int count) {
      final buffer = StringBuffer('@@ -1,$count +1,$count @@\n');
      for (var i = 0; i < count; i++) {
        buffer.writeln(' context line $i of the patch body');
      }
      return buffer.toString();
    }

    // An empty raw line parses as a context line with empty content, so this
    // yields many tokens with EMPTY text — pure line/token/list overhead.
    String patchWithEmptyLines(int count) {
      final buffer = StringBuffer('@@ -1,$count +1,$count @@\n');
      for (var i = 0; i < count; i++) {
        buffer.writeln();
      }
      return buffer.toString();
    }

    test('a result over the per-item cap is skipped, not stored', () async {
      const patch = '@@ -1,1 +1,1 @@\n context line\n';
      DiffWorkerPool.debugMaxCachedResultBytes =
          4; // < estimated bytes of patch
      DiffWorkerPool.debugMaxCacheBytes = 1 << 20;

      final events = await tokenize('budget:huge', 'lib/huge.dart', patch);

      expect(events.whereType<DiffDone>(), hasLength(1));
      expect(
        events.whereType<DiffTokensChunk>(),
        isNotEmpty,
        reason: 'an uncacheable result must still be delivered in full',
      );
      expect(DiffWorkerPool.instance.cacheSize, 0);
      expect(DiffWorkerPool.instance.cacheBytes, 0);
    });

    test('skipping an oversized result never evicts a cached one', () async {
      DiffWorkerPool.debugMaxCacheBytes = 1 << 20;
      DiffWorkerPool.debugMaxCachedResultBytes = 5000;

      await tokenize('budget:small', 'lib/small.dart', patchWithLines(4));
      final retained = DiffWorkerPool.instance.cacheBytes;
      expect(DiffWorkerPool.instance.cacheSize, 1);
      expect(retained, greaterThan(0));

      // ~244k estimated bytes — well over the 5000-byte item cap.
      await tokenize('budget:huge', 'lib/huge.dart', patchWithLines(2000));

      expect(
        DiffWorkerPool.instance.cacheSize,
        1,
        reason: 'the oversized result is skipped, not stored',
      );
      expect(
        DiffWorkerPool.instance.debugCachedKeys.single,
        startsWith('lib/small.dart|'),
      );
      expect(DiffWorkerPool.instance.cacheBytes, retained);
    });

    test('per-line/token/list overhead is charged for empty tokens', () async {
      DiffWorkerPool.debugMaxCacheBytes = 1 << 20;
      DiffWorkerPool.debugMaxCachedResultBytes = 1 << 20;

      // 60 lines whose tokens all have empty text: text-only accounting would
      // count ~0 for the body, yet the shells are real retained bytes.
      await tokenize(
        'overhead:empty',
        'lib/empty.dart',
        patchWithEmptyLines(60),
      );

      expect(DiffWorkerPool.instance.cacheSize, 1);
      expect(
        DiffWorkerPool.instance.cacheBytes,
        greaterThan(60 * 24),
        reason:
            'each empty line still costs its list shell + slot + token; a '
            'text-only figure would be ~0 for the body',
      );

      // A budget set between the (tiny) text size and the overhead-inclusive
      // size must still skip it — proving the overhead is what counts.
      DiffWorkerPool.debugMaxCachedResultBytes = 100;
      await DiffWorkerPool.instance.shutdown();
      await tokenize(
        'overhead:empty2',
        'lib/empty2.dart',
        patchWithEmptyLines(60),
      );
      expect(DiffWorkerPool.instance.cacheSize, 0);
    });

    test(
      'a result over the total budget is skipped even as the sole entry',
      () async {
        DiffWorkerPool.debugMaxCachedResultBytes =
            1 << 20; // item budget generous
        DiffWorkerPool.debugMaxCacheBytes = 100; // total budget tight

        await tokenize('edge:sole', 'lib/sole.dart', '@@ -1,1 +1,1 @@\n abc\n');

        expect(DiffWorkerPool.instance.cacheBytes, 0);
        expect(
          DiffWorkerPool.instance.cacheSize,
          0,
          reason:
              'an entry over the total budget is skipped, not kept as a sole '
              'entry (no length>1 exception)',
        );
      },
    );

    test(
      'total budget evicts the LRU entry and a hit refreshes recency',
      () async {
        // Identical text under three distinct keys → three equal-sized results.
        const patch = '@@ -1,1 +1,1 @@\n shared body line\n';
        Future<void> cache(String key) => tokenize('budget:$key', key, patch);

        await cache('a');
        final perResult = DiffWorkerPool.instance.cacheBytes;
        expect(perResult, greaterThan(0));
        await cache('b');
        expect(DiffWorkerPool.instance.cacheSize, 2);

        // Exactly two results fit, so adding a third evicts one.
        DiffWorkerPool.debugMaxCacheBytes = perResult * 2;
        DiffWorkerPool.debugMaxCachedResultBytes = perResult * 10;

        await cache('c');
        expect(DiffWorkerPool.instance.cacheSize, 2);
        expect(DiffWorkerPool.instance.cacheBytes, perResult * 2);
        expect(
          DiffWorkerPool.instance.debugCachedKeys.map(
            (k) => k.split('|').first,
          ),
          ['b', 'c'],
          reason: 'the entry evicted is the least-recently-used one (a)',
        );

        // Re-reading 'b' promotes it to most-recently-used. If eviction ignored
        // use (FIFO), 'b' would still be the victim below; as an LRU it must
        // survive while 'c' — inserted later but untouched — is evicted.
        await cache('b');
        await cache('a');
        expect(
          DiffWorkerPool.instance.debugCachedKeys.map(
            (k) => k.split('|').first,
          ),
          ['b', 'a'],
          reason:
              'a cache hit must refresh recency, not preserve insertion order',
        );
      },
    );
  });

  // Workers used to live for the whole process lifetime after a single PR
  // review. Idle teardown bounds that retention without dropping the result
  // cache or breaking later enqueues.
  test(
    'idle teardown waits for the active job, releases workers, re-spawns',
    () async {
      // The delay is far shorter than a worker round-trip (isolate spawn + shiki
      // grammar load), so the timer fires WHILE the job is in flight: the busy
      // guard must re-arm rather than tear workers down mid-job. This does not
      // depend on the cold spawn happening to exceed a large timeout.
      DiffWorkerPool.debugIdleTeardownDelay = const Duration(milliseconds: 20);
      addTearDown(() async {
        DiffWorkerPool.debugIdleTeardownDelay = null;
        await DiffWorkerPool.instance.shutdown();
      });

      const patch =
          '@@ -1,2 +1,2 @@\n-final int x = 1;\n+final int x = 2;\n print(x);\n';

      Future<int> runOnce(String fileId) async {
        var chunks = 0;
        await DiffWorkerPool.instance
            .enqueue(
              fileId: fileId,
              patch: patch,
              language: 'dart',
              isDark: true,
              generation: 1,
              cacheKey: 'lib/$fileId.dart',
            )
            .forEach((event) {
              if (event is DiffTokensChunk) {
                chunks++;
              }
            });
        return chunks;
      }

      expect(await runOnce('idle:0'), greaterThan(0));
      expect(
        DiffWorkerPool.instance.workerCount,
        greaterThan(0),
        reason:
            'the busy guard must keep the idle timer from tearing workers down '
            'mid-job (the timer fired repeatedly during the round-trip)',
      );

      expect(
        await _waitUntil(() => DiffWorkerPool.instance.workerCount == 0),
        isTrue,
        reason: 'idle workers must be released after the delay',
      );
      expect(
        DiffWorkerPool.instance.cacheSize,
        1,
        reason: 'idle teardown stops workers but keeps completed results',
      );

      // A later enqueue re-spawns workers lazily and still delivers tokens.
      expect(await runOnce('idle:1'), greaterThan(0));
      expect(DiffWorkerPool.instance.workerCount, greaterThan(0));
    },
  );
}

/// Polls [predicate] until it holds or [timeout] elapses.
Future<bool> _waitUntil(
  bool Function() predicate, {
  Duration timeout = const Duration(seconds: 10),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    if (predicate()) {
      return true;
    }
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
  return predicate();
}
