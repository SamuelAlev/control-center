import 'package:cc_domain/features/messaging/domain/entities/space.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Space', () {
    Space createSpace({String name = 'General'}) {
      return Space(
        id: 'ch-1',
        name: name,
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
      );
    }

    test('constructs with required fields', () {
      final space = createSpace();
      expect(space.id, 'ch-1');
      expect(space.name, 'General');
    });

    test('supports an empty name', () {
      final space = createSpace(name: '');
      expect(space.name, '');
    });

    test('supports workspaceId', () {
      final space = Space(
        id: 'ch-2',
        name: 'Team',
        workspaceId: 'ws-1',
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
      );
      expect(space.workspaceId, 'ws-1');
    });

    test('equality works', () {
      final a = createSpace();
      final b = createSpace();
      expect(a, equals(b));
    });

    test('copyWith overrides', () {
      final space = createSpace();
      final updated = space.copyWith(name: 'Updated');
      expect(updated.name, 'Updated');
      expect(updated.id, space.id);
    });

    test('copyWith can remove workspaceId', () {
      final space = Space(
        id: 'ch-1',
        name: 'General',
        workspaceId: 'ws-1',
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
      );
      final updated = space.copyWith(removeWorkspaceId: true);
      expect(updated.workspaceId, isNull);
    });
  });
}
