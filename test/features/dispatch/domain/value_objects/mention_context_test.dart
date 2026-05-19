import 'package:control_center/features/dispatch/domain/value_objects/mention_context.dart';
import 'package:test/test.dart';

void main() {
  // ---- MentionRosterEntry -------------------------------------------------

  group('MentionRosterEntry', () {
    test('equals when all fields match', timeout: const Timeout.factor(2), () {
      const a = MentionRosterEntry(agentId: 'a1', name: 'Alice', isTopLevel: true);
      const b = MentionRosterEntry(agentId: 'a1', name: 'Alice', isTopLevel: true);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('not equal when agentId differs', timeout: const Timeout.factor(2), () {
      const a = MentionRosterEntry(agentId: 'a1', name: 'Alice', isTopLevel: true);
      const b = MentionRosterEntry(agentId: 'a2', name: 'Alice', isTopLevel: true);
      expect(a, isNot(equals(b)));
    });

    test('not equal when name differs', timeout: const Timeout.factor(2), () {
      const a = MentionRosterEntry(agentId: 'a1', name: 'Alice', isTopLevel: true);
      const b = MentionRosterEntry(agentId: 'a1', name: 'Bob', isTopLevel: true);
      expect(a, isNot(equals(b)));
    });

    test('not equal when isTopLevel differs', timeout: const Timeout.factor(2), () {
      const a = MentionRosterEntry(agentId: 'a1', name: 'Alice', isTopLevel: true);
      const b = MentionRosterEntry(agentId: 'a1', name: 'Alice', isTopLevel: false);
      expect(a, isNot(equals(b)));
    });

    test('identical instance equals itself', timeout: const Timeout.factor(2), () {
      const a = MentionRosterEntry(agentId: 'a1', name: 'Alice', isTopLevel: false);
      expect(a, equals(a));
    });

    test('not equal to non-MentionRosterEntry', timeout: const Timeout.factor(2), () {
      const a = MentionRosterEntry(agentId: 'a1', name: 'Alice', isTopLevel: false);
      expect(a, isNot(equals('not an entry')));
    });

    test('hashCode consistent with equality', timeout: const Timeout.factor(2), () {
      const a = MentionRosterEntry(agentId: 'a1', name: 'Alice', isTopLevel: true);
      const b = MentionRosterEntry(agentId: 'a1', name: 'Alice', isTopLevel: true);
      expect(a.hashCode, equals(b.hashCode));
    });
  });

  // ---- MentionContext -----------------------------------------------------

  group('MentionContext', () {
    test('equals when summonedBy and roster match', timeout: const Timeout.factor(2), () {
      final roster = [
        const MentionRosterEntry(agentId: 'a1', name: 'Alice', isTopLevel: true),
        const MentionRosterEntry(agentId: 'b2', name: 'Bob', isTopLevel: false),
      ];
      final a = MentionContext(summonedBy: 'user1', channelRoster: roster);
      final b = MentionContext(summonedBy: 'user1', channelRoster: roster);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('not equal when summonedBy differs', timeout: const Timeout.factor(2), () {
      final roster = <MentionRosterEntry>[];
      final a = MentionContext(summonedBy: 'user1', channelRoster: roster);
      final b = MentionContext(summonedBy: 'user2', channelRoster: roster);
      expect(a, isNot(equals(b)));
    });

    test('not equal when roster length differs', timeout: const Timeout.factor(2), () {
      const a = MentionContext(summonedBy: 'user1', channelRoster: [
        MentionRosterEntry(agentId: 'a1', name: 'Alice', isTopLevel: true),
      ]);
      const b = MentionContext(summonedBy: 'user1', channelRoster: <MentionRosterEntry>[]);
      expect(a, isNot(equals(b)));
    });

    test('not equal when roster entries differ', timeout: const Timeout.factor(2), () {
      const a = MentionContext(summonedBy: 'user1', channelRoster: [
        MentionRosterEntry(agentId: 'a1', name: 'Alice', isTopLevel: true),
      ]);
      const b = MentionContext(summonedBy: 'user1', channelRoster: [
        MentionRosterEntry(agentId: 'b2', name: 'Bob', isTopLevel: true),
      ]);
      expect(a, isNot(equals(b)));
    });

    test('identical instance equals itself', timeout: const Timeout.factor(2), () {
      const a = MentionContext(summonedBy: 'user1', channelRoster: []);
      expect(a, equals(a));
    });

    test('not equal to non-MentionContext', timeout: const Timeout.factor(2), () {
      const a = MentionContext(summonedBy: 'user1', channelRoster: []);
      expect(a, isNot(equals(42)));
    });

    test('empty rosters with same summonedBy are equal', timeout: const Timeout.factor(2), () {
      const a = MentionContext(summonedBy: 'user1', channelRoster: []);
      const b = MentionContext(summonedBy: 'user1', channelRoster: []);
      expect(a, equals(b));
    });

    test('roster order matters for equality', timeout: const Timeout.factor(2), () {
      final rosterA = [
        const MentionRosterEntry(agentId: 'a1', name: 'Alice', isTopLevel: true),
        const MentionRosterEntry(agentId: 'b2', name: 'Bob', isTopLevel: false),
      ];
      final rosterB = [
        const MentionRosterEntry(agentId: 'b2', name: 'Bob', isTopLevel: false),
        const MentionRosterEntry(agentId: 'a1', name: 'Alice', isTopLevel: true),
      ];
      final a = MentionContext(summonedBy: 'user1', channelRoster: rosterA);
      final b = MentionContext(summonedBy: 'user1', channelRoster: rosterB);
      // Order matters in list equality
      expect(a, isNot(equals(b)));
    });
  });
}
