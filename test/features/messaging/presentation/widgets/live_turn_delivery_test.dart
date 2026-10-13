import 'dart:async';

import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/core/domain/services/active_stream_registry.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_update.dart';
import 'package:cc_host/src/repo_rpc/subscription_manager.dart';
import 'package:cc_host/src/repo_rpc/watch_query.dart';
import 'package:cc_infra/src/messaging/space_turn_relay.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:control_center/core/theme/font_settings.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/messaging/presentation/widgets/ask_user/ask_user_card.dart';
import 'package:control_center/features/messaging/presentation/widgets/ask_user/ask_user_summary.dart';
import 'package:control_center/features/messaging/presentation/widgets/bubbles/question_bubble.dart';
import 'package:control_center/features/messaging/presentation/widgets/bubbles/steering_bubble.dart';
import 'package:control_center/features/messaging/presentation/widgets/bubbles/transcript_flow.dart';
import 'package:control_center/features/messaging/presentation/widgets/message_feed.dart';
import 'package:control_center/features/messaging/providers/live_turn_providers.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/active_workspace.dart';
import '../../../../helpers/test_wrap.dart';

void main() {
  testWidgets(
    'live tools, answered questions and steering render without reopening',
    (tester) async {
      tester.view.physicalSize = const Size(1100, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final registry = ActiveStreamRegistry();
      final (server, channel) = InProcessRpcChannel.pair();
      final manager = SubscriptionManager(
        registry: WatchQueryRegistry([
          WatchQuery(
            name: 'messaging.watchSpaceTurns',
            isEventStream: true,
            handler: (_) => watchSpaceTurnFrames(registry, 'space'),
          ),
        ]),
        deviceId: 'device',
        userId: 'user',
        send: (frame) => unawaited(server.send(frame)),
      );
      final requests = server.incoming.listen((frame) {
        final params = (frame['params'] as Map).cast<String, dynamic>();
        final response = switch (frame['method']) {
          RpcMethods.subscribe => manager.subscribe(
            id: frame['id'],
            params: params,
          ),
          RpcMethods.unsubscribe => manager.unsubscribe(
            id: frame['id'],
            params: params,
          ),
          _ => throw StateError('Unexpected RPC: ${frame['method']}'),
        };
        unawaited(server.send(response));
      });
      final client = RemoteRpcClient(channel)
        ..activeWorkspaceId = 'ws-1'
        ..start();
      final window =
          StreamController<
            ({List<Message> messages, bool hasMore})
          >.broadcast();
      final start = DateTime.utc(2026, 10, 12, 9, 52);
      final tool = ToolSegment(
        toolName: 'Bash',
        toolCallId: 'check',
        inputs: const {
          'description': 'Typecheck and lint the changed files',
          'command': 'check',
        },
        status: ToolSegmentStatus.running,
        startedAt: start.add(const Duration(seconds: 1)),
      );
      registry.register('run', spaceId: 'space');
      registry.apply(
        'run',
        SegmentOpened(
          0,
          TextSegment(
            text: 'I will check the changes.',
            startedAt: start,
            durationMs: 10,
          ),
        ),
      );
      registry.apply('run', SegmentOpened(1, tool));
      List<TranscriptSegment> completed = const [];
      Message run({bool complete = false}) => Message(
        id: 'run',
        spaceId: 'space',
        conversationId: 'conversation',
        senderId: 'agent-1',
        senderType: SenderType.agent,
        content: '',
        messageType: MessageType.agentTurn,
        createdAt: start,
        metadata: {'streamComplete': complete, 'segments_elided': true},
      );
      Message question({required bool answered}) => Message(
        id: 'question',
        spaceId: 'space',
        conversationId: 'conversation',
        senderId: 'agent-1',
        senderType: SenderType.agent,
        content: 'Which configuration should I check?',
        messageType: MessageType.userQuestion,
        createdAt: start.add(const Duration(milliseconds: 1500)),
        metadata: {
          'answered': answered,
          'options': [
            {'label': 'Staging'},
          ],
          if (answered)
            'answer': {
              'selected': ['Staging'],
            },
        },
      );
      Message steering(String state) => Message(
        id: 'steering',
        spaceId: 'space',
        conversationId: 'conversation',
        senderId: 'user',
        senderType: SenderType.user,
        content: 'Use the staging configuration',
        messageType: MessageType.steering,
        createdAt: start.add(const Duration(seconds: 2)),
        metadata: {
          'steerState': state,
          'steerRunId': 'run',
          'steerInjectedAt': start
              .add(const Duration(seconds: 2))
              .millisecondsSinceEpoch,
        },
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeWorkspaceIdOverride(),
            spaceTurnRelayPortProvider.overrideWithValue(
              RpcMessagingRepository(client),
            ),
            spaceFeedWindowedProvider((
              spaceId: 'space',
              conversationId: 'conversation',
            )).overrideWith((ref) => window.stream),
            spaceUserLastReadAtProvider(
              'space',
            ).overrideWith((ref) => Stream.value(null)),
            codeFontFamilyProvider.overrideWith((ref) => 'monospace'),
            agentDetailProvider('agent-1').overrideWith((ref) async => null),
            messageDetailProvider('run').overrideWith(
              (ref) => Stream.value(
                Message(
                  id: 'run',
                  spaceId: 'space',
                  conversationId: 'conversation',
                  senderId: 'agent-1',
                  senderType: SenderType.agent,
                  content: '',
                  messageType: MessageType.agentTurn,
                  createdAt: start,
                  metadata: {
                    'streamComplete': completed.isNotEmpty,
                    'segments': encodeTranscript(completed),
                  },
                ),
              ),
            ),
            conversationActiveRunsProvider((
              workspaceId: 'ws-1',
              conversationId: 'conversation',
            )).overrideWith((ref) => Stream.value([])),
          ],
          child: testWrap(
            const SpaceMessageFeed(
              spaceId: 'space',
              conversationId: 'conversation',
            ),
          ),
        ),
      );
      window.add((messages: [run()], hasMore: false));
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(
        find.textContaining(
          'Typecheck and lint the changed files',
          findRichText: true,
        ),
        findsWidgets,
      );
      window.add((
        messages: [run(), question(answered: false)],
        hasMore: false,
      ));
      await tester.pump();
      await tester.pump();
      expect(find.byType(AskUserCard), findsOneWidget);
      expect(
        find.ancestor(
          of: find.byType(QuestionBubble),
          matching: find.byType(TranscriptFlow),
        ),
        findsNothing,
      );
      window.add((messages: [run(), question(answered: true)], hasMore: false));
      await tester.pump();
      await tester.pump();
      expect(find.byType(AskUserCard), findsNothing);
      expect(find.byType(AskUserSummary), findsOneWidget);
      expect(
        find.ancestor(
          of: find.byType(QuestionBubble),
          matching: find.byType(TranscriptFlow),
        ),
        findsOneWidget,
      );

      window.add((
        messages: [run(), question(answered: true), steering('queued')],
        hasMore: false,
      ));
      await tester.pump();
      expect(find.byType(SteeringBubble), findsNothing);
      window.add((
        messages: [run(), question(answered: true), steering('injected')],
        hasMore: false,
      ));
      await tester.pump();
      await tester.pump();
      expect(find.byType(SteeringBubble), findsOneWidget);

      // All of these reach the subscription manager in one burst. Losing the
      // opened event used to freeze the bubble at Bash until navigation reseeded it.
      registry.apply(
        'run',
        SegmentClosed(
          1,
          tool.copyWith(
            outputs: 'All checks passed',
            status: ToolSegmentStatus.ok,
            durationMs: 1000,
          ),
        ),
      );
      final answerAt = start.add(const Duration(seconds: 3));
      registry.apply(
        'run',
        SegmentOpened(2, TextSegment(text: '', startedAt: answerAt)),
      );
      registry.apply(
        'run',
        const SegmentDelta(2, 'The staging checks passed.'),
      );
      registry.apply(
        'run',
        SegmentClosed(
          2,
          TextSegment(
            text: 'The staging checks passed.',
            startedAt: answerAt,
            durationMs: 10,
          ),
        ),
      );
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      final answer = find.textContaining(
        'The staging checks passed.',
        findRichText: true,
      );
      expect(answer, findsWidgets);
      expect(
        tester.getTopLeft(find.byType(SteeringBubble)).dy,
        lessThan(tester.getTopLeft(answer.first).dy),
      );
      expect(find.byType(SteeringBubble), findsOneWidget);
      expect(find.byType(AskUserSummary), findsOneWidget);
      expect(
        tester.getBottomLeft(find.byType(AskUserSummary)).dy,
        lessThan(tester.getTopLeft(find.byType(SteeringBubble)).dy),
      );

      completed = registry.snapshot('run')!;
      registry.apply('run', const TurnFinished(2, TurnOutcome.completed));
      await registry.unregister('run');
      window.add((
        messages: [
          run(complete: true),
          question(answered: true),
          steering('injected'),
        ],
        hasMore: false,
      ));
      await tester.pumpAndSettle();
      expect(answer, findsWidgets);
      expect(find.byType(SteeringBubble), findsOneWidget);
      expect(find.byType(AskUserSummary), findsOneWidget);
      expect(
        tester.getBottomLeft(find.byType(AskUserSummary)).dy,
        lessThan(tester.getTopLeft(answer.first).dy),
      );
      expect(
        tester.getTopLeft(find.byType(SteeringBubble)).dy,
        lessThan(tester.getTopLeft(answer.first).dy),
      );

      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      // RPC teardown completes on the real event loop, not the widget clock.
      await tester.runAsync(() async {
        await manager.dispose();
        await client.close();
        await requests.cancel();
        await server.close();
        await window.close();
      });
    },
    timeout: const Timeout(Duration(seconds: 45)),
  );
}
