import 'package:cc_domain/core/domain/value_objects/wake_context.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WakeReason', () {
    test('has all 14 values', () {
      expect(WakeReason.values, hasLength(14));
      expect(WakeReason.values, contains(WakeReason.userMessage));
      expect(WakeReason.values, contains(WakeReason.assignment));
      expect(WakeReason.values, contains(WakeReason.recovery));
      expect(WakeReason.values, contains(WakeReason.childCompleted));
      expect(WakeReason.values, contains(WakeReason.schedule));
      expect(WakeReason.values, contains(WakeReason.pipelineStep));
      expect(WakeReason.values, contains(WakeReason.goalContinuation));
      expect(WakeReason.values, contains(WakeReason.improvementReview));
    });

    test('wire names are snake_case and parse back', () {
      for (final reason in WakeReason.values) {
        expect(reason.wire, matches(RegExp(r'^[a-z]+(_[a-z]+)*$')));
        expect(WakeReasonWire.tryParse(reason.wire), reason);
      }
      expect(WakeReason.goalContinuation.wire, 'goal_continuation');
      expect(WakeReasonWire.tryParse('follow_up'), isNull);
      expect(WakeReasonWire.tryParse(null), isNull);
    });
  });

  group('WakeContext', () {
    WakeContext makeSubject({
      String? ticketId,
      String? spaceId,
      WakeReason wakeReason = WakeReason.userMessage,
      String? messageId,
      String? pipelineRunId,
    }) {
      return WakeContext(
        startedByRunId: null,
        ticketId: ticketId,
        spaceId: spaceId,
        wakeReason: wakeReason,
        messageId: messageId,
        pipelineRunId: pipelineRunId,
      );
    }

    Map<String, String> env(WakeContext ctx) =>
        ctx.toEnvironment(runId: 'run-42', agentId: 'agent-x', workspaceId: 'ws-99');

    group('constructor', () {
      test('sets all fields', () {
        const ctx = WakeContext(
          startedByRunId: null,
          ticketId: 'ticket-1',
          spaceId: 'chan-1',
          wakeReason: WakeReason.assignment,
          messageId: 'msg-1',
          pipelineRunId: 'pipe-1',
        );

        expect(ctx.ticketId, 'ticket-1');
        expect(ctx.spaceId, 'chan-1');
        expect(ctx.wakeReason, WakeReason.assignment);
        expect(ctx.messageId, 'msg-1');
        expect(ctx.pipelineRunId, 'pipe-1');
        expect(ctx.hasWakes, isFalse);
        expect(ctx.nonce, isNull);
      });

      test('leaves optional fields null by default', () {
        final ctx = makeSubject();

        expect(ctx.ticketId, isNull);
        expect(ctx.spaceId, isNull);
        expect(ctx.messageId, isNull);
        expect(ctx.pipelineRunId, isNull);
        expect(ctx.wakeIds, isEmpty);
      });
    });

    group('toEnvironment', () {
      test('includes the run identity and the wire reason', () {
        final e = env(makeSubject(wakeReason: WakeReason.goalContinuation));

        expect(e['CC_RUN_ID'], 'run-42');
        expect(e['CC_AGENT_ID'], 'agent-x');
        expect(e['CC_WORKSPACE_ID'], 'ws-99');
        expect(e['CC_WAKE_REASON'], 'goal_continuation');
      });

      test('includes optional fields when provided', () {
        final e = env(
          makeSubject(
            ticketId: 'ticket-7',
            spaceId: 'chan-3',
            messageId: 'msg-5',
            pipelineRunId: 'pipe-9',
          ),
        );

        expect(e['CC_TASK_ID'], 'ticket-7');
        expect(e['CC_SPACE_ID'], 'chan-3');
        expect(e['CC_MESSAGE_ID'], 'msg-5');
        expect(e['CC_PIPELINE_RUN_ID'], 'pipe-9');
      });

      test('omits null optional fields from map', () {
        final e = env(makeSubject());

        expect(e.containsKey('CC_SPACE_ID'), isFalse);
        expect(e.containsKey('CC_MESSAGE_ID'), isFalse);
        expect(e.containsKey('CC_PIPELINE_RUN_ID'), isFalse);
        expect(e.containsKey('CC_WAKE_IDS'), isFalse);
      });

      test('uses empty string for null ticketId', () {
        expect(env(makeSubject())['CC_TASK_ID'], '');
      });
    });

    group('toString', () {
      test('names the reason and the wakes', () {
        expect(
          makeSubject(wakeReason: WakeReason.schedule).toString(),
          'WakeContext(reason=schedule, wakes=)',
        );
      });
    });

    group('== and hashCode', () {
      test('equal when all fields match', () {
        final a = makeSubject(
          ticketId: 't1',
          spaceId: 'c1',
          wakeReason: WakeReason.pipelineStep,
          messageId: 'm1',
          pipelineRunId: 'p1',
        );
        final b = makeSubject(
          ticketId: 't1',
          spaceId: 'c1',
          wakeReason: WakeReason.pipelineStep,
          messageId: 'm1',
          pipelineRunId: 'p1',
        );

        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
        expect(const WakeContext.userMessage(), makeSubject());
      });

      test('not equal when any field differs', () {
        final base = makeSubject();
        for (final other in [
          makeSubject(ticketId: 't2'),
          makeSubject(spaceId: 'c1'),
          makeSubject(wakeReason: WakeReason.childCompleted),
          makeSubject(messageId: 'm1'),
          makeSubject(pipelineRunId: 'p1'),
        ]) {
          expect(base, isNot(equals(other)));
        }
      });

      test('identical instances are equal', () {
        final ctx = makeSubject();

        expect(identical(ctx, ctx), isTrue);
        expect(ctx, equals(ctx));
      });
    });
  });
}
