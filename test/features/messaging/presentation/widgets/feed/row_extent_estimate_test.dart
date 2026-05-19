import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:control_center/features/messaging/presentation/widgets/feed/row_extent_estimate.dart';
import 'package:flutter_test/flutter_test.dart';

Message _message({
  required MessageType type,
  String content = '',
  Map<String, dynamic>? metadata,
  SenderType sender = SenderType.agent,
}) => Message(
  id: 'm1',
  spaceId: 'ch-1',
  conversationId: 'ch-1',
  senderId: 'agent-1',
  senderType: sender,
  content: content,
  messageType: type,
  metadata: metadata,
  createdAt: DateTime(2024),
);

double _estimate(Message m, {bool collapseHeader = false}) =>
    estimateMessageRowExtent(
      m,
      collapseHeader: collapseHeader,
      columnWidth: 700,
    );

void main() {
  group('estimateMessageRowExtent', () {
    test('grows with the amount of prose', () {
      final short = _estimate(
        _message(type: MessageType.text, content: 'ok'),
      );
      final long = _estimate(
        _message(type: MessageType.text, content: 'word ' * 400),
      );
      expect(long, greaterThan(short * 4));
    });

    test('counts hard line breaks, not just wrapped length', () {
      final wrapped = _estimate(
        _message(type: MessageType.text, content: 'x' * 40),
      );
      final broken = _estimate(
        _message(type: MessageType.text, content: List.filled(8, 'x').join('\n')),
      );
      expect(broken, greaterThan(wrapped));
    });

    test('caps a pathological paste instead of returning a five-figure extent', () {
      final huge = _estimate(
        _message(type: MessageType.text, content: 'x' * 2000000),
      );
      expect(huge, lessThan(5000));
    });

    test('a collapsed header is shorter than a full one', () {
      final message = _message(type: MessageType.text, content: 'hello');
      expect(
        _estimate(message, collapseHeader: true),
        lessThan(_estimate(message)),
      );
    });

    test('an agent turn is taller for every transcript segment it carries', () {
      final bare = _estimate(
        _message(type: MessageType.agentTurn, content: 'done'),
      );
      final busy = _estimate(
        _message(
          type: MessageType.agentTurn,
          content: 'done',
          metadata: const {'segments_elided': true, 'segment_count': 20},
        ),
      );
      expect(busy, greaterThan(bare + 20 * 20));
    });

    test('counts a full row\'s segments without decoding the transcript', () {
      final full = _message(
        type: MessageType.agentTurn,
        content: 'done',
        metadata: const {
          'segments': [
            {'kind': 'text', 'text': 'a'},
            {'kind': 'text', 'text': 'b'},
            {'kind': 'text', 'text': 'c'},
          ],
        },
      );
      final elidedSame = _message(
        type: MessageType.agentTurn,
        content: 'done',
        metadata: const {'segments_elided': true, 'segment_count': 3},
      );
      expect(_estimate(full), _estimate(elidedSame));
    });

    test('falls back to a guess for an elided row the server did not count', () {
      // Rows written before `segment_count` existed still have to be given a
      // height that is not "one line of prose".
      final uncounted = _estimate(
        _message(
          type: MessageType.agentTurn,
          content: 'done',
          metadata: const {'segments_elided': true},
        ),
      );
      final none = _estimate(
        _message(type: MessageType.agentTurn, content: 'done'),
      );
      expect(uncounted, greaterThan(none));
    });

    test('card-shaped kinds take a fixed extent, not their text length', () {
      final short = _estimate(
        _message(type: MessageType.plan, content: 'plan'),
      );
      final long = _estimate(
        _message(type: MessageType.plan, content: 'plan ' * 500),
      );
      expect(short, long);
    });

    test('never returns zero, so an empty row still occupies the list', () {
      for (final type in MessageType.values) {
        expect(_estimate(_message(type: type)), greaterThan(0));
      }
    });
  });
}
