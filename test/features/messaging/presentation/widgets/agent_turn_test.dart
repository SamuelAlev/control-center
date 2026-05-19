import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/entities/channel_message.dart';
import 'package:cc_domain/core/domain/value_objects/agent_skills.dart';
import 'package:cc_infra/src/messaging/active_stream_registry.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_bubble/agent_turn.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/github_user_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _agent = Agent(
  id: 'agent-1',
  name: 'Architect',
  title: 'Software Architect',
  agentMdPath: '/path',
  workspaceId: 'ws-1',
  skills: AgentSkills([]),
  createdAt: DateTime(2024),
);

ChannelMessage _msg({String content = 'Answer here'}) => ChannelMessage(
      id: 't1',
      channelId: 'c1',
      senderId: 'agent-1',
      senderType: ChannelSenderType.agent,
      content: content,
      messageType: ChannelMessageType.agentTurn,
      createdAt: DateTime(2024),
    );

Widget _wrap(Widget child) =>
    SingleChildScrollView(child: CcTheme(data: CcThemeData.light(), child: child));

void main() {
  testWidgets('flat turn renders name header and answer, no avatar',
      (tester) async {
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
          activeStreamRegistryProvider
              .overrideWithValue(ActiveStreamRegistry()),
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

  testWidgets('collapseHeader omits the name header but keeps the answer',
      (tester) async {
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
          activeStreamRegistryProvider
              .overrideWithValue(ActiveStreamRegistry()),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: _wrap(AgentTurn(
              message: _msg(),
              codeFont: 'monospace',
              collapseHeader: true,
            )),
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
}
