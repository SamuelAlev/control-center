import 'package:cc_domain/features/pr_review/domain/entities/pr_file.dart';
import 'package:cc_domain/features/pr_review/domain/services/diff_parser.dart';
import 'package:control_center/features/pr_review/presentation/utils/diff_isolate_worker.dart';
import 'package:control_center/features/pr_review/presentation/utils/syntax_highlighter.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_diff_view/unified/diff_structure_store.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_diff_view/unified/pr_diff_document.dart';
import 'package:control_center/shared/syntax/shiki_tokenizers.dart';
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

  group('expanded context highlighting', () {
    const patch =
        '@@ -1,3 +1,3 @@\n'
        ' /* open\n'
        '-old\n'
        '+new\n'
        '@@ -40,1 +40,1 @@\n'
        ' later\n';

    setUp(() => debugDisableShikiAsync = true);
    tearDown(() => debugDisableShikiAsync = false);

    PrFile file() => PrFile(
      filename: 'a.dart',
      status: PrFileStatus.modified,
      additions: 1,
      deletions: 1,
      patch: patch,
    );

    test(
      'colours rows revealed by a gap expand, seeded by the hunk above',
      () async {
        doc.setFiles([file()]);
        store.requestTokens({0});
        await pumpEventQueue();

        final raw = store.ensureStructure(0);
        final gap = _gapIndex(raw);
        final later = raw.contents.indexOf('later');
        const slice = [' still comment', '*/'];
        doc.setStructure(
          0,
          _spliceGap(
            raw,
            gap,
            slice,
            oldStart: raw.oldLines[gap]!,
            newStart: raw.newLines[gap]!,
          ),
          augment: false,
        );
        store.spliceTokens(0, gap, slice);
        await pumpEventQueue();

        final tokens = store.tokensOf(0)!;
        final revealed = tokens[gap]!;
        expect(revealed.map((t) => t.text).join(), ' still comment');

        // Same colours as tokenizing the comment from where it opened. A bare
        // tokenize of the revealed line would colour it as code.
        final seeded = highlightDiffLines(
          '/* open\nnew\n still comment\n*/',
          'dart',
          dark: false,
        );
        final bare = highlightDiffLines(
          ' still comment\n*/',
          'dart',
          dark: false,
        );
        expect(
          revealed.map((t) => t.colorValue).toList(),
          seeded[2].map((t) => t.colorValue).toList(),
        );
        expect(
          revealed.map((t) => t.colorValue).toList(),
          isNot(bare[0].map((t) => t.colorValue).toList()),
        );

        // The row below the gap keeps the highlight it already had, shifted
        // down by the inserted lines.
        expect(
          tokens[later + slice.length - 1]!.map((t) => t.text).join(),
          'later',
        );
      },
    );

    test(
      'worker chunks that arrive after the expand land on shifted rows',
      () async {
        doc.setFiles([file()]);
        final raw = store.ensureStructure(0);
        final gap = _gapIndex(raw);
        final later = raw.contents.indexOf('later');
        const slice = [' still comment', '*/'];
        store.requestTokens({0});
        doc.setStructure(
          0,
          _spliceGap(
            raw,
            gap,
            slice,
            oldStart: raw.oldLines[gap]!,
            newStart: raw.newLines[gap]!,
          ),
          augment: false,
        );
        store.spliceTokens(0, gap, slice);
        await pumpEventQueue();

        final tokens = store.tokensOf(0)!;
        expect(
          tokens[later + slice.length - 1]!.map((t) => t.text).join(),
          'later',
          reason:
              'a chunk emitted against the pre-expand patch must follow '
              'the splice',
        );
        expect(tokens[gap]!.map((t) => t.text).join(), ' still comment');
        expect(tokens[gap]!.any((t) => t.colorValue != null), isTrue);
      },
    );
  });
}

int _gapIndex(DiffRawLines raw) {
  for (var i = 0; i < raw.length; i++) {
    if (raw.kindAt(i) == DiffLineKind.expandGap &&
        raw.gapOldEnds[i] != kEofGapSentinel) {
      return i;
    }
  }
  throw StateError('no expand gap');
}

DiffRawLines _spliceGap(
  DiffRawLines raw,
  int gapIndex,
  List<String> slice, {
  required int oldStart,
  required int newStart,
}) {
  final kinds = List<int>.from(raw.kinds)..removeAt(gapIndex);
  final contents = List<String>.from(raw.contents)..removeAt(gapIndex);
  final oldLines = List<int?>.from(raw.oldLines)..removeAt(gapIndex);
  final newLines = List<int?>.from(raw.newLines)..removeAt(gapIndex);
  final hunkHeaders = List<String?>.from(raw.hunkHeaders)..removeAt(gapIndex);
  final gapOldEnds = List<int?>.from(raw.gapOldEnds)..removeAt(gapIndex);
  final gapNewEnds = List<int?>.from(raw.gapNewEnds)..removeAt(gapIndex);
  for (var k = 0; k < slice.length; k++) {
    kinds.insert(gapIndex + k, DiffLineKind.context.index);
    contents.insert(gapIndex + k, slice[k]);
    oldLines.insert(gapIndex + k, oldStart + k);
    newLines.insert(gapIndex + k, newStart + k);
    hunkHeaders.insert(gapIndex + k, null);
    gapOldEnds.insert(gapIndex + k, null);
    gapNewEnds.insert(gapIndex + k, null);
  }
  var maxChars = raw.maxLineChars;
  for (final line in slice) {
    if (line.length > maxChars) {
      maxChars = line.length;
    }
  }
  return DiffRawLines(
    kinds: kinds,
    contents: contents,
    oldLines: oldLines,
    newLines: newLines,
    hunkHeaders: hunkHeaders,
    gapOldEnds: gapOldEnds,
    gapNewEnds: gapNewEnds,
    maxLineChars: maxChars,
  );
}
