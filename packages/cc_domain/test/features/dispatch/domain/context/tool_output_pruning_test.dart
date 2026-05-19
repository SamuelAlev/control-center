import 'package:cc_domain/core/domain/entities/channel_message.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_domain/features/dispatch/domain/context/tool_output_pruning.dart';
import 'package:cc_domain/features/dispatch/domain/context/tool_result_elision.dart';
import 'package:test/test.dart';

final _t0 = DateTime.utc(2026);

ChannelMessage _user(String id, {int minute = 0}) => ChannelMessage(
      id: id,
      channelId: 'c',
      senderId: 'user',
      senderType: ChannelSenderType.user,
      content: 'do the thing',
      messageType: ChannelMessageType.text,
      createdAt: _t0.add(Duration(minutes: minute)),
    );

ChannelMessage _turn(
  String id,
  List<TranscriptSegment> segments, {
  int minute = 0,
}) =>
    ChannelMessage(
      id: id,
      channelId: 'c',
      senderId: 'agent',
      senderType: ChannelSenderType.agent,
      content: 'ok',
      messageType: ChannelMessageType.agentTurn,
      metadata: {'segments': encodeTranscript(segments)},
      createdAt: _t0.add(Duration(minutes: minute)),
    );

ToolSegment _tool(
  String name,
  String outputs, {
  Map<String, dynamic>? inputs,
  bool error = false,
}) =>
    ToolSegment(
      toolName: name,
      toolCallId: '$name-${outputs.hashCode}',
      inputs: inputs,
      outputs: outputs,
      status: error ? ToolSegmentStatus.error : ToolSegmentStatus.ok,
      startedAt: _t0,
      durationMs: 1,
    );

void main() {
  const pruner = ConversationPruner();
  final now = _t0.add(const Duration(hours: 1));

  group('elision pass', () {
    test('blanks an empty search result outside the recent window', () {
      final messages = [
        _user('u0', minute: 0),
        _turn('t0', [_tool('grep', 'No matches found')], minute: 1),
        // Two later user turns push t0 out of the keep-recent window.
        _user('u1', minute: 2),
        _turn('t1', [_tool('read', 'x')], minute: 3),
        _user('u2', minute: 4),
        _turn('t2', [_tool('read', 'y')], minute: 5),
      ];
      final plan = pruner.plan(messages, now: now);
      final segs = plan.updatedSegmentsByMessageId['t0'];
      expect(segs, isNotNull);
      final tool = segs!.single as ToolSegment;
      expect(tool.outputs, elidedResultMarker);
      expect(tool.isPruned, isTrue);
    });

    test('keeps a real error message', () {
      final messages = [
        _user('u0'),
        _turn('t0', [_tool('bash', 'fatal: boom', error: true)], minute: 1),
        _user('u1', minute: 2),
        _turn('t1', [_tool('read', 'x')], minute: 3),
        _user('u2', minute: 4),
        _turn('t2', [_tool('read', 'y')], minute: 5),
      ];
      final plan = pruner.plan(messages, now: now);
      expect(plan.updatedSegmentsByMessageId.containsKey('t0'), isFalse);
    });
  });

  group('recent-turns protection', () {
    test('never prunes tools inside the last two turns', () {
      final messages = [
        _user('u0'),
        _turn('t0', [_tool('grep', 'No matches found')], minute: 1),
      ];
      // t0 is the in-flight turn — protected.
      final plan = pruner.plan(messages, now: now);
      expect(plan.isEmpty, isTrue);
    });
  });

  group('superseded-read pruning', () {
    test('keeps only the latest read of a path', () {
      final older = _tool('read', 'OLD CONTENT' * 10,
          inputs: {'file_path': '/a.dart'});
      final newer = _tool('read', 'NEW CONTENT' * 10,
          inputs: {'file_path': '/a.dart'});
      final messages = [
        _user('u0'),
        _turn('t0', [older], minute: 1),
        _user('u1', minute: 2),
        _turn('t1', [newer], minute: 3),
        _user('u2', minute: 4),
        _turn('t2', [_tool('bash', 'z')], minute: 5),
      ];
      final plan = pruner.plan(messages, now: now);
      // t0's older read is superseded; t1's newer read kept (but t1 is also in
      // the keep window here, so it is untouched).
      final t0 = plan.updatedSegmentsByMessageId['t0'];
      expect(t0, isNotNull);
      expect((t0!.single as ToolSegment).outputs, supersededReadMarker);
    });
  });

  group('budget pruning', () {
    test('protects newest output then prunes the rest past the minimum', () {
      // Build a long history of fat tool outputs across many old turns.
      final messages = <ChannelMessage>[];
      var minute = 0;
      // 12 old turns each with a ~10k-token (≈38k char) tool output.
      for (var i = 0; i < 12; i++) {
        messages.add(_user('u$i', minute: minute++));
        messages.add(_turn('t$i', [_tool('bash', 'X' * 38000)], minute: minute++));
      }
      // Two recent turns kept pristine.
      messages.add(_user('uR1', minute: minute++));
      messages.add(_turn('tR1', [_tool('bash', 'recent')], minute: minute++));
      messages.add(_user('uR2', minute: minute++));
      messages.add(_turn('tR2', [_tool('bash', 'recent')], minute: minute++));

      final plan = pruner.plan(messages, now: now,
          gate: CachePruneGate.always);
      // The newest protected ~40k tokens survive; older fat outputs get pruned.
      expect(plan.isEmpty, isFalse);
      expect(plan.reclaimedTokens, greaterThan(20000));
      // The oldest turn must be pruned.
      final t0 = plan.updatedSegmentsByMessageId['t0'];
      expect(t0, isNotNull);
      expect((t0!.single as ToolSegment).outputs, prunedResultMarker);
    });

    test('does not prune when the cache gate forbids it', () {
      final messages = <ChannelMessage>[];
      var minute = 0;
      for (var i = 0; i < 12; i++) {
        messages.add(_user('u$i', minute: minute++));
        messages.add(_turn('t$i', [_tool('bash', 'X' * 38000)], minute: minute++));
      }
      messages.add(_user('uR1', minute: minute++));
      messages.add(_turn('tR1', [_tool('bash', 'recent')], minute: minute++));
      messages.add(_user('uR2', minute: minute++));
      messages.add(_turn('tR2', [_tool('bash', 'recent')], minute: minute++));

      const forbid = CachePruneGate(
        trailingSuffixTokens: 100000,
        sinceLastActivity: Duration.zero,
      );
      final plan = pruner.plan(messages, now: now, gate: forbid);
      // Budget pruning is gated off, but elision/superseded still run; here
      // there is nothing uneventful, so the plan is empty.
      expect(plan.isEmpty, isTrue);
    });
  });
}
