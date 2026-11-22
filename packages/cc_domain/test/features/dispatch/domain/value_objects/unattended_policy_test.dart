import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/core/domain/ports/agent_question_port.dart';
import 'package:cc_domain/features/dispatch/domain/prompts/prompt_builder.dart';
import 'package:cc_domain/features/dispatch/domain/usecases/build_conversation_context_use_case.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/unattended_policy.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/still_in_flight_row.dart';
import 'package:test/test.dart';

Message _row(
  String id, {
  MessageType type = MessageType.system,
  Map<String, dynamic>? metadata,
  bool compacted = false,
  String content =
      '## Still in flight (from the server at 09:00; refresh '
      'before relying on it)\n- Goal: segment 2 → goal_status',
}) => Message(
  id: id,
  spaceId: 's',
  conversationId: 'c',
  senderId: 'system',
  senderType: SenderType.system,
  content: content,
  messageType: type,
  metadata: metadata,
  compacted: compacted,
  createdAt: DateTime.utc(2026),
);

void main() {
  group('UnattendedPolicy', () {
    test('defaults: 72 hours, digest at 09:00', () {
      final policy = UnattendedPolicy.fromSetting(null);
      expect(policy.expiry, const Duration(hours: 72));
      expect(policy.digestHour, 9);
      expect(UnattendedPolicy.fromSetting('not json'), policy);
      expect(UnattendedPolicy.fromSetting('[1]'), policy);
    });

    test('reads the stored shape and clamps it to 1 hour..7 days', () {
      expect(
        UnattendedPolicy.fromSetting(
          '{"expiry_minutes": 90, "digest_hour": 17}',
        ),
        UnattendedPolicy(expiry: const Duration(minutes: 90), digestHour: 17),
      );
      expect(
        UnattendedPolicy.fromSetting('{"expiry_minutes": 5}').expiry,
        const Duration(hours: 1),
      );
      expect(
        UnattendedPolicy.fromSetting('{"expiry_minutes": 99999}').expiry,
        const Duration(days: 7),
      );
      expect(
        UnattendedPolicy.fromSetting('{"digest_hour": 30}').digestHour,
        23,
      );
      expect(UnattendedPolicy(digestHour: 7).toJson(), {
        'expiry_minutes': 4320,
        'digest_hour': 7,
      });
      expect(
        () => UnattendedPolicy(expiry: const Duration(minutes: 30)),
        throwsArgumentError,
      );
    });

    test('the assume answer, word for word', () {
      expect(
        unattendedAssumeAnswer,
        'nobody is available: state your assumption, proceed only if the '
        'stop conditions allow it, and record it',
      );
      expect(unattendedAssumeAfter, const Duration(minutes: 10));
    });

    test('the notices name the expiry and never say approved', () {
      final q = unattendedQuestionNotice(const Duration(hours: 24));
      expect(q, contains('within 24 hours'));
      expect(q, contains('unanswered'));
      final a = unattendedApprovalNotice(
        'Push to main',
        const Duration(days: 2),
      );
      expect(a, contains('"Push to main" within 2 days'));
      expect(a, contains('counts as denied'));
      expect(a, contains('nothing was approved'));
      expect(
        unattendedExpiredRow(
          what: 'question',
          summary: 'Which DB?',
          expiry: const Duration(minutes: 90),
          goalPaused: true,
        ),
        'Nobody answered the question "Which DB?" within 90 minutes, so it '
        'is withdrawn. The goal is paused until a person reviews it.',
      );
    });
  });

  group('an unanswered question', () {
    test('withdrawn: the agent reads the notice as an error', () {
      final outcome = AskUserOutcome.fromAnswer(
        const AgentQuestionAnswer.unanswered('nobody answered', proceed: false),
      );
      expect(outcome.text, 'nobody answered');
      expect(outcome.isError, isTrue);
    });

    test('released by assume: the agent reads the notice and proceeds', () {
      final outcome = AskUserOutcome.fromAnswer(
        const AgentQuestionAnswer.unanswered(
          unattendedAssumeAnswer,
          proceed: true,
        ),
      );
      expect(outcome.text, unattendedAssumeAnswer);
      expect(outcome.isError, isFalse);
    });
  });

  group('the Still in flight row', () {
    test('is a marked system row of one agent', () {
      expect(
        stillInFlightRowAgent(_row('b', metadata: {stillInFlightRowKey: 'a1'})),
        'a1',
      );
      expect(stillInFlightRowAgent(_row('b')), isNull);
      expect(
        stillInFlightRowAgent(
          _row(
            'b',
            type: MessageType.text,
            metadata: {stillInFlightRowKey: 'a1'},
          ),
        ),
        isNull,
      );
    });

    test('only the newest live block of the agent counts', () {
      final rows = [
        _row('old', metadata: {stillInFlightRowKey: 'a1'}, compacted: true),
        _row('mine', metadata: {stillInFlightRowKey: 'a1'}),
        _row('theirs', metadata: {stillInFlightRowKey: 'a2'}),
      ];
      expect(newestStillInFlightRow(rows, 'a1')?.id, 'mine');
      expect(newestStillInFlightRow(rows, 'a3'), isNull);
    });

    test('two turns after one compaction: the block is in the context once, '
        'in place, and later messages follow it', () {
      Message msg(String id, int minute, {SenderType type = SenderType.user}) =>
          Message(
            id: id,
            spaceId: 's',
            conversationId: 'c',
            senderId: type == SenderType.user ? 'u-1' : 'a1',
            senderType: type,
            content: 'message $id',
            messageType: MessageType.text,
            createdAt: DateTime.utc(2026, 11, 19, 9, minute),
          );
      final block = Message(
        id: 'blk',
        spaceId: 's',
        conversationId: 'c',
        senderId: 'system',
        senderType: SenderType.system,
        content: '## Still in flight (from the server at 2026-11-19 09:10 '
            'UTC; refresh before relying on it)\n- Goal: segment 2',
        messageType: MessageType.system,
        metadata: {stillInFlightRowKey: 'a1'},
        createdAt: DateTime.utc(2026, 11, 19, 9, 10),
      );
      ConversationContextParts turn(List<Message> window) =>
          buildConversationContextParts(
            spaceId: 's',
            selfAgentId: 'a1',
            selfAgentName: 'architect',
            messages: [...window, block],
            verbatimWindow: window,
            summaries: const [],
            semanticHits: const [],
            stillInFlight: block,
          );
      List<String> keys(ConversationContextParts p) => [
        for (final e in p.entries) e.key.split('#').first,
      ];

      final first = turn([msg('u1', 8)]);
      expect(keys(first), ['recent:u1', 'inflight:blk']);

      final second = turn([
        msg('u1', 8),
        msg('a2', 12, type: SenderType.agent),
        msg('u3', 14),
      ]);
      expect(keys(second), [
        'recent:u1',
        'inflight:blk',
        'recent:a2',
        'recent:u3',
      ]);
      expect('Still in flight'.allMatches(second.text), hasLength(1));
      expect(
        second.text.indexOf('Still in flight'),
        lessThan(second.text.indexOf('message u3')),
      );
      expect(
        second.entries[1].provenance,
        PromptConversationProvenance.system,
      );
    });

    test('with no recent messages the block still has its place', () {
      final block = _row('blk', metadata: {stillInFlightRowKey: 'a1'});
      final parts = buildConversationContextParts(
        spaceId: 's',
        selfAgentId: 'a1',
        selfAgentName: 'architect',
        messages: [block],
        verbatimWindow: const [],
        summaries: const [],
        semanticHits: const [],
        stillInFlight: block,
      );
      expect(parts.entries.single.key, startsWith('inflight:blk#'));
    });
  });
}
