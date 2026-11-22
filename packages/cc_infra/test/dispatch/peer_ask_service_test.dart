import 'package:cc_domain/cc_domain.dart' show WorkspaceMismatchException;
import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/core/domain/events/agent_events.dart';
import 'package:cc_domain/core/domain/value_objects/agent_lifecycle_status.dart';
import 'package:cc_domain/core/domain/value_objects/wake_context.dart';
import 'package:cc_domain/features/dispatch/domain/entities/peer_ask.dart';
import 'package:cc_domain/features/dispatch/domain/entities/wake.dart';
import 'package:cc_domain/features/dispatch/domain/services/peer_ask_text.dart';
import 'package:cc_domain/features/dispatch/domain/services/wake_frame.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/limit_park.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/peer_ask_values.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/run_end_reason.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_detail.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_values.dart';
import 'package:cc_infra/src/dispatch/peer_ask_service.dart';
import 'package:cc_infra/src/dispatch/wake_dispatch.dart'
    show WakeDispatchRequest;
import 'package:test/test.dart';

import 'peer_test_kit.dart';

/// [PeerAskService] beyond the tools (plan section 10, D20, A3–A5): expiry
/// and the restart sweep, the once-only interim notices, a cancel that wakes
/// nobody, a question that is never delivered, isolation, and whose run a
/// reply continues.
void main() {
  late PeerKit kit;

  setUp(() async {
    kit = PeerKit()
      ..agent('agent-a', 'Ada')
      ..agent('agent-b', 'Bo')
      ..conversation('c-a', spaceId: 'sp-a')
      ..conversation('c-b', spaceId: 'sp-b')
      ..run(
        'run-a',
        agentId: 'agent-a',
        conversationId: 'c-a',
        requester: 'user-1',
      );
    kit.messages['q-1'] = Message(
      id: 'q-1',
      spaceId: 'sp-b',
      conversationId: 'c-b',
      senderId: 'agent-a',
      senderType: SenderType.agent,
      content: 'Is the cast safe?',
      messageType: MessageType.text,
      createdAt: kit.now,
    );
    await kit.start();
  });

  Future<PeerAskResult> ask({
    PeerAskMode mode = PeerAskMode.background,
    Duration? wait,
    String askerRunId = 'run-a',
  }) => kit.service.ask(
    PeerAskRequest(
      workspaceId: PeerKit.ws,
      kind: PeerAskKind.ask,
      mode: mode,
      askerAgentId: 'agent-a',
      askerName: 'Ada',
      askerRunId: askerRunId,
      askerConversationId: 'c-a',
      recipientAgentId: 'agent-b',
      recipientSpaceId: 'sp-b',
      recipientConversationId: 'c-b',
      questionMessageId: 'q-1',
      question: 'Is the cast safe?',
      chain: const ['agent-a'],
      wait: wait,
    ),
  );

  PeerAsk only() => kit.asks.all(PeerKit.ws).single;

  /// The asker's wakes from the ask (replies and interim notices).
  List<Wake> replies() => [
    for (final w in kit.wakes.all(PeerKit.ws))
      if (w.reason == WakeReason.peerReply) w,
  ];

  group('expiry and the sweep', () {
    test(
      'an unanswered ask expires at 24 h and wakes the asker once',
      () async {
        await ask();
        kit.now = kit.now.add(PeerAskLimits.expiry);
        await kit.service.sweep();
        await kit.service.sweep();
        expect(only().status, PeerAskStatus.expired);
        final reply = replies().single;
        expect(reply.agentId, 'agent-a');
        expect(reply.conversationId, 'c-a');
        expect(reply.detail.status, 'expired');
      },
    );

    test(
      'the boot sweep settles a run that ended while nobody listened',
      () async {
        await ask();
        expect(only().dispatchedRunId, 'run-1');
        // The run ended and its row and answer were written, but its
        // settlement was never heard (the server went down).
        final run = kit.runs['run-1']!;
        kit.runs['run-1'] = AgentRunLog(
          id: run.id,
          agentId: run.agentId,
          workspaceId: run.workspaceId,
          spaceId: run.spaceId,
          conversationId: run.conversationId,
          startedAt: run.startedAt,
          completedAt: kit.now,
          status: RunStatus.completed,
          endReason: RunEndReason.completed,
        );
        kit.messages['run-1'] = Message(
          id: 'run-1',
          spaceId: 'sp-b',
          conversationId: 'c-b',
          senderId: 'agent-b',
          senderType: SenderType.agent,
          content: 'Guarded upstream.',
          messageType: MessageType.text,
          createdAt: kit.now,
        );
        kit.now = kit.now.add(PeerAskService.missedSettleAfter);
        await kit.service.start();
        await kit.service.stop();
        expect(only().status, PeerAskStatus.answered);
        expect(replies().single.payload, 'Guarded upstream.');
      },
    );
  });

  group('interim notices, once per kind', () {
    test(
      'a short answer with an active wake_me rule is a promise, once',
      () async {
        kit.wakeRuleSet = true;
        await ask();
        await kit.finish('run-1', answer: 'After the build, about 20 minutes.');
        expect(only().status, PeerAskStatus.pending);
        expect(only().promisedAt, isNotNull);
        expect(replies().single.detail.status, PeerReplyInterim.promised);
        // The second short answer is the answer: a promise is made once.
        kit.run('run-2', agentId: 'agent-b', conversationId: 'c-b');
        await kit.finish('run-2', answer: 'Safe.');
        expect(only().status, PeerAskStatus.answered);
        expect(
          replies().map((w) => w.detail.status),
          unorderedEquals([PeerReplyInterim.promised, 'answered']),
        );
      },
    );

    test('a recipient waiting on a person tells the asker once', () async {
      await ask();
      AgentAwaitingInput waiting(String id) => AgentAwaitingInput(
        workspaceId: PeerKit.ws,
        waitId: id,
        kind: AgentInputKind.approval,
        summary: 'Push to main',
        occurredAt: kit.now,
        conversationId: 'c-b',
        agentId: 'agent-b',
        runId: 'run-1',
      );
      kit.bus
        ..publish(waiting('w-1'))
        ..publish(waiting('w-2'));
      await kit.pump();
      final notice = replies().single;
      expect(notice.detail.status, PeerReplyInterim.blockedOnPerson);
      expect(notice.detail.fields[WakeFields.requestKind], 'approval');
      expect(only().status, PeerAskStatus.pending);
    });

    test('a blocking ask returns at once when the recipient waits on a '
        'person', () async {
      final pending = ask(
        mode: PeerAskMode.wait,
        wait: const Duration(hours: 1),
      );
      await kit.pump();
      kit.bus.publish(
        AgentAwaitingInput(
          workspaceId: PeerKit.ws,
          waitId: 'w-1',
          kind: AgentInputKind.question,
          summary: 'Which branch?',
          occurredAt: kit.now,
          conversationId: 'c-b',
          agentId: 'agent-b',
          runId: 'run-1',
        ),
      );
      final result = await pending;
      expect(
        result,
        isA<PeerAskPending>()
            .having((p) => p.why, 'why', PeerReplyInterim.blockedOnPerson)
            .having((p) => p.requestKind, 'requestKind', 'question'),
      );
      expect(replies(), isEmpty, reason: 'told inline, not woken');
    });

    group('a recipient at its usage limit', () {
      List<Wake> parks() => [
        for (final w in kit.wakes.all(PeerKit.ws))
          if (w.reason == WakeReason.limitReset) w,
      ];

      /// The recipient's runs (the asker's notices start runs of its own).
      List<WakeDispatchRequest> recipientRuns() => [
        for (final r in kit.dispatched)
          if (r.agentId == 'agent-b') r,
      ];

      test('a reset before the expiry parks it through the limit park; the '
          'resumed run answers the open ask', () async {
        await ask();
        final resets = kit.now.add(const Duration(hours: 2));
        await kit.finish(
          'run-1',
          endReason: RunEndReason.usageLimit,
          limitResetsAt: resets,
        );
        expect(only().status, PeerAskStatus.pending);
        final notice = replies().single;
        expect(notice.detail.status, PeerReplyInterim.parkedAtLimit);
        final resumes = resets.add(LimitPark.resetSlack);
        expect(
          notice.detail.fields[WakeFields.resetsAt],
          resets.toIso8601String(),
        );
        expect(
          notice.detail.fields[WakeFields.resumesAt],
          resumes.toIso8601String(),
        );
        final park = parks().single;
        expect(park.dedupKey, LimitPark.dedupKey('run-1'));
        expect(park.detail.askId, only().id);
        expect(park.detail.sourceRunId, 'run-1');
        expect(park.agentId, 'agent-b');
        expect(park.conversationId, 'c-b');
        expect(park.notBefore.isAtSameMomentAs(resumes), isTrue);
        expect(park.payload, 'Is the cast safe?');
        expect(park.state, WakeState.pending);

        // Nothing restarts before the reset.
        await kit.deliver();
        expect(recipientRuns(), hasLength(1));
        kit.now = resumes.add(const Duration(seconds: 1));
        await kit.queue.tick();
        await kit.pump();
        expect(recipientRuns(), hasLength(2));
        expect(
          recipientRuns().last.wakeContext.wakeReason,
          WakeReason.limitReset,
        );
        final resumed =
            'run-${kit.dispatched.indexOf(recipientRuns().last) + 1}';
        expect(only().dispatchedRunId, resumed);

        await kit.finish(resumed, answer: 'Safe: the guard runs first.');
        expect(only().status, PeerAskStatus.answered);
        expect(
          replies().where(
            (w) => w.detail.status == PeerAskStatus.answered.wire,
          ),
          hasLength(1),
        );
      });

      test('the park acts for whoever the parked run acted for', () async {
        await ask();
        expect(parks(), isEmpty);
        final run = kit.runs['run-1']!;
        expect(
          run.requestedByUserId,
          isNull,
          reason: 'the question is a bot run',
        );
        // The question pushed into a person's run: that run is theirs.
        kit.runs['run-1'] = AgentRunLog(
          id: run.id,
          agentId: run.agentId,
          workspaceId: run.workspaceId,
          spaceId: run.spaceId,
          conversationId: run.conversationId,
          startedAt: run.startedAt,
          status: RunStatus.running,
          requestedByUserId: 'user-9',
          wakeReason: WakeReason.userMessage,
        );
        await kit.finish(
          'run-1',
          endReason: RunEndReason.usageLimit,
          limitResetsAt: kit.now.add(const Duration(hours: 1)),
        );
        expect(parks().single.requestedByUserId, 'user-9');
      });

      test('no reported reset: the ask fails at once on the limit', () async {
        await ask();
        await kit.finish('run-1', endReason: RunEndReason.usageLimit);
        expect(only().status, PeerAskStatus.failed);
        expect(only().error, PeerAskErrors.usageLimit);
        final reply = replies().single;
        expect(reply.detail.status, PeerAskStatus.failed.wire);
        expect(reply.detail.fields[WakeFields.error], PeerAskErrors.usageLimit);
        expect(parks(), isEmpty);
      });

      test('a reset the run would resume after the expiry: the ask fails at '
          'once on the limit', () async {
        await ask();
        await kit.finish(
          'run-1',
          endReason: RunEndReason.usageLimit,
          limitResetsAt: only().expiresAt.subtract(const Duration(seconds: 10)),
        );
        expect(only().status, PeerAskStatus.failed);
        expect(only().error, PeerAskErrors.usageLimit);
        expect(
          replies().single.detail.fields[WakeFields.error],
          PeerAskErrors.usageLimit,
        );
        expect(parks(), isEmpty);
      });

      test('the asker cancels while the recipient is parked: the park wake is '
          'cancelled and nothing restarts', () async {
        await ask();
        final resets = kit.now.add(const Duration(hours: 2));
        await kit.finish(
          'run-1',
          endReason: RunEndReason.usageLimit,
          limitResetsAt: resets,
        );
        expect(parks().single.state, WakeState.pending);
        expect(await kit.service.cancel(PeerKit.ws, only().id), isTrue);
        expect(parks().single.state, WakeState.cancelled);
        kit.now = resets.add(const Duration(minutes: 5));
        await kit.queue.tick();
        await kit.pump();
        expect(recipientRuns(), hasLength(1));
        expect(only().status, PeerAskStatus.cancelled);
      });

      test('a person\'s park of the same run wins its key and is cancelled: '
          'the ask fails at once on the limit and the asker is woken', () async {
        await ask();
        expect(only().dispatchedRunId, 'run-1');
        // The question ran in a person's run, whose own park took the run's
        // `limit:` key first.
        final person = Wake(
          id: 'person-park',
          workspaceId: PeerKit.ws,
          spaceId: kit.conversations['c-b']!.spaceId,
          conversationId: 'c-b',
          agentId: 'agent-b',
          reason: WakeReason.limitReset,
          payload: '',
          detail: WakeDetail(sourceRunId: 'run-1'),
          dedupKey: LimitPark.dedupKey('run-1'),
          notBefore: kit.now.add(const Duration(hours: 2)),
          requestedByUserId: 'user-9',
          state: WakeState.held,
          stateReason: LimitPark.heldReason,
          createdAt: kit.now,
        );
        expect(await kit.queue.enqueue(person), isTrue);
        await kit.finish(
          'run-1',
          endReason: RunEndReason.usageLimit,
          limitResetsAt: kit.now.add(const Duration(hours: 2)),
        );
        expect(only().status, PeerAskStatus.pending);
        expect(
          await kit.queue.cancel(PeerKit.ws, 'person-park', reason: 'person'),
          isTrue,
        );
        await kit.pump();
        expect(only().status, PeerAskStatus.failed);
        // As its own park's end says it: the error, then how the park ended;
        // the asker's reply carries the error's kind.
        expect(only().error, '${PeerAskErrors.usageLimit}: person');
        expect(
          replies().last.detail.fields[WakeFields.error],
          PeerAskErrors.usageLimit,
        );
      });

      test('a usage-limit end the server missed: the sweep fails the ask '
          'unless a park is open', () async {
        await ask();
        final run = kit.runs['run-1']!;
        // The run ended while nobody listened: no settlement event.
        kit.runs['run-1'] = AgentRunLog(
          id: run.id,
          agentId: run.agentId,
          workspaceId: run.workspaceId,
          spaceId: run.spaceId,
          conversationId: run.conversationId,
          startedAt: run.startedAt,
          completedAt: kit.now,
          status: RunStatus.error,
          endReason: RunEndReason.usageLimit,
        );
        kit.now = kit.now.add(const Duration(minutes: 2));
        await kit.service.sweep();
        expect(only().status, PeerAskStatus.failed);
        expect(only().error, PeerAskErrors.usageLimit);
      });
    });
  });

  group('cancel and failures', () {
    test('a cancelled ask wakes nobody and leaves the run alone', () async {
      await ask();
      expect(await kit.service.cancel(PeerKit.ws, only().id), isTrue);
      expect(only().status, PeerAskStatus.cancelled);
      await kit.finish('run-1', answer: 'Too late.');
      await kit.deliver();
      expect(replies(), isEmpty);
      expect(only().status, PeerAskStatus.cancelled);
      expect(await kit.service.cancel(PeerKit.ws, only().id), isFalse);
    });

    test("another workspace's ask is not cancelled", () async {
      await ask();
      await expectLater(
        kit.service.cancel(PeerKit.other, only().id),
        throwsA(isA<WorkspaceMismatchException>()),
      );
      expect(only().status, PeerAskStatus.pending);
    });

    test(
      'an ask from a conversation of another workspace is refused',
      () async {
        kit.conversation('c-x', spaceId: 'sp-x', workspaceId: PeerKit.other);
        await expectLater(
          kit.service.ask(
            const PeerAskRequest(
              workspaceId: PeerKit.ws,
              kind: PeerAskKind.ask,
              mode: PeerAskMode.background,
              askerAgentId: 'agent-a',
              askerName: 'Ada',
              askerConversationId: 'c-x',
              recipientAgentId: 'agent-b',
              recipientSpaceId: 'sp-b',
              recipientConversationId: 'c-b',
              questionMessageId: 'q-1',
              question: 'Is the cast safe?',
              chain: ['agent-a'],
            ),
          ),
          throwsA(isA<WorkspaceMismatchException>()),
        );
        expect(kit.asks.all(PeerKit.ws), isEmpty);
      },
    );

    test('a question the queue skips fails its ask, told inline', () async {
      kit.agents['agent-b'] = kit.agents['agent-b']!.copyWith(
        lifecycleStatus: AgentLifecycleStatus.archived,
      );
      final result = await ask();
      expect(
        result,
        isA<PeerAskSettledInline>().having(
          (s) => s.status,
          'status',
          PeerAskStatus.failed,
        ),
      );
      expect(only().status, PeerAskStatus.failed);
      expect(only().error, startsWith(PeerAskErrors.notDelivered));
      expect(replies(), isEmpty);
    });

    test('a question the queue refuses outright fails its ask, told '
        'inline', () async {
      kit.agents.remove('agent-b');
      final result = await ask();
      expect(
        result,
        isA<PeerAskSettledInline>()
            .having((s) => s.status, 'status', PeerAskStatus.failed)
            .having((s) => s.error, 'error', PeerAskErrors.notDelivered),
      );
      expect(only().status, PeerAskStatus.failed);
      expect(only().error, startsWith(PeerAskErrors.notDelivered));
      expect(replies(), isEmpty);
    });

    test('a recipient holding 20 pending asks refuses the 21st', () async {
      for (var i = 0; i < PeerAskLimits.maxPendingPerRecipient; i++) {
        kit.agent('asker-$i', 'Asker $i');
        await kit.asks.insert(
          PeerAsk(
            id: 'held-$i',
            workspaceId: PeerKit.ws,
            askerAgentId: 'asker-$i',
            askerConversationId: 'c-$i',
            askerSpaceId: 'sp-$i',
            recipientAgentId: 'agent-b',
            questionHash: 'h-$i',
            createdAt: kit.now,
            expiresAt: kit.now.add(PeerAskLimits.expiry),
          ),
        );
      }
      final refusal = await kit.service.refusalFor(
        workspaceId: PeerKit.ws,
        askerAgentId: 'agent-a',
        askerConversationId: 'c-a',
        recipientAgentId: 'agent-b',
        question: 'Is the cast safe?',
        chain: PeerChain.none,
      );
      expect(refusal?.kind, PeerAskRefusals.limitReached);
      // One fewer is admitted.
      await kit.asks.settle(
        PeerKit.ws,
        id: 'held-0',
        status: PeerAskStatus.answered,
        now: kit.now,
      );
      expect(
        await kit.service.refusalFor(
          workspaceId: PeerKit.ws,
          askerAgentId: 'agent-a',
          askerConversationId: 'c-a',
          recipientAgentId: 'agent-b',
          question: 'Is the cast safe?',
          chain: PeerChain.none,
        ),
        isNull,
      );
    });

    group('asks made at once (the limits are held with the insert)', () {
      // What a tool does: the refusal check, then the ask.
      Future<String> attempt(String question) async {
        final refusal = await kit.service.refusalFor(
          workspaceId: PeerKit.ws,
          askerAgentId: 'agent-a',
          askerConversationId: 'c-a',
          recipientAgentId: 'agent-b',
          question: question,
          chain: PeerChain.none,
        );
        if (refusal != null) {
          return refusal.kind;
        }
        final result = await kit.service.ask(
          PeerAskRequest(
            workspaceId: PeerKit.ws,
            kind: PeerAskKind.ask,
            mode: PeerAskMode.background,
            askerAgentId: 'agent-a',
            askerName: 'Ada',
            askerRunId: 'run-a',
            askerConversationId: 'c-a',
            recipientAgentId: 'agent-b',
            recipientSpaceId: 'sp-b',
            recipientConversationId: 'c-b',
            questionMessageId: 'q-1',
            question: question,
            chain: const ['agent-a'],
          ),
        );
        return switch (result) {
          PeerAskRefused(:final refusal) => refusal.kind,
          _ => 'asked',
        };
      }

      test('twelve in parallel: the asker cap holds at ten', () async {
        final outcomes = await Future.wait([
          for (var i = 0; i < 12; i++) attempt('Question $i?'),
        ]);
        expect(outcomes.where((o) => o == 'asked'), hasLength(10));
        expect(
          outcomes.where((o) => o == PeerAskRefusals.limitReached),
          hasLength(2),
        );
        expect(kit.asks.all(PeerKit.ws), hasLength(10));
      });

      test(
        'the same question twice in parallel: one ask, one duplicate',
        () async {
          final outcomes = await Future.wait([
            attempt('Is the cast safe?'),
            attempt('Is the cast safe?'),
          ]);
          expect(
            outcomes,
            unorderedEquals(['asked', PeerAskRefusals.duplicate]),
          );
          expect(kit.asks.all(PeerKit.ws), hasLength(1));
        },
      );
    });

    test('a server stop changes nothing', () async {
      await ask();
      await kit.finish('run-1', endReason: RunEndReason.serverStopped);
      expect(only().status, PeerAskStatus.pending);
      expect(replies(), isEmpty);
    });
  });

  group('whose run a reply continues', () {
    test('the question is a bot run; the reply acts for the asker run\'s '
        'person and is pushed into that person\'s live run', () async {
      await ask();
      expect(kit.dispatched.single.requestedByUserId, isNull);
      final live = KitSession(
        agentId: 'agent-a',
        conversationId: 'c-a',
        runLogId: 'run-a',
        spaceId: 'sp-a',
        requestedByUserId: 'user-1',
      );
      kit.sessions.add(live);
      await kit.finish('run-1', answer: 'Safe.');
      await kit.deliver();
      final reply = replies().single;
      expect(reply.requestedByUserId, 'user-1');
      expect(reply.state, isIn([WakeState.claimed, WakeState.delivered]));
      expect(live.steeringQueue.isEmpty, isFalse);
    });

    test('a live run of another person in the asker conversation is not '
        'fed the reply', () async {
      await ask();
      final other = KitSession(
        agentId: 'agent-a',
        conversationId: 'c-a',
        runLogId: 'run-other',
        spaceId: 'sp-a',
        requestedByUserId: 'user-2',
      );
      kit.sessions.add(other);
      await kit.finish('run-1', answer: 'Safe.');
      await kit.deliver();
      expect(other.steeringQueue.isEmpty, isTrue);
      expect(replies().single.state, isNot(WakeState.delivered));
    });

    test('an asker bot run gets a bot reply', () async {
      kit.run('run-bot', agentId: 'agent-a', conversationId: 'c-a');
      await ask(askerRunId: 'run-bot');
      await kit.finish('run-1', answer: 'Safe.');
      await kit.deliver();
      expect(replies().single.requestedByUserId, isNull);
      expect(kit.dispatched.last.agentId, 'agent-a');
      expect(kit.dispatched.last.requestedByUserId, isNull);
    });
  });
}
