import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/conversation_outline_entry.dart';
import 'package:control_center/features/messaging/presentation/widgets/feed/feed_timeline.dart';
import 'package:flutter_test/flutter_test.dart';

final _t0 = DateTime.utc(2026, 1, 1, 12);

DateTime _at(int i) => _t0.add(Duration(minutes: i));

Message _message(int i, {SenderType sender = SenderType.agent}) => Message(
  id: 'm$i',
  spaceId: 's',
  conversationId: 's',
  senderId: sender == SenderType.agent ? 'agent-1' : 'user-1',
  senderType: sender,
  content: 'message $i',
  messageType: MessageType.text,
  createdAt: _at(i),
);

ConversationOutlineEntry _entry(
  int i, {
  SenderType sender = SenderType.agent,
}) => ConversationOutlineEntry(
  id: 'm$i',
  createdAt: _at(i),
  senderId: sender == SenderType.agent ? 'agent-1' : 'user-1',
  senderType: sender,
  messageType: MessageType.text,
  contentChars: 9,
);

List<Message> _messages(int from, int to) => [
  for (var i = from; i < to; i++) _message(i),
];

List<ConversationOutlineEntry> _outline(int count) => [
  for (var i = 0; i < count; i++) _entry(i),
];

/// A compact picture of the spans: `L<n>` loaded (with `*` when it reaches
/// the newest message and `^` after a gap), `P<n>` stand-ins.
List<String> _shape(FeedTimeline timeline) => [
  for (final span in timeline.spans)
    switch (span) {
      LoadedSpan(:final messages, :final afterGap, :final reachesNewest) =>
        'L${messages.length}${afterGap ? '^' : ''}${reachesNewest ? '*' : ''}',
      StandInSpan(:final entries) => 'P${entries.length}',
    },
];

void main() {
  test('without history the feed is the live window', () {
    final timeline = composeFeedTimeline(
      live: _messages(0, 5),
      liveHasMore: false,
      outline: _outline(5),
    );
    expect(_shape(timeline), ['L5*']);
    expect(timeline.outlineStale, isFalse);
  });

  test('while the outline loads, only the live window shows', () {
    final timeline = composeFeedTimeline(
      live: _messages(90, 100),
      liveHasMore: true,
    );
    expect(_shape(timeline), ['L10^*']);
  });

  test('history beyond the live window is stand-ins', () {
    final timeline = composeFeedTimeline(
      live: _messages(90, 100),
      liveHasMore: true,
      outline: _outline(100),
    );
    expect(_shape(timeline), ['P90', 'L10^*']);
    final standIns = (timeline.spans.first as StandInSpan).entries;
    expect(standIns.first.id, 'm0');
    expect(standIns.last.id, 'm89');
  });

  test('a range in the middle of history loads between stand-ins', () {
    final timeline = composeFeedTimeline(
      live: _messages(90, 100),
      liveHasMore: true,
      outline: _outline(100),
      range: _messages(40, 50),
    );
    expect(_shape(timeline), ['P40', 'L10^', 'P40', 'L10^*']);
  });

  test('a range reaching the live window merges with it', () {
    final timeline = composeFeedTimeline(
      live: _messages(90, 100),
      liveHasMore: true,
      outline: _outline(100),
      // Overlaps the live window: the overlap is the live window's.
      range: _messages(70, 95),
    );
    expect(_shape(timeline), ['P70', 'L30^*']);
    final merged = (timeline.spans.last as LoadedSpan).messages;
    expect(merged.map((m) => m.id).toSet(), hasLength(30));
  });

  test('a range from the first message has no gap before it', () {
    final timeline = composeFeedTimeline(
      live: _messages(90, 100),
      liveHasMore: true,
      outline: _outline(100),
      range: _messages(0, 10),
    );
    expect(_shape(timeline), ['L10', 'P80', 'L10^*']);
  });

  test('an outline older than the live window is stale', () {
    // The outline was read before the 50 newest messages existed.
    final timeline = composeFeedTimeline(
      live: _messages(90, 100),
      liveHasMore: true,
      outline: _outline(50),
    );
    expect(timeline.outlineStale, isTrue);
    expect(_shape(timeline), ['P50', 'L10^*']);
  });

  test('a range message the outline does not list makes it stale', () {
    final timeline = composeFeedTimeline(
      live: _messages(90, 100),
      liveHasMore: true,
      outline: [
        for (final e in _outline(100))
          if (e.id != 'm45') e,
      ],
      range: _messages(40, 50),
    );
    expect(timeline.outlineStale, isTrue);
  });

  group('firstUnreadId', () {
    test('finds the earliest unread across stand-ins and loaded spans', () {
      final timeline = composeFeedTimeline(
        live: _messages(90, 100),
        liveHasMore: true,
        outline: _outline(100),
      );
      expect(firstUnreadId(timeline.spans, _at(50)), 'm51');
      expect(firstUnreadId(timeline.spans, _at(95)), 'm96');
      expect(firstUnreadId(timeline.spans, _at(100)), isNull);
      expect(firstUnreadId(timeline.spans, null), isNull);
    });

    test("the reader's own messages are never unread", () {
      final timeline = composeFeedTimeline(
        live: [
          _message(0),
          _message(1, sender: SenderType.user),
          _message(2),
        ],
        liveHasMore: false,
      );
      expect(firstUnreadId(timeline.spans, _at(0)), 'm2');
    });
  });
}
