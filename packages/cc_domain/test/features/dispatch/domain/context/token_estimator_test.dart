import 'package:cc_domain/core/domain/entities/channel_message.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_domain/features/dispatch/domain/context/token_estimator.dart';
import 'package:test/test.dart';

void main() {
  const est = TokenEstimator.instance;
  final t0 = DateTime.utc(2026);

  test('empty text is zero tokens', () {
    expect(est.estimate(''), 0);
  });

  test('estimate grows roughly linearly with length', () {
    expect(est.estimate('a' * 38), 10);
    expect(est.estimate('a' * 380), 100);
  });

  test('estimateSegment counts tool name + inputs + outputs', () {
    final seg = ToolSegment(
      toolName: 'bash',
      toolCallId: '1',
      inputs: const {'cmd': 'ls'},
      outputs: 'a' * 380,
      startedAt: t0,
    );
    expect(est.estimateSegment(seg), greaterThanOrEqualTo(100));
  });

  test('estimateMessage sums an agent turn transcript', () {
    final msg = ChannelMessage(
      id: 'm',
      channelId: 'c',
      senderId: 'agent',
      senderType: ChannelSenderType.agent,
      content: 'short',
      messageType: ChannelMessageType.agentTurn,
      metadata: {
        'segments': encodeTranscript([
          TextSegment(text: 'a' * 380, startedAt: t0),
          ReasoningSegment(text: 'b' * 380, startedAt: t0),
        ]),
      },
      createdAt: t0,
    );
    // Two ~100-token segments dominate the 5-char content fallback.
    expect(est.estimateMessage(msg), greaterThanOrEqualTo(190));
  });

  test('estimateMessage falls back to content for plain text', () {
    final msg = ChannelMessage(
      id: 'm',
      channelId: 'c',
      senderId: 'user',
      senderType: ChannelSenderType.user,
      content: 'a' * 380,
      messageType: ChannelMessageType.text,
      createdAt: t0,
    );
    expect(est.estimateMessage(msg), 100);
  });
}
