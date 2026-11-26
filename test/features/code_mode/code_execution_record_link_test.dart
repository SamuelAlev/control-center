import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_domain/features/code_mode/domain/ports/code_execution_repository.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/code_mode/presentation/widgets/code_execution_record_link.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/l10n/localizations_loader.dart';
import 'package:control_center/router/app_router.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/widgets/transcript/widgets/script_record_link.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../helpers/test_wrap.dart';
import 'code_mode_fakes.dart';

const _ws = 'ws1';

class _Ws extends ActiveWorkspaceIdNotifier {
  @override
  String? build() => _ws;
}

void main() {
  late AppLocalizations l10n;
  late FakeCodeModeRepository repo;

  setUpAll(() async {
    l10n = await appLocalizationsDelegate.load(const Locale('en'));
  });

  setUp(() => repo = FakeCodeModeRepository());

  Future<GoRouter> pump(WidgetTester tester, Widget child) async {
    final router = GoRouter(
      initialLocation: '/here',
      routes: [
        GoRoute(path: '/here', builder: (context, state) => child),
        GoRoute(
          path: codeExecutionRoute(workspaceIdParam, codeExecutionIdParam),
          builder: (context, state) =>
              Text('record ${state.pathParameters['executionId']}'),
        ),
        GoRoute(
          path: codeExecutionsRoute(workspaceIdParam),
          builder: (context, state) => const Text('list'),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeWorkspaceIdProvider.overrideWith(_Ws.new),
          codeModeRepositoryProvider.overrideWithValue(repo),
          routerProvider.overrideWithValue(router),
        ],
        child: testRouterWrap(router),
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  group('transcript row', () {
    final seg = ToolSegment(
      toolName: 'repl',
      toolCallId: 'call-3',
      inputs: const {'code': 'return 1;'},
      outputs: 'ok',
      status: ToolSegmentStatus.ok,
      startedAt: DateTime.utc(2026, 11, 17, 9, 30),
    );

    Widget row({String? runId, String? conversationId = 'conv-1'}) =>
        ScriptRecordLinkScope(
          builder: codeExecutionRecordLinkBuilder(
            workspaceId: _ws,
            runId: runId,
            conversationId: conversationId,
          ),
          child: Builder(
            builder: (context) =>
                ScriptRecordLinkScope.maybeOf(context)!(context, seg) ??
                const SizedBox.shrink(),
          ),
        );

    testWidgets('shows at once, and asks once, on press', (tester) async {
      repo.onList = (_) async => CodeExecutionPage(
        items: [codeExecution(id: 'run-1/call-3#2', toolCallId: 'call-3')],
      );
      final router = await pump(tester, row());
      // Nothing is looked up while the transcript renders.
      expect(find.text(l10n.codeExecutionOpenRecord), findsOneWidget);
      expect(repo.queries, isEmpty);

      await tester.tap(find.text(l10n.codeExecutionOpenRecord));
      await tester.pumpAndSettle();
      final query = repo.queries.single;
      expect(query.toolCallId, 'call-3');
      expect(query.conversationId, 'conv-1');
      expect(find.text('record run-1/call-3#2'), findsOneWidget);
      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        codeExecutionRoute(_ws, 'run-1/call-3#2'),
      );
    });

    testWidgets('several matches open the one nearest the row', (tester) async {
      repo.onList = (_) async => CodeExecutionPage(
        items: [
          codeExecution(
            id: 'run-1/call-3#2',
            toolCallId: 'call-3',
            startedAt: DateTime.utc(2026, 11, 17, 9, 36),
          ),
          codeExecution(
            id: 'run-1/call-3',
            toolCallId: 'call-3',
            startedAt: DateTime.utc(2026, 11, 17, 9, 30, 1),
          ),
        ],
      );
      await pump(tester, row(runId: 'run-1'));
      await tester.tap(find.text(l10n.codeExecutionOpenRecord));
      await tester.pumpAndSettle();
      expect(repo.queries.single.runId, 'run-1');
      expect(find.text('record run-1/call-3'), findsOneWidget);
    });

    testWidgets('no record opens the run\'s list instead', (tester) async {
      final router = await pump(tester, row(runId: 'run-1'));
      await tester.tap(find.text(l10n.codeExecutionOpenRecord));
      await tester.pumpAndSettle();
      expect(repo.queries, hasLength(1));
      expect(
        router.routerDelegate.currentConfiguration.uri.toString(),
        codeExecutionsRoute(_ws, runId: 'run-1'),
      );
    });

    testWidgets('a failed lookup opens the conversation\'s list', (
      tester,
    ) async {
      repo.onList = (_) async => throw Exception('offline');
      final router = await pump(tester, row());
      await tester.tap(find.text(l10n.codeExecutionOpenRecord));
      await tester.pumpAndSettle();
      expect(
        router.routerDelegate.currentConfiguration.uri.toString(),
        codeExecutionsRoute(_ws, conversationId: 'conv-1'),
      );
    });

    testWidgets('no run and no conversation, no link', (tester) async {
      await pump(tester, row(conversationId: null));
      expect(find.text(l10n.codeExecutionOpenRecord), findsNothing);
    });
  });

  group('approval origin', () {
    testWidgets('links only when the record resolves', (tester) async {
      repo.details['run-1/call-1'] = CodeExecutionDetail(
        execution: codeExecution(),
        calls: const [],
      );
      await pump(
        tester,
        const Column(
          children: [
            CodeExecutionOriginRecordLink(executionId: 'run-1/call-1'),
            CodeExecutionOriginRecordLink(executionId: 'run-1/running'),
          ],
        ),
      );
      expect(find.text(l10n.codeExecutionOpenRecord), findsOneWidget);
      await tester.tap(find.text(l10n.codeExecutionOpenRecord));
      await tester.pumpAndSettle();
      expect(find.text('record run-1/call-1'), findsOneWidget);
    });

    testWidgets('a refused record offers no link', (tester) async {
      repo.detailError = Exception('refused');
      await pump(
        tester,
        const CodeExecutionOriginRecordLink(executionId: 'run-1/call-1'),
      );
      expect(find.text(l10n.codeExecutionOpenRecord), findsNothing);
    });
  });

  testWidgets('the link text reads as a link, not a button', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester, CodeExecutionRecordLinkText(onPressed: () {}));

    final node = tester.getSemantics(find.text(l10n.codeExecutionOpenRecord));
    expect(node.label, l10n.codeExecutionOpenRecord);
    expect(node.flagsCollection.isLink, isTrue);
    expect(node.flagsCollection.isButton, isFalse);
    handle.dispose();
  });
}
