import 'package:cc_domain/core/domain/entities/channel_message.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_domain/features/dispatch/domain/context/context_window_usage.dart';
import 'package:test/test.dart';

final _t0 = DateTime.utc(2026);

ChannelMessage _msg(String content, {bool compacted = false}) => ChannelMessage(
      id: 'm${content.hashCode}',
      channelId: 'c',
      senderId: 'user',
      senderType: ChannelSenderType.user,
      content: content,
      messageType: ChannelMessageType.text,
      compacted: compacted,
      createdAt: _t0,
    );

void main() {
  test('fraction and thresholds reflect usage', () {
    const u = ContextWindowUsage(usedTokens: 150000, windowTokens: 200000);
    expect(u.fraction, closeTo(0.75, 0.001));
    expect(u.isWarning, isTrue);
    expect(u.isCritical, isFalse);
    expect(u.remainingTokens, 50000);
  });

  test('critical at 90%+', () {
    const u = ContextWindowUsage(usedTokens: 190000, windowTokens: 200000);
    expect(u.isCritical, isTrue);
  });

  test('computeContextWindowUsage excludes compacted messages', () {
    final messages = [
      _msg('a' * 3800, compacted: true), // ~1000 tokens, excluded
      _msg('b' * 380), // ~100 tokens, counted
    ];
    final usage = computeContextWindowUsage(
      messages: messages,
      windowTokens: 200000,
      systemOverheadTokens: 0,
    );
    // Only the non-compacted ~100-token message counts.
    expect(usage.usedTokens, lessThan(200));
    expect(usage.usedTokens, greaterThanOrEqualTo(100));
  });

  test('reads the last agent turn breakdown', () {
    final turn = ChannelMessage(
      id: 't',
      channelId: 'c',
      senderId: 'agent',
      senderType: ChannelSenderType.agent,
      content: 'ok',
      messageType: ChannelMessageType.agentTurn,
      metadata: {
        'segments': encodeTranscript([TextSegment(text: 'ok', startedAt: _t0)]),
        'turn': {'totalTokens': 1234},
      },
      createdAt: _t0,
    );
    final usage = computeContextWindowUsage(
      messages: [turn],
      windowTokens: 200000,
    );
    expect(usage.lastTurn?.input, 1234);
  });
}
