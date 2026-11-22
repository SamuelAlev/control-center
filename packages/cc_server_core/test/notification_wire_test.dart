import 'dart:io';

import 'package:cc_domain/core/domain/events/agent_events.dart';
import 'package:cc_domain/core/domain/events/digest_events.dart';
import 'package:cc_domain/core/domain/events/learning_events.dart';
import 'package:cc_domain/core/domain/events/messaging_events.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/agent_goal_status.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_hold.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_rule_values.dart';
import 'package:cc_domain/features/notifications/domain/value_objects/notification_kind.dart';
import 'package:cc_server_core/src/notification_wire.dart';
import 'package:cc_server_core/src/push/web_push_service.dart'
    show isQuietPush;
import 'package:test/test.dart';

void main() {
  group('messageReceivedFrame', () {
    MessageReceived agentReply({String? conversationId}) => MessageReceived(
      spaceId: 'sp-1',
      messageId: 'm-1',
      senderName: 'Bot',
      contentPreview: 'done',
      isAgentMessage: true,
      workspaceId: 'ws-1',
      conversationId: conversationId,
      occurredAt: DateTime(2026),
    );

    // A space holds parallel conversations: without the conversation the
    // client can only deep-link to the space, which opens its standing one.
    test('carries the conversation the message was posted in', () {
      final frame = messageReceivedFrame(agentReply(conversationId: 'conv-2'));
      expect(frame!.params['space_id'], 'sp-1');
      expect(frame.params['conversation_id'], 'conv-2');
    });

    test('omits conversation_id when the publisher had none', () {
      final frame = messageReceivedFrame(agentReply());
      expect(frame!.params, isNot(contains('conversation_id')));
    });
  });

  group('agentAwaitingInputFrame', () {
    test('omits what the wait did not know', () {
      final frame = agentAwaitingInputFrame(
        AgentAwaitingInput(
          workspaceId: 'ws-1',
          waitId: 'wait-1',
          kind: AgentInputKind.approval,
          summary: 'Push to main',
          occurredAt: DateTime(2026),
        ),
      );
      expect(frame.method, 'notifications/agent_awaiting_input');
      expect(frame.params, {
        'workspace_id': 'ws-1',
        'wait_id': 'wait-1',
        'kind': 'approval',
        'summary': 'Push to main',
        'notification_kind': 'question',
        'quiet': false,
      });
    });
  });

  group('goalSettledFrame', () {
    GoalSettled settled(
      AgentGoalStatus status, {
      GoalHold? hold,
      String? summary,
      String? requestedByUserId = 'user-1',
    }) => GoalSettled(
      goalId: 'goal-1',
      workspaceId: 'ws-1',
      spaceId: 'space-1',
      conversationId: 'conv-1',
      agentId: 'agent-1',
      status: status,
      hold: hold,
      summary: summary,
      requestedByUserId: requestedByUserId,
      occurredAt: DateTime(2026),
    );

    test('an outcome is a notify frame for the person who started the goal', () {
      final frame = goalSettledFrame(
        settled(AgentGoalStatus.completed, summary: 'Shipped.'),
      );
      expect(frame.method, 'notifications/goal_settled');
      expect(frame.params, {
        'workspace_id': 'ws-1',
        'goal_id': 'goal-1',
        'space_id': 'space-1',
        'conversation_id': 'conv-1',
        'agent_id': 'agent-1',
        'status': 'completed',
        'summary': 'Shipped.',
        'for_user_id': 'user-1',
        'notification_kind': 'notify',
        'quiet': true,
      });
    });

    for (final status in [
      AgentGoalStatus.completed,
      AgentGoalStatus.failed,
      AgentGoalStatus.cancelled,
      AgentGoalStatus.budgetExhausted,
    ]) {
      test('${status.wire} is a notify frame', () {
        final frame = goalSettledFrame(settled(status));
        expect(frame.params['status'], status.wire);
        expect(frame.params['notification_kind'], 'notify');
      });
    }

    test('a pause that needs a person is a review frame with its hold', () {
      final frame = goalSettledFrame(
        settled(AgentGoalStatus.paused, hold: GoalHold.needsReview),
      );
      expect(frame.params['status'], 'paused');
      expect(frame.params['hold'], 'needs_review');
      expect(frame.params['notification_kind'], 'review');
    });

    test('omits what the goal did not carry', () {
      final frame = goalSettledFrame(
        settled(AgentGoalStatus.failed, requestedByUserId: null),
      );
      expect(frame.params, isNot(contains('summary')));
      expect(frame.params, isNot(contains('hold')));
      expect(frame.params, isNot(contains('for_user_id')));
    });
  });

  group('wakeRuleEndedFrame', () {
    WakeRuleEnded ended(WakeRuleEndReason reason, {String? person = 'u-1'}) =>
        WakeRuleEnded(
          ruleId: 'rule-1',
          workspaceId: 'ws-1',
          spaceId: 'sp-1',
          conversationId: 'conv-1',
          agentId: 'agent-1',
          reason: reason,
          requestedByUserId: person,
          occurredAt: DateTime.utc(2026),
        );

    test('a rule that ran out is a notify frame for its person', () {
      final frame = wakeRuleEndedFrame(ended(WakeRuleEndReason.runCap))!;
      expect(frame.method, 'notifications/wake_rule_ended');
      expect(frame.params, {
        'workspace_id': 'ws-1',
        'rule_id': 'rule-1',
        'space_id': 'sp-1',
        'conversation_id': 'conv-1',
        'agent_id': 'agent-1',
        'reason': WakeRuleEndReason.runCap.wire,
        'for_user_id': 'u-1',
        'notification_kind': 'notify',
        'quiet': true,
      });
    });

    test('only the ends nobody chose, and only a person\'s rule', () {
      for (final reason in WakeRuleEndReason.values) {
        expect(
          wakeRuleEndedFrame(ended(reason)) != null,
          notifiedWakeRuleEnds.contains(reason),
          reason: reason.name,
        );
      }
      expect(
        wakeRuleEndedFrame(ended(WakeRuleEndReason.expired, person: null)),
        isNull,
      );
      expect(
        wakeRuleEndedFrame(ended(WakeRuleEndReason.cancelled)),
        isNull,
      );
    });
  });

  group('waitingDigestFrame', () {
    test('a review frame for one person, listing what waits', () {
      final frame = waitingDigestFrame(
        WaitingDigest(
          workspaceId: 'ws-1',
          forUserId: 'u-1',
          day: '2026-11-20',
          items: [
            WaitingDigestItem(
              type: WaitingDigestItemType.goalReview,
              id: 'goal-1',
              summary: 'Keep the changelog current',
              spaceId: 'sp-1',
              conversationId: 'conv-1',
              agentId: 'agent-1',
            ),
            WaitingDigestItem(
              type: WaitingDigestItemType.heldWake,
              id: 'wake-1',
              summary: 'nightly',
            ),
            WaitingDigestItem(
              type: WaitingDigestItemType.request,
              id: 'cf-1',
              summary: 'Push to main',
              conversationId: 'conv-2',
              expiresAt: DateTime.utc(2026, 11, 22, 18, 30),
            ),
          ],
          occurredAt: DateTime.utc(2026, 11, 20, 8),
        ),
      );
      expect(frame.method, 'notifications/waiting_digest');
      expect(frame.params, {
        'workspace_id': 'ws-1',
        'for_user_id': 'u-1',
        'day': '2026-11-20',
        'count': 3,
        'items': [
          {
            'type': 'goal_review',
            'id': 'goal-1',
            'summary': 'Keep the changelog current',
            'space_id': 'sp-1',
            'conversation_id': 'conv-1',
            'agent_id': 'agent-1',
          },
          {'type': 'held_wake', 'id': 'wake-1', 'summary': 'nightly'},
          {
            'type': 'request',
            'id': 'cf-1',
            'summary': 'Push to main',
            'conversation_id': 'conv-2',
            'expires_at': '2026-11-22T18:30:00.000Z',
          },
        ],
        'notification_kind': 'review',
        'quiet': false,
      });
    });
  });

  group('learning and pipeline frames', () {
    test('improvement_proposed: a review for the goal\'s person', () {
      final frame = improvementProposedFrame(
        ImprovementProposed(
          workspaceId: 'ws-1',
          spaceId: 'space-1',
          conversationId: 'conv-1',
          agentId: 'agent-1',
          goalId: 'goal-1',
          proposalIds: const ['p-1', 'p-2'],
          requestedByUserId: 'user-1',
          occurredAt: DateTime.utc(2026, 11, 19),
        ),
      );
      expect(frame.method, 'notifications/improvement_proposed');
      expect(frame.params, {
        'workspace_id': 'ws-1',
        'space_id': 'space-1',
        'conversation_id': 'conv-1',
        'agent_id': 'agent-1',
        'goal_id': 'goal-1',
        'proposal_ids': ['p-1', 'p-2'],
        'count': 2,
        'for_user_id': 'user-1',
        'notification_kind': 'review',
        'quiet': false,
      });
      final bot = improvementProposedFrame(
        ImprovementProposed(
          workspaceId: 'ws-1',
          spaceId: 'space-1',
          conversationId: 'conv-1',
          agentId: 'agent-1',
          goalId: null,
          proposalIds: const ['p-1'],
          requestedByUserId: null,
          occurredAt: DateTime.utc(2026, 11, 19),
        ),
      );
      expect(bot.params.containsKey('goal_id'), isFalse);
      expect(bot.params.containsKey('for_user_id'), isFalse);
    });

    test('pipeline_run_held: a review for the run\'s requester', () {
      final frame = pipelineRunHeldFrame(
        PipelineRunHeld(
          workspaceId: 'ws-1',
          pipelineRunId: 'run-1',
          orchestrationId: 'orch-1',
          spaceId: 'space-1',
          reason: 'orchestration_budget',
          capMicros: 5000000,
          spentMicros: 5120000,
          requestedByUserId: 'user-1',
          occurredAt: DateTime.utc(2026, 11, 19),
        ),
      );
      expect(frame.method, 'notifications/pipeline_run_held');
      expect(frame.params, {
        'workspace_id': 'ws-1',
        'pipeline_run_id': 'run-1',
        'orchestration_id': 'orch-1',
        'space_id': 'space-1',
        'reason': 'orchestration_budget',
        'cap_micros': 5000000,
        'spent_micros': 5120000,
        'for_user_id': 'user-1',
        'can_raise_cap': true,
        'notification_kind': 'review',
        'quiet': false,
      });
      final bot = pipelineRunHeldFrame(
        PipelineRunHeld(
          workspaceId: 'ws-1',
          pipelineRunId: 'run-1',
          orchestrationId: 'orch-1',
          spaceId: null,
          reason: 'orchestration_budget',
          capMicros: 5000000,
          spentMicros: 5120000,
          requestedByUserId: null,
          occurredAt: DateTime.utc(2026, 11, 19),
        ),
      );
      expect(bot.params.containsKey('for_user_id'), isFalse);
      expect(
        bot.params.containsKey('can_raise_cap'),
        isFalse,
        reason: "a bot's run reaches members who may not raise it",
      );
    });
  });

  test('every frame builder gives its frame a notification_kind', () {
    // Structural: a new frame without a kind fails here before a client
    // has to guess how loud it is.
    final source = File('lib/src/notification_wire.dart').readAsStringSync();
    final builders = RegExp(
      r'^NotificationFrame\??\s+(\w+)\(',
      multiLine: true,
    ).allMatches(source).toList();
    expect(builders, hasLength(greaterThan(25)));
    for (var i = 0; i < builders.length; i++) {
      final end = i + 1 < builders.length
          ? builders[i + 1].start
          : source.length;
      final body = source.substring(builders[i].start, end);
      if (!body.contains('method:')) {
        continue;
      }
      expect(
        body,
        contains('notificationKindKey:'),
        reason: '${builders[i].group(1)} has no notification_kind',
      );
    }
  });

  group('quiet', () {
    // Each builder's `quiet` value, read from the source.
    Map<String, String> quietOfBuilders() {
      final source = File('lib/src/notification_wire.dart').readAsStringSync();
      final builders = RegExp(
        r'^NotificationFrame\??\s+(\w+)\(',
        multiLine: true,
      ).allMatches(source).toList();
      final out = <String, String>{};
      for (var i = 0; i < builders.length; i++) {
        final end = i + 1 < builders.length
            ? builders[i + 1].start
            : source.length;
        final body = source.substring(builders[i].start, end);
        if (!body.contains('method:')) {
          continue;
        }
        final m = RegExp(r'notificationQuietKey:\s*([^,]+),').firstMatch(body);
        out[builders[i].group(1)!] = m?.group(1)?.trim() ?? '<missing>';
      }
      return out;
    }

    test('only the long-running work FYI frames may be quiet; every other '
        'frame says quiet: false', () {
      const allowed = {
        'wakeRuleEndedFrame': 'true',
        'goalSettledFrame': 'event.status.isTerminal',
      };
      final quiet = quietOfBuilders();
      expect(quiet, hasLength(greaterThan(25)));
      for (final MapEntry(:key, :value) in quiet.entries) {
        expect(
          value,
          allowed[key] ?? 'false',
          reason: allowed.containsKey(key)
              ? '$key changed its quiet rule'
              : '$key is not on the quiet allowlist',
        );
      }
    });

    test('every frame that existed before the long-running work keeps a '
        'normal-urgency, sounding push', () {
      // The frame builders at the commit before this build.
      const before = [
        'messageReceivedFrame',
        'ticketAssignedFrame',
        'ticketStatusChangedFrame',
        'ticketReassignedFrame',
        'prPublishedFrame',
        'prMergedFrame',
        'prMentionedFrame',
        'prReviewRequestedFrame',
        'prMergeReadinessFrame',
        'prReviewDecisionFrame',
        'prChecksStatusFrame',
        'prCommentMentionedFrame',
        'prThreadRepliedFrame',
        'prThreadResolvedFrame',
        'reviewBecameStaleFrame',
        'externalPrMergedFrame',
        'meetingStartingSoonFrame',
        'calendarAuthExpiredFrame',
        'rigControlChangedFrame',
        'rigReapedFrame',
        'rigClosedFrame',
        'agentAwaitingInputFrame',
        'agentActionBlockedFrame',
      ];
      final quiet = quietOfBuilders();
      for (final name in before) {
        expect(quiet[name], 'false', reason: '$name must not be quiet');
        // What the push reads from such a frame: normal urgency, a card
        // that sounds, whatever its kind.
        for (final kind in NotificationKind.values) {
          expect(
            isQuietPush({notificationKindKey: kind.wire, 'quiet': false}),
            isFalse,
            reason: name,
          );
        }
      }
      // A built frame agrees with the source.
      final message = messageReceivedFrame(
        MessageReceived(
          spaceId: 'sp-1',
          messageId: 'm-1',
          senderName: 'Bot',
          contentPreview: 'done',
          isAgentMessage: true,
          workspaceId: 'ws-1',
          occurredAt: DateTime(2026),
        ),
      )!;
      expect(message.params['quiet'], isFalse);
      expect(isQuietPush(message.params), isFalse);
    });

    test('a finished goal is quiet; a goal that needs a person is not', () {
      GoalSettled settled(AgentGoalStatus status, {GoalHold? hold}) =>
          GoalSettled(
            goalId: 'goal-1',
            workspaceId: 'ws-1',
            spaceId: 'space-1',
            conversationId: 'conv-1',
            agentId: 'agent-1',
            status: status,
            hold: hold,
            summary: null,
            requestedByUserId: 'user-1',
            occurredAt: DateTime(2026),
          );
      expect(
        isQuietPush(goalSettledFrame(settled(AgentGoalStatus.completed)).params),
        isTrue,
      );
      expect(
        isQuietPush(
          goalSettledFrame(
            settled(AgentGoalStatus.paused, hold: GoalHold.needsReview),
          ).params,
        ),
        isFalse,
      );
    });
  });

  test('the three kinds have stable wire names', () {
    expect(NotificationKind.values.map((k) => k.wire), [
      'notify',
      'question',
      'review',
    ]);
    expect(notificationKindKey, 'notification_kind');
    expect(NotificationKindWire.tryParse('review'), NotificationKind.review);
    expect(NotificationKindWire.tryParse('nope'), isNull);
  });
}
