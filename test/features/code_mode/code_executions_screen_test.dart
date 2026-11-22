import 'dart:async';

import 'package:cc_domain/cc_domain.dart' show RpcErrorCodes;
import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/ports/run_transcript_relay_port.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_update_codec.dart';
import 'package:cc_domain/features/code_mode/domain/entities/code_execution.dart';
import 'package:cc_domain/features/code_mode/domain/entities/code_execution_call.dart';
import 'package:cc_domain/features/code_mode/domain/ports/code_execution_repository.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_execution_status.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/script_call_site.dart';
import 'package:cc_rpc/cc_rpc.dart' show RemoteRpcException;
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/theme/font_settings.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/code_mode/presentation/code_mode_copy.dart';
import 'package:control_center/features/code_mode/presentation/screens/code_executions_screen.dart';
import 'package:control_center/features/code_mode/presentation/widgets/code_execution_call_row.dart';
import 'package:control_center/features/code_mode/presentation/widgets/code_execution_detail.dart';
import 'package:control_center/features/code_mode/presentation/widgets/code_execution_header.dart';
import 'package:control_center/features/code_mode/presentation/widgets/code_execution_row.dart';
import 'package:control_center/features/code_mode/presentation/widgets/code_executions_list.dart';
import 'package:control_center/features/code_mode/providers/code_executions_list_provider.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/l10n/localizations_loader.dart';
import 'package:control_center/router/app_router.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/widgets/transcript/widgets/script_body.dart';
import 'package:control_center/shared/widgets/transcript/widgets/script_tree/script_call_tree.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../helpers/test_wrap.dart';
import 'code_mode_fakes.dart';

const _ws = 'ws1';

class _Workspace extends ActiveWorkspaceIdNotifier {
  @override
  String? build() => _ws;
}

/// An id with both characters a record id may carry: `<run>/<call>#<n>`.
const _awkwardId = 'run-7/call-3#2';

void main() {
  late AppLocalizations l10n;
  late FakeCodeModeRepository repo;
  late _Relay relay;

  setUpAll(() async {
    l10n = await appLocalizationsDelegate.load(const Locale('en'));
  });

  setUp(() {
    repo = FakeCodeModeRepository();
    relay = _Relay();
    addTearDown(relay.close);
  });

  Future<GoRouter> pump(
    WidgetTester tester, {
    String? location,
    Locale locale = const Locale('en'),
  }) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = historyTestRouter(
      initialLocation: location ?? codeExecutionsRoute(_ws),
      routes: [
        GoRoute(path: '/before', builder: (context, state) => const Text('B')),
        ...codeExecutionRoutes(),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeWorkspaceIdProvider.overrideWith(_Workspace.new),
          codeModeRepositoryProvider.overrideWithValue(repo),
          runTranscriptRelayPortProvider.overrideWithValue(relay),
          codeFontFamilyProvider.overrideWithValue('monospace'),
          workspaceAgentsProvider(
            _ws,
          ).overrideWith((ref) => Stream.value(const <Agent>[])),
        ],
        child: testRouterWrap(router, locale: locale),
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  List<CodeExecution> numbered(int from, int count) => [
    for (var i = from; i < from + count; i++)
      codeExecution(
        id: 'run-1/call-$i',
        toolCallId: 'call-$i',
        description: 'Script $i',
      ),
  ];

  group('list', () {
    testWidgets('empty workspace says so', (tester) async {
      await pump(tester);
      expect(find.text(l10n.codeExecutionsEmpty), findsOneWidget);
      expect(repo.queries.single.cursor, isNull);
    });

    testWidgets('a failed read shows the reason', (tester) async {
      repo.onList = (_) async =>
          throw RemoteRpcException(RpcErrorCodes.internalError, 'list broke');
      await pump(tester);
      expect(find.text('list broke'), findsOneWidget);
      expect(find.byType(CodeExecutionRow), findsNothing);
    });

    testWidgets('pages lazily as the end comes into view', (tester) async {
      repo.onList = (q) async => switch (q.cursor) {
        null => CodeExecutionPage(items: numbered(0, 50), nextCursor: 'c1'),
        'c1' => CodeExecutionPage(items: numbered(50, 10)),
        _ => throw StateError('unexpected cursor ${q.cursor}'),
      };
      await pump(tester);
      expect(repo.queries, hasLength(1));
      expect(find.text('Script 0'), findsOneWidget);
      // Only what is on screen is built.
      expect(find.text('Script 49'), findsNothing);

      await tester.scrollUntilVisible(
        find.text('Script 59'),
        400,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();
      expect(repo.queries.map((q) => q.cursor), [null, 'c1']);
      expect(find.text('Script 59'), findsOneWidget);
    });

    testWidgets('a failed next page offers a retry', (tester) async {
      var fail = true;
      repo.onList = (q) async {
        if (q.cursor == null) {
          return CodeExecutionPage(items: numbered(0, 3), nextCursor: 'c1');
        }
        if (fail) {
          fail = false;
          throw RemoteRpcException(RpcErrorCodes.internalError, 'page broke');
        }
        return CodeExecutionPage(items: numbered(3, 1));
      };
      await pump(tester);
      expect(find.text('page broke'), findsOneWidget);
      await tester.tap(find.text(l10n.retry));
      await tester.pumpAndSettle();
      expect(find.text('Script 3'), findsOneWidget);
      expect(find.text('page broke'), findsNothing);
    });

    testWidgets('the outcome filter offers what a record can be', (
      tester,
    ) async {
      await pump(tester);
      final select = tester.widget<CcMultiSelect<CodeExecutionStatus>>(
        find.byType(CcMultiSelect<CodeExecutionStatus>),
      );
      final offered = [for (final o in select.options) o.value];
      expect(offered, contains(CodeExecutionStatus.running));
      expect(offered, isNot(contains(CodeExecutionStatus.refused)));
      expect(offered, kRecordedCodeExecutionStatuses);
    });

    testWidgets('a running row has no duration, and updates when it ends', (
      tester,
    ) async {
      final started = DateTime.utc(2026, 11, 17, 9, 30);
      var done = false;
      CodeExecution row() => codeExecution(
        status: done
            ? CodeExecutionStatus.completed
            : CodeExecutionStatus.running,
        durationMs: done ? 1840 : 0,
        callCounts: done ? NestedCallCounts(completed: 2) : NestedCallCounts(),
      );
      repo.onList = (_) async => CodeExecutionPage(items: [row()]);
      await pump(tester);
      expect(find.text(l10n.scriptStateRunning), findsOneWidget);
      expect(find.text(formatScriptDuration(l10n, 0)), findsNothing);
      expect(find.text(l10n.scriptCallCount(0)), findsNothing);

      done = true;
      relay.emit([
        ToolSegment(
          toolName: 'repl',
          toolCallId: 'call-1',
          status: ToolSegmentStatus.ok,
          startedAt: started,
        ),
      ]);
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      // One narrow read for the running row, not the whole list again.
      expect(repo.queries, hasLength(2));
      expect(repo.queries.last.toolCallId, 'call-1');
      expect(repo.queries.last.runId, 'run-1');
      expect(find.text(l10n.scriptStateCompleted), findsOneWidget);
      expect(
        find.textContaining(formatScriptDuration(l10n, 1840)),
        findsOneWidget,
      );
    });

    testWidgets('a running-only list lets go of a script once it ends', (
      tester,
    ) async {
      var done = false;
      repo.onList = (_) async => CodeExecutionPage(
        items: [
          codeExecution(
            status: done
                ? CodeExecutionStatus.completed
                : CodeExecutionStatus.running,
            durationMs: done ? 1840 : 0,
          ),
        ],
      );
      await pump(
        tester,
        location: codeExecutionsRoute(_ws, statuses: ['running']),
      );
      expect(find.text(l10n.scriptStateRunning), findsOneWidget);

      done = true;
      relay.emit([
        ToolSegment(
          toolName: 'repl',
          toolCallId: 'call-1',
          status: ToolSegmentStatus.ok,
          startedAt: DateTime.utc(2026, 11, 17, 9, 30),
        ),
      ]);
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(find.text(l10n.scriptStateCompleted), findsNothing);
      expect(find.text(l10n.scriptStateRunning), findsNothing);
    });

    testWidgets('filters and scope come from the URL', (tester) async {
      repo.onList = (_) async => const CodeExecutionPage(items: []);
      final router = await pump(
        tester,
        location: codeExecutionsRoute(
          _ws,
          runId: 'run-9',
          statuses: ['failed', 'timed_out'],
        ),
      );
      final q = repo.queries.single;
      expect(q.runId, 'run-9');
      expect(q.statuses, {
        CodeExecutionStatus.failed,
        CodeExecutionStatus.timedOut,
      });
      expect(find.text(l10n.codeExecutionsEmptyFiltered), findsOneWidget);
      expect(find.text(l10n.codeExecutionsScopeRun), findsOneWidget);

      await tester.tap(find.text(l10n.codeExecutionsShowAll));
      await tester.pumpAndSettle();
      final uri = router.routerDelegate.currentConfiguration.uri;
      expect(uri.queryParameters.containsKey(codeExecutionsRunParam), isFalse);
      expect(
        uri.queryParameters[codeExecutionsStatusParam],
        'failed,timed_out',
      );
      expect(repo.queries.last.runId, isNull);
      expect(repo.queries.last.statuses, hasLength(2));
    });

    test('the filter survives its location', () {
      final filter = codeExecutionsFilterOf(
        _ws,
        Uri.parse(
          codeExecutionsRoute(
            _ws,
            conversationId: 'conv/1',
            agentId: 'a#1',
            statuses: ['failed', 'refused', 'nonsense'],
          ),
        ),
      );
      expect(filter.conversationId, 'conv/1');
      expect(filter.agentId, 'a#1');
      // A refused script is never recorded, and the server refuses a query
      // for one: an old link naming it still reads the list.
      expect(filter.statuses, {CodeExecutionStatus.failed});
      expect(
        codeExecutionsFilterOf(
          _ws,
          Uri.parse(codeExecutionsLocationOf(filter)),
        ),
        filter,
      );
    });
  });

  group('record', () {
    testWidgets('an id with / and # round-trips through its route whole', (
      tester,
    ) async {
      repo.details[_awkwardId] = CodeExecutionDetail(
        execution: codeExecution(id: _awkwardId, runId: 'run-7'),
        calls: const [],
      );
      repo.onList = (_) async => CodeExecutionPage(
        items: [codeExecution(id: _awkwardId, runId: 'run-7')],
      );
      final router = await pump(tester);
      final location = codeExecutionRoute(_ws, _awkwardId);
      expect(location, isNot(contains('#')));
      expect(location.split('/').last, Uri.encodeComponent(_awkwardId));

      await tester.tap(find.byType(CodeExecutionRow));
      await tester.pumpAndSettle();
      expect(repo.detailReads, [_awkwardId]);
      expect(router.routerDelegate.currentConfiguration.uri.path, location);
      expect(find.byType(CodeExecutionDetailView), findsOneWidget);

      // Landing on the URL directly reads the same record.
      repo.detailReads.clear();
      router.go(location);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<CodeExecutionDetailView>(
              find.byType(CodeExecutionDetailView),
            )
            .executionId,
        _awkwardId,
      );
    });

    testWidgets('back returns to the list it came from', (tester) async {
      repo.details['run-1/call-1'] = CodeExecutionDetail(
        execution: codeExecution(),
        calls: const [],
      );
      repo.onList = (_) async => CodeExecutionPage(items: [codeExecution()]);
      final router = await pump(tester);
      await tester.tap(find.byType(CodeExecutionRow));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.back));
      await tester.pumpAndSettle();
      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        codeExecutionsRoute(_ws),
      );
      // The list stayed mounted under the record: no second read.
      expect(repo.queries, hasLength(1));
    });

    // A kind from the host's vocabulary for each ending; none while running
    // or after a completed script. A refused script is never recorded.
    String? kindOf(CodeExecutionStatus status) => switch (status) {
      CodeExecutionStatus.running || CodeExecutionStatus.completed => null,
      CodeExecutionStatus.failed => CodeExecutionErrorKind.scriptError,
      CodeExecutionStatus.timedOut => 'deadline',
      CodeExecutionStatus.cancelled => CodeExecutionErrorKind.cancelled,
      CodeExecutionStatus.memoryExceeded => 'heap',
      CodeExecutionStatus.outputExceeded => 'output',
      CodeExecutionStatus.sandboxError => CodeExecutionErrorKind.serverStopped,
      CodeExecutionStatus.refused => throw StateError('never recorded'),
    };

    for (final status in kRecordedCodeExecutionStatuses.where(
      (s) => s != CodeExecutionStatus.running,
    )) {
      testWidgets('shows a ${status.wire} record', (tester) async {
        final id = 'run-1/${status.wire}';
        repo.details[id] = CodeExecutionDetail(
          execution: codeExecution(
            id: id,
            status: status,
            errorKind: kindOf(status),
          ),
          payload: CodeExecutionPayload(
            executionId: id,
            source: 'const prs = await tools.github_list_pull_requests({});',
            output: 'three open',
          ),
          calls: [codeExecutionCall(id, 1)],
        );
        await pump(tester, location: codeExecutionRoute(_ws, id));
        expect(
          find.descendant(
            of: find.byType(CodeExecutionHeader),
            matching: find.text(
              scriptStateLabel(l10n, scriptRunStateOf(status)),
            ),
          ),
          findsOneWidget,
        );
        expect(find.text(l10n.codeExecutionScript), findsOneWidget);
        expect(find.text('three open'), findsOneWidget);
        if (kindOf(status) case final kind?) {
          // The kind in words, and as the value it is.
          expect(find.text(kind), findsOneWidget);
          expect(
            find.text(codeExecutionEndReason(l10n, kind)!),
            findsOneWidget,
          );
        }
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('a script that threw names its error', (tester) async {
      const id = 'run-1/threw';
      repo.details[id] = CodeExecutionDetail(
        execution: codeExecution(
          id: id,
          status: CodeExecutionStatus.failed,
          errorKind: CodeExecutionErrorKind.scriptError,
        ),
        payload: CodeExecutionPayload(
          executionId: id,
          source: 'null.x;',
          errorName: 'TypeError',
        ),
        calls: const [],
      );
      await pump(tester, location: codeExecutionRoute(_ws, id));
      expect(
        find.text(l10n.codeExecutionEndedScriptErrorNamed('TypeError')),
        findsOneWidget,
      );
      expect(find.text('script_error'), findsOneWidget);
    });

    testWidgets('a running record shows its calls so far, then its end', (
      tester,
    ) async {
      const id = 'run-1/call-1';
      final started = DateTime.utc(2026, 11, 17, 9, 30);
      CodeExecutionDetail record({required bool done}) => CodeExecutionDetail(
        execution: codeExecution(
          id: id,
          status: done
              ? CodeExecutionStatus.completed
              : CodeExecutionStatus.running,
          durationMs: done ? 2400 : 0,
          callCounts: done
              ? NestedCallCounts(completed: 3)
              : NestedCallCounts(),
        ),
        payload: CodeExecutionPayload(
          executionId: id,
          source: 'return 1;',
          output: done ? 'three open' : '',
        ),
        calls: [
          for (var i = 1; i <= (done ? 3 : 2); i++) codeExecutionCall(id, i),
        ],
      );
      List<TranscriptSegment> transcript({required bool done, int calls = 2}) =>
          [
            ToolSegment(
              toolName: 'repl',
              toolCallId: 'call-1',
              status: done ? ToolSegmentStatus.ok : ToolSegmentStatus.running,
              startedAt: started,
            ),
            for (var i = 1; i <= calls; i++)
              ToolSegment(
                toolName: 'read',
                toolCallId: 'call-1/$i',
                parentToolCallId: 'call-1',
                status: ToolSegmentStatus.ok,
                startedAt: started,
              ),
          ];
      repo.details[id] = record(done: false);
      await pump(tester, location: codeExecutionRoute(_ws, id));
      relay.emit(transcript(done: false));
      await tester.pump();

      final header = find.byType(CodeExecutionHeader);
      expect(
        find.descendant(
          of: header,
          matching: find.text(l10n.scriptStateRunning),
        ),
        findsOneWidget,
      );
      expect(find.text(l10n.codeExecutionRunningNote), findsOneWidget);
      expect(find.text(l10n.codeExecutionFactStarted), findsOneWidget);
      // No duration and no output until it ends; the calls settled so far.
      expect(find.text(l10n.codeExecutionFactDuration), findsNothing);
      expect(find.text(l10n.transcriptOutput), findsNothing);
      expect(
        find.descendant(
          of: header,
          matching: find.text(l10n.scriptCallCount(2)),
        ),
        findsOneWidget,
      );
      expect(find.byType(CodeExecutionCallRow), findsNWidgets(2));
      expect(repo.detailReads, [id]);

      // The transcript moving on without the script changing reads nothing.
      relay.emit(transcript(done: false));
      await tester.pump(const Duration(seconds: 3));
      expect(repo.detailReads, [id]);

      // The script ends: the record is read again, once, a moment later.
      repo.details[id] = record(done: true);
      relay.emit(transcript(done: true, calls: 3));
      await tester.pump();
      expect(repo.detailReads, [id]);
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(repo.detailReads, [id, id]);
      expect(
        find.descendant(
          of: header,
          matching: find.text(l10n.scriptStateCompleted),
        ),
        findsOneWidget,
      );
      expect(find.text(l10n.codeExecutionRunningNote), findsNothing);
      expect(find.text(l10n.codeExecutionFactDuration), findsOneWidget);
      expect(find.text('three open'), findsOneWidget);

      // Finished, it no longer follows the run.
      relay.emit(transcript(done: true, calls: 4));
      await tester.pump(const Duration(seconds: 3));
      expect(repo.detailReads, [id, id]);
    });

    testWidgets('a call opens to its arguments and result', (tester) async {
      const id = 'run-1/call-1';
      repo.details[id] = CodeExecutionDetail(
        execution: codeExecution(),
        calls: [
          codeExecutionCall(
            id,
            1,
            gate: NestedCallGateDecision.approved,
            approvalWaitMs: 4200,
          ),
          codeExecutionCall(
            id,
            2,
            status: NestedCallStatus.denied,
            gate: NestedCallGateDecision.denied,
            error: 'A person denied this call.',
          ),
        ],
      );
      await pump(tester, location: codeExecutionRoute(_ws, id));
      expect(find.text(l10n.codeExecutionGateApproved), findsNothing);
      expect(
        find.textContaining(l10n.codeExecutionGateApproved),
        findsOneWidget,
      );
      expect(find.textContaining('4.2'), findsOneWidget);
      // The call's outcome and the gate's decision.
      expect(find.text(l10n.codeExecutionCallDenied), findsNWidgets(2));

      await tester.tap(find.text('#2'));
      await tester.pumpAndSettle();
      expect(find.text('A person denied this call.'), findsOneWidget);
      expect(find.text(l10n.codeExecutionCallArguments), findsOneWidget);
    });

    testWidgets('a record without its payload says it is no longer kept', (
      tester,
    ) async {
      const id = 'run-1/call-1';
      repo.details[id] = CodeExecutionDetail(
        execution: codeExecution(),
        calls: const [],
      );
      await pump(tester, location: codeExecutionRoute(_ws, id));
      expect(find.text(l10n.codeExecutionNoPayload), findsOneWidget);
      expect(find.text(l10n.codeExecutionNoCalls), findsOneWidget);
    });

    testWidgets('a long call list builds only what is on screen', (
      tester,
    ) async {
      const id = 'run-1/call-1';
      repo.details[id] = CodeExecutionDetail(
        execution: codeExecution(),
        calls: [for (var i = 1; i <= 3000; i++) codeExecutionCall(id, i)],
      );
      await pump(tester, location: codeExecutionRoute(_ws, id));
      expect(find.text(l10n.codeExecutionCallsHeading(3000)), findsOneWidget);
      expect(find.byType(CodeExecutionCallRow).evaluate().length, lessThan(60));
    });

    testWidgets('calls with sites are laid over the script', (tester) async {
      const id = 'run-1/call-1';
      const source =
          'for (const r of repos) {\n'
          '  await tools.github_list_pull_requests({ repo: r });\n'
          '}\n'
          'if (none) {\n'
          '  await tools.post_message({ text: "none" });\n'
          '}';
      CodeExecutionCall call(int n, NestedCallStatus status) =>
          CodeExecutionCall(
            executionId: id,
            sequence: n,
            toolCallId: '$id#$n',
            toolName: 'github_list_pull_requests',
            startOffsetMs: n * 10,
            durationMs: 120,
            status: status,
            site: ScriptCallSite(2, 15),
          );
      repo.details[id] = CodeExecutionDetail(
        execution: codeExecution(),
        payload: CodeExecutionPayload(executionId: id, source: source),
        calls: [
          call(1, NestedCallStatus.completed),
          call(2, NestedCallStatus.denied),
          call(3, NestedCallStatus.timedOut),
        ],
      );
      await pump(tester, location: codeExecutionRoute(_ws, id));
      expect(
        find.byType(ScriptCallTreeSliver<CodeExecutionCall>),
        findsOneWidget,
      );
      expect(find.byType(CodeExecutionCallRow), findsNWidgets(3));
      expect(find.text('Loop'), findsOneWidget);
      expect(find.text('for (const r of repos)'), findsOneWidget);
      expect(find.text('1 ok · 1 denied · 1 cancelled'), findsOneWidget);
      // The record is finished: the arm it never reached was skipped.
      expect(find.text('if none'), findsOneWidget);
      expect(find.text('Skipped'), findsNWidgets(2));
    });

    testWidgets('5000 calls with sites build only what is on screen', (
      tester,
    ) async {
      const id = 'run-1/call-1';
      const source =
          'for (const r of repos) {\n'
          '  await tools.github_list_pull_requests({ repo: r });\n'
          '}';
      repo.details[id] = CodeExecutionDetail(
        execution: codeExecution(),
        payload: CodeExecutionPayload(executionId: id, source: source),
        calls: [
          for (var n = 1; n <= 5000; n++)
            CodeExecutionCall(
              executionId: id,
              sequence: n,
              toolCallId: '$id#$n',
              toolName: 'github_list_pull_requests',
              startOffsetMs: n,
              durationMs: 1,
              status: n == 2500
                  ? NestedCallStatus.failed
                  : NestedCallStatus.completed,
              site: ScriptCallSite(2, 15),
            ),
        ],
      );
      final watch = Stopwatch()..start();
      await pump(tester, location: codeExecutionRoute(_ws, id));
      watch.stop();
      // ignore: avoid_print
      print(
        'w2-ui2: 5000-call record, first settled frame in '
        '${watch.elapsedMilliseconds} ms',
      );
      expect(find.byType(ScriptCallTreeSliver<CodeExecutionCall>), findsOne);
      // Folded: the first two, the failure and the last three.
      expect(find.byType(CodeExecutionCallRow), findsNWidgets(6));
      expect(
        find.textContaining('Show 2497 more calls', findRichText: true),
        findsNWidgets(2),
      );
      // The record names a tool as it is called, cut to its first 23
      // characters.
      expect(
        find.textContaining(
          'Show 2497 more calls · github_list_pull_reques… 2,497',
          findRichText: true,
        ),
        findsNWidgets(2),
      );

      // One press shows the next hundred, built only as they scroll in.
      await tester.tap(
        find.textContaining('Show 2497 more calls', findRichText: true).first,
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Show 2497 more calls', findRichText: true),
        findsNothing,
      );
      final built = find.byType(CodeExecutionCallRow).evaluate().length;
      expect(built, greaterThan(6));
      expect(built, lessThan(60));
    });

    testWidgets('a call a person approved is never folded away', (
      tester,
    ) async {
      const id = 'run-1/call-1';
      const source =
          'for (const r of repos) {\n'
          '  await tools.github_list_pull_requests({ repo: r });\n'
          '}';
      repo.details[id] = CodeExecutionDetail(
        execution: codeExecution(),
        payload: CodeExecutionPayload(executionId: id, source: source),
        calls: [
          for (var n = 1; n <= 20; n++)
            CodeExecutionCall(
              executionId: id,
              sequence: n,
              toolCallId: '$id#$n',
              toolName: 'github_list_pull_requests',
              startOffsetMs: n,
              durationMs: 1,
              status: NestedCallStatus.completed,
              gateDecision: n == 10
                  ? NestedCallGateDecision.approved
                  : NestedCallGateDecision.allowed,
              site: ScriptCallSite(2, 15),
            ),
        ],
      );
      await pump(tester, location: codeExecutionRoute(_ws, id));
      expect(find.text('#10'), findsOneWidget);
      expect(find.text('#9'), findsNothing);
      // Calls 3 to 9 and 11 to 17.
      expect(
        find.textContaining('Show 7 more calls', findRichText: true),
        findsNWidgets(2),
      );
    });

    testWidgets('calls with no site stay the flat list', (tester) async {
      const id = 'run-1/call-1';
      repo.details[id] = CodeExecutionDetail(
        execution: codeExecution(),
        payload: CodeExecutionPayload(
          executionId: id,
          source: 'await tools.github_list_pull_requests({});',
        ),
        calls: [codeExecutionCall(id, 1), codeExecutionCall(id, 2)],
      );
      await pump(tester, location: codeExecutionRoute(_ws, id));
      expect(
        find.byType(ScriptCallTreeSliver<CodeExecutionCall>),
        findsNothing,
      );
      expect(find.byType(CodeExecutionCallRow), findsNWidgets(2));
    });

    testWidgets('a missing record says so', (tester) async {
      await pump(tester, location: codeExecutionRoute(_ws, 'run-1/gone'));
      expect(find.text(l10n.codeExecutionNotFound), findsOneWidget);
    });

    testWidgets('a refused record is told in words, not shown', (tester) async {
      repo.detailError = RemoteRpcException(
        RpcErrorCodes.unauthorized,
        'unauthorized',
      );
      await pump(tester, location: codeExecutionRoute(_ws, 'run-1/call-1'));
      expect(find.text(l10n.codeExecutionRefusedSpace), findsOneWidget);
      expect(find.text('unauthorized'), findsNothing);
    });

    testWidgets('renders right to left', (tester) async {
      const id = 'run-1/call-1';
      repo.details[id] = CodeExecutionDetail(
        execution: codeExecution(),
        payload: CodeExecutionPayload(executionId: id, source: 'return 1;'),
        calls: [for (var i = 1; i <= 5; i++) codeExecutionCall(id, i)],
      );
      repo.onList = (_) async => CodeExecutionPage(items: [codeExecution()]);
      await pump(
        tester,
        location: codeExecutionRoute(_ws, id),
        // Arabic lays the app out right to left.
        locale: const Locale('ar'),
      );
      expect(
        Directionality.of(tester.element(find.byType(CodeExecutionDetailView))),
        TextDirection.rtl,
      );
      await tester.tap(find.text('#1'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      // The list stays mounted under the record.
      expect(
        find.byType(CodeExecutionsList, skipOffstage: false),
        findsOneWidget,
      );
    });
  });
}

/// A run's transcript relay the test drives: every watch gets what [emit]
/// sends, as a seed (the provider replaces its segments with each one).
class _Relay implements RunTranscriptRelayPort {
  final _events = StreamController<RunTranscriptEvent>.broadcast();

  /// Sends [segments] as the run's transcript now.
  void emit(List<TranscriptSegment> segments) =>
      _events.add(RunTranscriptSeed(segments));

  /// Ends every watch.
  Future<void> close() => _events.close();

  @override
  Stream<RunTranscriptEvent> watchRunTranscript(String runId) => _events.stream;

  @override
  Future<List<TranscriptSegment>> fetchRunTranscript(String runId) async =>
      const [];
}
