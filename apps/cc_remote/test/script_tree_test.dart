@TestOn('browser')
library;

import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_domain/features/code_mode/domain/services/script_run_view_lines.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/script_call_site.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/l10n/phone_widgets_localizations.dart';
import 'package:cc_remote/l10n/remote_locales.dart';
import 'package:cc_remote/widgets/agent_transcript.dart';
import 'package:cc_remote/widgets/script_hidden_calls.dart';
import 'package:cc_remote/widgets/script_tree.dart';
import 'package:cc_remote/widgets/script_tree_rows.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _script = '''
const hits = await tools.search({ pattern: "TODO" });
await Promise.all([
  tools.read({ path: "README.md" }),
  tools.read({ path: "ARCH.md" }),
]);
for (const file of hits.files) {
  if (file.big) {
    await tools.read({ path: file });
  } else {
    await tools.grep({ pattern: "FIXME", path: file });
  }
}
if (hits.files.length > 0) {
  await tools.edit({ path: "TODO.md" });
} else {
  await tools.write({ path: "TODO.md" });
}''';

final _ts = DateTime.utc(2026);

ScriptCallSite? _site(String tool, int nth) {
  final lines = _script.split('\n');
  var seen = 0;
  for (var i = 0; i < lines.length; i++) {
    final at = lines[i].indexOf('tools.$tool(');
    if (at >= 0 && seen++ == nth) {
      return ScriptCallSite(i + 1, at + 7);
    }
  }
  return null;
}

ToolSegment _repl({ToolSegmentStatus status = ToolSegmentStatus.running}) =>
    ToolSegment(
      toolName: 'repl',
      toolCallId: 'r1',
      inputs: const {'code': _script, 'description': 'Tidy the TODO list'},
      status: status,
      startedAt: _ts,
    );

ToolSegment _call(
  String tool,
  int index, {
  int nth = 0,
  String? description,
  ToolSegmentStatus status = ToolSegmentStatus.ok,
  String? outcome,
  bool placed = true,
}) => ToolSegment(
  toolName: tool,
  toolCallId: 'r1/$index',
  inputs: {'description': description ?? '$tool $index'},
  outputs: 'ok',
  status: status,
  startedAt: _ts,
  parentToolCallId: 'r1',
  outcome: outcome,
  callSite: placed ? _site(tool, nth) : null,
);

/// The search, both parallel reads and [iterations] loop calls that
/// alternate between the arms; [failAt] fails one of them.
List<ToolSegment> _calls({int iterations = 0, int? failAt, bool edit = false}) {
  var i = 0;
  return [
    _call('search', i++),
    _call('read', i++),
    _call('read', i++, nth: 1),
    for (var k = 0; k < iterations; k++)
      k.isEven
          ? _call(
              'read',
              i++,
              nth: 2,
              description: 'loop $k',
              status: k == failAt
                  ? ToolSegmentStatus.error
                  : ToolSegmentStatus.ok,
            )
          : _call(
              'grep',
              i++,
              description: 'loop $k',
              status: k == failAt
                  ? ToolSegmentStatus.error
                  : ToolSegmentStatus.ok,
            ),
    if (edit) _call('edit', i++),
  ];
}

Future<void> _pump(
  WidgetTester tester,
  List<TranscriptSegment> segments, {
  bool isLive = true,
  Locale locale = const Locale('en'),
}) async {
  tester.view.physicalSize = const Size(420, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      child: WidgetsApp(
        color: const Color(0xFFFFFFFF),
        locale: locale,
        supportedLocales: kSupportedRemoteLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          PhoneWidgetsLocalizationsDelegate(),
        ],
        pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
          settings: settings,
          pageBuilder: (context, _, _) => builder(context),
        ),
        home: CcTheme(
          data: CcThemeData.light(),
          child: SingleChildScrollView(
            child: AgentTranscript(segments: segments, isLive: isLive),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.tap(find.text('Tidy the TODO list'));
  await tester.pump();
}

Finder _pending(String word) => find.descendant(
  of: find.byType(PhoneScriptPendingRow),
  matching: find.text(word),
);

void main() {
  testWidgets('before the first call every call is queued', (tester) async {
    await _pump(tester, [_repl()]);
    expect(find.byType(PhoneScriptTree), findsOneWidget);
    expect(_pending('Queued'), findsNWidgets(7));
    expect(find.text('In parallel'), findsOneWidget);
    expect(find.text('Loop'), findsOneWidget);
    expect(find.text('for (const file of hits.files)'), findsOneWidget);
    expect(find.text('if hits.files.length > 0'), findsOneWidget);
  });

  testWidgets('made calls replace their queued rows; arms caption loop rows', (
    tester,
  ) async {
    await _pump(tester, [_repl(), ..._calls(iterations: 2)]);
    expect(find.text('search 0'), findsOneWidget);
    expect(find.text('2 ok'), findsWidgets);
    // In the loop, each row names the arm it was made in.
    expect(find.text('if file.big'), findsOneWidget);
    expect(find.text('else'), findsNWidgets(2));
    // The branch after the loop has not been reached.
    expect(find.text('Queued'), findsNWidgets(4));
  });

  testWidgets('finished: the arm not taken is skipped', (tester) async {
    await _pump(tester, [
      _repl(status: ToolSegmentStatus.ok),
      ..._calls(iterations: 2, edit: true),
    ], isLive: false);
    expect(_pending('Skipped'), findsOneWidget);
    expect(find.text('Skipped'), findsNWidgets(2));
    expect(_pending('Queued'), findsNothing);
  });

  testWidgets('a long loop folds its middle; a failure stays in sight', (
    tester,
  ) async {
    await _pump(tester, [
      _repl(status: ToolSegmentStatus.ok),
      ..._calls(iterations: 12, failAt: 6, edit: true),
    ], isLive: false);
    expect(find.text('loop 0'), findsOneWidget);
    expect(find.text('loop 1'), findsOneWidget);
    expect(find.text('loop 6'), findsOneWidget);
    expect(find.text('loop 11'), findsOneWidget);
    expect(find.text('loop 3'), findsNothing);
    expect(find.text('Show 4 more calls'), findsOneWidget);
    expect(find.text('Show 2 more calls'), findsOneWidget);
    final hidden = find.byType(PhoneScriptHiddenCalls).first;
    expect(tester.getSize(hidden).height, greaterThanOrEqualTo(44));

    await tester.tap(find.text('Show 4 more calls'));
    await tester.pump();
    expect(find.text('loop 3'), findsOneWidget);
    expect(find.byType(PhoneScriptHiddenCalls), findsNothing);

    // Opened stays opened when the script row is closed and reopened.
    await tester.tap(find.text('Tidy the TODO list'));
    await tester.pump();
    expect(find.byType(PhoneScriptTree), findsNothing);
    await tester.tap(find.text('Tidy the TODO list'));
    await tester.pump();
    expect(find.text('loop 3'), findsOneWidget);
    expect(find.byType(PhoneScriptHiddenCalls), findsNothing);
  });

  testWidgets('a 5000-call loop opens a hundred calls per press', (
    tester,
  ) async {
    await _pump(tester, [
      _repl(status: ToolSegmentStatus.ok),
      ..._calls(iterations: 5000, edit: true),
    ], isLive: false);
    expect(find.text('Show 4995 more calls'), findsOneWidget);
    // What the fold hides, the rarest tool first.
    expect(find.text('Grep 2,497 · Read 2,498'), findsOneWidget);
    await tester.tap(find.text('Show 4995 more calls'));
    await tester.pump();
    // From the top of the hidden run: loop 2 to loop 101.
    expect(find.text('loop 101'), findsOneWidget);
    expect(find.text('loop 102'), findsNothing);
    expect(find.text('Show 4895 more calls'), findsOneWidget);
  });

  testWidgets('a queued row reads like the row it becomes', (tester) async {
    await _pump(tester, [_repl()]);
    final l10n = AppLocalizations.of(
      tester.element(find.byType(AgentTranscript)),
    );
    // No raw argument object: the tool's name, as its made row shows it.
    expect(find.textContaining('{'), findsNothing);
    final made = tester.widget<Text>(
      find
          .descendant(
            of: find.byType(PhoneScriptPendingRow).first,
            matching: find.byType(Text),
          )
          .first,
    );
    expect(made.data, isNot(contains('pattern')));
    expect(made.data, isNot(l10n.scriptToolComputed));
  });

  testWidgets('a line deeper than the indent bound sits at the bound', (
    tester,
  ) async {
    final code = [
      'const x = 1;',
      'await tools.read({ description: "top" });',
      for (var depth = 1; depth <= 20; depth++) ...[
        'if (x) {',
        if (depth == scriptTreeMaxIndent - 1)
          'await tools.read({ description: "shallow" });',
        if (depth == 12) 'await tools.read({ description: "twelve" });',
        if (depth == 20) 'await tools.read({ description: "twenty" });',
      ],
      for (var depth = 1; depth <= 20; depth++) '}',
    ].join('\n');
    await _pump(tester, [
      ToolSegment(
        toolName: 'repl',
        toolCallId: 'r1',
        inputs: {'code': code, 'description': 'Tidy the TODO list'},
        status: ToolSegmentStatus.running,
        startedAt: _ts,
      ),
    ]);
    double start(String label) => tester.getTopLeft(find.text(label)).dx;
    expect(start('top'), lessThan(start('shallow')));
    expect(start('shallow'), lessThan(start('twelve')));
    expect(start('twenty'), start('twelve'));
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
    ToolSegment repl(String code, ToolSegmentStatus status) => ToolSegment(
      toolName: 'repl',
      toolCallId: 'r1',
      inputs: {'code': code, 'description': 'Tidy the TODO list'},
      status: status,
      startedAt: _ts,
    );

    testWidgets('a long name first in the fold keeps the next in sight', (
      tester,
    ) async {
      final lines = source.split('\n');
      await _pump(tester, [
        repl(source, ToolSegmentStatus.ok),
        for (var i = 0; i < 12; i++)
          ToolSegment(
            toolName: i == 5 ? tool : 'read',
            toolCallId: 'r1/$i',
            inputs: {'description': 'call $i'},
            outputs: 'ok',
            status: ToolSegmentStatus.ok,
            startedAt: _ts,
            parentToolCallId: 'r1',
            callSite: ScriptCallSite(
              i == 5 ? 3 : 5,
              lines[i == 5 ? 2 : 4].indexOf('tools.') + 7,
            ),
          ),
      ], isLive: false);
      final line = find.textContaining(' · Read 6');
      expect(line, findsOneWidget);
      final paragraph = tester.renderObject<RenderParagraph>(line);
      final text = paragraph.text.toPlainText();
      expect(text, endsWith('… 1 · Read 6'));
      expect(text, isNot(contains('\u202E')));
      expect(text, isNot(contains('\u200D')));
      expect(paragraph.didExceedMaxLines, isFalse);
    });

    testWidgets('a queued row drops what a name hides', (tester) async {
      const hidden = 'await tools["ev\u202Eil\u200D"]({});';
      await _pump(tester, [repl(hidden, ToolSegmentStatus.running)]);
      expect(find.text('Evil'), findsOneWidget);
      expect(find.textContaining('\u202E'), findsNothing);
      expect(find.textContaining('\u200D'), findsNothing);
    });
  });

  testWidgets('calls with no site stay the flat list', (tester) async {
    await _pump(tester, [
      _repl(status: ToolSegmentStatus.ok),
      _call('search', 0, placed: false),
      _call('read', 1, placed: false),
    ], isLive: false);
    expect(find.byType(PhoneScriptTree), findsNothing);
    expect(find.text('search 0'), findsOneWidget);
    expect(find.text('read 1'), findsOneWidget);
  });

  testWidgets('right to left: the tree mirrors, the code stays LTR', (
    tester,
  ) async {
    await _pump(tester, [
      _repl(),
      ..._calls(iterations: 2),
    ], locale: const Locale('ar'));
    final l10n = AppLocalizations.of(
      tester.element(find.byType(AgentTranscript)),
    );
    final header = find.text('for (const file of hits.files)');
    expect(tester.widget<Text>(header).textDirection, TextDirection.ltr);
    expect(
      tester.getCenter(find.text(l10n.scriptGroupLoop)).dx,
      greaterThan(tester.getCenter(header).dx),
    );
    final pending = find.byType(PhoneScriptPendingRow).first;
    expect(
      tester
          .getCenter(
            find.descendant(of: pending, matching: find.byType(Icon)).first,
          )
          .dx,
      greaterThan(
        tester
            .getCenter(
              find.descendant(of: pending, matching: find.byType(Text)).first,
            )
            .dx,
      ),
    );
  });
}
