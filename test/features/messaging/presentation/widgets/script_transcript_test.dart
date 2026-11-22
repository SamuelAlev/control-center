import 'package:cc_domain/cc_domain.dart' show ConfirmationRequestDto;
import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/core/domain/value_objects/script_call_origin.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/code_mode/presentation/widgets/code_execution_record_link.dart';
import 'package:control_center/features/messaging/presentation/widgets/agent_approval_card.dart';
import 'package:control_center/features/messaging/presentation/widgets/bubbles/question_bubble.dart';
import 'package:control_center/features/messaging/presentation/widgets/bubbles/transcript_flow.dart';
import 'package:control_center/features/messaging/presentation/widgets/bubbles/transcript_segment_row.dart';
import 'package:control_center/features/messaging/presentation/widgets/script_origin_line.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/observability/presentation/tool_render/tool_call_card.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/transcript/widgets/code_preview.dart';
import 'package:control_center/shared/widgets/transcript/widgets/nested_tool_calls.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_wrap.dart';

final _ts = DateTime.fromMillisecondsSinceEpoch(1700000000000);

const _code =
    'const files = await tools.search({ pattern: "TODO" });\n'
    'return files.total;';

ToolSegment _repl({
  ToolSegmentStatus status = ToolSegmentStatus.ok,
  String outputs =
      'Script completed in 2.4 s · 3 tool calls (1 ok, 1 failed, '
      '1 denied)\n42',
  String id = 'r1',
}) => ToolSegment(
  toolName: 'repl',
  toolCallId: id,
  inputs: const {'code': _code, 'description': 'Count the TODOs'},
  outputs: outputs,
  status: status,
  startedAt: _ts,
  durationMs: status == ToolSegmentStatus.running ? null : 2400,
);

ToolSegment _call(
  String id,
  String path, {
  String? parent = 'r1',
  ToolSegmentStatus status = ToolSegmentStatus.ok,
  String outputs = 'ok',
  String? outcome,
}) => ToolSegment(
  toolName: 'read',
  toolCallId: id,
  inputs: {'path': path},
  outputs: outputs,
  status: status,
  startedAt: _ts,
  durationMs: status == ToolSegmentStatus.running ? null : 10,
  parentToolCallId: parent,
  outcome: outcome,
);

Widget _flow(List<TranscriptSegment> segments, {bool isLive = false}) =>
    SingleChildScrollView(
      child: TranscriptFlow(
        segments: segments,
        codeFont: 'monospace',
        isLive: isLive,
      ),
    );

double _top(WidgetTester tester, Finder f) => tester.getTopLeft(f).dy;

void main() {
  group('repl row', () {
    testWidgets('description is the label; the script starts collapsed', (
      tester,
    ) async {
      await tester.pumpWidget(
        testWrap(TranscriptSegmentRow(segment: _repl(), codeFont: 'monospace')),
      );
      expect(
        find.textContaining('Count the TODOs', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.textContaining('JavaScript', findRichText: true),
        findsOneWidget,
      );
      // Collapsed row: no body yet.
      expect(find.text('Completed'), findsNothing);

      await tester.tap(
        find.textContaining('Count the TODOs', findRichText: true),
      );
      await tester.pumpAndSettle();
      // The status line reads as a status, not as the server's sentence.
      expect(find.text('Completed'), findsOneWidget);
      expect(find.textContaining('Script completed in'), findsNothing);
      expect(find.text('42'), findsOneWidget);
      // The script itself stays folded until asked for.
      expect(find.text('Script'), findsOneWidget);
      expect(find.text('2 lines'), findsOneWidget);
      expect(find.byType(CodePreview), findsNothing);

      await tester.tap(find.text('Script'));
      await tester.pumpAndSettle();
      expect(find.byType(CodePreview), findsOneWidget);
    });

    testWidgets('failure and timeout read as their own status', (tester) async {
      await tester.pumpWidget(
        testWrap(
          TranscriptSegmentRow(
            segment: _repl(
              status: ToolSegmentStatus.error,
              outputs: 'Script timed out after 30 s · no tool calls',
            ),
            codeFont: 'monospace',
          ),
        ),
      );
      // An error row opens by default.
      await tester.pumpAndSettle();
      expect(find.text('Timed out'), findsOneWidget);
    });

    testWidgets('the external adapter name renders the same row', (
      tester,
    ) async {
      await tester.pumpWidget(
        testWrap(
          TranscriptSegmentRow(
            segment: ToolSegment(
              toolName: 'mcp__control-center__repl',
              toolCallId: 'x',
              inputs: const {'code': _code, 'description': 'Via MCP'},
              status: ToolSegmentStatus.running,
              startedAt: _ts,
            ),
            codeFont: 'monospace',
          ),
        ),
      );
      expect(
        find.textContaining('Via MCP', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.textContaining('JavaScript', findRichText: true),
        findsOneWidget,
      );
    });
  });

  group('nested calls', () {
    final segments = <TranscriptSegment>[
      _repl(),
      _call('r1/1', 'lib/a.dart'),
      _call(
        'r1/2',
        'lib/b.dart',
        status: ToolSegmentStatus.error,
        outputs: 'not found',
      ),
      _call(
        'r1/3',
        'lib/c.dart',
        status: ToolSegmentStatus.error,
        outputs: 'User denied: not now',
        outcome: 'denied',
      ),
    ];

    testWidgets('fold under the script row with a summary, in call order', (
      tester,
    ) async {
      await tester.pumpWidget(testWrap(_flow(segments)));
      // One row; the calls are inside it, summarised.
      expect(find.byType(TranscriptSegmentRow), findsOneWidget);
      expect(find.text('3 calls · 1 failed · 1 denied'), findsOneWidget);

      await tester.tap(
        find.textContaining('Count the TODOs', findRichText: true),
      );
      await tester.pumpAndSettle();
      expect(find.byType(NestedToolCalls), findsOneWidget);
      expect(find.byType(TranscriptSegmentRow), findsNWidgets(4));
      final a = find.textContaining('lib/a.dart', findRichText: true);
      final b = find.textContaining('lib/b.dart', findRichText: true);
      final c = find.textContaining('lib/c.dart', findRichText: true);
      expect(_top(tester, a), lessThan(_top(tester, b)));
      expect(_top(tester, b), lessThan(_top(tester, c)));
      // Each call keeps its own status; a denial is not a failure.
      expect(find.byIcon(AppIcons.shieldOff), findsOneWidget);
      expect(find.byIcon(AppIcons.circleX), findsOneWidget);
      expect(
        find.textContaining('Tool calls', findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets('a running script lists its calls live with a spinner', (
      tester,
    ) async {
      await tester.pumpWidget(
        testWrap(
          _flow([
            _repl(status: ToolSegmentStatus.running, outputs: ''),
            _call(
              'r1/1',
              'lib/a.dart',
              status: ToolSegmentStatus.running,
              outputs: '',
            ),
            _call('r1/2', 'lib/b.dart'),
          ], isLive: true),
        ),
      );
      expect(find.text('2 calls'), findsOneWidget);
      // The newest call has finished, but the turn is not idle: the call
      // still running says what the agent is doing.
      expect(
        find.textContaining('Reading files', findRichText: true),
        findsOneWidget,
      );
      await tester.tap(
        find.textContaining('Count the TODOs', findRichText: true),
      );
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Running'), findsOneWidget);
      expect(
        find.textContaining('1 running · 1 ok', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.textContaining('lib/a.dart', findRichText: true),
        findsOneWidget,
      );
      expect(find.byType(CcSpinner), findsWidgets);
    });

    testWidgets('between calls the live status names the script', (
      tester,
    ) async {
      await tester.pumpWidget(
        testWrap(
          _flow([
            _repl(status: ToolSegmentStatus.running, outputs: ''),
            _call('r1/1', 'lib/a.dart'),
          ], isLive: true),
        ),
      );
      expect(
        find.textContaining('Running a script', findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets('two scripts sharing an id each keep their own calls', (
      tester,
    ) async {
      // Local models reuse `call_0`: the second script's calls stay in the
      // second row, and its call ids repeat the first script's.
      await tester.pumpWidget(
        testWrap(
          _flow([
            _repl(id: 'call_0'),
            _call('call_0/1', 'lib/first.dart', parent: 'call_0'),
            _repl(id: 'call_0'),
            _call('call_0/1', 'lib/second.dart', parent: 'call_0'),
            _call('call_0/1', 'lib/third.dart', parent: 'call_0'),
          ]),
        ),
      );
      expect(find.byType(TranscriptSegmentRow), findsNWidgets(2));
      expect(find.text('1 call'), findsOneWidget);
      expect(find.text('2 calls'), findsOneWidget);

      // Open the second script: its two calls share an id, so its list keys
      // rows by position (a key per id would collide and throw).
      await tester.tap(
        find.textContaining('Count the TODOs', findRichText: true).last,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        find.textContaining('lib/second.dart', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.textContaining('lib/third.dart', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.textContaining('lib/first.dart', findRichText: true),
        findsNothing,
      );
    });

    testWidgets('a call whose parent is not a script is its own row', (
      tester,
    ) async {
      await tester.pumpWidget(
        testWrap(
          _flow([
            _repl(id: 'call_0'),
            _call('call_0', 'lib/plain.dart', parent: null),
            _call('call_0/1', 'lib/borrowed.dart', parent: 'call_0'),
          ]),
        ),
      );
      expect(find.byType(TranscriptSegmentRow), findsNWidgets(3));
      expect(
        find.textContaining('lib/borrowed.dart', findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets('a call whose script is missing renders as its own row', (
      tester,
    ) async {
      await tester.pumpWidget(
        testWrap(_flow([_call('gone/1', 'lib/orphan.dart', parent: 'gone')])),
      );
      expect(find.byType(TranscriptSegmentRow), findsOneWidget);
      expect(
        find.textContaining('lib/orphan.dart', findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets('500 calls build lazily', (tester) async {
      tester.view.physicalSize = const Size(1200, 2000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        testWrap(
          _flow([
            _repl(),
            for (var i = 1; i <= 500; i++) _call('r1/$i', 'lib/f$i.dart'),
          ]),
        ),
      );
      expect(find.text('500 calls'), findsOneWidget);
      await tester.tap(
        find.textContaining('Count the TODOs', findRichText: true),
      );
      await tester.pumpAndSettle();
      final built = find.byType(TranscriptSegmentRow).evaluate().length;
      expect(built, greaterThan(5));
      expect(built, lessThan(60));
      expect(find.textContaining('500 ok', findRichText: true), findsOneWidget);
    });

    testWidgets('right to left: the row mirrors, the script stays LTR', (
      tester,
    ) async {
      await tester.pumpWidget(
        testWrap(
          TranscriptSegmentRow(
            segment: _repl(),
            codeFont: 'monospace',
            nestedCalls: [_call('r1/1', 'lib/a.dart')],
          ),
          textDirection: TextDirection.rtl,
        ),
      );
      final label = find.textContaining('Count the TODOs', findRichText: true);
      final rowRect = tester.getRect(find.byType(TranscriptSegmentRow).first);
      // The label starts at the right-hand edge in RTL.
      expect(tester.getRect(label).right, greaterThan(rowRect.center.dx));
      await tester.tap(label);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Script'));
      await tester.pumpAndSettle();
      final preview = find.byType(CodePreview);
      expect(preview, findsOneWidget);
      final direction = tester.widget<Directionality>(
        find
            .descendant(of: preview, matching: find.byType(Directionality))
            .first,
      );
      expect(direction.textDirection, TextDirection.ltr);
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('run activity folds a script\'s calls into its card', (
    tester,
  ) async {
    await tester.pumpWidget(
      testWrap(
        SingleChildScrollView(
          child: TranscriptToolList(
            segments: [
              _repl(),
              _call('r1/1', 'lib/a.dart'),
              _call('gone/1', 'lib/orphan.dart', parent: 'gone'),
            ],
          ),
        ),
      ),
    );
    // The script and the orphan; the script's call is inside the first.
    expect(find.byType(ToolCallCard), findsNWidgets(2));
    expect(find.text('1 call'), findsOneWidget);
    await tester.tap(find.text('repl'));
    await tester.pumpAndSettle();
    expect(find.byType(ToolCallCard), findsNWidgets(3));
    expect(find.text('Completed'), findsOneWidget);
  });

  group('from a script', () {
    ConfirmationRequestDto request({ScriptCallOrigin? origin}) =>
        ConfirmationRequestDto(
          id: 'req',
          spaceId: 'space',
          conversationId: 'conversation',
          title: 'Run git push',
          detail: '',
          severity: 'warning',
          createdAt: '2026-01-01T00:00:00Z',
          origin: origin,
        );

    Widget card(ConfirmationRequestDto r) => ApprovalCard(
      request: r,
      busy: false,
      onApprove: () {},
      onApproveAndRemember: () {},
      onDeny: () {},
      onShowScript: () {},
    );

    testWidgets('an approval card says so, and only then', (tester) async {
      await tester.pumpWidget(
        testWrap(
          card(
            request(
              origin: ScriptCallOrigin(
                parentToolCallId: 'r1',
                executionId: 'run/r1',
              ),
            ),
          ),
        ),
      );
      expect(find.text('From a script the agent is running'), findsOneWidget);
      expect(find.byType(ScriptOriginLine), findsOneWidget);
      expect(find.text('Show script'), findsOneWidget);

      await tester.pumpWidget(testWrap(card(request())));
      expect(find.byType(ScriptOriginLine), findsNothing);
    });

    testWidgets('a call from a Python cell links no record', (tester) async {
      await tester.pumpWidget(
        testWrap(
          card(
            request(
              origin: ScriptCallOrigin(
                parentToolCallId: 'r1',
                executionId: 'run/r1',
              ),
            ),
          ),
        ),
      );
      expect(find.byType(CodeExecutionOriginRecordLink), findsOneWidget);

      await tester.pumpWidget(
        testWrap(
          card(request(origin: ScriptCallOrigin(parentToolCallId: 'e'))),
        ),
      );
      expect(find.byType(ScriptOriginLine), findsOneWidget);
      expect(find.byType(CodeExecutionOriginRecordLink), findsNothing);
    });

    Message question({Map<String, dynamic>? origin}) => Message(
      id: 'q',
      spaceId: 'space',
      conversationId: 'conversation',
      senderId: 'agent',
      senderType: SenderType.agent,
      content: 'Which files?',
      messageType: MessageType.userQuestion,
      createdAt: _ts,
      metadata: {
        'question': 'Which files?',
        'options': [
          {'label': 'All', 'value': 'all'},
        ],
        'origin': ?origin,
      },
    );

    testWidgets('a question from a Python cell links no record', (
      tester,
    ) async {
      await tester.pumpWidget(
        testWrap(
          QuestionBubble(
            message: question(origin: {'parent_tool_call_id': 'e'}),
          ),
        ),
      );
      expect(find.byType(ScriptOriginLine), findsOneWidget);
      expect(find.text('Show script'), findsOneWidget);
      expect(find.byType(CodeExecutionOriginRecordLink), findsNothing);
    });

    testWidgets('a question form says so, and only then', (tester) async {
      await tester.pumpWidget(
        testWrap(
          QuestionBubble(
            message: question(
              origin: {'parent_tool_call_id': 'r1', 'execution_id': 'run/r1'},
            ),
          ),
        ),
      );
      expect(find.text('From a script the agent is running'), findsOneWidget);

      // "Show script" asks the open conversation to bring the row into view.
      await tester.tap(find.text('Show script'));
      await tester.pump();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(QuestionBubble)),
      );
      expect(container.read(pendingFocusToolCallProvider), (
        spaceId: 'space',
        conversationId: 'conversation',
        toolCallId: 'r1',
      ));

      await tester.pumpWidget(testWrap(QuestionBubble(message: question())));
      await tester.pump();
      expect(find.byType(ScriptOriginLine), findsNothing);
    });
  });
}
