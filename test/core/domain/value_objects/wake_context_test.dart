import 'package:cc_domain/core/domain/value_objects/wake_context.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WakeReason', () {
    test('has all 6 values', () {
      expect(WakeReason.values, hasLength(6));
      expect(WakeReason.values, contains(WakeReason.userMessage));
      expect(WakeReason.values, contains(WakeReason.assignment));
      expect(WakeReason.values, contains(WakeReason.recovery));
      expect(WakeReason.values, contains(WakeReason.childCompleted));
      expect(WakeReason.values, contains(WakeReason.followUp));
      expect(WakeReason.values, contains(WakeReason.pipelineStep));
    });
  });

  group('WakeContext', () {
    WakeContext makeSubject({
      String? ticketId,
      String runId = 'run-1',
      String agentId = 'agent-1',
      String workspaceId = 'ws-1',
      String? channelId,
      WakeReason wakeReason = WakeReason.userMessage,
      String? messageId,
      String? pipelineRunId,
    }) {
      return WakeContext(
        ticketId: ticketId,
        runId: runId,
        agentId: agentId,
        workspaceId: workspaceId,
        channelId: channelId,
        wakeReason: wakeReason,
        messageId: messageId,
        pipelineRunId: pipelineRunId,
      );
    }

    group('constructor', () {
      test('sets all fields', () {
        const ctx = WakeContext(
          ticketId: 'ticket-1',
          runId: 'run-1',
          agentId: 'agent-1',
          workspaceId: 'ws-1',
          channelId: 'chan-1',
          wakeReason: WakeReason.assignment,
          messageId: 'msg-1',
          pipelineRunId: 'pipe-1',
        );

        expect(ctx.ticketId, 'ticket-1');
        expect(ctx.runId, 'run-1');
        expect(ctx.agentId, 'agent-1');
        expect(ctx.workspaceId, 'ws-1');
        expect(ctx.channelId, 'chan-1');
        expect(ctx.wakeReason, WakeReason.assignment);
        expect(ctx.messageId, 'msg-1');
        expect(ctx.pipelineRunId, 'pipe-1');
      });

      test('leaves optional fields null by default', () {
        final ctx = makeSubject();

        expect(ctx.ticketId, isNull);
        expect(ctx.channelId, isNull);
        expect(ctx.messageId, isNull);
        expect(ctx.pipelineRunId, isNull);
      });
    });

    group('toEnvironment', () {
      test('includes all required fields', () {
        final env = makeSubject(
          runId: 'run-42',
          agentId: 'agent-x',
          workspaceId: 'ws-99',
          wakeReason: WakeReason.recovery,
        ).toEnvironment();

        expect(env['CC_RUN_ID'], 'run-42');
        expect(env['CC_AGENT_ID'], 'agent-x');
        expect(env['CC_WORKSPACE_ID'], 'ws-99');
        expect(env['CC_WAKE_REASON'], 'recovery');
      });

      test('includes optional fields when provided', () {
        final env = makeSubject(
          ticketId: 'ticket-7',
          channelId: 'chan-3',
          messageId: 'msg-5',
          pipelineRunId: 'pipe-9',
        ).toEnvironment();

        expect(env['CC_TASK_ID'], 'ticket-7');
        expect(env['CC_CHANNEL_ID'], 'chan-3');
        expect(env['CC_MESSAGE_ID'], 'msg-5');
        expect(env['CC_PIPELINE_RUN_ID'], 'pipe-9');
      });

      test('omits null optional fields from map', () {
        final env = makeSubject().toEnvironment();

        expect(env.containsKey('CC_CHANNEL_ID'), isFalse);
        expect(env.containsKey('CC_MESSAGE_ID'), isFalse);
        expect(env.containsKey('CC_PIPELINE_RUN_ID'), isFalse);
      });

      test('uses empty string for null ticketId', () {
        final env = makeSubject().toEnvironment();

        expect(env['CC_TASK_ID'], '');
      });
    });

    group('toString', () {
      test('returns expected format', () {
        final ctx = makeSubject(
          runId: 'run-1',
          agentId: 'agent-1',
          wakeReason: WakeReason.followUp,
        );

        expect(
          ctx.toString(),
          'WakeContext(runId=run-1, agentId=agent-1, reason=followUp)',
        );
      });
    });

    group('== and hashCode', () {
      test('equal when all fields match', () {
        final a = makeSubject(
          ticketId: 't1',
          runId: 'r1',
          agentId: 'a1',
          workspaceId: 'w1',
          channelId: 'c1',
          wakeReason: WakeReason.pipelineStep,
          messageId: 'm1',
          pipelineRunId: 'p1',
        );
        final b = makeSubject(
          ticketId: 't1',
          runId: 'r1',
          agentId: 'a1',
          workspaceId: 'w1',
          channelId: 'c1',
          wakeReason: WakeReason.pipelineStep,
          messageId: 'm1',
          pipelineRunId: 'p1',
        );

        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('not equal when ticketId differs', () {
        final a = makeSubject(ticketId: 't1');
        final b = makeSubject(ticketId: 't2');

        expect(a, isNot(equals(b)));
      });

      test('not equal when runId differs', () {
        final a = makeSubject(runId: 'r1');
        final b = makeSubject(runId: 'r2');

        expect(a, isNot(equals(b)));
      });

      test('not equal when agentId differs', () {
        final a = makeSubject(agentId: 'a1');
        final b = makeSubject(agentId: 'a2');

        expect(a, isNot(equals(b)));
      });

      test('not equal when workspaceId differs', () {
        final a = makeSubject(workspaceId: 'w1');
        final b = makeSubject(workspaceId: 'w2');

        expect(a, isNot(equals(b)));
      });

      test('not equal when channelId differs', () {
        final a = makeSubject(channelId: 'c1');
        final b = makeSubject(channelId: null);

        expect(a, isNot(equals(b)));
      });

      test('not equal when wakeReason differs', () {
        final a = makeSubject(wakeReason: WakeReason.userMessage);
        final b = makeSubject(wakeReason: WakeReason.childCompleted);

        expect(a, isNot(equals(b)));
      });

      test('not equal when messageId differs', () {
        final a = makeSubject(messageId: 'm1');
        final b = makeSubject(messageId: null);

        expect(a, isNot(equals(b)));
      });

      test('not equal when pipelineRunId differs', () {
        final a = makeSubject(pipelineRunId: 'p1');
        final b = makeSubject(pipelineRunId: null);

        expect(a, isNot(equals(b)));
      });

      test('hashCode is consistent across multiple calls', () {
        final ctx = makeSubject(
          ticketId: 't1',
          runId: 'r1',
          agentId: 'a1',
          workspaceId: 'w1',
          channelId: 'c1',
          wakeReason: WakeReason.recovery,
          messageId: 'm1',
          pipelineRunId: 'p1',
        );

        expect(ctx.hashCode, equals(ctx.hashCode));
      });

      test('identical instances are equal', () {
        final ctx = makeSubject();

        expect(identical(ctx, ctx), isTrue);
        expect(ctx, equals(ctx));
      });
    });
  });
}
