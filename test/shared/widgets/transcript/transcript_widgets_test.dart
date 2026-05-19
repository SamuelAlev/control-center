import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:control_center/shared/widgets/transcript/util/split_diff.dart';
import 'package:control_center/shared/widgets/transcript/widgets/code_preview.dart';
import 'package:control_center/shared/widgets/transcript/widgets/file_change_body.dart';
import 'package:control_center/shared/widgets/transcript/widgets/grep_result_body.dart';
import 'package:control_center/shared/widgets/transcript/widgets/inline_diff_view.dart';
import 'package:control_center/shared/widgets/transcript/widgets/shimmer_text.dart';
import 'package:control_center/shared/widgets/transcript/widgets/split_diff_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_wrap.dart';

Widget _host(Widget child, {bool reduceMotion = false}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: reduceMotion),
    child: Scaffold(body: SingleChildScrollView(child: child)),
  ),
);

void main() {
  final tokens = DesignSystemTokens.light();

  group('InlineDiffView', () {
    testWidgets('renders added and removed lines', (tester) async {
      await tester.pumpWidget(
        _host(
          InlineDiffView(
            oldText: 'line one\nold line',
            newText: 'line one\nnew line',
            codeFont: 'monospace',
            tokens: tokens,
          ),
        ),
      );
      expect(find.textContaining('old line'), findsOneWidget);
      expect(find.textContaining('new line'), findsOneWidget);
      // +/- gutter markers.
      expect(find.text('+'), findsWidgets);
      expect(find.text('-'), findsWidgets);
    });
  });

  group('SplitDiffView', () {
    testWidgets('renders both sides of a replaced line', (tester) async {
      await tester.pumpWidget(
        _host(
          SplitDiffView(
            oldText: 'keep me\nfinal removed = 1;',
            newText: 'keep me\nfinal added = 2;',
            codeFont: 'monospace',
            tokens: tokens,
          ),
        ),
      );
      expect(find.textContaining('final removed = 1;'), findsWidgets);
      expect(find.textContaining('final added = 2;'), findsWidgets);
      // Change is never signalled by colour alone: each side keeps its marker.
      expect(find.text('-'), findsWidgets);
      expect(find.text('+'), findsWidgets);
    });

    testWidgets('a pure insertion has no deletion marker', (tester) async {
      await tester.pumpWidget(
        _host(
          SplitDiffView(
            oldText: 'kept line\n',
            newText: 'kept line\nbrand new line\n',
            codeFont: 'monospace',
            tokens: tokens,
          ),
        ),
      );
      expect(find.textContaining('brand new line'), findsWidgets);
      expect(find.text('+'), findsWidgets);
      expect(find.text('-'), findsNothing);
    });

    testWidgets('a long diff truncates behind a "show all" expander', (
      tester,
    ) async {
      final old = List.generate(30, (i) => 'line $i').join('\n');
      final updated = List.generate(30, (i) => 'changed $i').join('\n');
      await tester.pumpWidget(
        testWrap(
          SplitDiffView(
            oldText: old,
            newText: updated,
            codeFont: 'monospace',
            tokens: tokens,
            maxRows: 5,
            maxHeight: double.infinity,
          ),
        ),
      );
      expect(find.textContaining('changed 4'), findsWidgets);
      expect(find.textContaining('changed 20'), findsNothing);
      await tester.tap(find.textContaining('Show all'));
      await tester.pumpAndSettle();
      expect(find.textContaining('changed 20'), findsWidgets);
    });

    testWidgets('identical texts render as context rows only', (tester) async {
      await tester.pumpWidget(
        _host(
          SplitDiffView(
            oldText: 'same\n',
            newText: 'same\n',
            codeFont: 'monospace',
            tokens: tokens,
          ),
        ),
      );
      expect(find.text('+'), findsNothing);
      expect(find.text('-'), findsNothing);
    });
  });

  group('GrepResultBody', () {
    testWidgets('groups hits by file with a stats line', (tester) async {
      await tester.pumpWidget(
        testWrap(
          GrepResultBody(
            outputs:
                'lib/a.dart:12: final retryCount = 1;\n'
                'lib/a.dart:30: return retryCount;\n'
                'lib/b.dart:3: // no retry here',
            codeFont: 'monospace',
            tokens: tokens,
            pattern: 'retry',
          ),
        ),
      );
      expect(find.text('3 matches · 2 files'), findsOneWidget);
      expect(find.text('lib/a.dart'), findsOneWidget);
      expect(find.text('lib/b.dart'), findsOneWidget);
      expect(find.text('12'), findsWidgets);
      expect(find.textContaining('retryCount'), findsWidgets);
    });

    testWidgets('renders the trailing truncation note', (tester) async {
      await tester.pumpWidget(
        testWrap(
          GrepResultBody(
            outputs: 'a.dart:1: x\n\n(250 total matches; showing first 200)',
            codeFont: 'monospace',
            tokens: tokens,
          ),
        ),
      );
      expect(
        find.text('(250 total matches; showing first 200)'),
        findsOneWidget,
      );
    });

    testWidgets('empty output renders the no-matches state', (tester) async {
      await tester.pumpWidget(
        testWrap(
          GrepResultBody(
            outputs: 'No matches for /foo/.',
            codeFont: 'monospace',
            tokens: tokens,
          ),
        ),
      );
      expect(find.text('No matches'), findsOneWidget);
    });
  });

  group('applyIntralineBackground', () {
    test('splits a span at the range boundaries and tints only the middle', () {
      const spans = <InlineSpan>[TextSpan(text: 'child: MaterialApp(')];
      final out = applyIntralineBackground(spans, const <IntralineRange>[
        (7, 18),
      ], const Color(0xFFABF2BC));
      expect(out, hasLength(3));
      expect((out[0] as TextSpan).text, 'child: ');
      expect((out[1] as TextSpan).text, 'MaterialApp');
      expect(
        (out[1] as TextSpan).style?.backgroundColor,
        const Color(0xFFABF2BC),
      );
      expect((out[2] as TextSpan).text, '(');
      expect((out[2] as TextSpan).style?.backgroundColor, isNull);
    });

    test('keeps each span\'s syntax colour under the tint', () {
      const spans = <InlineSpan>[
        TextSpan(
          text: 'const',
          style: TextStyle(color: Color(0xFF0000FF)),
        ),
        TextSpan(text: ' x'),
      ];
      final out = applyIntralineBackground(spans, const <IntralineRange>[
        (0, 5),
      ], const Color(0xFFABF2BC));
      expect((out.first as TextSpan).style?.color, const Color(0xFF0000FF));
      expect(
        (out.first as TextSpan).style?.backgroundColor,
        const Color(0xFFABF2BC),
      );
    });

    test('a range spanning two spans tints both', () {
      const spans = <InlineSpan>[TextSpan(text: 'ab'), TextSpan(text: 'cd')];
      final out = applyIntralineBackground(spans, const <IntralineRange>[
        (1, 3),
      ], const Color(0xFFABF2BC));
      final tinted = out
          .whereType<TextSpan>()
          .where((s) => s.style?.backgroundColor != null)
          .map((s) => s.text)
          .toList();
      expect(tinted, ['b', 'c']);
    });

    test('does not mutate the input spans', () {
      const spans = <InlineSpan>[TextSpan(text: 'abcd')];
      applyIntralineBackground(spans, const <IntralineRange>[
        (1, 3),
      ], const Color(0xFFABF2BC));
      expect(spans, hasLength(1));
      expect((spans.single as TextSpan).text, 'abcd');
    });
  });

  group('FileEditDiffBody', () {
    testWidgets('goes side-by-side when it has room', (tester) async {
      await tester.pumpWidget(
        testWrap(
          SizedBox(
            width: 700,
            child: FileEditDiffBody(
              oldText: 'final removed = 1;',
              newText: 'final added = 2;',
              codeFont: 'monospace',
              tokens: tokens,
              filePath: 'lib/x.dart',
            ),
          ),
        ),
      );
      expect(find.byType(SplitDiffView), findsOneWidget);
      expect(find.byType(InlineDiffView), findsNothing);
      // The Claude-Code-style status eyebrow over the diff.
      expect(find.text('Modified'), findsOneWidget);
    });

    testWidgets('falls back to the unified diff when narrow', (tester) async {
      await tester.pumpWidget(
        testWrap(
          SizedBox(
            width: 380,
            child: FileEditDiffBody(
              oldText: 'final removed = 1;',
              newText: 'final added = 2;',
              codeFont: 'monospace',
              tokens: tokens,
            ),
          ),
        ),
      );
      expect(find.byType(InlineDiffView), findsOneWidget);
      expect(find.byType(SplitDiffView), findsNothing);
    });
  });

  group('FileWriteBody', () {
    testWidgets('labels a created file', (tester) async {
      await tester.pumpWidget(
        testWrap(
          FileWriteBody(
            contents: 'final x = 1;',
            codeFont: 'monospace',
            tokens: tokens,
            outputs: 'File created successfully at: /tmp/x.dart',
          ),
        ),
      );
      expect(find.text('Created'), findsOneWidget);
      expect(find.textContaining('final x = 1;'), findsWidgets);
    });

    testWidgets('labels an overwritten file', (tester) async {
      await tester.pumpWidget(
        testWrap(
          FileWriteBody(
            contents: 'final x = 1;',
            codeFont: 'monospace',
            tokens: tokens,
            outputs: 'The file /tmp/x.dart has been updated.',
          ),
        ),
      );
      expect(find.text('Modified'), findsOneWidget);
    });

    testWidgets('claims nothing when the result does not say', (tester) async {
      await tester.pumpWidget(
        testWrap(
          FileWriteBody(
            contents: 'final x = 1;',
            codeFont: 'monospace',
            tokens: tokens,
          ),
        ),
      );
      expect(find.text('Created'), findsNothing);
      expect(find.text('Modified'), findsNothing);
      expect(find.textContaining('final x = 1;'), findsWidgets);
    });
  });

  group('CodePreview', () {
    testWidgets('renders code with a line-number gutter', (tester) async {
      await tester.pumpWidget(
        _host(
          CodePreview(
            code: 'final x = 1;\nfinal y = 2;',
            codeFont: 'monospace',
            tokens: tokens,
            startLine: 10,
          ),
        ),
      );
      expect(find.textContaining('final x = 1;'), findsOneWidget);
      // Gutter shows the original starting line number.
      expect(find.text('10'), findsOneWidget);
      expect(find.text('11'), findsOneWidget);
    });
  });

  group('ShimmerText', () {
    testWidgets('reduced motion renders static text and settles', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(const ShimmerText('Thinking…'), reduceMotion: true),
      );
      expect(find.text('Thinking…'), findsOneWidget);
      // No perpetual animation: the tree settles.
      await tester.pumpAndSettle();
      expect(find.text('Thinking…'), findsOneWidget);
    });

    testWidgets('animated variant still shows the label', (tester) async {
      await tester.pumpWidget(_host(const ShimmerText('Working…')));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Working…'), findsOneWidget);
    });
  });
}
