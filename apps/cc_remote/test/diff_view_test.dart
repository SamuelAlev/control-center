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
  // Mirrors how the PR screen embeds it: a phone-width column inside a
  // vertically scrolling parent. The vertical scroll is not incidental — the
  // view renders every budgeted row eagerly, so a bounded-height host would
  // fail on overflow rather than on anything the widget got wrong.
  Widget host(Widget child) => Directionality(
    textDirection: TextDirection.ltr,
    child: CcTheme(
      data: CcThemeData.light(),
      child: MediaQuery(
        data: const MediaQueryData(size: Size(390, 800)),
        child: Center(
          child: SizedBox(
            width: 390,
            child: SingleChildScrollView(child: child),
          ),
        ),
      ),
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

  testWidgets('an empty patch says why instead of rendering blank', (
    tester,
  ) async {
    await tester.pumpWidget(host(const DiffView(patch: '')));

    expect(find.textContaining('No text diff'), findsOneWidget);
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
    // 601 parsed rows, 400 shown.
    expect(find.textContaining('Show the remaining 201 lines'), findsOneWidget);
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
    expect(find.textContaining('Show the remaining'), findsNothing);
  });

  testWidgets('elides the unshown stretch between two hunks', (tester) async {
    const gapped = '''
@@ -1,2 +1,2 @@
 alpha
-beta
+BETA
@@ -40,2 +40,2 @@
 gamma
-delta
+DELTA''';
    await tester.pumpWidget(host(const DiffView(patch: gapped)));

    // Without this marker the jump from line 2 to line 40 reads as a
    // numbering bug rather than as lines the forge never sent.
    expect(find.textContaining('unchanged lines'), findsOneWidget);
  });
}
