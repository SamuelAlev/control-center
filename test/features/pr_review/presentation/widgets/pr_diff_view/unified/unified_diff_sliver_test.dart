import 'package:cc_domain/features/pr_review/domain/entities/pr_file.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/diff_overflow_mode.dart';
import 'package:control_center/features/pr_review/presentation/utils/diff_isolate_worker.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_diff_view/unified/diff_slot.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_diff_view/unified/diff_structure_store.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_diff_view/unified/pr_diff_document.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_diff_view/unified/unified_diff_config.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_diff_view/unified/unified_diff_sliver.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // ── UnifiedDiffPaintConfig ───────────────────────────────────────

  group('UnifiedDiffPaintConfig', () {
    test('equality on identical fields', () {
      const a = UnifiedDiffPaintConfig(
        brightness: Brightness.light,
        baseStyle: TextStyle(fontSize: 13),
        gutterBgColor: Color(0xFFF0F0F0),
        gutterBorderColor: Color(0xFFDDDDDD),
        expandGapBgColor: Color(0xFFEEEEEE),
        expandGapBorderColor: Color(0xFFCCCCCC),
        expandGapTextColor: Color(0xFF666666),
        commentHighlightColor: Color(0x1A0000FF),
        commentHighlightActiveColor: Color(0x330000FF),
        revision: 42,
      );
      const b = UnifiedDiffPaintConfig(
        brightness: Brightness.light,
        baseStyle: TextStyle(fontSize: 13),
        gutterBgColor: Color(0xFFF0F0F0),
        gutterBorderColor: Color(0xFFDDDDDD),
        expandGapBgColor: Color(0xFFEEEEEE),
        expandGapBorderColor: Color(0xFFCCCCCC),
        expandGapTextColor: Color(0xFF666666),
        commentHighlightColor: Color(0x1A0000FF),
        commentHighlightActiveColor: Color(0x330000FF),
        revision: 42,
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('inequality on different revision', () {
      const a = UnifiedDiffPaintConfig(
        brightness: Brightness.light,
        baseStyle: TextStyle(fontSize: 13),
        gutterBgColor: Color(0xFF000000),
        gutterBorderColor: Color(0xFF000000),
        expandGapBgColor: Color(0xFF000000),
        expandGapBorderColor: Color(0xFF000000),
        expandGapTextColor: Color(0xFF000000),
        commentHighlightColor: Color(0x00000000),
        commentHighlightActiveColor: Color(0x00000000),
        revision: 1,
      );
      const b = UnifiedDiffPaintConfig(
        brightness: Brightness.light,
        baseStyle: TextStyle(fontSize: 13),
        gutterBgColor: Color(0xFF000000),
        gutterBorderColor: Color(0xFF000000),
        expandGapBgColor: Color(0xFF000000),
        expandGapBorderColor: Color(0xFF000000),
        expandGapTextColor: Color(0xFF000000),
        commentHighlightColor: Color(0x00000000),
        commentHighlightActiveColor: Color(0x00000000),
        revision: 2,
      );
      expect(a, isNot(equals(b)));
    });

    test('inequality on different brightness', () {
      const a = UnifiedDiffPaintConfig(
        brightness: Brightness.light,
        baseStyle: TextStyle(),
        gutterBgColor: Color(0xFF000000),
        gutterBorderColor: Color(0xFF000000),
        expandGapBgColor: Color(0xFF000000),
        expandGapBorderColor: Color(0xFF000000),
        expandGapTextColor: Color(0xFF000000),
        commentHighlightColor: Color(0x00000000),
        commentHighlightActiveColor: Color(0x00000000),
        revision: 0,
      );
      const b = UnifiedDiffPaintConfig(
        brightness: Brightness.dark,
        baseStyle: TextStyle(),
        gutterBgColor: Color(0xFF000000),
        gutterBorderColor: Color(0xFF000000),
        expandGapBgColor: Color(0xFF000000),
        expandGapBorderColor: Color(0xFF000000),
        expandGapTextColor: Color(0xFF000000),
        commentHighlightColor: Color(0x00000000),
        commentHighlightActiveColor: Color(0x00000000),
        revision: 0,
      );
      expect(a, isNot(equals(b)));
    });

    test('defaults: topInset=0, overflowMode=scroll, searchFile=-1, '
        'searchRawIndex=-1, splitMode=false', () {
      const config = UnifiedDiffPaintConfig(
        brightness: Brightness.light,
        baseStyle: TextStyle(),
        gutterBgColor: Color(0xFF000000),
        gutterBorderColor: Color(0xFF000000),
        expandGapBgColor: Color(0xFF000000),
        expandGapBorderColor: Color(0xFF000000),
        expandGapTextColor: Color(0xFF000000),
        commentHighlightColor: Color(0x00000000),
        commentHighlightActiveColor: Color(0x00000000),
        revision: 0,
      );
      expect(config.topInset, 0);
      expect(config.overflowMode, DiffOverflowMode.scroll);
      expect(config.searchFile, -1);
      expect(config.searchRawIndex, -1);
      expect(config.splitMode, false);
    });

    test('split mode is preserved', () {
      const config = UnifiedDiffPaintConfig(
        brightness: Brightness.dark,
        baseStyle: TextStyle(),
        gutterBgColor: Color(0xFF000000),
        gutterBorderColor: Color(0xFF000000),
        expandGapBgColor: Color(0xFF000000),
        expandGapBorderColor: Color(0xFF000000),
        expandGapTextColor: Color(0xFF000000),
        commentHighlightColor: Color(0x00000000),
        commentHighlightActiveColor: Color(0x00000000),
        revision: 0,
        splitMode: true,
      );
      expect(config.splitMode, true);
    });

    test('topInset is preserved', () {
      const config = UnifiedDiffPaintConfig(
        brightness: Brightness.light,
        baseStyle: TextStyle(),
        gutterBgColor: Color(0xFF000000),
        gutterBorderColor: Color(0xFF000000),
        expandGapBgColor: Color(0xFF000000),
        expandGapBorderColor: Color(0xFF000000),
        expandGapTextColor: Color(0xFF000000),
        commentHighlightColor: Color(0x00000000),
        commentHighlightActiveColor: Color(0x00000000),
        revision: 0,
        topInset: 48,
      );
      expect(config.topInset, 48);
    });

    test('overflowMode is preserved', () {
      const config = UnifiedDiffPaintConfig(
        brightness: Brightness.light,
        baseStyle: TextStyle(),
        gutterBgColor: Color(0xFF000000),
        gutterBorderColor: Color(0xFF000000),
        expandGapBgColor: Color(0xFF000000),
        expandGapBorderColor: Color(0xFF000000),
        expandGapTextColor: Color(0xFF000000),
        commentHighlightColor: Color(0x00000000),
        commentHighlightActiveColor: Color(0x00000000),
        revision: 0,
        overflowMode: DiffOverflowMode.wrap,
      );
      expect(config.overflowMode, DiffOverflowMode.wrap);
    });

    test('searchFile/searchRawIndex are preserved', () {
      const config = UnifiedDiffPaintConfig(
        brightness: Brightness.light,
        baseStyle: TextStyle(),
        gutterBgColor: Color(0xFF000000),
        gutterBorderColor: Color(0xFF000000),
        expandGapBgColor: Color(0xFF000000),
        expandGapBorderColor: Color(0xFF000000),
        expandGapTextColor: Color(0xFF000000),
        commentHighlightColor: Color(0x00000000),
        commentHighlightActiveColor: Color(0x00000000),
        revision: 0,
        searchFile: 3,
        searchRawIndex: 42,
      );
      expect(config.searchFile, 3);
      expect(config.searchRawIndex, 42);
    });
  });

  // ── DiffCommentHighlight ─────────────────────────────────────────

  group('DiffCommentHighlight', () {
    test('equality on identical fields', () {
      const a = DiffCommentHighlight(startCol: 10, endCol: 20, active: true);
      const b = DiffCommentHighlight(startCol: 10, endCol: 20, active: true);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('inequality on different active state', () {
      const a = DiffCommentHighlight(startCol: 5, active: true);
      const b = DiffCommentHighlight(startCol: 5, active: false);
      expect(a, isNot(equals(b)));
    });

    test('inequality on different startCol', () {
      const a = DiffCommentHighlight(startCol: 1);
      const b = DiffCommentHighlight(startCol: 2);
      expect(a, isNot(equals(b)));
    });

    test('inequality on different endCol', () {
      const a = DiffCommentHighlight(startCol: 5, endCol: 10);
      const b = DiffCommentHighlight(startCol: 5, endCol: 20);
      expect(a, isNot(equals(b)));
    });

    test('null endCol means to-right-edge', () {
      const h = DiffCommentHighlight(startCol: 8);
      expect(h.endCol, isNull);
      expect(h.active, false);
    });

    test('active defaults to false', () {
      const h = DiffCommentHighlight(startCol: 0);
      expect(h.active, false);
    });
  });

  // ── UnifiedDiffSliver widget properties ──────────────────────────

  group('UnifiedDiffSliver', () {
    test('stores all constructor properties', () {
      final doc = PrDiffDocument(lineHeight: 20, headerHeight: 32);
      final store = DiffStructureStore(document: doc, maxTokenFiles: 8);
      const config = UnifiedDiffPaintConfig(
        brightness: Brightness.light,
        baseStyle: TextStyle(fontSize: 13),
        gutterBgColor: Color(0xFF000000),
        gutterBorderColor: Color(0xFF000000),
        expandGapBgColor: Color(0xFF000000),
        expandGapBorderColor: Color(0xFF000000),
        expandGapTextColor: Color(0xFF000000),
        commentHighlightColor: Color(0x00000000),
        commentHighlightActiveColor: Color(0x00000000),
        revision: 0,
      );
      final slots = <DiffSlot>[];
      final highlights = <int, Map<int, DiffCommentHighlight>>{};

      final widget = UnifiedDiffSliver(
        delegate: SliverChildBuilderDelegate((_, _) => const SizedBox.shrink()),
        document: doc,
        store: store,
        config: config,
        slots: slots,
        commentHighlights: highlights,
        onGutterTap: (_, _) {},
        onSelectionChanged: () {},
        onLayoutModeChanged: () {},
      );

      expect(widget.document, same(doc));
      expect(widget.store, same(store));
      expect(widget.config, same(config));
      expect(widget.slots, same(slots));
      expect(widget.commentHighlights, same(highlights));
      expect(widget.onGutterTap, isNotNull);
      expect(widget.onSelectionChanged, isNotNull);
      expect(widget.onLayoutModeChanged, isNotNull);
    });

    test('allows null callbacks', () {
      final doc = PrDiffDocument(lineHeight: 20, headerHeight: 32);
      final store = DiffStructureStore(document: doc, maxTokenFiles: 8);
      const config = UnifiedDiffPaintConfig(
        brightness: Brightness.light,
        baseStyle: TextStyle(),
        gutterBgColor: Color(0xFF000000),
        gutterBorderColor: Color(0xFF000000),
        expandGapBgColor: Color(0xFF000000),
        expandGapBorderColor: Color(0xFF000000),
        expandGapTextColor: Color(0xFF000000),
        commentHighlightColor: Color(0x00000000),
        commentHighlightActiveColor: Color(0x00000000),
        revision: 0,
      );

      final widget = UnifiedDiffSliver(
        delegate: SliverChildBuilderDelegate((_, _) => const SizedBox.shrink()),
        document: doc,
        store: store,
        config: config,
        slots: const [],
      );

      expect(widget.onGutterTap, isNull);
      expect(widget.onSelectionChanged, isNull);
      expect(widget.onLayoutModeChanged, isNull);
    });
  });

  // ── DiffSlot ────────────────────────────────────────────────────

  group('DiffSlot', () {
    test('constructs with all required fields', () {
      const slot = DiffSlot(
        kind: DiffSlotKind.header,
        key: 'hdr:0',
        fileIndex: 0,
        offset: 0,
        height: 32,
      );
      expect(slot.kind, DiffSlotKind.header);
      expect(slot.key, 'hdr:0');
      expect(slot.fileIndex, 0);
      expect(slot.offset, 0);
      expect(slot.height, 32);
    });

    test('default rawIndex is -1', () {
      const slot = DiffSlot(
        kind: DiffSlotKind.gap,
        key: 'gap:0:5',
        fileIndex: 0,
        offset: 100,
        height: 24,
      );
      expect(slot.rawIndex, -1);
    });

    test('default anchorDisplayLine is -1', () {
      const slot = DiffSlot(
        kind: DiffSlotKind.comment,
        key: 'thread:abc',
        fileIndex: 0,
        offset: 200,
        height: 80,
      );
      expect(slot.anchorDisplayLine, -1);
    });

    test('rawIndex is preserved', () {
      const slot = DiffSlot(
        kind: DiffSlotKind.gap,
        key: 'gap:0:5',
        fileIndex: 0,
        offset: 100,
        height: 24,
        rawIndex: 5,
      );
      expect(slot.rawIndex, 5);
    });

    test('anchorDisplayLine is preserved', () {
      const slot = DiffSlot(
        kind: DiffSlotKind.comment,
        key: 'thread:abc',
        fileIndex: 1,
        offset: 200,
        height: 80,
        anchorDisplayLine: 42,
      );
      expect(slot.anchorDisplayLine, 42);
    });
  });

  // ── kDiffSplitGutterWidth ───────────────────────────────────────

  test('kDiffSplitGutterWidth is positive', () {
    expect(kDiffSplitGutterWidth, greaterThan(0));
  });

  // ── Lazy structure parse vs slot offsets ────────────────────────

  group('lazy structure parse during layout', () {
    setUpAll(() => DiffWorkerPool.debugForceInline = true);
    tearDownAll(() => DiffWorkerPool.debugForceInline = false);

    // A hunk that does NOT start at line 1: the parser synthesizes a leading
    // "Show lines 1-4" expand-gap row (and the document appends an EOF gap),
    // so the parsed display-row count exceeds the pre-parse newline estimate
    // and the parse moves every later file's offset.
    const patch = '@@ -5,3 +5,4 @@\n a\n+b\n c\n d\n';

    PrFile file(String name) => PrFile(
      filename: name,
      status: PrFileStatus.modified,
      additions: 1,
      deletions: 0,
      patch: patch,
    );

    testWidgets(
      'slot children track live document offsets when a parse moves files '
      '(host only eagerly parses the opening file)',
      (tester) async {
        final doc = PrDiffDocument(lineHeight: 20, headerHeight: 32)
          ..setFiles([file('a.dart'), file('b.dart')]);
        final store = DiffStructureStore(document: doc, maxTokenFiles: 8);

        // Snapshot slot offsets from the ESTIMATED heights, before any parse —
        // exactly what the host's slot list holds on a PR over the eager-parse
        // budget.
        final staleOffsetOfB = doc.offsetOfFile(1);
        final slots = [
          DiffSlot(
            kind: DiffSlotKind.header,
            key: 'hdr:a',
            fileIndex: 0,
            offset: doc.offsetOfFile(0),
            height: 32,
          ),
          DiffSlot(
            kind: DiffSlotKind.header,
            key: 'hdr:b',
            fileIndex: 1,
            offset: staleOffsetOfB,
            height: 32,
          ),
        ];

        var geometryMoved = 0;
        await tester.pumpWidget(
          MaterialApp(
            home: CustomScrollView(
              slivers: [
                UnifiedDiffSliver(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => SizedBox(
                      key: ValueKey(slots[i].key),
                      height: slots[i].height,
                    ),
                    childCount: slots.length,
                  ),
                  document: doc,
                  store: store,
                  config: const UnifiedDiffPaintConfig(
                    brightness: Brightness.light,
                    baseStyle: TextStyle(fontSize: 13),
                    gutterBgColor: Color(0xFFF0F0F0),
                    gutterBorderColor: Color(0xFFDDDDDD),
                    expandGapBgColor: Color(0xFFEEEEEE),
                    expandGapBorderColor: Color(0xFFCCCCCC),
                    expandGapTextColor: Color(0xFF666666),
                    commentHighlightColor: Color(0x1A0000FF),
                    commentHighlightActiveColor: Color(0x330000FF),
                    revision: 0,
                  ),
                  slots: slots,
                  onLayoutModeChanged: () => geometryMoved++,
                ),
              ],
            ),
          ),
        );

        // The first layout parsed the visible files, replacing estimated
        // heights with exact ones.
        expect(doc.structureOf(0), isNotNull);
        final liveOffsetOfB = doc.offsetOfFile(1);
        // Fixture guard: the parse really moved file b — without drift this
        // test asserts nothing.
        expect(liveOffsetOfB, isNot(equals(staleOffsetOfB)));

        // The header child is positioned at the document's LIVE offset, not
        // the slot snapshot: positioning by the snapshot painted headers
        // mid-file with a blank band at the real file boundary.
        final headerTop = tester
            .getTopLeft(find.byKey(const ValueKey('hdr:b')))
            .dy;
        expect(headerTop, moreOrLessEquals(liveOffsetOfB, epsilon: 0.01));

        // And the host was asked (post-frame) to rebuild its slot list
        // against the new geometry.
        expect(geometryMoved, greaterThan(0));
      },
    );
  });

  // ── Pinned header owns the pointer ───────────────────────────────

  group('pinned header blocks selection of rows underneath', () {
    setUpAll(() => DiffWorkerPool.debugForceInline = true);
    tearDownAll(() => DiffWorkerPool.debugForceInline = false);

    const headerHeight = 32.0;
    const lineHeight = 20.0;

    String longPatch() {
      final buf = StringBuffer('@@ -1,80 +1,80 @@\n');
      for (var i = 1; i <= 80; i++) {
        buf.writeln(' line $i');
      }
      return buf.toString();
    }

    const paintConfig = UnifiedDiffPaintConfig(
      brightness: Brightness.light,
      baseStyle: TextStyle(fontSize: 13),
      gutterBgColor: Color(0xFFF0F0F0),
      gutterBorderColor: Color(0xFFDDDDDD),
      expandGapBgColor: Color(0xFFEEEEEE),
      expandGapBorderColor: Color(0xFFCCCCCC),
      expandGapTextColor: Color(0xFF666666),
      commentHighlightColor: Color(0x1A0000FF),
      commentHighlightActiveColor: Color(0x330000FF),
      revision: 0,
    );

    Future<RenderUnifiedDiffSliver> pumpScrolled(WidgetTester tester) async {
      final doc =
          PrDiffDocument(lineHeight: lineHeight, headerHeight: headerHeight)
            ..setFiles([
              PrFile(
                filename: 'lib/a.dart',
                status: PrFileStatus.modified,
                additions: 0,
                deletions: 0,
                patch: longPatch(),
              ),
            ]);
      final store = DiffStructureStore(document: doc, maxTokenFiles: 8);
      final slots = [
        DiffSlot(
          kind: DiffSlotKind.header,
          key: 'hdr:a',
          fileIndex: 0,
          offset: 0,
          height: headerHeight,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: CustomScrollView(
            slivers: [
              UnifiedDiffSliver(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => SizedBox(
                    key: ValueKey(slots[i].key),
                    height: slots[i].height,
                  ),
                  childCount: slots.length,
                ),
                document: doc,
                store: store,
                config: paintConfig,
                slots: slots,
              ),
            ],
          ),
        ),
      );
      await tester.pump();

      final scrollable = tester.state<ScrollableState>(find.byType(Scrollable));
      // Deep enough that several code rows sit under the docked header.
      scrollable.position.jumpTo(200);
      await tester.pump();

      return tester.renderObject<RenderUnifiedDiffSliver>(
        find.byType(UnifiedDiffSliver),
      );
    }

    testWidgets('code under the docked header is not a hit target', (
      tester,
    ) async {
      final sliver = await pumpScrolled(tester);

      expect(sliver.stickyHeaderPinned, isTrue);
      expect(sliver.coversStickyHeader(headerHeight / 2), isTrue);
      expect(sliver.codeRowAt(headerHeight / 2), isNull);
      expect(sliver.cellAt(headerHeight / 2, 200), isNull);
      expect(sliver.displayRowAt(headerHeight / 2), isNull);

      // Just below the bar is still a real code row, and the sliver
      // itself still claims the pointer there (selection / gutter tap).
      expect(sliver.coversStickyHeader(headerHeight + 4), isFalse);
      expect(sliver.codeRowAt(headerHeight + 4), isNotNull);
      expect(sliver.cellAt(headerHeight + 4, 200), isNotNull);
      expect(
        sliver.hitTestSelf(
          mainAxisPosition: headerHeight + 4,
          crossAxisPosition: 200,
        ),
        isTrue,
      );
      expect(
        sliver.hitTestSelf(
          mainAxisPosition: headerHeight / 2,
          crossAxisPosition: 200,
        ),
        isFalse,
      );
    });

    testWidgets('a mouse drag that starts on the header does not select', (
      tester,
    ) async {
      final sliver = await pumpScrolled(tester);
      final origin = tester.getTopLeft(find.byType(CustomScrollView));

      final gesture = await tester.startGesture(
        origin + const Offset(200, headerHeight / 2),
        kind: PointerDeviceKind.mouse,
      );
      await tester.pump();
      await gesture.moveBy(const Offset(0, 48));
      await tester.pump();
      await gesture.up();
      await tester.pump();

      expect(sliver.hasSelection, isFalse);
    });
  });
}
