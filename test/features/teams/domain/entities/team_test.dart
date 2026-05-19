import 'package:control_center/features/teams/domain/entities/team.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final testCreatedAt = DateTime(2024, 1, 15);

  Team createTeam({
    String id = 'team-1',
    String workspaceId = 'ws-1',
    String name = 'Alpha Team',
    String? description,
    DateTime? createdAt,
  }) {
    return Team(
      id: id,
      workspaceId: workspaceId,
      name: name,
      description: description,
      createdAt: createdAt ?? testCreatedAt,
    );
  }

  group('Team', () {
    group('constructor', () {
      test('creates team with required fields', timeout: const Timeout.factor(2), () {
        final t = createTeam();
        expect(t.id, 'team-1');
        expect(t.workspaceId, 'ws-1');
        expect(t.name, 'Alpha Team');
        expect(t.description, isNull);
        expect(t.createdAt, testCreatedAt);
      });

      test('creates team with description', timeout: const Timeout.factor(2), () {
        final t = createTeam(description: 'A description');
        expect(t.description, 'A description');
      });

      test('constructor asserts name is not empty', timeout: const Timeout.factor(2), () {
        expect(
          () => Team(
            id: 'team-x',
            workspaceId: 'ws-1',
            name: '',
            createdAt: testCreatedAt,
          ),
          throwsA(isA<AssertionError>()),
        );
      });
    });

    group('copyWith', () {
      test('returns identical team with no arguments', timeout: const Timeout.factor(2), () {
        final t = createTeam(description: 'original');
        final copy = t.copyWith();
        expect(copy.name, t.name);
        expect(copy.description, t.description);
        expect(copy.id, t.id);
        expect(copy.workspaceId, t.workspaceId);
        expect(copy.createdAt, t.createdAt);
      });

      test('updates name', timeout: const Timeout.factor(2), () {
        final t = createTeam();
        final copy = t.copyWith(name: 'Beta Team');
        expect(copy.name, 'Beta Team');
        expect(copy.id, t.id);
      });

      test('updates description', timeout: const Timeout.factor(2), () {
        final t = createTeam();
        final copy = t.copyWith(description: 'new desc');
        expect(copy.description, 'new desc');
      });

      test('preserves original when copyWith has null args', timeout: const Timeout.factor(2), () {
        final t = createTeam(description: 'original');
        final copy = t.copyWith();
        expect(copy.description, 'original');
      });
    });

    group('== and hashCode', () {
      test('== returns true for same id', timeout: const Timeout.factor(2), () {
        final t1 = createTeam(id: 'team-1');
        final t2 = createTeam(id: 'team-1', name: 'Different Name');
        expect(t1, equals(t2));
      });

      test('== returns false for different id', timeout: const Timeout.factor(2), () {
        final t1 = createTeam(id: 'team-1');
        final t2 = createTeam(id: 'team-2');
        expect(t1, isNot(equals(t2)));
      });

      test('== returns true for same reference', timeout: const Timeout.factor(2), () {
        final t = createTeam();
        expect(t, equals(t));
      });

      test('== returns false for different runtime type', timeout: const Timeout.factor(2), () {
        final t = createTeam();
        expect(t, isNot(equals('not a team')));
      });

      test('hashCode matches for equal teams', timeout: const Timeout.factor(2), () {
        final t1 = createTeam(id: 'team-1');
        final t2 = createTeam(id: 'team-1', name: 'Different');
        expect(t1.hashCode, equals(t2.hashCode));
      });

      test('hashCode differs for different teams', timeout: const Timeout.factor(2), () {
        final t1 = createTeam(id: 'team-1');
        final t2 = createTeam(id: 'team-2');
        expect(t1.hashCode, isNot(equals(t2.hashCode)));
      });
    });
  });
}
