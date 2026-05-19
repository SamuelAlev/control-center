import 'package:cc_domain/features/pr_review/domain/entities/pr_file.dart';
import 'package:control_center/features/pr_review/presentation/utils/diff_isolate_worker.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_diff_view/unified/diff_structure_store.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_diff_view/unified/pr_diff_document.dart';
import 'package:flutter_test/flutter_test.dart';

// `.zzz` has no shiki grammar, so tokenization runs plain — the store's
// bookkeeping is what's under test, not the highlighter. Plain tokenization
// still emits one token per line, so "has tokens" stays a meaningful assertion.
PrFile _file(String name) => PrFile(
  filename: name,
  status: PrFileStatus.modified,
  additions: 1,
  deletions: 1,
  patch: '@@ -1,2 +1,2 @@\n-old line\n+new line\n context\n',
);

void main() {
  late PrDiffDocument doc;
  late DiffStructureStore store;

  setUp(() {
    // Keep tokenization on the main isolate: widget tests must not spawn
    // workers, and the inline path exercises the same event sequence.
    DiffWorkerPool.debugForceInline = true;
    doc = PrDiffDocument(lineHeight: 18, headerHeight: 28);
    doc.setFiles([_file('a.zzz'), _file('b.zzz')]);
    store = DiffStructureStore(document: doc, maxTokenFiles: 300);
  });

  tearDown(() async {
    store.dispose();
    DiffWorkerPool.debugForceInline = false;
    await DiffWorkerPool.instance.shutdown();
  });

  group('DiffStructureStore token requests', () {
    test('fills tokens for a requested file', () async {
      store.requestTokens({0});
      await pumpEventQueue();

      expect(store.tokensOf(0), isNotEmpty);
    });

    test('re-requests a file whose job was cancelled before it delivered '
        'anything', () async {
      // Scroll file 0 into the window and straight back out before its job
      // gets a turn — the fast-fling case. The store reserves a token map the
      // moment the job starts, so the cancelled file is left holding an empty
      // one.
      store
        ..requestTokens({0})
        ..requestTokens({1});

      // Scroll it back in. Nothing has run yet, so the only thing that can
      // make this file colour again is the store re-requesting it.
      store.requestTokens({0});
      await pumpEventQueue();

      expect(
        store.tokensOf(0),
        isNotEmpty,
        reason:
            'a cancelled-then-revisited file must re-request its tokens, '
            'not read its reserved empty map as "already coloured"',
      );
    });

    test('does not re-request a file that already finished', () async {
      store.requestTokens({0});
      await pumpEventQueue();
      final first = store.tokensOf(0);

      store
        ..requestTokens({1})
        ..requestTokens({0});
      await pumpEventQueue();

      // Same map instance — settled files are served from the store, never
      // re-enqueued.
      expect(identical(store.tokensOf(0), first), isTrue);
    });

    test('invalidateFile lets a file be requested again', () async {
      store.requestTokens({0});
      await pumpEventQueue();
      final first = store.tokensOf(0);

      store.invalidateFile(0);
      expect(store.tokensOf(0), isNull);

      store.requestTokens({0});
      await pumpEventQueue();

      expect(store.tokensOf(0), isNotEmpty);
      expect(identical(store.tokensOf(0), first), isFalse);
    });
  });
}
