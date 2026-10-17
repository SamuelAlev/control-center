@TestOn('browser')
library;

import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/l10n/phone_widgets_localizations.dart';
import 'package:cc_remote/l10n/remote_locales.dart';
import 'package:cc_remote/widgets/agent_transcript.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget host(
    List<ToolSegment> segments, {
    Locale locale = const Locale('en'),
  }) {
    return WidgetsApp(
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
}
