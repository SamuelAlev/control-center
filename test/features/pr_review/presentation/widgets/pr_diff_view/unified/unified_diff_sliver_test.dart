import 'package:control_center/features/pr_review/domain/value_objects/diff_overflow_mode.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_diff_view/unified/diff_slot.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_diff_view/unified/diff_structure_store.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_diff_view/unified/pr_diff_document.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_diff_view/unified/unified_diff_sliver.dart';
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
      const a = DiffCommentHighlight(
        startCol: 10,
        endCol: 20,
        active: true,
      );
      const b = DiffCommentHighlight(
        startCol: 10,
        endCol: 20,
        active: true,
      );
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
      final doc = PrDiffDocument(
        lineHeight: 20,
        headerHeight: 32,
        autoCollapseThreshold: 100,
      );
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
      final doc = PrDiffDocument(
        lineHeight: 20,
        headerHeight: 32,
        autoCollapseThreshold: 100,
      );
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
}
