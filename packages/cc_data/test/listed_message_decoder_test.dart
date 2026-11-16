import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/message_lifecycle_states.dart';
import 'package:test/test.dart';

/// A list subscription reuses the message it decoded last time for a row the
/// server did not change, and decodes again the moment it did.
void main() {
  Map<String, dynamic> row(
    String id, {
    int? revision = 0,
    String content = 'hello',
    Map<String, dynamic>? metadata,
  }) => {
    'id': id,
    'content': content,
    'sender_id': 'u1',
    'sender_type': 'user',
    'message_type': 'text',
    'metadata': metadata,
    'space_id': 's1',
    'conversation_id': 'c1',
    'compacted': false,
    'created_at': '2026-11-16T09:00:00.000',
    'revision': ?revision,
  };

  test('an unchanged row is the identical instance, without a decode', () {
    final decoder = ListedMessageDecoder(fallbackSpaceId: 's1');
    final first = decoder.decode([row('m1'), row('m2')]);
    // Same id and revision: the content is not even looked at, which is the
    // point. A server never sends this pair; it proves no decode ran.
    final second = decoder.decode([
      row('m1', content: 'never read'),
      row('m2'),
      row('m3'),
    ]);
    expect(identical(second[0], first[0]), isTrue);
    expect(second[0].content, 'hello');
    expect(identical(second[1], first[1]), isTrue);
    expect(second[2].id, 'm3');
  });

  test('a revision bump decodes the row again', () {
    final decoder = ListedMessageDecoder(fallbackSpaceId: 's1');
    final first = decoder.decode([row('m1')]);
    final second = decoder.decode([row('m1', revision: 1, content: 'edited')]);
    expect(identical(second.single, first.single), isFalse);
    expect(second.single.content, 'edited');
    expect(second.single.revision, 1);
  });

  test('transcript facts the row does not hold decode it again', () {
    final decoder = ListedMessageDecoder(fallbackSpaceId: 's1');
    final streaming = decoder.decode([
      row('t1', metadata: {'segments_elided': true}),
    ]);
    final finished = decoder.decode([
      row('t1', metadata: {'segments_elided': true, 'segment_count': 4}),
    ]);
    expect(identical(finished.single, streaming.single), isFalse);
    expect(finished.single.metadata?['segment_count'], 4);
    final again = decoder.decode([
      row('t1', metadata: {'segments_elided': true, 'segment_count': 4}),
    ]);
    expect(identical(again.single, finished.single), isTrue);
  });

  test('a row without a revision is always decoded', () {
    final decoder = ListedMessageDecoder(fallbackSpaceId: 's1');
    final first = decoder.decode([row('m1', revision: null)]);
    final second = decoder.decode([row('m1', revision: null)]);
    expect(identical(second.single, first.single), isFalse);
  });

  test('only the previous emission is remembered', () {
    final decoder = ListedMessageDecoder(fallbackSpaceId: 's1');
    final first = decoder.decode([row('m1')]);
    decoder.decode(const []);
    final third = decoder.decode([row('m1')]);
    expect(identical(third.single, first.single), isFalse);
  });

  test('an outline entry decodes from its compact array', () {
    final entry = RpcMessagingRepository.outlineEntryFromWire([
      'm1',
      DateTime.utc(2026, 11, 16, 9).millisecondsSinceEpoch,
      'agent-1',
      'agent',
      'agentTurn',
      42,
      7,
      'queued',
      1,
      3,
    ]);
    expect(entry.id, 'm1');
    expect(entry.createdAt.toUtc(), DateTime.utc(2026, 11, 16, 9));
    expect(entry.senderType, SenderType.agent);
    expect(entry.messageType, MessageType.agentTurn);
    expect(entry.contentChars, 42);
    expect(entry.segmentCount, 7);
    expect(entry.steerState, SteeringState.queued);
    expect(entry.answered, isTrue);
    expect(entry.revision, 3);

    final bare = RpcMessagingRepository.outlineEntryFromWire([
      'm2',
      0,
      'u1',
      'user',
      'text',
      0,
      null,
      null,
      0,
      0,
    ]);
    expect(bare.segmentCount, isNull);
    expect(bare.steerState, isNull);
    expect(bare.answered, isFalse);
  });
}
