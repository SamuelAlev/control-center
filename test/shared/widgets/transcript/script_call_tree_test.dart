import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_domain/features/code_mode/domain/services/script_run_view_lines.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/presentation/widgets/bubbles/transcript_segment_row.dart';
import 'package:control_center/shared/widgets/transcript/widgets/nested_tool_calls.dart';
import 'package:control_center/shared/widgets/transcript/widgets/script_tree/script_call_tree.dart';
import 'package:control_center/shared/widgets/transcript/widgets/script_tree/script_hidden_calls.dart';
import 'package:control_center/shared/widgets/transcript/widgets/script_tree/script_pending_row.dart';
import 'package:control_center/shared/widgets/transcript/widgets/script_tree/script_tree_rows.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_wrap.dart';
import 'script_tree_fixture.dart';

Widget _calls(
  List<ToolSegment> calls, {
  ToolSegment? script,
  bool ended = false,
}) => SingleChildScrollView(
  child: NestedToolCalls(
    script: script ?? replSegment(),
    calls: calls,
    ended: ended,
    codeFont: 'monospace',
    itemBuilder: (context, call) => TranscriptSegmentRow(
      segment: call,
      codeFont: 'monospace',
      nested: true,
      pending: !ended && call.status == ToolSegmentStatus.running,
    ),
  ),
);

Future<void> _pump(
  WidgetTester tester,
  List<ToolSegment> calls, {
  ToolSegment? script,
  bool ended = false,
  TextDirection? textDirection,
}) async {
  tester.view.physicalSize = const Size(900, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    testWrap(
      _calls(calls, script: script, ended: ended),
      textDirection: textDirection,
    ),
  );
  await tester.pump();
}

Finder _queued(String text) => find.descendant(
  of: find.byType(ScriptPendingRow),
  matching: find.text(text, findRichText: true),
);

Finder _pending(String word) => find.descendant(
  of: find.byType(ScriptPendingRow),
  matching: find.text(word),
);

void main() {
  group('states', () {
    testWidgets('just started: one call runs, the rest are queued', (
      tester,
    ) async {
      await _pump(tester, sampleCalls(searchDone: false));
      expect(find.byType(ScriptCallTree<ToolSegment>), findsOneWidget);
      expect(find.byType(TranscriptSegmentRow), findsOneWidget);
      // Five parallel reads, two loop calls, the edit and the write.
      expect(find.byType(ScriptPendingRow), findsNWidgets(9));
      expect(_pending('Queued'), findsNWidgets(9));
      // Only the running call spins.
      expect(find.byType(CcSpinner), findsOneWidget);
      expect(find.text('In parallel'), findsOneWidget);
      expect(find.text('Promise.all'), findsOneWidget);
      expect(find.text('Loop'), findsOneWidget);
      expect(find.text('for (const file of hits.files)'), findsOneWidget);
      expect(find.text('if hits.files.length > 0'), findsOneWidget);
      expect(find.text('else'), findsOneWidget);
      expect(
        find.textContaining('9 queued', findRichText: true),
        findsOneWidget,
      );
      // A queued row is worded like the row it becomes: a literal shows as
      // the made row shows it, an expression as its source.
      expect(_queued('Read  README.md'), findsOneWidget);
      expect(_queued('Read  file'), findsOneWidget);
      expect(_queued('Grep  FIXME'), findsOneWidget);
      expect(_queued('Write  TODO.md'), findsOneWidget);
      expect(find.textContaining('{', findRichText: true), findsNothing);
    });

    testWidgets('a queued row becomes the made row in place', (tester) async {
      await _pump(tester, sampleCalls(searchDone: false));
      final firstRead = find.byType(ScriptPendingRow).first;
      final top = tester.getTopLeft(firstRead).dy;
      await _pump(tester, sampleCalls(docsDone: 0));
      final made = find.textContaining('README.md', findRichText: true);
      expect(made, findsOneWidget);
      expect(tester.getTopLeft(made).dy, closeTo(top, 8));
      expect(find.byType(CcSpinner), findsNWidgets(5));
      expect(find.text('5 running'), findsOneWidget);
    });

    testWidgets('mid-run: a long loop folds its middle, the running call '
        'stays', (tester) async {
      await _pump(tester, sampleCalls(iterations: 7, loopDone: false));
      // 14 made: the first 2 and the last 3 show.
      expect(
        find.textContaining('Show 9 more calls', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.textContaining('feature_1.dart', findRichText: true),
        findsWidgets,
      );
      expect(
        find.textContaining('feature_7.dart', findRichText: true),
        findsWidgets,
      );
      expect(
        find.textContaining('feature_4.dart', findRichText: true),
        findsNothing,
      );
      expect(find.text('1 running · 13 ok'), findsOneWidget);
      // The branch has not been reached.
      expect(find.text('Queued'), findsNWidgets(4));

      await tester.tap(
        find.textContaining('Show 9 more calls', findRichText: true),
      );
      await tester.pump();
      expect(
        find.textContaining('Show 9 more calls', findRichText: true),
        findsNothing,
      );
      expect(
        find.textContaining('feature_4.dart', findRichText: true),
        findsWidgets,
      );
      // A rule starts each iteration after the first.
      expect(find.byType(ScriptIterationRule), findsNWidgets(6));
    });

    testWidgets('finished: the branch not taken reads as skipped', (
      tester,
    ) async {
      await _pump(
        tester,
        sampleCalls(),
        script: replSegment(status: ToolSegmentStatus.ok),
        ended: true,
      );
      expect(find.byType(ScriptPendingRow), findsOneWidget);
      expect(_pending('Skipped'), findsOneWidget);
      expect(find.text('Skipped'), findsNWidgets(2));
      expect(
        find.textContaining('Show 19 more calls', findRichText: true),
        findsOneWidget,
      );
      expect(find.byType(CcSpinner), findsNothing);
      expect(
        find.textContaining('1 skipped', findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets('finished: a failed and a denied call stay in sight', (
      tester,
    ) async {
      await _pump(
        tester,
        sampleCalls(failedIteration: 5, deniedEdit: true),
        script: replSegment(status: ToolSegmentStatus.ok),
        ended: true,
      );
      // The failed grep of iteration 6 breaks the hidden run in two and
      // brings the read that began its iteration: which file it was.
      expect(
        find.textContaining('Show 8 more calls', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.textContaining('Show 9 more calls', findRichText: true),
        findsOneWidget,
      );
      final started = find.textContaining('feature_6.dart', findRichText: true);
      expect(started, findsWidgets);
      expect(
        tester.getTopLeft(started.first).dy,
        lessThan(
          tester
              .getTopLeft(
                find.textContaining('Show 9 more calls', findRichText: true),
              )
              .dy,
        ),
      );
      expect(find.text('23 ok · 1 failed'), findsOneWidget);
      expect(find.text('1 denied'), findsOneWidget);
    });

    testWidgets('a script that ended before a call leaves it skipped', (
      tester,
    ) async {
      await _pump(
        tester,
        sampleCalls(iterations: 0, branch: false),
        script: replSegment(status: ToolSegmentStatus.error),
        ended: true,
      );
      expect(_pending('Queued'), findsNothing);
      expect(_pending('Skipped'), findsNWidgets(4));
    });
  });

  group('groups', () {
    testWidgets('a call in an arm inside a loop carries the arm', (
      tester,
    ) async {
      const src = branchInLoopScript;
      await _pump(tester, [
        nestedCall('read', 0, source: src),
        nestedCall('grep', 1, source: src),
        nestedCall('read', 2, source: src),
      ], script: replSegment(code: src));
      // The branch folds into the loop: each row names its arm.
      expect(find.byType(ScriptArmCaption), findsNWidgets(3));
      expect(find.text('if f.big'), findsNWidgets(2));
      expect(find.text('else'), findsOneWidget);
    });

    testWidgets('each and function groups name themselves', (tester) async {
      const src =
          'async function load(p) {\n'
          '  return tools.read({ path: p });\n'
          '}\n'
          'await Promise.all(files.map((f) => tools.grep({ path: f })));';
      await _pump(tester, const [], script: replSegment(code: src));
      expect(find.text('Function'), findsOneWidget);
      expect(find.text('load(p)'), findsOneWidget);
      expect(find.text('For each'), findsOneWidget);
    });

    testWidgets('calls not placed come last, under a caption', (tester) async {
      await _pump(tester, [
        nestedCall('search', 0),
        nestedCall('bash', 1, placed: false, inputs: const {'command': 'ls'}),
      ]);
      expect(find.text('Calls not placed in the script'), findsOneWidget);
      final caption = find.text('Calls not placed in the script');
      final bash = find.textContaining('ls', findRichText: true).last;
      expect(
        tester.getTopLeft(caption).dy,
        lessThan(tester.getTopLeft(bash).dy),
      );
    });
  });

  group('fallbacks', () {
    testWidgets('calls with no site are the flat list', (tester) async {
      await _pump(tester, [
        for (final call in sampleCalls(iterations: 1))
          ToolSegment(
            toolName: call.toolName,
            toolCallId: call.toolCallId,
            inputs: call.inputs,
            outputs: call.outputs,
            status: call.status,
            startedAt: call.startedAt,
            durationMs: call.durationMs,
            parentToolCallId: call.parentToolCallId,
          ),
      ]);
      expect(find.byType(ScriptCallTree<ToolSegment>), findsNothing);
      expect(find.byType(ScriptPendingRow), findsNothing);
      expect(find.byType(TranscriptSegmentRow), findsNWidgets(9));
    });

    testWidgets('a script the outline cannot follow is the flat list', (
      tester,
    ) async {
      const src = 'await tools.read({ path: "a" ';
      await _pump(tester, [
        nestedCall('read', 0, source: src),
      ], script: replSegment(code: src));
      expect(find.byType(ScriptCallTree<ToolSegment>), findsNothing);
      expect(find.byType(TranscriptSegmentRow), findsOneWidget);
    });

    testWidgets('a script with no tool calls shows nothing', (tester) async {
      await _pump(tester, const [], script: replSegment(code: 'return 1;'));
      expect(find.text('Tool calls'), findsNothing);
      expect(find.byType(ScriptCallTree<ToolSegment>), findsNothing);
    });
  });

  testWidgets('semantics give a row its state', (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(tester, sampleCalls(searchDone: false));
    expect(find.bySemanticsLabel('Write TODO.md, Queued'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('^In parallel Promise.all')), findsOne);
    handle.dispose();
  });

  testWidgets('right to left: the tree mirrors, the code stays LTR', (
    tester,
  ) async {
    await _pump(
      tester,
      sampleCalls(iterations: 7, loopDone: false),
      textDirection: TextDirection.rtl,
    );
    final header = find.text('for (const file of hits.files)');
    final code = tester.widget<Text>(header);
    expect(code.textDirection, TextDirection.ltr);
    // The kind word sits at the start, which is now the right.
    expect(
      tester.getCenter(find.text('Loop')).dx,
      greaterThan(tester.getCenter(header).dx),
    );
    // A queued row's glyph leads at the right, its words follow it.
    final pending = find.byType(ScriptPendingRow).first;
    expect(
      tester
          .getCenter(
            find.descendant(of: pending, matching: find.byType(Icon)).first,
          )
          .dx,
      greaterThan(
        tester
            .getCenter(
              find
                  .descendant(
                    of: pending,
                    matching: find.byWidgetPredicate(
                      (w) => w is Text && w.textSpan != null,
                    ),
                  )
                  .first,
            )
            .dx,
      ),
    );
  });

  testWidgets('a line deeper than the indent bound sits at the bound', (
    tester,
  ) async {
    const probe = Key('probe');
    Future<double> startOf(int depth) async {
      await tester.pumpWidget(
        testWrap(
          ScriptTreeIndent(
            depth: depth,
            child: const SizedBox(key: probe, width: 10, height: 10),
          ),
        ),
      );
      return tester.getTopLeft(find.byKey(probe)).dx;
    }

    final atBound = await startOf(scriptTreeMaxIndent);
    expect(atBound, greaterThan(await startOf(scriptTreeMaxIndent - 1)));
    expect(await startOf(scriptTreeMaxIndent + 1), atBound);
    expect(await startOf(200), atBound);
  });

  group('tool names a script or a record chose', () {
    // 64 characters once U+202E and U+200D are dropped.
    final tool = 'mcp__srv__${'x' * 30}\u202E${'y' * 30}\u200D${'z' * 4}';
    final source =
        'for (const f of fs) {\n'
        '  if (f.odd) {\n'
        '    await tools.$tool({ p: f });\n'
        '  } else {\n'
        '    await tools.read({ path: f });\n'
        '  }\n'
        '}';

    testWidgets('a long name first in the fold keeps the next in sight', (
      tester,
    ) async {
      await _pump(
        tester,
        [
          for (var i = 0; i < 20; i++)
            nestedCall(
              i == 10 ? tool : 'read',
              i,
              source: source,
              inputs: i == 10 ? const {'p': 'f'} : {'path': 'f$i.md'},
            ),
        ],
        script: replSegment(code: source),
        ended: true,
      );
      final line = find.textContaining(
        'Show 15 more calls',
        findRichText: true,
      );
      expect(line, findsOneWidget);
      final paragraph = tester.renderObject<RenderParagraph>(line);
      final text = paragraph.text.toPlainText();
      expect(text, endsWith(' 1 · Read 14'));
      expect(text, contains('…'));
      expect(text, isNot(contains('\u202E')));
      expect(text, isNot(contains('\u200D')));
      expect(paragraph.didExceedMaxLines, isFalse);
    });

    testWidgets('a queued row drops what a name hides', (tester) async {
      const hidden = 'await tools["ev\u202Eil\u200D"]({});';
      await _pump(tester, const [], script: replSegment(code: hidden));
      expect(find.textContaining('Evil', findRichText: true), findsOneWidget);
      expect(find.textContaining('\u202E', findRichText: true), findsNothing);
      expect(find.textContaining('\u200D', findRichText: true), findsNothing);
    });
  });

  testWidgets('a 5000-call loop opens a hundred calls per press', (
    tester,
  ) async {
    await _pump(tester, sampleCalls(iterations: 2500), ended: true);
    Finder rows() => find.descendant(
      of: find.byType(ScriptCallTree<ToolSegment>),
      matching: find.byType(TranscriptSegmentRow),
    );
    final folded = rows().evaluate().length;
    expect(
      find.textContaining('Show 4995 more calls', findRichText: true),
      findsOneWidget,
    );
    // What the fold hides, the rarest tool first.
    expect(
      find.textContaining(
        'Show 4995 more calls · Grep 2,497 · Read 2,498',
        findRichText: true,
      ),
      findsOneWidget,
    );

    final watch = Stopwatch()..start();
    await tester.tap(
      find.textContaining('Show 4995 more calls', findRichText: true),
    );
    await tester.pump();
    watch.stop();
    // ignore: avoid_print
    print(
      'w2-ui3: 5000-call loop, frame after one press in '
      '${watch.elapsedMilliseconds} ms',
    );
    expect(rows().evaluate().length, folded + 100);
    // The control stays under them with what is still hidden.
    expect(
      find.textContaining('Show 4895 more calls', findRichText: true),
      findsOneWidget,
    );

    // Below the fold of the test view now: press it directly.
    tester
        .widget<ScriptHiddenCallsButton>(find.byType(ScriptHiddenCallsButton))
        .onPressed();
    await tester.pump();
    expect(rows().evaluate().length, folded + 200);
    expect(
      find.textContaining('Show 4795 more calls', findRichText: true),
      findsOneWidget,
    );
  });

  group('opened groups', () {
    Widget row(List<ToolSegment> calls, {DateTime? startedAt}) {
      final script = replSegment(status: ToolSegmentStatus.ok);
      return SingleChildScrollView(
        child: TranscriptSegmentRow(
          segment: startedAt == null
              ? script
              : ToolSegment(
                  toolName: script.toolName,
                  toolCallId: script.toolCallId,
                  inputs: script.inputs,
                  outputs: script.outputs,
                  status: script.status,
                  startedAt: startedAt,
                  durationMs: script.durationMs,
                ),
          codeFont: 'monospace',
          nestedCalls: calls,
        ),
      );
    }

    Future<void> toggle(WidgetTester tester) async {
      await tester.tap(
        find.textContaining('Tidy the TODO list', findRichText: true),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('stay open when the row is closed and reopened, and when '
        'the calls rebuild', (tester) async {
      tester.view.physicalSize = const Size(900, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(testWrap(row(sampleCalls())));
      if (find.byType(NestedToolCalls).evaluate().isEmpty) {
        await toggle(tester);
      }
      await tester.tap(
        find.textContaining('Show 19 more calls', findRichText: true),
      );
      await tester.pump();
      expect(
        find.textContaining('Show 19 more calls', findRichText: true),
        findsNothing,
      );

      await toggle(tester);
      expect(find.byType(NestedToolCalls), findsNothing);
      await toggle(tester);
      expect(find.byType(NestedToolCalls), findsOneWidget);
      expect(
        find.textContaining('Show 19 more calls', findRichText: true),
        findsNothing,
      );

      // A new list of the same calls, as a stream update delivers.
      await tester.pumpWidget(testWrap(row(sampleCalls())));
      await tester.pump();
      expect(
        find.textContaining('Show 19 more calls', findRichText: true),
        findsNothing,
      );

      // Another script, even under the same call id, starts folded.
      await tester.pumpWidget(
        testWrap(row(sampleCalls(), startedAt: DateTime.utc(2030))),
      );
      await tester.pump();
      if (find.byType(NestedToolCalls).evaluate().isEmpty) {
        await toggle(tester);
      }
      expect(
        find.textContaining('Show 19 more calls', findRichText: true),
        findsOneWidget,
      );
    });
  });
}
