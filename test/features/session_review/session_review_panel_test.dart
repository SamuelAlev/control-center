import 'package:cc_domain/features/pr_review/domain/entities/pr_file.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/session_review/presentation/widgets/session_file_diff_view.dart';
import 'package:control_center/features/session_review/presentation/widgets/session_review_panel.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) => CcTheme(
  data: CcThemeData.light(),
  child: Directionality(
    textDirection: TextDirection.ltr,
    child: MediaQuery(
      data: const MediaQueryData(),
      child: DefaultTextStyle(
        style: const TextStyle(fontSize: 14, color: Color(0xFF000000)),
        child: Overlay(
          initialEntries: [
            OverlayEntry(
              builder: (_) => SizedBox(width: 900, height: 700, child: child),
            ),
          ],
        ),
      ),
    ),
  ),
);

const _smallPatch = '''
@@ -1,3 +1,4 @@
 context line
-removed line
+added line one
+added line two
 trailing context
''';

PrFile _file(
  String name, {
  PrFileStatus status = PrFileStatus.modified,
  int add = 2,
  int del = 1,
  String? patch,
}) => PrFile(
  filename: name,
  status: status,
  additions: add,
  deletions: del,
  patch: patch ?? _smallPatch,
);

String _hugePatch(int lines) {
  final b = StringBuffer('@@ -1,1 +1,$lines @@\n context\n');
  for (var i = 0; i < lines; i++) {
    b.writeln('+added line $i');
  }
  return b.toString();
}

void main() {
  testWidgets('renders an accordion of changed files with a count badge', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        SessionReviewPanel(
          files: [
            _file('lib/a.dart', status: PrFileStatus.modified),
            _file('lib/widgets/b.dart', status: PrFileStatus.added, del: 0),
            _file('README.md', status: PrFileStatus.removed, add: 0),
          ],
        ),
      ),
    );

    expect(find.text('Session changes'), findsOneWidget);
    expect(find.text('3'), findsOneWidget); // file-count badge
    expect(find.text('Added'), findsOneWidget);
    expect(find.text('Removed'), findsOneWidget);
    // Directory/filename split: the directory prefix renders (in a RichText).
    expect(
      find.textContaining('lib/widgets/', findRichText: true),
      findsOneWidget,
    );
  });

  testWidgets('expand-all reveals diffs, collapse-all hides them', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        SessionReviewPanel(files: [_file('lib/a.dart'), _file('lib/b.dart')]),
      ),
    );

    expect(find.byType(SessionFileDiffView), findsNothing);

    await tester.tap(find.text('Expand all'));
    await tester.pumpAndSettle();
    expect(find.byType(SessionFileDiffView), findsNWidgets(2));

    await tester.tap(find.text('Collapse all'));
    await tester.pumpAndSettle();
    expect(find.byType(SessionFileDiffView), findsNothing);
  });

  testWidgets('unified/split toggle switches diff style', (tester) async {
    await tester.pumpWidget(
      _host(
        SessionReviewPanel(
          files: [_file('lib/a.dart')],
          initiallyExpandedAll: true,
        ),
      ),
    );

    final unified = tester.widget<SessionFileDiffView>(
      find.byType(SessionFileDiffView),
    );
    expect(unified.style, SessionDiffStyle.unified);

    await tester.tap(find.text('Split'));
    await tester.pumpAndSettle();

    final split = tester.widget<SessionFileDiffView>(
      find.byType(SessionFileDiffView),
    );
    expect(split.style, SessionDiffStyle.split);
  });

  testWidgets('shows an empty state when there are no changes', (tester) async {
    await tester.pumpWidget(_host(const SessionReviewPanel(files: [])));
    expect(find.text('No file changes in this session'), findsOneWidget);
  });

  testWidgets('shows a loading state while computing', (tester) async {
    await tester.pumpWidget(
      _host(const SessionReviewPanel(files: [], loading: true)),
    );
    expect(find.text('Computing changes…'), findsOneWidget);
    expect(find.byType(CcSpinner), findsOneWidget);
  });

  group('SessionFileDiffView render paths', () {
    testWidgets('small diff uses the eager (non-virtualized) path', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(const SessionFileDiffView(patch: _smallPatch)),
      );
      // Eager path: a SingleChildScrollView, no internal ListView.
      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(find.byType(ListView), findsNothing);
      expect(find.textContaining('added line one'), findsOneWidget);
    });

    testWidgets('diff above the extreme threshold is virtualized', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          SessionFileDiffView(
            patch: _hugePatch(kExtremeDiffChangedLines + 100),
          ),
        ),
      );
      // Virtualized path: a fixed-extent ListView, no eager scroll view.
      expect(find.byType(ListView), findsOneWidget);
      expect(find.byType(SingleChildScrollView), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
