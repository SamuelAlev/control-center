import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/value_objects/agent_skills.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/core/domain/value_objects/principal.dart';
import 'package:cc_domain/features/messaging/domain/entities/channel_participant.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/messaging/presentation/widgets/mode_enforcement_badge.dart';
import 'package:control_center/features/messaging/providers/channel_adapter_enforcement_provider.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/settings/providers/adapter_preferences_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
// `flutter_riverpod` does not re-export `Override`; `misc.dart` is its public
// home in riverpod 3.
import 'package:riverpod/misc.dart' show Override;

const _workspaceId = 'ws-1';
const _channelId = 'ch-1';

class _FakeActiveWorkspaceId extends ActiveWorkspaceIdNotifier {
  @override
  String? build() => _workspaceId;
}

class _FakeDefaultChatAdapter extends DefaultChatAdapterNotifier {
  _FakeDefaultChatAdapter(this._id);
  final String? _id;
  @override
  String? build() => _id;
}

Agent _agent(String id, String? adapterId) => Agent(
  id: id,
  name: id,
  title: 'Dev',
  agentMdPath: '.kilo/$id.md',
  workspaceId: _workspaceId,
  skills: AgentSkills(const []),
  adapterId: adapterId,
  createdAt: DateTime.utc(2026),
);

ChannelParticipant _participant(String agentId) => ChannelParticipant(
  id: 'p-$agentId',
  channelId: _channelId,
  principalId: agentId,
  participantType: PrincipalType.agent,
  role: 'member',
  joinedAt: DateTime.utc(2026),
);

Widget _wrap(Widget child) {
  return CcTheme(
    data: CcThemeData.light(),
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    ),
  );
}

List<Override> _overrides({
  required List<Agent> agents,
  required List<ChannelParticipant> participants,
  String? defaultAdapterId,
}) => [
  activeWorkspaceIdProvider.overrideWith(_FakeActiveWorkspaceId.new),
  defaultChatAdapterProvider.overrideWith(
    () => _FakeDefaultChatAdapter(defaultAdapterId),
  ),
  workspaceAgentsProvider(
    _workspaceId,
  ).overrideWith((ref) => Stream.value(agents)),
  channelParticipantsProvider(
    _channelId,
  ).overrideWith((ref) => Stream.value(participants)),
];

Future<void> _pumpBadge(
  WidgetTester tester, {
  required Mode mode,
  required List<Override> overrides,
}) async {
  tester.view.physicalSize = const Size(600, 300);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: _wrap(
        ModeEnforcementBadge(channelId: _channelId, currentMode: mode),
      ),
    ),
  );
  await tester.pump();
}

/// A container whose participant and agent streams have already delivered, so a
/// synchronous read sees real data rather than the loading state.
Future<ProviderContainer> _primed({
  required List<Agent> agents,
  required List<ChannelParticipant> participants,
  String? defaultAdapterId,
}) async {
  final container = ProviderContainer(
    overrides: _overrides(
      agents: agents,
      participants: participants,
      defaultAdapterId: defaultAdapterId,
    ),
  );
  addTearDown(container.dispose);
  // Both sources are autoDispose, so a bare `read(...future)` would tear the
  // provider down before its stream emitted. Hold the subscriptions open for the
  // life of the test instead.
  final subscriptions = [
    container.listen(channelParticipantsProvider(_channelId), (_, _) {}),
    container.listen(workspaceAgentsProvider(_workspaceId), (_, _) {}),
  ];
  addTearDown(() {
    for (final s in subscriptions) {
      s.close();
    }
  });
  await container.read(channelParticipantsProvider(_channelId).future);
  await container.read(workspaceAgentsProvider(_workspaceId).future);
  return container;
}

void main() {
  group('channelAdapterEnforcementProvider', () {
    test("resolves the agent's own adapter", () async {
      final container = await _primed(
        agents: [_agent('a1', 'opencode')],
        participants: [_participant('a1')],
        defaultAdapterId: 'cc-harness',
      );

      final resolved = container.read(
        channelAdapterEnforcementProvider(_channelId),
      );
      // The agent's own adapterId wins over the configured default.
      expect(resolved?.adapter.id, 'opencode');
      expect(resolved?.enforcement.enforcesModeGuarantees, isFalse);
    });

    test('falls back to the default adapter for an unknown agent', () async {
      final container = await _primed(
        agents: const [],
        participants: [_participant('ghost')],
        defaultAdapterId: 'cc-harness',
      );

      final resolved = container.read(
        channelAdapterEnforcementProvider(_channelId),
      );
      expect(resolved?.adapter.id, 'cc-harness');
      expect(resolved?.enforcement.enforcesModeGuarantees, isTrue);
    });

    test('reports the weakest adapter when agents disagree', () async {
      // A fully-enforced peer must never mask a sandbox-only one.
      final container = await _primed(
        agents: [_agent('a1', 'cc-harness'), _agent('a2', 'gemini')],
        participants: [_participant('a1'), _participant('a2')],
      );

      final resolved = container.read(
        channelAdapterEnforcementProvider(_channelId),
      );
      expect(resolved?.adapter.id, 'gemini');
      expect(resolved?.enforcement.enforcesModeGuarantees, isFalse);
    });

    test('is null when nothing resolves', () async {
      // Unknown, not "fine" — the badge must stay silent rather than reassure.
      final container = await _primed(agents: const [], participants: const []);

      expect(
        container.read(channelAdapterEnforcementProvider(_channelId)),
        isNull,
      );
    });
  });

  group('ModeEnforcementBadge', () {
    testWidgets('warns in plan mode on a sandbox-only adapter', (tester) async {
      await _pumpBadge(
        tester,
        mode: Mode.plan,
        overrides: _overrides(
          agents: const [],
          participants: const [],
          defaultAdapterId: 'gemini',
        ),
      );

      expect(find.text('Degraded'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is CcTooltip &&
              (w.message ?? '').contains('relies on the sandbox only') &&
              w.message!.contains('Gemini CLI') &&
              w.message!.contains('Plan'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('stays silent in chat mode', (tester) async {
      // Chat mode promises no restriction, so there is no promise to walk back.
      await _pumpBadge(
        tester,
        mode: Mode.chat,
        overrides: _overrides(
          agents: const [],
          participants: const [],
          defaultAdapterId: 'gemini',
        ),
      );

      expect(find.text('Degraded'), findsNothing);
    });

    testWidgets('stays silent on the fully-enforcing harness', (tester) async {
      await _pumpBadge(
        tester,
        mode: Mode.plan,
        overrides: _overrides(
          agents: const [],
          participants: const [],
          defaultAdapterId: 'cc-harness',
        ),
      );

      expect(find.text('Degraded'), findsNothing);
    });

    testWidgets('stays silent while the adapter is unresolved', (tester) async {
      await _pumpBadge(
        tester,
        mode: Mode.plan,
        overrides: _overrides(agents: const [], participants: const []),
      );

      expect(find.text('Degraded'), findsNothing);
    });

    testWidgets('warns in orchestrate mode too', (tester) async {
      await _pumpBadge(
        tester,
        mode: Mode.orchestrate,
        overrides: _overrides(
          agents: const [],
          participants: const [],
          defaultAdapterId: 'claude-code',
        ),
      );

      expect(find.text('Degraded'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) => w is CcTooltip && (w.message ?? '').contains('Claude Code'),
        ),
        findsOneWidget,
      );
    });
  });
}
