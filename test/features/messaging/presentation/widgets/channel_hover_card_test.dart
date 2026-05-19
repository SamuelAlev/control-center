import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/value_objects/agent_skills.dart';
import 'package:cc_domain/core/domain/value_objects/principal.dart';
import 'package:cc_domain/features/agents/domain/value_objects/agent_live_state.dart';
import 'package:cc_domain/features/dispatch/domain/context/context_window_usage.dart';
import 'package:cc_domain/features/messaging/domain/entities/channel.dart';
import 'package:cc_domain/features/messaging/domain/entities/channel_participant.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/channel_provisioning_status.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_hover_card.dart';
import 'package:control_center/features/messaging/presentation/widgets/conversations_sidebar_section.dart';
import 'package:control_center/features/messaging/providers/channel_activity_summary_provider.dart';
import 'package:control_center/features/messaging/providers/context_usage_provider.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod/src/framework.dart' show Override;

const _workspaceId = 'ws-1';
const _channelId = 'ch-1';

class _ActiveWorkspaceIdNotifier extends ActiveWorkspaceIdNotifier {
  @override
  String? build() => _workspaceId;
}

Channel _channel({
  ChannelProvisioningStatus status = ChannelProvisioningStatus.ready,
}) => Channel(
  id: _channelId,
  name: 'tete',
  workspaceId: _workspaceId,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
  provisioningStatus: status,
);

Agent _agent(String id, String name) => Agent(
  id: id,
  name: name,
  title: '$name agent',
  agentMdPath: '/agents/$id/AGENTS.md',
  workspaceId: _workspaceId,
  skills: AgentSkills(const []),
  createdAt: DateTime(2026),
);

ChannelLiveRun _run({
  required String runId,
  String agentId = 'architect',
  String? summary,
  AgentLiveState state = AgentLiveState.running,
  Duration ago = const Duration(minutes: 2, seconds: 3),
  List<ChannelLiveRun> children = const [],
}) => ChannelLiveRun(
  runId: runId,
  agentId: agentId,
  startedAt: DateTime.now().subtract(ago),
  state: state,
  summary: summary,
  children: children,
);

ChannelActivitySummary _summary({
  List<ChannelLiveRun> liveRuns = const [],
  DateTime? startedAt,
  int totalTokens = 412000,
  int costCents = 124,
  int runCount = 3,
  DateTime? lastActivityAt,
}) => ChannelActivitySummary(
  liveRuns: liveRuns,
  startedAt: startedAt,
  totalTokens: totalTokens,
  costCents: costCents,
  runCount: runCount,
  lastActivityAt: lastActivityAt,
);

late AppPreferences prefs;

/// Overrides every read the flyout (and the row hosting it) makes, so nothing
/// reaches for DB/RPC infrastructure.
List<Override> _overrides({
  required ChannelActivitySummary summary,
  bool needsInput = false,
  List<Agent> agents = const [],
  List<ChannelParticipant> participants = const [],
  ContextWindowUsage usage = const ContextWindowUsage(
    usedTokens: 145000,
    windowTokens: 200000,
  ),
  List<Channel> channels = const [],
}) => [
  activeWorkspaceIdProvider.overrideWith(_ActiveWorkspaceIdNotifier.new),
  appPreferencesProvider.overrideWithValue(prefs),
  workspacesProvider.overrideWith((ref) => Stream.value(const [])),
  workspaceVisibleChannelsProvider(_workspaceId).overrideWithValue(channels),
  workspaceAgentsProvider(
    _workspaceId,
  ).overrideWith((ref) => Stream.value(agents)),
  channelActivitySummaryProvider((
    workspaceId: _workspaceId,
    conversationId: _channelId,
  )).overrideWithValue(summary),
  channelNeedsInputProvider(_channelId).overrideWithValue(needsInput),
  channelStatusProvider(_channelId).overrideWithValue(ChannelStatus.idle),
  channelUnreadProvider(_channelId).overrideWithValue(false),
  channelPrsProvider(_channelId).overrideWithValue(const []),
  channelParticipantsProvider(
    _channelId,
  ).overrideWith((ref) => Stream.value(participants)),
  for (final id in ['architect', 'reviewer', 'subagent'])
    conversationContextUsageProvider((
      channelId: _channelId,
      agentId: id,
    )).overrideWithValue(usage),
];

Widget _hostCard({
  required List<Override> overrides,
  Channel? channel,
  void Function(ChannelLiveRun run, String label)? onOpenRun,
  VoidCallback? onOpenChannel,
}) => ProviderScope(
  overrides: overrides,
  child: CcTheme(
    data: CcThemeData.light(),
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: ChannelHoverCard(
            channel: channel ?? _channel(),
            workspaceId: _workspaceId,
            onOpenChannel: onOpenChannel ?? () {},
            onOpenRun: onOpenRun ?? (_, _) {},
          ),
        ),
      ),
    ),
  ),
);

/// Hosts the real sidebar section at a channels location, so the hover wiring
/// (dwell, bridge, close grace) is exercised end to end.
Widget _hostSidebar(List<Override> overrides) => ProviderScope(
  overrides: overrides,
  child: CcTheme(
    data: CcThemeData.light(),
    child: MaterialApp.router(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: GoRouter(
        initialLocation: channelsRoute(_workspaceId),
        routes: [
          GoRoute(
            path: '/workspaces/:workspaceId/channels',
            builder: (_, _) => const Scaffold(
              body: SizedBox(width: 248, child: ConversationsSidebarSection()),
            ),
            routes: [
              GoRoute(
                path: ':channelId',
                builder: (_, _) => const Scaffold(body: Text('channel')),
              ),
            ],
          ),
        ],
      ),
    ),
  ),
);

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    prefs = AppPreferences.inMemory();
  });

  group('ChannelHoverCard', () {
    testWidgets('names the channel and reports it as running', (tester) async {
      await tester.pumpWidget(
        _hostCard(
          overrides: _overrides(
            summary: _summary(
              liveRuns: [_run(runId: 'r-1')],
              startedAt: DateTime.now().subtract(const Duration(minutes: 4)),
            ),
            agents: [_agent('architect', 'Architect')],
          ),
        ),
      );
      await tester.pump();

      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      expect(find.text('tete'), findsOneWidget);
      expect(find.text(l10n.running), findsOneWidget);
      expect(find.text('Architect'), findsOneWidget);
      // "1 agent running", straight from the live-run count.
      expect(find.textContaining(l10n.agentsRunningCount(1)), findsOneWidget);
    });

    testWidgets('lists live subagents beneath their agent with task labels', (
      tester,
    ) async {
      await tester.pumpWidget(
        _hostCard(
          overrides: _overrides(
            summary: _summary(
              liveRuns: [
                _run(
                  runId: 'r-1',
                  children: [
                    _run(runId: 'k-1', summary: 'audit diff tree'),
                    _run(runId: 'k-2', summary: 'write tests'),
                  ],
                ),
              ],
              startedAt: DateTime.now().subtract(const Duration(minutes: 4)),
            ),
            agents: [_agent('architect', 'Architect')],
          ),
        ),
      );
      await tester.pump();

      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      expect(find.text('audit diff tree'), findsOneWidget);
      expect(find.text('write tests'), findsOneWidget);
      expect(
        find.textContaining(l10n.subagentsRunningCount(2)),
        findsOneWidget,
      );
    });

    testWidgets('shows one context meter per live agent, not one per channel', (
      tester,
    ) async {
      await tester.pumpWidget(
        _hostCard(
          overrides: _overrides(
            summary: _summary(
              liveRuns: [
                _run(runId: 'r-1'),
                _run(runId: 'r-2', agentId: 'reviewer'),
              ],
              startedAt: DateTime.now(),
            ),
            agents: [
              _agent('architect', 'Architect'),
              _agent('reviewer', 'Reviewer'),
            ],
          ),
        ),
      );
      await tester.pump();

      expect(find.text('145k / 200k'), findsNWidgets(2));
    });

    testWidgets('an unknown context window renders no meter at all', (
      tester,
    ) async {
      await tester.pumpWidget(
        _hostCard(
          overrides: _overrides(
            summary: _summary(
              liveRuns: [_run(runId: 'r-1')],
              startedAt: DateTime.now(),
            ),
            agents: [_agent('architect', 'Architect')],
            usage: ContextWindowUsage.unknown,
          ),
        ),
      );
      await tester.pump();

      expect(find.textContaining(' / '), findsNothing);
    });

    testWidgets('an idle channel shows its roster and last activity', (
      tester,
    ) async {
      await tester.pumpWidget(
        _hostCard(
          overrides: _overrides(
            summary: _summary(
              lastActivityAt: DateTime.now().subtract(
                const Duration(minutes: 12),
              ),
            ),
            agents: [
              _agent('architect', 'Architect'),
              _agent('reviewer', 'Reviewer'),
            ],
            participants: [
              ChannelParticipant(
                id: 'p-1',
                channelId: _channelId,
                principalId: 'architect',
                participantType: PrincipalType.agent,
                role: 'member',
                joinedAt: DateTime(2026),
              ),
              ChannelParticipant(
                id: 'p-2',
                channelId: _channelId,
                principalId: 'reviewer',
                participantType: PrincipalType.agent,
                role: 'member',
                joinedAt: DateTime(2026),
              ),
            ],
          ),
        ),
      );
      await tester.pump();

      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      expect(find.text(l10n.idle), findsOneWidget);
      expect(find.text(l10n.generalAgentsEmpty), findsOneWidget);
      expect(find.text('Architect · Reviewer'), findsOneWidget);
      expect(find.textContaining('12'), findsWidgets);
    });

    testWidgets(
      'a channel that has never run says so instead of showing zeros',
      (tester) async {
        await tester.pumpWidget(
          _hostCard(
            overrides: _overrides(
              summary: _summary(totalTokens: 0, costCents: 0, runCount: 0),
            ),
          ),
        );
        await tester.pump();

        final l10n = await AppLocalizations.delegate.load(const Locale('en'));
        expect(find.text(l10n.channelFlyoutNeverRun), findsOneWidget);
      },
    );

    testWidgets('needs-input outranks the running state in the header', (
      tester,
    ) async {
      await tester.pumpWidget(
        _hostCard(
          overrides: _overrides(
            summary: _summary(
              liveRuns: [_run(runId: 'r-1')],
              startedAt: DateTime.now(),
            ),
            needsInput: true,
            agents: [_agent('architect', 'Architect')],
          ),
        ),
      );
      await tester.pump();

      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      expect(find.text(l10n.channelFlyoutNeedsInput), findsOneWidget);
      expect(find.text(l10n.running), findsNothing);
    });

    testWidgets('a failed setup outranks everything', (tester) async {
      await tester.pumpWidget(
        _hostCard(
          channel: _channel(status: ChannelProvisioningStatus.failed),
          overrides: _overrides(summary: _summary(), needsInput: true),
        ),
      );
      await tester.pump();

      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      expect(find.text(l10n.channelFlyoutSetupFailed), findsOneWidget);
    });

    testWidgets('reports unresolvable pricing as unknown, never as free', (
      tester,
    ) async {
      await tester.pumpWidget(
        _hostCard(
          overrides: _overrides(
            summary: _summary(totalTokens: 5000, costCents: 0),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('—'), findsOneWidget);
      expect(find.text(r'$0.00'), findsNothing);
    });

    testWidgets('tapping a subagent row hands its run back', (tester) async {
      final opened = <String>[];
      await tester.pumpWidget(
        _hostCard(
          overrides: _overrides(
            summary: _summary(
              liveRuns: [
                _run(
                  runId: 'r-1',
                  children: [_run(runId: 'k-1', summary: 'write tests')],
                ),
              ],
              startedAt: DateTime.now(),
            ),
            agents: [_agent('architect', 'Architect')],
          ),
          onOpenRun: (run, label) => opened.add('${run.runId}:$label'),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('write tests'));
      await tester.pump();

      expect(opened, ['k-1:write tests']);
    });

    testWidgets('tapping the header opens the channel', (tester) async {
      var opened = 0;
      await tester.pumpWidget(
        _hostCard(
          overrides: _overrides(summary: _summary()),
          onOpenChannel: () => opened++,
        ),
      );
      await tester.pump();

      await tester.tap(find.text('tete'));
      await tester.pump();

      expect(opened, 1);
    });
  });

  group('ChannelHoverTarget', () {
    testWidgets('reveals the card after the hover dwell and hides on exit', (
      tester,
    ) async {
      await tester.pumpWidget(
        _hostSidebar(
          _overrides(
            channels: [_channel()],
            summary: _summary(
              liveRuns: [_run(runId: 'r-1')],
              startedAt: DateTime.now(),
            ),
            agents: [_agent('architect', 'Architect')],
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // The row is there; the card is not, because nothing is hovered.
      expect(find.text('tete'), findsOneWidget);
      expect(find.byType(ChannelHoverCard), findsNothing);

      final pointer = TestPointer(1, PointerDeviceKind.mouse);
      final row = tester.getCenter(find.text('tete'));
      await tester.sendEventToBinding(pointer.hover(row));
      await tester.pump();

      // Still nothing: the dwell has not elapsed, so a cursor merely passing
      // over the sidebar never opens anything.
      expect(find.byType(ChannelHoverCard), findsNothing);

      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();
      expect(find.byType(ChannelHoverCard), findsOneWidget);
      expect(find.text('Architect'), findsOneWidget);

      // Leaving closes it, but only after the grace period that lets the
      // pointer cross the gap into the card.
      await tester.sendEventToBinding(pointer.hover(const Offset(900, 20)));
      await tester.pump();
      expect(find.byType(ChannelHoverCard), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byType(ChannelHoverCard), findsNothing);
    });

    testWidgets('the card survives the pointer moving into it', (tester) async {
      await tester.pumpWidget(
        _hostSidebar(
          _overrides(
            channels: [_channel()],
            summary: _summary(
              liveRuns: [_run(runId: 'r-1')],
              startedAt: DateTime.now(),
            ),
            agents: [_agent('architect', 'Architect')],
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final pointer = TestPointer(1, PointerDeviceKind.mouse);
      await tester.sendEventToBinding(
        pointer.hover(tester.getCenter(find.text('tete'))),
      );
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();
      expect(find.byType(ChannelHoverCard), findsOneWidget);

      // Off the row, onto the card: the close is scheduled by the row's exit and
      // must be cancelled by the card's enter.
      await tester.sendEventToBinding(
        pointer.hover(tester.getCenter(find.byType(ChannelHoverCard))),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(ChannelHoverCard), findsOneWidget);
    });
  });
}
