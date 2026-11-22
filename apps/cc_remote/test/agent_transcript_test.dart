@TestOn('browser')
library;

import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/l10n/phone_widgets_localizations.dart';
import 'package:cc_remote/l10n/remote_locales.dart';
import 'package:cc_remote/syntax/diff_highlighter_engine.dart' as engine;
import 'package:cc_remote/widgets/agent_transcript.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget host(
    List<TranscriptSegment> segments, {
    Locale locale = const Locale('en'),
  }) {
    return ProviderScope(
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
          child: Center(
            child: AgentTranscript(segments: segments, isLive: false),
          ),
        ),
      ),
    );
  }

  ToolSegment tool(String name, String id, {Map<String, dynamic>? inputs}) =>
      ToolSegment(
        toolName: name,
        toolCallId: id,
        inputs: inputs,
        status: ToolSegmentStatus.ok,
        startedAt: DateTime.utc(2026),
      );

  testWidgets('a lost Claude sign-in reads as a notice, not a log line', (
    tester,
  ) async {
    await tester.pumpWidget(
      host([
        ErrorSegment(
          message: '[claude] Failed to authenticate: OAuth token revoked.',
          code: ErrorSegment.authenticationErrorCode,
          source: ErrorSegment.claudeCodeSource,
          startedAt: DateTime.utc(2026),
        ),
      ]),
    );
    await tester.pump();

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.byType(CcAlert), findsOneWidget);
    expect(find.text(l10n.transcriptClaudeSignInExpiredTitle), findsOneWidget);
    expect(
      find.text('Failed to authenticate: OAuth token revoked.'),
      findsOneWidget,
    );
  });

  testWidgets('a run refused for want of a sandbox is guidance by its code', (
    tester,
  ) async {
    await tester.pumpWidget(
      host([
        ErrorSegment(
          message: 'server sentence',
          code: ErrorSegment.sandboxUnavailableCode,
          startedAt: DateTime.utc(2026),
        ),
      ]),
    );
    await tester.pump();

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.byType(CcAlert), findsOneWidget);
    expect(find.text(l10n.runSandboxUnavailableTitle), findsOneWidget);
    expect(find.text(l10n.runSandboxUnavailable), findsOneWidget);
    expect(find.text('server sentence'), findsNothing);
  });

  testWidgets('Control Center rows show readable labels, raw IDs in details', (
    tester,
  ) async {
    const todo = 'mcp__control-center__todo_read';
    const memory = 'mcp__control-center__search_memory';
    const media = 'mcp__control-center__render_media';
    await tester.pumpWidget(
      host([tool(todo, 'todo'), tool(memory, 'memory'), tool(media, 'media')]),
    );

    expect(find.text('Tasks'), findsOneWidget);
    expect(find.text('Search memory'), findsOneWidget);
    expect(find.text('Render media'), findsOneWidget);
    expect(find.text(todo), findsNothing);
    await tester.tap(find.text('Tasks'));
    await tester.pump();
    expect(find.text(todo), findsOneWidget);
    expect(
      find.ancestor(
        of: find.text(todo),
        matching: find.byType(SelectableRegion),
      ),
      findsOneWidget,
    );
  });

  testWidgets('external MCP tool gets a human name, not its protocol prefix', (
    tester,
  ) async {
    const name = 'mcp__github__create_issue';
    await tester.pumpWidget(host([tool(name, 'external')]));
    expect(find.text('Create issue'), findsOneWidget);
    expect(find.text(name), findsNothing);
    await tester.tap(find.text('Create issue'));
    await tester.pump();
    expect(find.text(name), findsOneWidget);
  });

  testWidgets('built-in script summaries remain the primary row labels', (
    tester,
  ) async {
    await tester.pumpWidget(
      host([
        tool(
          'bash',
          'shell',
          inputs: {
            'description': 'Reading project files\nwith notes',
            'command': 'pwd',
          },
        ),
        tool('read', 'read'),
      ]),
    );
    expect(find.text('Reading project files'), findsOneWidget);
    expect(find.text('Read'), findsOneWidget);
    expect(find.text('bash'), findsNothing);
    await tester.tap(find.text('Reading project files'));
    await tester.pump();
    expect(find.text('bash'), findsOneWidget);
  });

  testWidgets('localized Control Center names retain LTR raw IDs in RTL', (
    tester,
  ) async {
    const name = 'mcp__control-center__todo_read';
    await tester.pumpWidget(
      host([tool(name, 'rtl')], locale: const Locale('ar')),
    );
    final localized = AppLocalizations.of(
      tester.element(find.byType(AgentTranscript)),
    );
    expect(localized.transcriptToolTodos, isNot('Tasks'));
    expect(find.text(localized.transcriptToolTodos), findsOneWidget);
    await tester.tap(find.text(localized.transcriptToolTodos));
    await tester.pump();
    expect(find.text(name), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.text(name))),
      TextDirection.ltr,
    );
  });

  group('code mode scripts', () {
    // The script source highlights through the diff engine; tokenize on
    // the test isolate so no worker timer outlives the test.
    setUpAll(() => engine.debugTokenizeInline = true);

    ToolSegment repl({
      ToolSegmentStatus status = ToolSegmentStatus.ok,
      String outputs =
          'Script completed in 2.4 s · 2 tool calls (1 ok, 1 denied)\n42',
    }) => ToolSegment(
      toolName: 'repl',
      toolCallId: 'r1',
      inputs: const {
        'code': 'const a = 1;\nreturn a;',
        'description': 'Count the TODOs',
      },
      outputs: outputs,
      status: status,
      startedAt: DateTime.utc(2026),
    );

    ToolSegment call(
      String id,
      String description, {
      String parent = 'r1',
      ToolSegmentStatus status = ToolSegmentStatus.ok,
      String outputs = 'ok',
      String? outcome,
    }) => ToolSegment(
      toolName: 'read',
      toolCallId: id,
      inputs: {'description': description},
      outputs: outputs,
      status: status,
      startedAt: DateTime.utc(2026),
      parentToolCallId: parent,
      outcome: outcome,
    );

    testWidgets('calls fold under the script row, in order, with status', (
      tester,
    ) async {
      await tester.pumpWidget(
        host([
          repl(),
          call('r1/1', 'First call'),
          call(
            'r1/2',
            'Second call',
            status: ToolSegmentStatus.error,
            outputs: 'Denied by user.',
            // A refusal is told by its outcome, never its text.
            outcome: 'denied',
          ),
        ]),
      );
      expect(find.text('Count the TODOs'), findsOneWidget);
      expect(find.text('2 calls · 1 denied'), findsOneWidget);
      expect(find.text('First call'), findsNothing);

      await tester.tap(find.text('Count the TODOs'));
      await tester.pump();
      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('42'), findsOneWidget);
      expect(find.text('Script'), findsOneWidget);
      expect(find.text('const a = 1;'), findsNothing);
      final first = tester.getTopLeft(find.text('First call')).dy;
      final second = tester.getTopLeft(find.text('Second call')).dy;
      expect(first, lessThan(second));

      await tester.tap(find.text('Script'));
      // The grammar loads deferred; settle so its timer does not outlive
      // the test.
      await tester.pumpAndSettle();
      expect(
        find.textContaining('const a = 1;', findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets('two scripts sharing an id keep their own calls and open '
        'on their own', (tester) async {
      ToolSegment script(String description) => ToolSegment(
        toolName: 'repl',
        toolCallId: 'call_0',
        inputs: {'code': 'return 1;', 'description': description},
        outputs: 'Script completed in 1.0 s · 1 tool call (1 ok)',
        status: ToolSegmentStatus.ok,
        startedAt: DateTime.utc(2026),
      );
      await tester.pumpWidget(
        host([
          script('First script'),
          call('call_0/1', 'Benign read', parent: 'call_0'),
          script('Second script'),
          call('call_0/1', 'Destructive write', parent: 'call_0'),
        ]),
      );
      expect(find.text('1 call'), findsNWidgets(2));
      await tester.tap(find.text('Second script'));
      await tester.pump();
      // Only the second script opened, and it holds its own call.
      expect(find.text('Destructive write'), findsOneWidget);
      expect(find.text('Benign read'), findsNothing);
      expect(
        tester.getTopLeft(find.text('Destructive write')).dy,
        greaterThan(tester.getTopLeft(find.text('Second script')).dy),
      );
    });

    testWidgets('a call whose parent is not a script keeps its own row', (
      tester,
    ) async {
      await tester.pumpWidget(
        host([
          tool('read', 'call_0', inputs: const {'description': 'Plain read'}),
          call('call_0/1', 'Borrowed call', parent: 'call_0'),
        ]),
      );
      expect(find.text('Borrowed call'), findsOneWidget);
    });

    testWidgets('a call whose script is missing keeps its own row', (
      tester,
    ) async {
      await tester.pumpWidget(
        host([call('gone/1', 'Orphan call', parent: 'gone')]),
      );
      expect(find.text('Orphan call'), findsOneWidget);
    });

    testWidgets('500 calls build lazily', (tester) async {
      await tester.pumpWidget(
        host([repl(), for (var i = 1; i <= 500; i++) call('r1/$i', 'Call $i')]),
      );
      expect(find.text('500 calls'), findsOneWidget);
      await tester.tap(find.text('Count the TODOs'));
      await tester.pump();
      expect(find.text('Call 1'), findsOneWidget);
      expect(find.text('Call 500'), findsNothing);
      final built = find.textContaining(RegExp(r'^Call \d+$')).evaluate();
      expect(built.length, lessThan(60));
    });

    testWidgets('the script stays LTR in a right-to-left locale', (
      tester,
    ) async {
      await tester.pumpWidget(host([repl()], locale: const Locale('ar')));
      await tester.tap(find.text('Count the TODOs'));
      await tester.pump();
      final l10n = AppLocalizations.of(
        tester.element(find.byType(AgentTranscript)),
      );
      await tester.tap(find.text(l10n.scriptSourceLabel));
      await tester.pumpAndSettle();
      final code = find.textContaining('const a = 1;', findRichText: true);
      expect(Directionality.of(tester.element(code)), TextDirection.ltr);
    });
  });
}
