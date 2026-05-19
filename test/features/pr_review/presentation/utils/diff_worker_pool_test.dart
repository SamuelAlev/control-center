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
}
