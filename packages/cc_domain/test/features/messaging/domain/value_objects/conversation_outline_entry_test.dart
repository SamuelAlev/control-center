import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/conversation_outline_entry.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/message_lifecycle_states.dart';
import 'package:test/test.dart';

void main() {
  ConversationOutlineEntry entry({
    String id = 'm1',
    int contentChars = 12,
    int? segmentCount,
    SteeringState? steerState,
    bool answered = false,
    int revision = 0,
  }) => ConversationOutlineEntry(
    id: id,
    createdAt: DateTime.utc(2026, 11, 16, 9),
    senderId: 'u1',
    senderType: SenderType.user,
    messageType: MessageType.text,
    contentChars: contentChars,
    segmentCount: segmentCount,
    steerState: steerState,
    answered: answered,
    revision: revision,
  );

  test('equal by every field, revision included', () {
    expect(entry(), entry());
    expect(entry().hashCode, entry().hashCode);
    expect(entry(revision: 1), isNot(entry()));
    expect(entry(segmentCount: 3), isNot(entry()));
    expect(entry(steerState: SteeringState.queued), isNot(entry()));
    expect(entry(answered: true), isNot(entry()));
  });

  test('refuses an empty id and negative counts', () {
    expect(() => entry(id: ''), throwsArgumentError);
    expect(() => entry(contentChars: -1), throwsArgumentError);
    expect(() => entry(segmentCount: -1), throwsArgumentError);
    expect(() => entry(revision: -1), throwsArgumentError);
  });
}
