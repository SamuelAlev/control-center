import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_update.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_update_codec.dart';
import 'package:cc_remote/live_turns.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final started = DateTime.utc(2026, 1, 1);

  PhoneTurnRelay relay({
    Future<List<TranscriptSegment>> Function(String messageId)? load,
  }) {
    return PhoneTurnRelay(
      spaceId: 'space',
      loadMessage: load ?? ((_) async => const <TranscriptSegment>[]),
    );
  }

  test('a seed is the live transcript, and an empty seed ends it', () {
    final turns = relay();
    turns.applyEvent(
      TurnRelaySeed([
        (
          messageId: 'm',
          segments: [TextSegment(text: 'hel', startedAt: started)],
        ),
      ]),
    );
    expect(turns.isLive('m'), isTrue);
    expect((turns.liveSegments('m')!.single as TextSegment).text, 'hel');

    turns.applyEvent(const TurnRelaySeed([]));
    expect(turns.isLive('m'), isFalse);
  });

  test('deltas append, and finish keeps the transcript off the live set', () {
    final turns = relay();
    turns.applyEvent(
      TurnRelayUpdates('m', [
        SegmentOpened(0, TextSegment(text: 'hel', startedAt: started)),
        const SegmentDelta(0, 'lo'),
        const TurnFinished(0, TurnOutcome.completed),
      ]),
    );
    expect(turns.isLive('m'), isFalse);
    expect((turns.finishedSegments('m')!.single as TextSegment).text, 'hello');
    expect(turns.liveSegments('m'), isNull);
  });

  test('one load is shared, then served from memory', () async {
    var calls = 0;
    final turns = relay(
      load: (id) async {
        calls++;
        expect(id, 'm');
        return [TextSegment(text: 'stored', startedAt: started)];
      },
    );
    final first = turns.load('m');
    final second = turns.load('m');
    expect(await first, await second);
    expect(calls, 1);
    await turns.load('m');
    expect(calls, 1);
    expect((turns.finishedSegments('m')!.single as TextSegment).text, 'stored');
  });

  MessageDto row(Map<String, dynamic> metadata, {String content = 'answer'}) {
    return MessageDto(
      id: 'm',
      content: content,
      senderId: 'agent',
      senderType: 'agent',
      messageType: 'agent_turn',
      metadata: metadata,
    );
  }

  test('an inline transcript is shown and not fetched', () {
    final view = presentPhoneTurn(
      message: row({
        'segments': [
          {'type': 'text', 'text': 'inline answer', 'ts': 0},
        ],
        'streamComplete': true,
      }),
      isMine: false,
      turns: relay(),
    );
    expect(view.fetch, isFalse);
    expect(view.showTranscript, isTrue);
    expect((view.segments.single as TextSegment).text, 'inline answer');
  });

  test('a finished lite row asks for one load, then shows it', () {
    final turns = relay();
    final waiting = presentPhoneTurn(
      message: row(const {'segments_elided': true, 'streamComplete': true}),
      isMine: false,
      turns: turns,
    );
    expect(waiting.fetch, isTrue);
    expect(waiting.showTranscript, isFalse);

    final loaded = presentPhoneTurn(
      message: row(const {'segments_elided': true, 'streamComplete': true}),
      isMine: false,
      turns: turns,
      fetched: [TextSegment(text: 'from the run', startedAt: started)],
    );
    expect(loaded.fetch, isFalse);
    expect(loaded.showTranscript, isTrue);
    expect((loaded.segments.single as TextSegment).text, 'from the run');
  });

  test('a streaming lite row follows the relay and does not fetch', () {
    final turns = relay();
    final waiting = presentPhoneTurn(
      message: row(const {
        'segments_elided': true,
        'streamComplete': false,
      }, content: 'partial'),
      isMine: false,
      turns: turns,
    );
    expect(waiting.fetch, isFalse);
    expect(waiting.showTranscript, isTrue);
    expect(waiting.streamComplete, isFalse);
    expect(waiting.segments, isEmpty);

    turns.applyEvent(
      TurnRelayUpdates('m', [
        SegmentOpened(0, TextSegment(text: 'hello', startedAt: started)),
      ]),
    );
    final live = presentPhoneTurn(
      message: row(const {'segments_elided': true, 'streamComplete': false}),
      isMine: false,
      turns: turns,
    );
    expect(live.fetch, isFalse);
    expect((live.segments.single as TextSegment).text, 'hello');
    expect(live.streamComplete, isFalse);
  });
}
