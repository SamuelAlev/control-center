import 'package:cc_domain/core/domain/entities/channel_message.dart';
import 'package:cc_domain/core/domain/value_objects/entity_ref.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EntityRef', () {
    test('round-trips through JSON', () {
      const ref = EntityRef(
        type: EntityRefType.pullRequest,
        id: '42',
        label: '#42',
        repoFullName: 'acme/app',
      );
      final json = ref.toJson();
      expect(json, {
        'type': 'pullRequest',
        'id': '42',
        'label': '#42',
        'repoFullName': 'acme/app',
      });
      expect(EntityRef.tryFromJson(json), ref);
    });

    test('omits null optional fields in JSON', () {
      const ref = EntityRef(type: EntityRefType.meeting, id: 'm1');
      expect(ref.toJson(), {'type': 'meeting', 'id': 'm1'});
    });

    test('tryFromJson returns null on unknown type', () {
      expect(EntityRef.tryFromJson({'type': 'news', 'id': 'x'}), isNull);
    });

    test('tryFromJson returns null on missing or empty id', () {
      expect(EntityRef.tryFromJson({'type': 'ticket'}), isNull);
      expect(EntityRef.tryFromJson({'type': 'ticket', 'id': ''}), isNull);
    });

    test('equality is structural', () {
      expect(
        const EntityRef(type: EntityRefType.ticket, id: 'a'),
        const EntityRef(type: EntityRefType.ticket, id: 'a'),
      );
      expect(
        const EntityRef(type: EntityRefType.ticket, id: 'a'),
        isNot(const EntityRef(type: EntityRefType.ticket, id: 'b')),
      );
    });
  });

  group('ChannelMessage.entityRefs', () {
    ChannelMessage msg(Map<String, dynamic>? metadata) => ChannelMessage(
      id: 'm',
      channelId: 'c',
      senderId: 'user',
      senderType: ChannelSenderType.user,
      content: 'hi',
      messageType: ChannelMessageType.text,
      metadata: metadata,
      createdAt: DateTime(2026),
    );

    test('returns empty when metadata is absent or malformed', () {
      expect(msg(null).entityRefs, isEmpty);
      expect(msg({'entityRefs': 'nope'}).entityRefs, isEmpty);
    });

    test('decodes valid refs and skips invalid entries', () {
      final m = msg({
        'entityRefs': [
          {'type': 'ticket', 'id': 't1', 'label': 'LIN-1'},
          {'type': 'bogus', 'id': 'x'}, // unknown type → skipped
          {'type': 'meeting'}, // missing id → skipped
          {'type': 'pullRequest', 'id': '7', 'repoFullName': 'a/b'},
        ],
      });
      expect(m.entityRefs, const [
        EntityRef(type: EntityRefType.ticket, id: 't1', label: 'LIN-1'),
        EntityRef(type: EntityRefType.pullRequest, id: '7', repoFullName: 'a/b'),
      ]);
    });
  });
}
