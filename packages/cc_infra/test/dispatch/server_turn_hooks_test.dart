import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/peer_ask_values.dart';
import 'package:cc_harness/context.dart'
    show serializeHarnessHistory, splitPinnedEvidence;
import 'package:cc_harness/loop.dart';
import 'package:cc_harness/messages.dart'
    show HarnessMessage, HarnessMessageOrigin;
import 'package:cc_infra/src/dispatch/peer_ask_service.dart';
import 'package:cc_infra/src/dispatch/server_turn_hooks.dart';
import 'package:test/test.dart';

import 'peer_test_kit.dart';

class _Owner implements AgentLoopTurnHooks {
  _Owner(this.answer);
  final WouldStop answer;
  int calls = 0;

  @override
  Future<WouldStop> onWouldStop(WouldStopContext context) async {
    calls++;
    return answer;
  }

  @override
  Future<String?> preCompact() async => 'owner focus';
}

/// A main run's turn hooks (A4): the server's would-stop handlers first,
/// then the owner's `stop` hook; and the peer handler that reminds a run
/// answering an ask, once, when it would stop with nothing to say.
void main() {
  const blank = WouldStopContext(turn: 3, lastAssistantText: '  ');
  final session = KitSession(
    agentId: 'agent-b',
    conversationId: 'c-b',
    runLogId: 'run-1',
  );

  test('no handler: the owner hooks alone; no run identity: likewise', () {
    final owner = _Owner(const WouldStopEnd());
    expect(
      ServerTurnHooks.compose(WouldStopHandlers(), session, owner: owner),
      same(owner),
    );
    final handlers = WouldStopHandlers()..add((_) async => null);
    expect(
      ServerTurnHooks.compose(
        handlers,
        KitSession(agentId: 'agent-b', conversationId: 'c-b', runLogId: null),
        owner: null,
      ),
      isNull,
    );
  });

  test('a server handler that continues decides before the owner', () async {
    final owner = _Owner(const WouldStopEnd());
    final seen = <ServerWouldStop>[];
    final handlers = WouldStopHandlers()
      ..add((stop) async => throw StateError('broken'))
      ..add((stop) async {
        seen.add(stop);
        return WouldStopContinue('answer the question', origin: null);
      });
    final hooks = ServerTurnHooks.compose(handlers, session, owner: owner)!;
    final answer = await hooks.onWouldStop(blank);
    expect(answer, isA<WouldStopContinue>());
    expect(owner.calls, 0);
    expect(seen.single.runId, 'run-1');
    expect(seen.single.agentId, 'agent-b');
    expect(seen.single.workspaceId, PeerKit.ws);
    expect(await hooks.preCompact(), 'owner focus');
  });

  test('handlers that let the turn end hand it to the owner', () async {
    final owner = _Owner(WouldStopContinue('owner says go on', origin: null));
    final handlers = WouldStopHandlers()
      ..add((_) async => null)
      ..add((_) async => const WouldStopEnd());
    final hooks = ServerTurnHooks.compose(handlers, session, owner: owner)!;
    expect(await hooks.onWouldStop(blank), isA<WouldStopContinue>());
    expect(owner.calls, 1);
    final alone = ServerTurnHooks.compose(handlers, session, owner: null)!;
    expect(await alone.onWouldStop(blank), isA<WouldStopEnd>());
  });

  test(
    'the peer stall reminder: once per ask, only for a blank stop',
    () async {
      final kit = PeerKit()
        ..agent('agent-a', 'Ada')
        ..agent('agent-b', 'Bo')
        ..conversation('c-a', spaceId: 'sp-a')
        ..conversation('c-b', spaceId: 'sp-b')
        ..run('run-a', agentId: 'agent-a', conversationId: 'c-a');
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
      await kit.service.ask(
        const PeerAskRequest(
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
          question: 'Is the cast safe?',
          chain: ['agent-a'],
        ),
      );
      // What the server wires.
      final handlers = WouldStopHandlers()..add(kit.service.onWouldStop);
      final hooks = ServerTurnHooks.compose(handlers, session, owner: null)!;
      const said = WouldStopContext(turn: 3, lastAssistantText: 'Safe.');
      expect(await hooks.onWouldStop(said), isA<WouldStopEnd>());
      final first = await hooks.onWouldStop(blank);
      expect(
        first,
        isA<WouldStopContinue>().having(
          (c) => c.message,
          'message',
          allOf(
            startsWith('Ada (an agent) asked you this'),
            contains('Is the cast safe?'),
          ),
        ),
      );
      // It carries the asker's words: a compaction summarises it as a
      // peer's message, never pins it as steering.
      expect((first as WouldStopContinue).origin, HarnessMessageOrigin.peer);
      final folded = serializeHarnessHistory([
        HarnessMessage.user('Answer Ada.', origin: HarnessMessageOrigin.wake),
        HarnessMessage.system(first.message, origin: first.origin),
      ]);
      expect(folded, contains('Is the cast safe?'));
      expect(
        splitPinnedEvidence(folded).pinned,
        isNot(contains('Is the cast safe?')),
      );
      expect(await hooks.onWouldStop(blank), isA<WouldStopEnd>());
      expect(kit.asks.all(PeerKit.ws).single.stallNoticedRunId, 'run-1');
    },
  );
}
