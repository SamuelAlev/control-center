import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/core/domain/services/active_stream_registry.dart';
import 'package:cc_domain/core/domain/value_objects/agent_skills.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_update.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/messaging/presentation/widgets/bubbles/agent_turn.dart';
import 'package:control_center/features/messaging/providers/live_turn_providers.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/github_user_avatar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

final _agent = Agent(
  id: 'agent-1',
  name: 'Architect',
  title: 'Software Architect',
  agentMdPath: '/path',
  workspaceId: 'ws-1',
  skills: AgentSkills([]),
  createdAt: DateTime(2024),
);

Message _msg({String content = 'Answer here'}) => Message(
  id: 't1',
  spaceId: 'c1',
  conversationId: 'c1',
  senderId: 'agent-1',
  senderType: SenderType.agent,
  content: content,
  messageType: MessageType.agentTurn,
  createdAt: DateTime(2024),
);

Widget _wrap(Widget child) => SingleChildScrollView(
  child: CcTheme(data: CcThemeData.light(), child: child),
);

class _TestActiveWorkspaceNotifier extends ActiveWorkspaceIdNotifier {
  _TestActiveWorkspaceNotifier(this._id);
  final String? _id;
  @override
  String? build() => _id;
}

void main() {
  testWidgets('flat turn renders name header and answer, no avatar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          agentDetailProvider('agent-1').overrideWith((ref) async => _agent),
          activeStreamRegistryProvider.overrideWithValue(
            ActiveStreamRegistry(),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: _wrap(AgentTurn(message: _msg(), codeFont: 'monospace')),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Name-only header present, answer body renders, no avatar (flat turn).
    expect(find.text('Architect'), findsOneWidget);
    expect(find.text('Answer here'), findsOneWidget);
    expect(find.byType(GitHubUserAvatar), findsNothing);
  });

  testWidgets('collapseHeader omits the name header but keeps the answer', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          agentDetailProvider('agent-1').overrideWith((ref) async => _agent),
          activeStreamRegistryProvider.overrideWithValue(
            ActiveStreamRegistry(),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: _wrap(
              AgentTurn(
                message: _msg(),
                codeFont: 'monospace',
                collapseHeader: true,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Consecutive same-sender turn: name is suppressed, answer still shows.
    expect(find.text('Architect'), findsNothing);
    expect(find.text('Answer here'), findsOneWidget);
  });

  group('pending turn', () {
    /// A turn whose row has landed but which has streamed nothing yet: empty
    /// content, `streamComplete: false`, no outcome.
    Message pending() => Message(
      id: 'run-1',
      spaceId: 'c1',
      conversationId: 'c1',
      senderId: 'agent-1',
      senderType: SenderType.agent,
      content: '',
      messageType: MessageType.agentTurn,
      metadata: const {'agentName': 'Architect', 'streamComplete': false},
      createdAt: DateTime(2024),
    );

    AgentRunLog run(String id) => AgentRunLog(
      id: id,
      agentId: 'agent-1',
      workspaceId: 'ws-1',
      conversationId: 'c1',
      startedAt: DateTime(2024),
      status: RunStatus.running,
    );

    Future<void> pumpWithRuns(
      WidgetTester tester,
      List<AgentRunLog> activeRuns, {
      Message? persisted,
      bool agentUnavailable = false,
    }) async {
      tester.view.physicalSize = const Size(800, 400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            agentDetailProvider(
              'agent-1',
            ).overrideWith((ref) async => agentUnavailable ? null : _agent),
            messageDetailProvider(
              'run-1',
            ).overrideWith((ref) => Stream.value(persisted)),
            activeStreamRegistryProvider.overrideWithValue(
              ActiveStreamRegistry(),
            ),
            activeWorkspaceIdProvider.overrideWith(
              () => _TestActiveWorkspaceNotifier('ws-1'),
            ),
            conversationActiveRunsProvider((
              workspaceId: 'ws-1',
              conversationId: 'c1',
            )).overrideWith((ref) => Stream.value(activeRuns)),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: _wrap(AgentTurn(message: pending(), codeFont: 'monospace')),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('shows the working line while its run is still open', (
      tester,
    ) async {
      // The relay stays silent until the first segment, so `isLive` is false
      // here. Without the run-log fallback the body collapsed to nothing and
      // the turn read as a bare name + timestamp.
      await pumpWithRuns(tester, [run('run-1')]);

      expect(find.text('Thinking…'), findsOneWidget);
    });

    testWidgets('stays blank when no run is open for it', (tester) async {
      // A turn stranded by a server restart keeps `streamComplete: false`
      // forever; it must not shimmer "Thinking…" for eternity.
      await pumpWithRuns(tester, const []);

      expect(find.text('Thinking…'), findsNothing);
    });

    testWidgets('another agent\'s open run does not make this turn pending', (
      tester,
    ) async {
      // A run log's id IS its own turn's message id, so a different run in the
      // same conversation must not light this bubble up.
      await pumpWithRuns(tester, [run('some-other-run')]);

      expect(find.text('Thinking…'), findsNothing);
    });

    testWidgets('recovers a cached placeholder after the run has ended', (
      tester,
    ) async {
      await pumpWithRuns(
        tester,
        const [],
        agentUnavailable: true,
        persisted: Message(
          id: 'run-1',
          spaceId: 'c1',
          conversationId: 'c1',
          senderId: 'agent-1',
          senderType: SenderType.agent,
          content: 'I need your answer before changing the older tests.',
          messageType: MessageType.agentTurn,
          createdAt: DateTime(2024),
          metadata: {
            'agentName': 'Architect',
            'streamComplete': true,
            'outcome': 'interrupted',
            'segments': encodeTranscript([
              TextSegment(
                text: 'I need your answer before changing the older tests.',
                startedAt: DateTime(2024),
                durationMs: 10,
              ),
            ]),
          },
        ),
      );

      expect(
        find.textContaining('I need your answer', findRichText: true),
        findsWidgets,
      );
      expect(find.text('Architect'), findsOneWidget);
      expect(find.text('agen'), findsNothing);
      expect(find.text('Thinking…'), findsNothing);
    });
  });

  testWidgets('completion replaces a watched unfinished detail', (
    tester,
  ) async {
    final unfinished = _msg(content: 'Partial answer').copyWith(
      metadata: const {'streamComplete': false, 'segments_elided': true},
    );
    final listed = ValueNotifier(unfinished);
    addTearDown(listed.dispose);
    var detail = unfinished;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          agentDetailProvider('agent-1').overrideWith((ref) async => _agent),
          activeStreamRegistryProvider.overrideWithValue(
            ActiveStreamRegistry(),
          ),
          messageDetailProvider(
            't1',
          ).overrideWith((ref) => Stream.value(detail)),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: _wrap(
              ValueListenableBuilder<Message>(
                valueListenable: listed,
                builder: (context, message, _) =>
                    AgentTurn(message: message, codeFont: 'monospace'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Partial answer', findRichText: true), findsOneWidget);

    detail = unfinished.copyWith(
      content: 'Final answer',
      metadata: {
        'streamComplete': true,
        'segments': encodeTranscript([
          TextSegment(
            text: 'Final transcript after completion',
            startedAt: DateTime(2024),
            durationMs: 10,
          ),
        ]),
      },
    );
    // Rebuild below ProviderScope, as a feed emission does. Re-pumping the
    // entire app would let the scope be dirtied during its own rebuild.
    listed.value = detail.copyWith(
      metadata: const {'streamComplete': true, 'segments_elided': true},
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(
      find.text('Final transcript after completion', findRichText: true),
      findsOneWidget,
    );
    expect(find.text('Partial answer', findRichText: true), findsNothing);
  });

  testWidgets('live text survives list flushes and font changes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final registry = ActiveStreamRegistry();
    final started = DateTime.utc(2024);
    registry.register('t1', spaceId: 'c1');
    registry.apply(
      't1',
      SegmentOpened(0, TextSegment(text: 'Hel', startedAt: started)),
    );
    addTearDown(() async {
      if (registry.isActive('t1')) {
        await registry.unregister('t1');
      }
    });
    final host = GlobalKey<_LiveFlushHostState>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          agentDetailProvider('agent-1').overrideWith((ref) async => _agent),
          activeStreamRegistryProvider.overrideWithValue(registry),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: _wrap(_LiveFlushHost(key: host))),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.textContaining('Hel', findRichText: true), findsWidgets);

    // The feed row's stored text moved on. The open transcript did not.
    host.currentState!.show('Hello stored by the flush');
    await tester.pump();
    expect(find.textContaining('Hel', findRichText: true), findsWidgets);

    host.currentState!.show('Hello stored by the flush', font: 'serif');
    await tester.pump();
    expect(find.textContaining('Hel', findRichText: true), findsWidgets);
  });

  testWidgets('a persisted turn displays updated text on the same row', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final host = GlobalKey<_LiveFlushHostState>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          agentDetailProvider('agent-1').overrideWith((ref) async => _agent),
          activeStreamRegistryProvider.overrideWithValue(
            ActiveStreamRegistry(),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: _wrap(_LiveFlushHost(key: host))),
        ),
      ),
    );
    await tester.pump();

    expect(find.textContaining('Hel', findRichText: true), findsWidgets);

    host.currentState!.show('Hello, edited');
    await tester.pump();
    expect(
      find.textContaining('Hello, edited', findRichText: true),
      findsWidgets,
    );
  });
}

class _LiveFlushHost extends StatefulWidget {
  const _LiveFlushHost({super.key});

  @override
  State<_LiveFlushHost> createState() => _LiveFlushHostState();
}

class _LiveFlushHostState extends State<_LiveFlushHost> {
  String content = 'Hel';
  String font = 'monospace';

  void show(String next, {String? font}) {
    setState(() {
      content = next;
      if (font != null) {
        this.font = font;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AgentTurn(
      message: Message(
        id: 't1',
        spaceId: 'c1',
        conversationId: 'c1',
        senderId: 'agent-1',
        senderType: SenderType.agent,
        content: content,
        messageType: MessageType.agentTurn,
        metadata: const {'agentName': 'Architect', 'streamComplete': false},
        createdAt: DateTime(2024),
      ),
      codeFont: font,
    );
  }
}
