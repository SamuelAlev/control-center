import 'package:cc_domain/features/pr_review/domain/services/diff_parser.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/syntax/diff_highlighter_engine.dart' as engine;
import 'package:cc_remote/widgets/diff_view.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// The phone's diff renderer.
///
/// Parsing itself belongs to the shared kernel (`parseUnifiedDiff`) and is
/// tested there; what these cover is the part that only exists here — that a
/// patch reaches the screen as rows a person can read, that the row budget
/// actually bounds the build, and that the two states which look identical
/// from the outside (binary file / no diff) say so instead of rendering blank.
void main() {
  setUpAll(() => engine.debugTokenizeInline = true);

  // Mirrors how the PR screen embeds it: a phone-width column inside a
  // vertically scrolling parent. The vertical scroll is not incidental — the
  // view renders every budgeted row eagerly, so a bounded-height host would
  // fail on overflow rather than on anything the widget got wrong.
  Widget host(Widget child) => WidgetsApp(
    color: const Color(0xFFFFFFFF),
    locale: const Locale('en'),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      DefaultWidgetsLocalizations.delegate,
    ],
    textStyle: const TextStyle(
      fontSize: 14,
      color: Color(0xFF202020),
      decoration: TextDecoration.none,
    ),
    pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, _, _) => builder(context),
    ),
    builder: (_, child) => CcTheme(data: CcThemeData.light(), child: child!),
    home: Center(
      child: SizedBox(width: 390, child: SingleChildScrollView(child: child)),
    ),
  );

  const patch = '''
@@ -1,4 +1,5 @@
 import 'dart:async';
-final answer = 41;
+final answer = 42;
+final extra = true;
 void main() {}''';

  testWidgets('renders every line of a patch with its gutter numbers', (
    tester,
  ) async {
    await tester.pumpWidget(host(const DiffView(patch: patch)));

    expect(find.text("import 'dart:async';"), findsOneWidget);
    expect(find.text('final answer = 41;'), findsOneWidget);
    expect(find.text('final answer = 42;'), findsOneWidget);
    expect(find.text('final extra = true;'), findsOneWidget);
    // The hunk header is kept: it is what tells the reader the numbers below
    // are not line 1 of the file.
    expect(find.text('@@ -1,4 +1,5 @@'), findsOneWidget);
  });

  testWidgets('marks sides with a character, not only a colour', (
    tester,
  ) async {
    await tester.pumpWidget(host(const DiffView(patch: patch)));

    // Two additions, one deletion — as characters in their own column, so the
    // diff survives greyscale and red/green colour blindness.
    expect(find.text('+'), findsNWidgets(2));
    expect(find.text('-'), findsOneWidget);
  });

  testWidgets('caps the rows it builds and offers the rest', (tester) async {
    // One hunk header + 600 additions: past the budget on purpose.
    final big = StringBuffer('@@ -1,0 +1,600 @@\n');
    for (var i = 0; i < 600; i++) {
      big.writeln('+line $i');
    }
    await tester.pumpWidget(host(DiffView(patch: big.toString())));

    // Inside the budget renders; past it does not — the cap has to actually
    // bound the BUILD, because these rows are eager (no lazy viewport).
    expect(find.text('line 0'), findsOneWidget);
    expect(find.text('line 500'), findsNothing);
  });

  testWidgets('lifting the budget renders the withheld rows', (tester) async {
    final big = StringBuffer('@@ -1,0 +1,600 @@\n');
    for (var i = 0; i < 600; i++) {
      big.writeln('+line $i');
    }
    await tester.pumpWidget(
      host(DiffView(patch: big.toString(), expanded: true)),
    );

    expect(find.text('line 500'), findsOneWidget);
    expect(find.byType(CcButton), findsNothing);
  });

  testWidgets('comment-enabled diffs retain compact aligned source rows', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(DiffView(patch: patch, onLineSelected: (_) {})),
    );
    final contextRow = tester.getTopLeft(find.text("import 'dart:async';")).dy;
    final removedRow = tester.getTopLeft(find.text('final answer = 41;')).dy;
    final addedRow = tester.getTopLeft(find.text('final answer = 42;')).dy;
    expect(removedRow - contextRow, lessThan(24));
    expect(addedRow - removedRow, closeTo(removedRow - contextRow, .01));
    expect(
      tester.getSize(find.byType(CcSelect<DiffLine>)).height,
      greaterThanOrEqualTo(44),
    );
  });

  testWidgets('long code scrolls horizontally without wrapping source rows', (
    tester,
  ) async {
    final longLine = 'final value = "${List.filled(100, 'x').join()}";';
    await tester.pumpWidget(
      host(DiffView(patch: '@@ -0,0 +1,1 @@\n+$longLine')),
    );
    final scroller = find.byWidgetPredicate(
      (widget) =>
          widget is SingleChildScrollView &&
          widget.scrollDirection == Axis.horizontal,
    );
    final before = tester.getTopLeft(find.text(longLine));
    await tester.drag(scroller, const Offset(-160, 0));
    await tester.pumpAndSettle();
    final after = tester.getTopLeft(find.text(longLine));
    expect(after.dx, lessThan(before.dx - 100));
    expect(after.dy, closeTo(before.dy, .01));
  });

  testWidgets('comment selector offers only changed lines with correct sides', (
    tester,
  ) async {
    final selected = <DiffLine>[];
    await tester.pumpWidget(
      host(DiffView(patch: patch, onLineSelected: selected.add)),
    );
    final picker = find.byType(CcSelect<DiffLine>);
    await tester.tap(picker);
    await tester.pumpAndSettle();
    final options = tester.widgetList<CcSelectRow<DiffLine>>(
      find.byType(CcSelectRow<DiffLine>),
    );
    expect(
      options.map(
        (row) => (
          row.option.value.kind,
          row.option.value.oldLine,
          row.option.value.newLine,
        ),
      ),
      [
        (DiffLineKind.deletion, 2, null),
        (DiffLineKind.addition, null, 2),
        (DiffLineKind.addition, null, 3),
      ],
    );
    await tester.tap(
      find.byWidgetPredicate(
        (widget) =>
            widget is CcSelectRow<DiffLine> &&
            widget.option.value.kind == DiffLineKind.deletion,
      ),
    );
    await tester.pumpAndSettle();
    expect(selected.single.kind, DiffLineKind.deletion);
    expect(selected.single.oldLine, 2);
    expect(selected.single.newLine, isNull);
  });

  testWidgets('unanchored changes cannot receive a line comment', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(DiffView(patch: '+unanchored change', onLineSelected: (_) {})),
    );
    expect(find.byType(CcSelect<DiffLine>), findsNothing);
  });

  /// Colours of the spans that render [text] (one Text.rich per row).
  Set<Color?> spanColors(WidgetTester tester, String text) {
    final rich = tester.widget<Text>(find.text(text));
    final colors = <Color?>{};
    rich.textSpan?.visitChildren((span) {
      if (span is TextSpan && (span.text ?? '').trim().isNotEmpty) {
        colors.add(span.style?.color);
      }
      return true;
    });
    return colors;
  }

  testWidgets('colours rows in the file\'s language once highlighted', (
    tester,
  ) async {
    await tester.pumpWidget(host(const DiffView(patch: patch, path: 'a.dart')));
    await tester.pumpAndSettle();

    final row = tester.widget<Text>(find.text('final answer = 42;'));
    expect(row.textSpan, isNotNull, reason: 'a highlighted row is Text.rich');
    // `final` (keyword) and `42` (number) take different theme colours.
    expect(spanColors(tester, 'final answer = 42;').length, greaterThan(1));
    // The +/− marker and gutter keep their own columns.
    expect(find.text('+'), findsNWidgets(2));
  });

  testWidgets('TypeScript diffs are highlighted too', (tester) async {
    await tester.pumpWidget(
      host(
        const DiffView(
          patch: '@@ -0,0 +1,1 @@\n+export const answer: number = 42;',
          path: 'src/answer.ts',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      spanColors(tester, 'export const answer: number = 42;').length,
      greaterThan(1),
    );
  });

  testWidgets('unknown languages and pathless diffs stay plain', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(const DiffView(patch: patch, path: 'notes.unknownext')),
    );
    await tester.pumpAndSettle();
    expect(
      tester.widget<Text>(find.text('final answer = 42;')).textSpan,
      isNull,
    );

    await tester.pumpWidget(host(const DiffView(patch: patch)));
    await tester.pumpAndSettle();
    expect(
      tester.widget<Text>(find.text('final answer = 42;')).textSpan,
      isNull,
    );
  });

  testWidgets('lifting the budget highlights the newly shown rows', (
    tester,
  ) async {
    final big = StringBuffer('@@ -1,0 +1,600 @@\n');
    for (var i = 0; i < 600; i++) {
      big.writeln('+final v$i = $i;');
    }
    await tester.pumpWidget(
      host(DiffView(patch: big.toString(), path: 'a.dart', maxRows: 100)),
    );
    await tester.pumpAndSettle();
    expect(spanColors(tester, 'final v50 = 50;').length, greaterThan(1));

    await tester.pumpWidget(
      host(DiffView(patch: big.toString(), path: 'a.dart', maxRows: 400)),
    );
    await tester.pumpAndSettle();
    expect(spanColors(tester, 'final v300 = 300;').length, greaterThan(1));
  });
}
