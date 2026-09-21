import 'package:cc_domain/features/messaging/domain/entities/space.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Space', () {
    test('equality works', () {
      final a = Space(
        id: 'ch-1',
        name: 'General',
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
      );
      final b = Space(
        id: 'ch-1',
        name: 'General',
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
      );
      expect(a, equals(b));
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
      expect(updated.id, space.id);
    });
  });
}
