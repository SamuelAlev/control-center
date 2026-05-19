import 'package:cc_markdown/cc_markdown.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child, {double width = 420}) => MaterialApp(
  home: Scaffold(
    body: Directionality(
      textDirection: TextDirection.ltr,
      // A deliberately narrow surface — the regression was a hardcoded
      // 900px table clipping/overflowing anything narrower than that.
      child: SizedBox(width: width, child: child),
    ),
  ),
);

/// A Netlify-style two-column "Name / Link" table: short labels beside long,
/// unbreakable URLs.
const _netlifyTable = '''
| Name | Link |
| :--- | :--- |
| Latest commit | e6321ac9be3ea9fd6fe92343a7a7dd915f02ad5c |
| Latest deploy log | [https://app.netlify.com/projects/usectrl/deploys/6a5e2cc64e6c7a000844d5d8](https://app.netlify.com/projects/usectrl/deploys/6a5e2cc64e6c7a000844d5d8) |
| Deploy Preview | [https://deploy-preview-2803.usectrl.dev](https://deploy-preview-2803.usectrl.dev) |
''';

void main() {
  const style = CcMarkdownStyle();

  Table findTable(WidgetTester tester) =>
      tester.widget<Table>(find.byType(Table));

  group('table column widths', () {
    testWidgets('a short label column collapses to intrinsic width, the wide '
        'column stays flexible', (tester) async {
      await tester.pumpWidget(
        _host(const CcMarkdown(data: _netlifyTable, style: style)),
      );
      await tester.pumpAndSettle();

      final table = findTable(tester);
      // Column 0 (the short "Name" labels) hugs its content.
      expect(table.columnWidths?[0], isA<IntrinsicColumnWidth>());
      // Column 1 (long URLs) is left to the flexible default so it absorbs the
      // remaining width and wraps rather than forcing the table wide.
      expect(table.columnWidths?[1], isNull);
      expect(table.defaultColumnWidth, isA<FlexColumnWidth>());
    });

    testWidgets('the table fits within a narrow surface without overflowing', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(const CcMarkdown(data: _netlifyTable, style: style), width: 360),
      );
      await tester.pumpAndSettle();

      // The old hardcoded 900px width overflowed a 360px surface. The table
      // must now lay out no wider than the surface.
      final tableSize = tester.getSize(find.byType(Table));
      expect(tableSize.width, lessThanOrEqualTo(360.0));
      expect(tester.takeException(), isNull);
    });

    testWidgets('on a wide surface the table fills the width while the label '
        'column hugs its content (no 50/50 split)', (tester) async {
      // The default 800px test window would clamp a wider surface, hiding the
      // regression (the old code capped at 900) — enlarge the view first.
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _host(const CcMarkdown(data: _netlifyTable, style: style), width: 1400),
      );
      await tester.pumpAndSettle();

      // The table fills the surface (GitHub-like) rather than stranding a
      // narrow stub — but the wide URL column, not the label column, gets the
      // space.
      final tableWidth = tester.getSize(find.byType(Table)).width;
      expect(tableWidth, greaterThan(1000.0));
      expect(tableWidth, lessThanOrEqualTo(1400.0));

      // The short "Name" label cell hugs its content: its width is a small
      // fraction of the table, not ~half (the old even flex split).
      final nameCell = tester.getSize(
        find
            .ancestor(
              of: find.textContaining('Latest deploy log', findRichText: true),
              matching: find.byType(Padding),
            )
            .first,
      );
      expect(nameCell.width, lessThan(tableWidth * 0.35));
    });

    testWidgets(
      'a table of uniformly short cells shrink-wraps to its content',
      (tester) async {
        const grid = '''
| A | B | C |
| - | - | - |
| 1 | 2 | 3 |
| 4 | 5 | 6 |
''';
        await tester.pumpWidget(
          _host(const CcMarkdown(data: grid, style: style), width: 800),
        );
        await tester.pumpAndSettle();

        // Every column is short and media-free, so all are intrinsic: with no
        // flexible column to stretch it, the table hugs its content rather than
        // sprawling across the 800px surface.
        final table = findTable(tester);
        expect(table.columnWidths?[0], isA<IntrinsicColumnWidth>());
        expect(table.columnWidths?[1], isA<IntrinsicColumnWidth>());
        expect(table.columnWidths?[2], isA<IntrinsicColumnWidth>());
        expect(tester.getSize(find.byType(Table)).width, lessThan(400.0));
      },
    );
  });

  group('cell alignment', () {
    // The coverage-bot cell shape: a right-aligned column whose cells hold
    // two lines split by <br/>. Align alone only right-positions the text
    // BLOCK; every line must right-align within it, like GitHub.
    const alignedHtmlTable =
        '<table><thead><tr><th align="center">S</th><th align="left">Cat</th>'
        '<th align="right">Pct</th></tr></thead><tbody>'
        '<tr><td align="center">A</td><td align="left">Lines</td>'
        '<td align="right">28.97%<br/>+2.20%</td></tr></tbody></table>';

    Finder cellText(String contains) => find.byWidgetPredicate(
      (w) =>
          w is Text && (w.textSpan?.toPlainText().contains(contains) ?? false),
    );

    DefaultTextStyle nearestStyle(WidgetTester tester, Finder text) =>
        tester.widget<DefaultTextStyle>(
          find
              .ancestor(of: text, matching: find.byType(DefaultTextStyle))
              .first,
        );

    testWidgets(
      'a right-aligned column right-aligns every line of a multi-line cell',
      (tester) async {
        await tester.pumpWidget(
          _host(const CcMarkdown(data: alignedHtmlTable, style: style)),
        );
        await tester.pumpAndSettle();

        expect(
          nearestStyle(tester, cellText('28.97%')).textAlign,
          TextAlign.end,
        );
      },
    );

    testWidgets('center and left columns propagate their alignment', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(const CcMarkdown(data: alignedHtmlTable, style: style)),
      );
      await tester.pumpAndSettle();

      expect(nearestStyle(tester, cellText('A')).textAlign, TextAlign.center);
      // Left columns add no override — the ambient (null) alignment stands.
      expect(nearestStyle(tester, cellText('Lines')).textAlign, isNull);
    });
  });

  group('colspan', () {
    // The coverage-bot "Changed Files" divider: a row whose first cell spans
    // every column. Flutter's Table cannot merge cells, so span tables swap
    // verticalInside for interleaved border-strip columns, hidden inside the
    // span — the spanned row must show NO vertical lines.
    const spanTable =
        '<table><thead><tr><th>File</th><th>Stmts</th><th>Lines</th></tr></thead>'
        '<tbody><tr><td colspan="3"><b>Changed Files</b></td></tr>'
        '<tr><td>app/server.ts</td><td>0%</td><td>2%</td></tr></tbody></table>';

    testWidgets('a spanned row hides its inner vertical strips, normal rows '
        'keep them', (tester) async {
      await tester.pumpWidget(
        _host(const CcMarkdown(data: spanTable, style: style)),
      );
      await tester.pumpAndSettle();

      final table = findTable(tester);
      // 3 content columns + 2 strip columns interleaved.
      expect(table.children.first.children, hasLength(5));
      int strips(TableRow row) => row.children.whereType<TableCell>().length;
      expect(strips(table.children[0]), 2); // header keeps its grid
      expect(strips(table.children[1]), 0); // spanned row reads merged
      expect(strips(table.children[2]), 2); // file row keeps its grid
      // The table-wide border no longer draws vertical insides itself.
      expect(table.border?.verticalInside, BorderSide.none);
      expect(table.border?.horizontalInside, isNot(BorderSide.none));
      expect(tester.takeException(), isNull);
    });

    testWidgets('a span-free table keeps the plain bordered layout', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(const CcMarkdown(data: _netlifyTable, style: style)),
      );
      await tester.pumpAndSettle();

      final table = findTable(tester);
      expect(table.children.first.children, hasLength(2));
      expect(table.border?.verticalInside, isNot(BorderSide.none));
    });
  });
}
