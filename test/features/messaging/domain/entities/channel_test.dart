import 'package:cc_domain/features/messaging/domain/entities/channel.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Channel', () {
    Channel createChannel({String name = 'General'}) {
      return Channel(
        id: 'ch-1',
        name: name,
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
      );
    }

    test('constructs with required fields', () {
      final channel = createChannel();
      expect(channel.id, 'ch-1');
      expect(channel.name, 'General');
    });

    test('supports an empty name', () {
      final channel = createChannel(name: '');
      expect(channel.name, '');
    });

    test('supports workspaceId', () {
      final channel = Channel(
        id: 'ch-2',
        name: 'Team',
        workspaceId: 'ws-1',
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
      );
      expect(channel.workspaceId, 'ws-1');
    });

    test('equality works', () {
      final a = createChannel();
      final b = createChannel();
      expect(a, equals(b));
    });

    test('copyWith overrides', () {
      final channel = createChannel();
      final updated = channel.copyWith(name: 'Updated');
      expect(updated.name, 'Updated');
      expect(updated.id, channel.id);
    });

    test('copyWith can remove workspaceId', () {
      final channel = Channel(
        id: 'ch-1',
        name: 'General',
        workspaceId: 'ws-1',
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
      );
      final updated = channel.copyWith(removeWorkspaceId: true);
      expect(updated.workspaceId, isNull);
    });
  });
}
