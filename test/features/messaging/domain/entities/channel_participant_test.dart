import 'package:control_center/features/messaging/domain/entities/channel_participant.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2025, 1, 15);

  ChannelParticipant createParticipant({
    String id = 'cp-1',
    String channelId = 'ch-1',
    String agentId = 'agent-1',
    String role = 'member',
    DateTime? joinedAt,
  }) {
    return ChannelParticipant(
      id: id,
      channelId: channelId,
      agentId: agentId,
      role: role,
      joinedAt: joinedAt ?? now,
    );
  }

  group('ChannelParticipant constructor', () {
    test('creates participant with required fields', () {
      final p = createParticipant();
      expect(p.id, 'cp-1');
      expect(p.channelId, 'ch-1');
      expect(p.agentId, 'agent-1');
      expect(p.role, 'member');
      expect(p.joinedAt, now);
    });

    test('throws assertion error for empty agentId', () {
      expect(
        () => ChannelParticipant(
          id: '1',
          channelId: 'ch-1',
          agentId: '',
          role: 'member',
          joinedAt: now,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('stores sentinel user value', () {
      final p = createParticipant(agentId: 'user');
      expect(p.agentId, 'user');
    });
  });

  group('ChannelParticipant computed properties', () {
    test('isUser returns true when agentId is "user"', () {
      final p = createParticipant(agentId: 'user');
      expect(p.isUser, isTrue);
    });

    test('isUser returns false for agent participant', () {
      final p = createParticipant(agentId: 'agent-1');
      expect(p.isUser, isFalse);
    });

    test('isUser returns false for other string values', () {
      final p = createParticipant(agentId: 'ceo');
      expect(p.isUser, isFalse);
    });
  });

  group('ChannelParticipant == and hashCode', () {
    test('identical participants are equal', () {
      final a = createParticipant();
      final b = createParticipant();
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('different id makes unequal', () {
      final a = createParticipant(id: 'a');
      final b = createParticipant(id: 'b');
      expect(a, isNot(equals(b)));
    });

    test('different channelId makes unequal', () {
      final a = createParticipant(channelId: 'ch-1');
      final b = createParticipant(channelId: 'ch-2');
      expect(a, isNot(equals(b)));
    });

    test('different agentId makes unequal', () {
      final a = createParticipant(agentId: 'agent-1');
      final b = createParticipant(agentId: 'agent-2');
      expect(a, isNot(equals(b)));
    });

    test('different role makes unequal', () {
      final a = createParticipant(role: 'member');
      final b = createParticipant(role: 'admin');
      expect(a, isNot(equals(b)));
    });

    test('self equality', () {
      final a = createParticipant();
      expect(a, equals(a));
    });
  });

  group('ChannelParticipant copyWith', () {
    test('returns new instance with updated role', () {
      final p = createParticipant();
      final updated = p.copyWith(role: 'admin');
      expect(updated.role, 'admin');
      expect(updated.id, 'cp-1');
    });

    test('returns new instance with updated agentId', () {
      final p = createParticipant(agentId: 'agent-1');
      final updated = p.copyWith(agentId: 'agent-2');
      expect(updated.agentId, 'agent-2');
    });

    test('copyWith without changes returns equal participant', () {
      final p = createParticipant();
      final updated = p.copyWith();
      expect(updated, equals(p));
    });
  });
}
