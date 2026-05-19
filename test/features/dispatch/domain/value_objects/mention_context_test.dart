import 'package:cc_domain/features/dispatch/domain/value_objects/mention_context.dart';
import 'package:test/test.dart';

void main() {
  // ---- MentionRosterEntry -------------------------------------------------

  group('MentionRosterEntry', () {
    test('equals when all fields match', () {
      const a = MentionRosterEntry.agent(
        agentId: 'a1',
        name: 'Alice',
        isTopLevel: true,
      );
      const b = MentionRosterEntry.agent(
        agentId: 'a1',
        name: 'Alice',
        isTopLevel: true,
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('not equal when agentId differs', () {
      const a = MentionRosterEntry.agent(
        agentId: 'a1',
        name: 'Alice',
        isTopLevel: true,
      );
      const b = MentionRosterEntry.agent(
        agentId: 'a2',
        name: 'Alice',
        isTopLevel: true,
      );
      expect(a, isNot(equals(b)));
    });

    test('not equal when name differs', () {
      const a = MentionRosterEntry.agent(
        agentId: 'a1',
        name: 'Alice',
        isTopLevel: true,
      );
      const b = MentionRosterEntry.agent(
        agentId: 'a1',
        name: 'Bob',
        isTopLevel: true,
      );
      expect(a, isNot(equals(b)));
    });

    test('not equal when isTopLevel differs', () {
      const a = MentionRosterEntry.agent(
        agentId: 'a1',
        name: 'Alice',
        isTopLevel: true,
      );
      const b = MentionRosterEntry.agent(
        agentId: 'a1',
        name: 'Alice',
        isTopLevel: false,
      );
      expect(a, isNot(equals(b)));
    });

    test('identical instance equals itself', () {
      const a = MentionRosterEntry.agent(
        agentId: 'a1',
        name: 'Alice',
        isTopLevel: false,
      );
      expect(a, equals(a));
    });

    test('not equal to non-MentionRosterEntry', () {
      const a = MentionRosterEntry.agent(
        agentId: 'a1',
        name: 'Alice',
        isTopLevel: false,
      );
      expect(a, isNot(equals('not an entry')));
    });

    test('hashCode consistent with equality', () {
      const a = MentionRosterEntry.agent(
        agentId: 'a1',
        name: 'Alice',
        isTopLevel: true,
      );
      const b = MentionRosterEntry.agent(
        agentId: 'a1',
        name: 'Alice',
        isTopLevel: true,
      );
      expect(a.hashCode, equals(b.hashCode));
    });

    test('agent entry is distinct from user entry', () {
      const agent = MentionRosterEntry.agent(
        agentId: 'a1',
        name: 'Alice',
        isTopLevel: true,
      );
      const user = MentionRosterEntry.user(userId: 'a1', name: 'Alice');
      expect(agent, isNot(equals(user)));
    });
  });

  // ---- MentionContext -----------------------------------------------------

  group('MentionContext', () {
    test('equals when summonedBy and roster match', () {
      final roster = [
        const MentionRosterEntry.agent(
          agentId: 'a1',
          name: 'Alice',
          isTopLevel: true,
        ),
        const MentionRosterEntry.agent(
          agentId: 'b2',
          name: 'Bob',
          isTopLevel: false,
        ),
      ];
      final a = MentionContext(summonedBy: 'user1', spaceRoster: roster);
      final b = MentionContext(summonedBy: 'user1', spaceRoster: roster);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('not equal when summonedBy differs', () {
      final roster = <MentionRosterEntry>[];
      final a = MentionContext(summonedBy: 'user1', spaceRoster: roster);
      final b = MentionContext(summonedBy: 'user2', spaceRoster: roster);
      expect(a, isNot(equals(b)));
    });

    test('not equal when roster length differs', () {
      const a = MentionContext(
        summonedBy: 'user1',
        spaceRoster: [
          MentionRosterEntry.agent(
            agentId: 'a1',
            name: 'Alice',
            isTopLevel: true,
          ),
        ],
      );
      const b = MentionContext(
        summonedBy: 'user1',
        spaceRoster: <MentionRosterEntry>[],
      );
      expect(a, isNot(equals(b)));
    });

    test('not equal when roster entries differ', () {
      const a = MentionContext(
        summonedBy: 'user1',
        spaceRoster: [
          MentionRosterEntry.agent(
            agentId: 'a1',
            name: 'Alice',
            isTopLevel: true,
          ),
        ],
      );
      const b = MentionContext(
        summonedBy: 'user1',
        spaceRoster: [
          MentionRosterEntry.agent(
            agentId: 'b2',
            name: 'Bob',
            isTopLevel: true,
          ),
        ],
      );
      expect(a, isNot(equals(b)));
    });

    test('identical instance equals itself', () {
      const a = MentionContext(summonedBy: 'user1', spaceRoster: []);
      expect(a, equals(a));
    });

    test('not equal to non-MentionContext', () {
      const a = MentionContext(summonedBy: 'user1', spaceRoster: []);
      expect(a, isNot(equals(42)));
    });

    test('empty rosters with same summonedBy are equal', () {
      const a = MentionContext(summonedBy: 'user1', spaceRoster: []);
      const b = MentionContext(summonedBy: 'user1', spaceRoster: []);
      expect(a, equals(b));
    });

    test('roster order matters for equality', () {
      final rosterA = [
        const MentionRosterEntry.agent(
          agentId: 'a1',
          name: 'Alice',
          isTopLevel: true,
        ),
        const MentionRosterEntry.agent(
          agentId: 'b2',
          name: 'Bob',
          isTopLevel: false,
        ),
      ];
      final rosterB = [
        const MentionRosterEntry.agent(
          agentId: 'b2',
          name: 'Bob',
          isTopLevel: false,
        ),
        const MentionRosterEntry.agent(
          agentId: 'a1',
          name: 'Alice',
          isTopLevel: true,
        ),
      ];
      final a = MentionContext(summonedBy: 'user1', spaceRoster: rosterA);
      final b = MentionContext(summonedBy: 'user1', spaceRoster: rosterB);
      // Order matters in list equality
      expect(a, isNot(equals(b)));
    });
  });
}
