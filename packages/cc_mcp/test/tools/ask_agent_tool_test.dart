import 'dart:convert';

import 'package:cc_domain/core/domain/value_objects/wake_context.dart';
import 'package:cc_domain/features/dispatch/domain/services/peer_ask_text.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/peer_ask_values.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/run_end_reason.dart';
import 'package:cc_domain/features/messaging/domain/services/peer_delegation_guards.dart';
import 'package:cc_mcp/src/tools/ask_agent_tool.dart';
import 'package:test/test.dart';

import 'peer_tool_kit.dart';

/// `ask_agent` posts the question in the pair's DM space and wakes the
/// recipient through the wake queue (plan section 10): a `wait` ask returns
/// the answer inline when it lands in time, otherwise the ask stays pending
/// and its answer wakes the asker once in the asker's own conversation.
void main() {
  late PeerKit kit;
  late KitMessaging messaging;
  late AskAgentTool tool;
  late AutonomyLevel askerAutonomy;
  late int? remainingBudget;

  AskAgentTool build({PairRateLimiter? limiter}) => AskAgentTool(
    agents: KitAgents(kit),
    messaging: messaging,
    rateLimiter: limiter ?? PairRateLimiter(),
    service: openGate(
      autonomy: (agent) =>
          agent == 'agent-a' ? askerAutonomy : AutonomyLevel.actWithApproval,
      remainingBudget: () => remainingBudget,
    ),
    peerAsks: kit.service,
  );

  setUp(() async {
    kit = PeerKit();
    messaging = KitMessaging(kit);
    askerAutonomy = AutonomyLevel.actWithApproval;
    remainingBudget = null;
    kit
      ..agent('agent-a', 'Ada')
      ..agent('agent-b', 'Bo')
      ..agent('agent-c', 'Cy');
    messaging.space('sp-a', agentIds: ['agent-a']);
    kit.run(
      'run-a',
      agentId: 'agent-a',
      conversationId: 'c-sp-a',
      requester: 'user-1',
    );
    tool = build();
    await kit.start();
  });

  Map<String, Object?> args({
    String message = 'Is the cast safe?',
    String mode = 'wait',
    int timeoutSeconds = 30,
    String to = 'agent-b',
    String from = 'agent-a',
  }) => {
    'workspace_id': PeerKit.ws,
    'to_agent_id': to,
    'from_agent_id': from,
    'message': message,
    'mode': mode,
    'timeout_seconds': timeoutSeconds,
  };

  Future<Map<String, dynamic>> call(
    Map<String, Object?> arguments, {
    String runId = 'run-a',
    String agentId = 'agent-a',
    String conversationId = 'c-sp-a',
    bool isError = false,
  }) async {
    final result = await tool.callForRun(
      arguments,
      runScope(agentId: agentId, runId: runId, conversationId: conversationId),
    );
    expect(result.isError, isError, reason: result.content.first.text);
    return jsonDecode(result.content.first.text) as Map<String, dynamic>;
  }

  test('an answer inside the blocking call is returned inline and wakes '
      'nobody', () async {
    final pending = call(args());
    await kit.pump();
    expect(kit.dispatched, hasLength(1));
    final started = kit.dispatched.single;
    expect(started.agentId, 'agent-b');
    expect(started.wakeContext.wakeReason, WakeReason.peerMessage);
    expect(
      started.requestedByUserId,
      isNull,
      reason: 'a peer run is a bot run',
    );
    expect(started.mentionChain, ['agent-a']);

    await kit.finish('run-1', answer: 'Yes, it is guarded upstream.');
    final answer = await pending;

    expect(answer['status'], 'answered');
    expect(answer['reply'], 'Yes, it is guarded upstream.');
    expect(answer['reply_inline'], isTrue);
    final ask = kit.asks.all(PeerKit.ws).single;
    expect(ask.status, PeerAskStatus.answered);
    expect(ask.replyInline, isTrue);
    await kit.pump();
    expect(kit.dispatched, hasLength(1), reason: 'no reply wake');
    expect(
      kit.wakes.all(PeerKit.ws).where((w) => w.agentId == 'agent-a'),
      isEmpty,
    );
  });

  test('a reply after the timeout wakes the asker once, in its own '
      'conversation, for whoever its run acted for', () async {
    final answer = await call(args(timeoutSeconds: 1));
    expect(answer['status'], 'pending');
    expect(answer['note'], contains('stays open'));
    expect(answer['note'], isNot(contains('get_messages')));
    final ask = kit.asks.all(PeerKit.ws).single;
    expect(ask.status, PeerAskStatus.pending);

    await kit.finish('run-1', answer: 'Guarded.');
    await kit.finish('run-1', answer: 'Guarded.');
    await kit.deliver();

    final replies = [
      for (final w in kit.wakes.all(PeerKit.ws))
        if (w.reason == WakeReason.peerReply) w,
    ];
    expect(replies, hasLength(1));
    final reply = replies.single;
    expect(reply.agentId, 'agent-a');
    expect(reply.conversationId, 'c-sp-a');
    expect(reply.requestedByUserId, 'user-1');
    expect(reply.detail.askId, ask.id);
    expect(reply.detail.status, 'answered');
    expect(reply.payload, 'Guarded.');
    expect(kit.dispatched.last.agentId, 'agent-a');
    expect(kit.dispatched.last.requestedByUserId, 'user-1');
  });

  test('background mode returns at once with the ask id', () async {
    final answer = await call(args(mode: 'background'));
    expect(answer['status'], 'pending');
    expect(answer['ask_id'], kit.asks.all(PeerKit.ws).single.id);
    expect(kit.asks.all(PeerKit.ws).single.mode, PeerAskMode.background);
  });

  test('a failed run fails the ask with the recipient named', () async {
    final pending = call(args());
    await kit.pump();
    await kit.finish('run-1', endReason: RunEndReason.error, summary: 'boom');
    final answer = await pending;
    expect(answer['status'], 'failed');
    expect(answer['error'], 'run_failed');
  });

  test(
    'a run that ends with no final message is a no_output failure',
    () async {
      final pending = call(args());
      await kit.pump();
      await kit.finish('run-1');
      final answer = await pending;
      expect(answer['status'], 'failed');
      expect(answer['error'], 'no_output');
    },
  );

  test(
    'the same question within 10 minutes is refused with the ask id',
    () async {
      await call(args(mode: 'background'));
      final first = kit.asks.all(PeerKit.ws).single;
      final again = await tool.callForRun(
        args(message: '  is THE cast   safe? '),
        runScope(agentId: 'agent-a', runId: 'run-a', conversationId: 'c-sp-a'),
      );
      // Case and spacing do not make a new question.
      expect(again.isError, isTrue);
      expect(refusalField(again, 'kind'), PeerAskRefusals.duplicate);
      expect(refusalField(again, 'ask_id'), first.id);
    },
  );

  test('ten pending asks from one asker refuse the eleventh', () async {
    for (var i = 0; i < PeerAskLimits.maxPendingPerAsker; i++) {
      kit.agent('agent-$i', 'Peer $i');
      await call(args(mode: 'background', to: 'agent-$i', message: 'q$i'));
    }
    final refused = await tool.callForRun(
      args(mode: 'background', message: 'one more'),
      runScope(agentId: 'agent-a', runId: 'run-a', conversationId: 'c-sp-a'),
    );
    expect(refused.isError, isTrue);
    expect(refusalField(refused, 'kind'), PeerAskRefusals.limitReached);
  });

  test('A asks B, B asks A in the background: refused as a cycle', () async {
    await call(args(mode: 'background'));
    await kit.pump();
    // B's run answering A's ask asks A back.
    final back = await tool.callForRun(
      args(to: 'agent-a', from: 'agent-b', mode: 'background', message: 'Why?'),
      runScope(agentId: 'agent-b', runId: 'run-1', conversationId: 'c-dm-2'),
    );
    expect(back.isError, isTrue);
    expect(refusalField(back, 'kind'), PeerAskRefusals.cycle);
    expect(kit.asks.all(PeerKit.ws), hasLength(1));
  });

  test('a read-only run may not ask', () async {
    kit.sessions.add(
      KitSession(
        agentId: 'agent-a',
        conversationId: 'c-sp-a',
        runLogId: 'run-a',
        readOnly: true,
      ),
    );
    kit.service.readOnlyRunOf = (conversation, run) => kit.sessions.any(
      (s) =>
          s.conversationId == conversation && s.runLogId == run && s.readOnly,
    );
    final refused = await tool.callForRun(
      args(),
      runScope(agentId: 'agent-a', runId: 'run-a', conversationId: 'c-sp-a'),
    );
    expect(refused.isError, isTrue);
    expect(refusalField(refused, 'kind'), PeerAskRefusals.readOnlyRun);
    expect(messaging.posted, isEmpty);
  });

  test('a call with no run conversation is refused', () async {
    final refused = await tool.run(args());
    expect(refused.isError, isTrue);
    expect(refusalField(refused, 'kind'), PeerAskRefusals.noConversation);
    expect(messaging.posted, isEmpty);
  });

  test(
    'the first ask of a run carries the reference, later ones do not',
    () async {
      final first = await call(args(mode: 'background'));
      final second = await call(args(mode: 'background', message: 'Another?'));
      expect(first['reference'], askAgentReference);
      expect(second.containsKey('reference'), isFalse);
    },
  );

  test('an agent of another workspace is not found', () async {
    kit.agent('agent-x', 'Xi', workspaceId: PeerKit.other);
    final refused = await tool.callForRun(
      args(to: 'agent-x'),
      runScope(agentId: 'agent-a', runId: 'run-a', conversationId: 'c-sp-a'),
    );
    expect(refused.isError, isTrue);
    expect(kit.asks.all(PeerKit.ws), isEmpty);
    expect(kit.dispatched, isEmpty);
  });

  test('autonomy ceiling and exhausted budget refuse before posting', () async {
    askerAutonomy = AutonomyLevel.proposeOnly;
    final ceiling = await tool.callForRun(
      args(),
      runScope(agentId: 'agent-a', runId: 'run-a', conversationId: 'c-sp-a'),
    );
    expect(ceiling.isError, isTrue);
    expect(ceiling.content.first.text, contains('ceiling'));
    askerAutonomy = AutonomyLevel.actWithApproval;
    remainingBudget = 0;
    final budget = await tool.callForRun(
      args(),
      runScope(agentId: 'agent-a', runId: 'run-a', conversationId: 'c-sp-a'),
    );
    expect(budget.isError, isTrue);
    expect(budget.content.first.text, contains('budget'));
    expect(messaging.posted, isEmpty);
    expect(messaging.spaces.keys, ['sp-a']);
  });

  test('a refused ask spends no rate-limit slot', () async {
    final limiter = PairRateLimiter(maxPerWindow: 1);
    tool = build(limiter: limiter);
    remainingBudget = 0;
    await tool.callForRun(
      args(),
      runScope(agentId: 'agent-a', runId: 'run-a', conversationId: 'c-sp-a'),
    );
    expect(limiter.tryAcquire('agent-a', 'agent-b', DateTime.now()), isTrue);
  });

  test('the DM space checks out no repos', () async {
    await call(args(mode: 'background'));
    expect(messaging.createdWithRepoIds, isEmpty);
  });

  test('the description ends with the peer guidance', () {
    expect(tool.description, endsWith(peerMessageGuidance));
    expect(tool.description, contains(askAgentModeText));
  });
}
